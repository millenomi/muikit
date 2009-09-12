//
//  L0Map.m
//  MuiKit
//
//  Created by ∞ on 12/09/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "L0Map.h"


@implementation L0Map

- (id) initWithKeyCallbacks:(const CFDictionaryKeyCallBacks*) kcbs valueCallbacks:(const CFDictionaryValueCallBacks*) vcbs;
{
	if (self = [super init])
		dict = CFDictionaryCreateMutable(kCFAllocatorDefault, 0, kcbs, vcbs);
	
	return self;
}


- (id) init;
{
	return [self initWithKeyCallbacks:&kCFTypeDictionaryKeyCallBacks valueCallbacks:&kCFTypeDictionaryValueCallBacks];
}

- (void) dealloc;
{
	CFRelease(dict);
	[super dealloc];
}

+ map;
{
	return [[self new] autorelease];
}

#pragma mark -
#pragma mark Accessors

- (NSUInteger) count;
{
	return CFDictionaryGetCount(dict);
}

- (void) setObject:(id) o forKey:(id) k;
{
	[self setPointer:o forPointerKey:k];
}

- (id) objectForKey:(id) k;
{
	return (id) [self pointerForPointerKey:k];
}

- (void) removeObjectForKey:(id) k;
{
	[self removeObjectForPointerKey:k];
}

- (void) setPointer:(void*) o forPointerKey:(void*) k;
{
	CFDictionarySetValue(dict, k, o);
}

- (void*) pointerForPointerKey:(void*) k;
{
	return (void*) CFDictionaryGetValue(dict, k);
}

- (void) removeObjectForPointerKey:(void*) k;
{
	CFDictionaryRemoveValue(dict, (const void*) k);
}

- (void) removeAllObjects;
{
	CFDictionaryRemoveAllValues(dict);
}

- (void) getKeys:(void **)keys values:(void **)objects;
{
	CFDictionaryGetKeysAndValues(dict, (const void**) keys, (const void**) objects);
}

- (void) getEnumeratorForKeys:(NSEnumerator**) keysEnu values:(NSEnumerator**) valuesEnu;
{
	NSUInteger c = [self count];
	void* values = malloc(c * sizeof(void*));
	void* keys = malloc(c * sizeof(void*));
	
	[self getKeys:&keys values:&values];
	
	if (keysEnu) {
		NSArray* a = [NSArray arrayWithObjects:(const id*) keys count:c];
		*keysEnu = [a objectEnumerator];
	}

	if (valuesEnu) {
		NSArray* a = [NSArray arrayWithObjects:(const id*) values count:c];
		*valuesEnu = [a objectEnumerator];
	}
	
	free(values);
	free(keys);
}

- (NSEnumerator*) allValues;
{
	NSEnumerator* vals; [self getEnumeratorForKeys:NULL values:&vals];
	return vals;
}

- (NSEnumerator*) allKeys;
{
	NSEnumerator* vals; [self getEnumeratorForKeys:&vals values:NULL];
	return vals;
}

@end
