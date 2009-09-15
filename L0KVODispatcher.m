//
//  L0MicroBindings.m
//  MuiKit
//
//  Created by ∞ on 17/07/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "L0KVODispatcher.h"
#import "L0KVODictionaryAdditions.h"

L0UniquePointerConstant(kL0KVODispatcherObservingContext);

@interface L0KVODispatcher ()

- (void) observe:(NSString *)keyPath ofObject:(id)object usingSelectorStringOrBlock:(id)selectorStringOrBlock options:(NSKeyValueObservingOptions)options;

@end

void L0KVODispatcherNoteEndReentry(id object, NSString* keyPath)
{
	
	L0LogAlways(@"Owch. This shouldn't have happened: endObserving:'%@' ofObject:%@ was called during an observe:... call. It can happen if you use NSKeyValueObservingOptionInitial. Fixing this is nontrivial and you should really really REALLY refactor your code to check the initial condition instead, or remove KVO dispatcher state changes in this callback.\nAs a convenient workaround, I have enqueued an end-observing call on the run loop which should work, but bizarreness is always around the corner. PS: break on L0KVODispatcherNoteEndReentry() to debug.", keyPath, object);
}


@implementation L0KVODispatcher

- (id) initWithTarget:(id) t;
{
	if (self = [super init]) {
		target = t;
		selectorsByKeyPathsAndObjects = [NSMutableDictionary new];
	}
		
	return self;
}

- (void) dealloc;
{
	for (NSValue* ptr in selectorsByKeyPathsAndObjects) {
		id object = [ptr nonretainedObjectValue];
		
		for (NSString* keyPath in [selectorsByKeyPathsAndObjects objectForKey:ptr])
			[object removeObserver:self forKeyPath:keyPath];
	}
	
	[selectorsByKeyPathsAndObjects release];
	[super dealloc];
}

- description;
{
	return [NSString stringWithFormat:@"%@ { target = %@ }", [super description], target];
}

#pragma mark -
#pragma mark Observation

- (void) observe:(NSString*) keyPath ofObject:(id) object usingSelector:(SEL) selector options:(NSKeyValueObservingOptions) options;
{
	[self observe:keyPath ofObject:object usingSelectorStringOrBlock:NSStringFromSelector(selector) options:options];
}

- (void) observe:(NSString *)keyPath ofObject:(id)object usingSelectorStringOrBlock:(id)selectorStringOrBlock options:(NSKeyValueObservingOptions)options;
{	
	NSValue* ptr = [NSValue valueWithNonretainedObject:object];
	NSMutableDictionary* selectorsByKeyPath = [selectorsByKeyPathsAndObjects objectForKey:ptr];
	NSString* previousSelector = [selectorsByKeyPath objectForKey:keyPath];
	
	if (!selectorsByKeyPath) {
		selectorsByKeyPath = [NSMutableDictionary dictionary];
		[selectorsByKeyPathsAndObjects setObject:selectorsByKeyPath forKey:ptr];
	}
	
	BOOL alreadyRegistered = (previousSelector != nil) && ![previousSelector isEqual:selectorStringOrBlock];
	
	NSAssert(!alreadyRegistered, @"Should not be observing with a different selector string");
	
	[selectorsByKeyPath setObject:[[selectorStringOrBlock copy] autorelease] forKey:keyPath];

	addingReentryCount++;
	[object addObserver:self forKeyPath:keyPath options:options context:(void*) kL0KVODispatcherObservingContext];
	addingReentryCount--;
	
	L0Log(@"%@ -- watching (a %@).%@ using %@", self, [object class], keyPath, selectorStringOrBlock);
}

#if __BLOCKS__
- (void) observe:(NSString*) keyPath ofObject:(id) object options:(NSKeyValueObservingOptions) options usingBlock:(L0KVODispatcherChangeBlock) block;
{
	[self observe:keyPath ofObject:object usingSelectorStringOrBlock:[[block copy] autorelease] options:options];
}
#endif

- (void) observeValueForKeyPath:(NSString*) keyPath ofObject:(id) object change:(NSDictionary*) change context:(void*) context;
{
	if (context != kL0KVODispatcherObservingContext) return;
	
	NSValue* ptr = [NSValue valueWithNonretainedObject:object];
	NSMutableDictionary* selectorsByKeyPath = [selectorsByKeyPathsAndObjects objectForKey:ptr];
	id selectorStringOrBlock = [selectorsByKeyPath objectForKey:keyPath];

	if (selectorStringOrBlock) {
#if __BLOCKS__
		if (![selectorStringOrBlock isKindOfClass:[NSString class]]) {
			((L0KVODispatcherChangeBlock)selectorStringOrBlock)(object, change);
		} else
#endif
		[target performSelector:NSSelectorFromString(selectorStringOrBlock) withObject:object withObject:change];
	}
}

