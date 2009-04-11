//
//  UIDevice+L0ModelDetection.h
//  MuiKit
//
//  Created by ∞ on 11/04/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

enum {
	kL0DeviceFamily_iPhone = 0,
	kL0DeviceFamily_iPodTouch = 1,
};
typedef NSUInteger L0DeviceFamily;

@interface UIDevice (L0ModelDetection)

@property(readonly) L0DeviceFamily deviceFamily;

@end
