//
//  NSURL+L0URLResolvingRedirects.h
//  MuiKit
//
//  Created by ∞ on 17/07/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

#if kL0MuiKitAllowBlocks
typedef void (^L0URLResolvingDidEndBlock)(NSURL*);
#endif

@interface NSURL (L0URLResolvingRedirects)

- (void) beginResolvingRedirectsWithDelegate:(id) delegate selector:(SEL) selector;

#if kL0MuiKitAllowBlocks
- (void) beginResolvingRedirectsAndInvoke:(L0URLResolvingDidEndBlock) block;
#endif

@end