- (void) endObservingObjectAndKeyPath:(NSArray*) objectAndKeyPath;
{
	[self endObserving:[objectAndKeyPath objectAtIndex:0] ofObject:[objectAndKeyPath objectAtIndex:1]];
}

- (void) endObserving:(NSString*) keyPath ofObject:(id) object;
{
	if (addingReentryCount > 0) {
		[self performSelector:@selector(endObservingObjectAndKeyPath:) withObject:[NSArray arrayWithObjects:object, keyPath, nil] afterDelay:0.01];
		L0KVODispatcherNoteEndReentry(object, keyPath);
		return;
	}
	
	NSValue* ptr = [NSValue valueWithNonretainedObject:object];
	NSMutableDictionary* selectorsByKeyPath = [selectorsByKeyPathsAndObjects objectForKey:ptr];

	if ([selectorsByKeyPath objectForKey:keyPath]) {
		L0Log(@"%@ stopping observation of (a %@).%@", self, [object class], keyPath);
		
		[selectorsByKeyPath removeObjectForKey:keyPath];
		if ([selectorsByKeyPath count] == 0)
			[selectorsByKeyPathsAndObjects removeObjectForKey:ptr];
		
		[object removeObserver:self forKeyPath:keyPath];
	}
}

#pragma mark -
#pragma mark To-many dispatch.

// insertion =>   - (void) inArrayOfObject:(id) o inserted:(id) i atIndex:(NSUInteger) idx;
// removal =>     - (void) inArrayOfObject:(id) o removed:(id) i atIndex:(NSUInteger) idx;
// replacement => - (void) inArrayOfObject:(id) o replaced:(id) oldObject with:(id) newObject atIndex:(NSUInteger) idx;
- (void) forEachArrayChange:(NSDictionary*) change forObject:(id) o invokeSelectorForInsertion:(SEL) insertion removal:(SEL) removal replacement:(SEL) replacement;
{
	NSKeyValueChange changeKind = L0KVOChangeKind(change);
	NSInvocation* insertionInv = nil, * removalInv = nil, * replacementInv = nil;
	
	// Set up the invocation stuff.
	if (changeKind == NSKeyValueChangeInsertion || (changeKind == NSKeyValueChangeReplacement && !replacement)) {
		NSMethodSignature* insertSig = [target methodSignatureForSelector:insertion];
		insertionInv = [NSInvocation invocationWithMethodSignature:insertSig];
		
		[insertionInv setTarget:target];
		[insertionInv setSelector:insertion];
		[insertionInv setArgument:&o atIndex:2];
	}
	
	if (changeKind == NSKeyValueChangeRemoval || (changeKind == NSKeyValueChangeReplacement && !replacement)) {
		NSMethodSignature* removeSig = [target methodSignatureForSelector:removal];
		removalInv = [NSInvocation invocationWithMethodSignature:removeSig];
		
		[removalInv setTarget:target];
		[removalInv setSelector:removal];
		[removalInv setArgument:&o atIndex:2];
	}	

	if (changeKind == NSKeyValueChangeReplacement && replacement) {
		NSMethodSignature* replacementSig = [target methodSignatureForSelector:replacement];
		replacementInv = [NSInvocation invocationWithMethodSignature:replacementSig];
		
		[replacementInv setTarget:target];
		[replacementInv setSelector:replacement];
		[replacementInv setArgument:&o atIndex:2];
	}
	
	
	NSIndexSet* indexes = L0KVOChangedIndexes(change);
	
	NSUInteger arrayIndex = [indexes firstIndex], changeIndex = 0;
	NSArray* insertions = (changeKind == NSKeyValueChangeRemoval)? nil : L0KVOChangedValue(change);
	NSArray* removals = (changeKind == NSKeyValueChangeInsertion)? nil : L0KVOPreviousValue(change);

	while (arrayIndex != NSNotFound) {		
		id insertedObject = [insertions objectAtIndex:changeIndex];
		id removedObject = [removals objectAtIndex:changeIndex];
		
		if (changeKind == NSKeyValueChangeRemoval || (changeKind == NSKeyValueChangeReplacement && !replacement)) {
			[removalInv setArgument:&removedObject atIndex:3];
			[removalInv setArgument:&arrayIndex atIndex:4];
			[removalInv invoke];			
		}
		
		if (changeKind == NSKeyValueChangeInsertion || (changeKind == NSKeyValueChangeReplacement && !replacement)) {
			[insertionInv setArgument:&insertedObject atIndex:3];
			[insertionInv setArgument:&arrayIndex atIndex:4];
			[insertionInv invoke];
		}
		
		if (changeKind == NSKeyValueChangeReplacement && replacement) {
			[replacementInv setArgument:&removedObject atIndex:3];
			[replacementInv setArgument:&insertedObject atIndex:4];
			[replacementInv setArgument:&arrayIndex atIndex:5];
			[replacementInv invoke];
		}
		
		arrayIndex = [indexes indexGreaterThanIndex:arrayIndex];
		changeIndex++;
	}
}

