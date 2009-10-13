//
//  UIDevice+L0ModelDetection.m
//  MuiKit
//
//  Created by ∞ on 11/04/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#if TARGET_OS_IPHONE

#import "UIDevice+L0ModelDetection.h"
#import <sys/sysctl.h>

#define kL0UIDeviceInternalModelNameSysctl "hw.machine"

@implementation UIDevice (L0ModelDetection)

- (L0DeviceFamily) deviceFamily;
{
	if ([self.model rangeOfString:@"iPhone"].location == NSNotFound)
		return kL0DeviceFamily_iPodTouch;
	else
		return kL0DeviceFamily_iPhone;
}

- (NSString*) internalModelName;
{
	size_t length;
	if (sysctlbyname(kL0UIDeviceInternalModelNameSysctl, NULL, &length, NULL, 0) == -1)
		return nil;
	
	char hardwareModelC[length];
	if (sysctlbyname(kL0UIDeviceInternalModelNameSysctl, &hardwareModelC, &length, NULL, 0) == -1)
		return nil;
	
	return [[[NSString alloc] initWithBytes:hardwareModelC length:length - 1 encoding:NSASCIIStringEncoding] autorelease];
}

@end

#endif
