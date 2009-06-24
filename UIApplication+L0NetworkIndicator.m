//
//  UIApplication-L0NetworkIndicator.m
//  MuiKit
//
//  Created by ∞ on 24/06/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "UIApplication+L0NetworkIndicator.h"


@implementation UIApplication (L0NetworkIndicator)

static int L0NumberOfNetworkUsers = 0;

- (void) beginNetworkUse;
{
	L0NumberOfNetworkUsers++;
	self.networkActivityIndicatorVisible = YES;
}

- (void) endNetworkUse;
{
	L0NumberOfNetworkUsers--;
	if (L0NumberOfNetworkUsers < 0)
		L0NumberOfNetworkUsers = 0;
	
	self.networkActivityIndicatorVisible = (L0NumberOfNetworkUsers > 0);
}

@end