- (void) forEachSetChange:(NSDictionary*) change forObject:(id) o invokeSelectorForInsertion:(SEL) insertion removal:(SEL) removal;
{
	NSKeyValueChange changeKind = L0KVOChangeKind(change);
	NSInvocation* insertionInv = nil, * removalInv = nil;
	
	// Set up the invocation stuff.
	if (changeKind == NSKeyValueChangeInsertion || changeKind == NSKeyValueChangeReplacement) {
		NSMethodSignature* insertSig = [target methodSignatureForSelector:insertion];
		insertionInv = [NSInvocation invocationWithMethodSignature:insertSig];
		
		[insertionInv setTarget:target];
		[insertionInv setSelector:insertion];
		[insertionInv setArgument:&o atIndex:2];
	}
	
	if (changeKind == NSKeyValueChangeRemoval || changeKind == NSKeyValueChangeReplacement) {
		NSMethodSignature* removeSig = [target methodSignatureForSelector:removal];
		removalInv = [NSInvocation invocationWithMethodSignature:removeSig];
		
		[removalInv setTarget:target];
		[removalInv setSelector:removal];
		[removalInv setArgument:&o atIndex:2];
	}
	
	NSSet* insertions = (changeKind == NSKeyValueChangeRemoval)? nil : L0KVOChangedValue(change);
	NSSet* removals = (changeKind == NSKeyValueChangeInsertion)? nil : L0KVOPreviousValue(change);
	
	for (id removedObject in removals) {
		[removalInv setArgument:&removedObject atIndex:3];
		[removalInv invoke];
	}
	
	for (id insertedObject in insertions) {
		[insertionInv setArgument:&insertedObject atIndex:3];
		[insertionInv invoke];
	}
}

#if __BLOCKS__
- (void) forEachArrayChange:(NSDictionary*) change invokeBlockForInsertion:(L0KVODispatcherArrayChangeBlock) insertion removal:(L0KVODispatcherArrayChangeBlock) removal replacement:(L0KVODispatcherArrayReplacementBlock) replacement;
{
	NSKeyValueChange changeKind = L0KVOChangeKind(change);
	
	NSIndexSet* indexes = L0KVOChangedIndexes(change);
	
	NSUInteger arrayIndex = [indexes firstIndex], changeIndex = 0;
	NSArray* insertions = (changeKind == NSKeyValueChangeRemoval)? nil : L0KVOChangedValue(change);
	NSArray* removals = (changeKind == NSKeyValueChangeInsertion)? nil : L0KVOPreviousValue(change);
	
	while (arrayIndex != NSNotFound) {		
		id insertedObject = [insertions objectAtIndex:changeIndex];
		id removedObject = [removals objectAtIndex:changeIndex];
		
		if (changeKind == NSKeyValueChangeRemoval || (changeKind == NSKeyValueChangeReplacement && !replacement))
			removal(removedObject, arrayIndex);			
		
		if (changeKind == NSKeyValueChangeInsertion || (changeKind == NSKeyValueChangeReplacement && !replacement))
			insertion(removedObject, arrayIndex);
		
		if (changeKind == NSKeyValueChangeReplacement && replacement)
			replacement(removedObject, insertedObject, arrayIndex);
		
		arrayIndex = [indexes indexGreaterThanIndex:arrayIndex];
		changeIndex++;
	}	
}

- (void) forEachSetChange:(NSDictionary*) change invokeBlockForInsertion:(L0KVODispatcherSetChangeBlock) insertion removal:(L0KVODispatcherSetChangeBlock) removal;
{
	NSKeyValueChange changeKind = L0KVOChangeKind(change);
	
	NSSet* insertions = (changeKind == NSKeyValueChangeRemoval)? nil : L0KVOChangedValue(change);
	NSSet* removals = (changeKind == NSKeyValueChangeInsertion)? nil : L0KVOPreviousValue(change);
	
	for (id removedObject in removals) {
		removal(removedObject);
	}
	
	for (id insertedObject in insertions) {
		insertion(insertedObject);
	}	
}
#endif

@end
