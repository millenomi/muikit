//
//  L0Map.h
//  MuiKit
//
//  Created by ∞ on 12/09/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface L0Map : NSObject {
	CFMutableDictionaryRef dict;
}

// Designated init.
- (id) initWithKeyCallbacks:(const CFDictionaryKeyCallBacks*) kcbs valueCallbacks:(const CFDictionaryValueCallBacks*) vcbs;

// Makes a map whose keys and values are objects that get retained and released.
- (id) init;
+ map;

- (NSUInteger) count;

- (id) objectForKey:(id) k;
- (void*) pointerForPointerKey:(void*) k;

- (void) setObject:(id) o forKey:(id) k;
- (void) setPointer:(void*) o forPointerKey:(void*) k;

- (void) removeObjectForKey:(id) k;
- (void) removeObjectForPointerKey:(void*) k;
- (void) removeAllObjects;

// Neither can be NULL.
- (void) getKeys:(void**) keys values:(void**) objects;

// Either can be NULL.
- (void) getEnumeratorForKeys:(NSEnumerator**) keys values:(NSEnumerator**) objects;

- (NSEnumerator*) allValues;
- (NSEnumerator*) allKeys;

@end
