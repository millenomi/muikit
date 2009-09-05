//
//  L0MicroBindings.h
//  MuiKit
//
//  Created by ∞ on 17/07/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifdef __BLOCKS__

typedef void (^L0KVODispatcherChangeBlock)(id object, NSDictionary* change);

// Please note -- since these are meant to be called in a KVO observation notification
// method, it is assumed you can exploit its closure to have a reference to the source object,
// so it isn't passed back as it happens in the selector-based variant.

typedef void (^L0KVODispatcherArrayChangeBlock)(id object, NSUInteger index);
typedef void (^L0KVODispatcherArrayReplacementBlock)(id oldObject, id newObject, NSUInteger index);
typedef void (^L0KVODispatcherSetChangeBlock)(id object);
#endif


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

#if __BLOCKS__
// As above, but uses a block for dispatch.

- (void) observe:(NSString*) keyPath ofObject:(id) object options:(NSKeyValueObservingOptions) options usingBlock:(L0KVODispatcherChangeBlock) block;
#endif

// We could keep track of the required selectors ourselves, but it's long stuff, so we offload
// this responsibility to our clients and provide only the dispatch code.
// To use, observe a key path with observe:... above, then in the selector call -forEachArrayChange:...
// or -forEachSetChange:... to invoke the selectors for each object that was inserted, removed or replaced.
// Pass in the change dictionary and the object. Can also be used elsewhere if you have a KVO change dictionary
// to dispatch.

// insertion =>   - (void) inArrayOfObject:(id) o inserted:(id) i atIndex:(NSUInteger) idx;
// removal =>     - (void) inArrayOfObject:(id) o removed:(id) i atIndex:(NSUInteger) idx;
// replacement => - (void) inArrayOfObject:(id) o replaced:(id) oldObject with:(id) newObject atIndex:(NSUInteger) idx;
// If replacement == NULL, instead a removal will be reported for the old object, then an insertion for the new object.
- (void) forEachArrayChange:(NSDictionary*) change forObject:(id) o invokeSelectorForInsertion:(SEL) insertion removal:(SEL) removal replacement:(SEL) replacement;

// insertion =>   - (void) inArrayOfObject:(id) o inserted:(id) i;
// removal =>     - (void) inArrayOfObject:(id) o removed:(id) i;
// Replacement mutations are always reported as removal of all old objects, followed by insertion of all new ones.
- (void) forEachSetChange:(NSDictionary*) change forObject:(id) o invokeSelectorForInsertion:(SEL) insertion removal:(SEL) removal;

#if __BLOCKS__
// Blocks-based versions of the above.
- (void) forEachArrayChange:(NSDictionary*) change invokeBlockForInsertion:(L0KVODispatcherArrayChangeBlock) insertion removal:(L0KVODispatcherArrayChangeBlock) removal replacement:(L0KVODispatcherArrayReplacementBlock) replacement;

- (void) forEachSetChange:(NSDictionary*) change invokeBlockForInsertion:(L0KVODispatcherSetChangeBlock) insertion removal:(L0KVODispatcherSetChangeBlock) removal;
#endif

// Ends observing a key path whose observation started with observe:..., observeArray:... or observeSet:...
// Note that deallocating the dispatcher will automatically remove all observation registrations.
- (void) endObserving:(NSString*) keyPath ofObject:(id) object;

@end
