//
//  L0MicroBindings.m
//  MuiKit
//
//  Created by ∞ on 17/07/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "L0KVODispatcher.h"
#import "L0KVODictionaryAdditions.h"

#if kL0KVODispatcherAllowVerboseLogging
#define L0KVOLog L0Log
#else
#define L0KVOLog(...)
#endif

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
	
	L0KVOLog(@"watching (a %@).%@ using %@", [object class], keyPath, selectorStringOrBlock);
#if DEBUG
	[self willObserveKeyPath:keyPath ofObject:object];
#endif
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
		// Prevent the object from going out of scope soon.
		[[object retain] autorelease];
		
#if __BLOCKS__
		if (![selectorStringOrBlock isKindOfClass:[NSString class]]) {
			((L0KVODispatcherChangeBlock)selectorStringOrBlock)(object, change);
		} else
#endif
		{
			[target performSelector:NSSelectorFromString(selectorStringOrBlock) withObject:object withObject:change];
		}
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
		L0KVOLog(@"stopping observation of (a %@).%@", [object class], keyPath);
		
		[selectorsByKeyPath removeObjectForKey:keyPath];
		if ([selectorsByKeyPath count] == 0)
			[selectorsByKeyPathsAndObjects removeObjectForKey:ptr];
		
		[object removeObserver:self forKeyPath:keyPath];

#if DEBUG
		[self didEndObservingKeyPath:keyPath ofObject:object];
#endif		
		
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
	
	if ([removals conformsToProtocol:@protocol(NSFastEnumeration)]) {
		for (id removedObject in removals) {
			removal(removedObject);
		}
	} else if (removals && ![removals isKindOfClass:[NSNull class]])
		removal(removals);
	
	if ([insertions conformsToProtocol:@protocol(NSFastEnumeration)]) {
		for (id insertedObject in insertions) {
			insertion(insertedObject);
		}	
	} else if (insertions && ![insertions isKindOfClass:[NSNull class]])
		insertion(insertions);
}
#endif

@end

#if DEBUG

/* -- - -- DEBUG FACILITIES -- - -- */

static NSMutableDictionary* nonretainedObjectsToObservers = nil;

@implementation L0KVODispatcher (L0KVODispatcherDebugTools)

+ (BOOL) shouldKeepTrackOfObservers;
{
	static BOOL foundOut = NO, shouldKeepTrack;
	
	if (!foundOut) {
		shouldKeepTrack = NO;
		
		if ([[NSUserDefaults standardUserDefaults] boolForKey:@"L0KVODispatcherShouldKeepTrackOfObservers"])
			shouldKeepTrack = YES;
		else {
			char* envVar = getenv("L0KVODispatcherShouldKeepTrackOfObservers");
			if (envVar && strcmp(envVar, "YES") == 0)
				shouldKeepTrack = YES;
		}
		
		if (shouldKeepTrack) {
			L0LogAlways(@"\n\n!! WARNING !!\nL0KVODispatcher is now tracking all observations, which you can query using [L0KVODispatcher observersOfObject:...] and [L0KVODispatcher observersOfObject:... keyPath:...]. Make sure you disable this when running normally.\n\n");
		}
		
		foundOut = YES;
	}
	
	return shouldKeepTrack;
}

+ nonretainedObjectsToObservers;
{
	if (!nonretainedObjectsToObservers)
		nonretainedObjectsToObservers = [NSMutableDictionary new];
	
	return nonretainedObjectsToObservers;
}

+ (void) addObserver:(L0KVODispatcher*) d ofKeyPath:(NSString*) path ofObject:(id) o;
{
	if (![self shouldKeepTrackOfObservers]) return;
	
	NSValue* v = [NSValue valueWithNonretainedObject:o];
	NSMutableDictionary* n2o = [self nonretainedObjectsToObservers];
	NSMutableDictionary* keysToDispatchers = [n2o objectForKey:v];
	
	if (!keysToDispatchers) {
		keysToDispatchers = [NSMutableDictionary dictionary];
		[n2o setObject:keysToDispatchers forKey:v];
	}
	
	NSMutableArray* dispatchers = [keysToDispatchers objectForKey:path];
	if (!dispatchers) {
		dispatchers = [NSMutableArray array];
		[keysToDispatchers setObject:dispatchers forKey:path];
	}
	
	[dispatchers addObject:d];
}

+ (void) removeObserver:(L0KVODispatcher*) d ofKeyPath:(NSString*) path ofObject:(id) o;
{
	if (![self shouldKeepTrackOfObservers]) return;
	
	NSValue* v = [NSValue valueWithNonretainedObject:o];
	NSMutableDictionary* n2o = [self nonretainedObjectsToObservers];
	
	NSMutableDictionary* keysToDispatchers = [n2o objectForKey:v];
	if (!keysToDispatchers)
		return;
	
	NSMutableArray* dispatchers = [keysToDispatchers objectForKey:path];
	if (!dispatchers)
		return;
	
	[dispatchers removeObject:d];
	if ([dispatchers count] == 0)
		[keysToDispatchers removeObjectForKey:path];
	if ([keysToDispatchers count] == 0)
		[n2o removeObjectForKey:v];
}

- (void) willObserveKeyPath:(NSString*) kp ofObject:(id) o;
{
	[[self class] addObserver:self ofKeyPath:kp ofObject:o];
}

- (void) didEndObservingKeyPath:(NSString*) kp ofObject:(id) o;
{
	[[self class] removeObserver:self ofKeyPath:kp ofObject:o];
}

+ (NSDictionary*) observersOfObject:(id) o;
{
	if (![self shouldKeepTrackOfObservers]) return nil;

	return [[self nonretainedObjectsToObservers] objectForKey:[NSValue valueWithNonretainedObject:o]];
}

+ (NSArray*) observersOfObject:(id) o keyPath:(NSString*) path;
{
	if (![self shouldKeepTrackOfObservers]) return nil;

	return [[self observersOfObject:o] objectForKey:path];
}

@end

#endif