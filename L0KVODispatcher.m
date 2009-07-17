//
//  L0MicroBindings.m
//  MuiKit
//
//  Created by ∞ on 17/07/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "L0KVODispatcher.h"

L0UniquePointerConstant(kL0MicroBindingsObservingContext);

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

- (void) observe:(NSString*) keyPath ofObject:(id) object usingSelector:(SEL) selector options:(NSKeyValueObservingOptions) options;
{
	NSValue* ptr = [NSValue valueWithNonretainedObject:object];
	NSMutableDictionary* selectorsByKeyPath = [selectorsByKeyPathsAndObjects objectForKey:ptr];
	NSString* selectorString = [selectorsByKeyPath objectForKey:keyPath];
	
	
	if (!selectorsByKeyPath) {
		selectorsByKeyPath = [NSMutableDictionary dictionary];
		[selectorsByKeyPathsAndObjects setObject:selectorsByKeyPath forKey:ptr];
	}

	BOOL alreadyRegistered = (selectorString != nil);

	selectorString = NSStringFromSelector(selector);		
	[selectorsByKeyPath setObject:selectorString forKey:keyPath];
		
	if (!alreadyRegistered)
		[object addObserver:self forKeyPath:keyPath options:options context:(void*) kL0MicroBindingsObservingContext];
}

- (void) observeValueForKeyPath:(NSString*) keyPath ofObject:(id) object change:(NSDictionary*) change context:(void*) context;
{
	if (context != kL0MicroBindingsObservingContext) return;
	
	NSValue* ptr = [NSValue valueWithNonretainedObject:object];
	NSMutableDictionary* selectorsByKeyPath = [selectorsByKeyPathsAndObjects objectForKey:ptr];
	NSString* selectorString = [selectorsByKeyPath objectForKey:keyPath];

	if (selectorString)
		[target performSelector:NSSelectorFromString(selectorString) withObject:object withObject:change];
}

- (void) endObserving:(NSString*) keyPath ofObject:(id) object;
{
	NSValue* ptr = [NSValue valueWithNonretainedObject:object];
	NSMutableDictionary* selectorsByKeyPath = [selectorsByKeyPathsAndObjects objectForKey:ptr];
	NSString* selectorString = [selectorsByKeyPath objectForKey:keyPath];

	[selectorsByKeyPath removeObjectForKey:keyPath];
	if ([selectorsByKeyPath count] == 0)
		[selectorsByKeyPathsAndObjects removeObjectForKey:ptr];
	
	[object removeObserver:self forKeyPath:keyPath];
}

@end
