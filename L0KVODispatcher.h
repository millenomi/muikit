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

- (void) observe:(NSString*) keyPath ofObject:(id) object usingSelector:(SEL) selector options:(NSKeyValueObservingOptions) options;
- (void) endObserving:(NSString*) keyPath ofObject:(id) object;

@end
