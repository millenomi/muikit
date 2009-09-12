//
//  UIApplication-L0NetworkIndicator.h
//  MuiKit
//
//  Created by ∞ on 24/06/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#if TARGET_OS_IPHONE

#import <UIKit/UIKit.h>


@interface UIApplication (L0NetworkIndicator)

// These enable or disable the network indicator.
// Each call to endNetworkUse ends a previous call to
// beginNetworkUse. They can be nested. The network indicator
// will not be dismissed until all clients have called
// endNetworkUse to match all previous beginNetworkUse
// calls.

// Although some care must be taken to avoid UI artifacts,
// extraneous calls to endNetworkUse (that don't match
// any call to beginNetworkUse) are harmless and have no
// effect.

- (void) beginNetworkUse;
- (void) endNetworkUse;

@end

#endif
