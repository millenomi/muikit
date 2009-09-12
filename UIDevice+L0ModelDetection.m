//
//  UIDevice+L0ModelDetection.m
//  MuiKit
//
//  Created by ∞ on 11/04/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#if TARGET_OS_IPHONE

#import "UIDevice+L0ModelDetection.h"

@implementation UIDevice (L0ModelDetection)

- (L0DeviceFamily) deviceFamily;
{
	if ([self.model rangeOfString:@"iPhone"].location == NSNotFound)
		return kL0DeviceFamily_iPodTouch;
	else
		return kL0DeviceFamily_iPhone;
}

@end

#endif
