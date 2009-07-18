//
//  L0MicroBindings.h
//  MuiKit
//
//  Created by ∞ on 17/07/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface L0KVODispatcher : NSObject {
	id target;
	NSMutableDictionary* selectorsByKeyPathsAndObjects;	
}

- (id) initWithTarget:(id) target;

// Generic observation method.
// The selector must be of the form - (void) keyOfObject:(id) object changed:(NSDictionary*) change;
// The change dictionary is the same one that KVO would have reported
// in observeValueForKeyPath:ofObject:change:context:.
- (void) observe:(NSString*) keyPath ofObject:(id) object usingSelector:(SEL) selector options:(NSKeyValueObservingOptions) options;

// We could keep track of the required selectors ourselves, but it's long stuff, so we offload
// this responsibility to our clients and provide only the dispatch code.
// To use, observe a key path with observe:... above, then in the selector call -forEachArrayChange:...
// or -forEachSetChange:... to invoke the selectors for each object that was inserted, removed or replaced.

// insertion =>   - (void) inArrayOfObject:(id) o inserted:(id) i atIndex:(NSUInteger) idx;
// removal =>     - (void) inArrayOfObject:(id) o removed:(id) i atIndex:(NSUInteger) idx;
// replacement => - (void) inArrayOfObject:(id) o replaced:(id) oldObject with:(id) newObject atIndex:(NSUInteger) idx;
// If replacement == NULL, instead a removal will be reported for the old object, then an insertion for the new object.
- (void) forEachArrayChange:(NSDictionary*) change forObject:(id) o invokeSelectorForInsertion:(SEL) insertion removal:(SEL) removal replacement:(SEL) replacement;

// insertion =>   - (void) inArrayOfObject:(id) o inserted:(id) i;
// removal =>     - (void) inArrayOfObject:(id) o removed:(id) i;
// Replacement mutations are always reported as removal of all old objects, followed by insertion of all new ones.
- (void) forEachSetChange:(NSDictionary*) change forObject:(id) o invokeSelectorForInsertion:(SEL) insertion removal:(SEL) removal;

// Ends observing a key path whose observation started with observe:..., observeArray:... or observeSet:...
// Note that deallocating the dispatcher will automatically remove all observation registrations.
- (void) endObserving:(NSString*) keyPath ofObject:(id) object;

@end
