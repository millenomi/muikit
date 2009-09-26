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
	
	int addingReentryCount;
}

- (id) initWithTarget:(id) target;

// Generic observation method.
// The selector must be of the form - (void) keyOfObject:(id) object changed:(NSDictionary*) change;
// The change dictionary is the same one that KVO would have reported
// in observeValueForKeyPath:ofObject:change:context:.
// Note that the KVO dispatcher does not retain the passed-in object. It's your responsibility to make
// sure it's kept alive for as long as needed.

// IMPLEMENTATION NOTE: L0KVODispatcher does NOT support altering the dispatcher's state while this method is being called. This might happen if options includes NSKeyValueObservingOptionInitial.
// IF YOU USE THIS FLAG, THE SELECTOR *MUST NOT* MAKE ANY CALL ON THE DISPATCHER BEFORE RETURNING. BEHAVIOR IN THIS CASE IS UNDEFINED.
- (void) observe:(NSString*) keyPath ofObject:(id) object usingSelector:(SEL) selector options:(NSKeyValueObservingOptions) options;

#if __BLOCKS__
// As above, but uses a block for dispatch.
// The same caveats apply for NSKeyValueObservingOptionInitial.
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
// Also note that unlike NSObject's removeObserver:... method, this method can safely be called to
// no effect in case you were not observing that key path on the object.
- (void) endObserving:(NSString*) keyPath ofObject:(id) object;

@end

#if DEBUG

/* DEBUG FACILITIES.
 KVO is hairy and brittle and opaque and I shouldn't really have based a product around it so yeah.
 L0KVODispatcher provides some debugging facilities to help fixing KVO trouble, especially someone-is-still-observing-on-dealloc KVO trouble.
 These facilities are disabled by default. To enable:
 
  - Make sure the copy of MuiKit you're linking to has the preprocessor directive DEBUG=1 set -- this happens automatically if you embed MuiKit by referencing the project and you use the Debug build style.
  - Do the following:
   * Set the @"L0KVODispatcherShouldKeepTrackOfObservers" user defaults key to YES (via setBool:forKey: or similar).
   AND/OR
   * Start the app with the L0KVODispatcherShouldKeepTrackOfObservers environment variable set to YES.
 
 Using the facilities yields arbitrary behavior if they're not on as specified above. Do not do that.
 
 So, if KVO says object 0x1234 is being still observed during its dealloc, just break on NSKVODeallocateBreak(), then issue a
	
	(gdb) po [L0KVODispatcher observersOfObject:(id) 0x1234]

 to see who's looking where they shouldn't. There, much better.
 */

@interface L0KVODispatcher (L0KVODispatcherDebugTools)

// Returns YES if debug facilities are turned on.
+ (BOOL) shouldKeepTrackOfObservers;

// Internal stuff used by the facilities.
// You can call nonretainedObjectsToObservers to get a NSDictionary of NSDictionaries which specifies who's observing what, in the following way:
// (NSValue with pointer to object being observed) => {
//		(key path observed) => [ (dispatcher 1), (dispatcher 2) ... ],
//		(key path observed 2) => [ (dispatcher a), (dispatcher b) ... ],
// }, ...
+ nonretainedObjectsToObservers;
+ addObserver:(L0KVODispatcher*) d ofKeyPath:(NSString*) path ofObject:(id) o;
+ removeObserver:(L0KVODispatcher*) d ofKeyPath:(NSString*) path ofObject:(id) o;

// IF debug facilities are on, you can break on these methods.
- (void) willObserveKeyPath:(NSString*) kp ofObject:(id) o;
- (void) didEndObservingKeyPath:(NSString*) kp ofObject:(id) o;

// Returns a dictionary where the keys are key paths observed on object o, and the values are arrays of KVO dispatchers that are currently observing that key.
+ (NSDictionary*) observersOfObject:(id) o;

// As per +observersOfObjects:, but returns just the array of dispatchers corresponding to the given key path.
+ (NSArray*) observersOfObject:(id) o keyPath:(NSString*) path;

@end

#endif
