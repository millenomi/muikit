//
//  L0SolicitReviewAppDelegate.h
//  L0SolicitReview
//
//  Created by ∞ on 13/12/08.
//  Copyright Emanuele Vulcano 2008. All rights reserved.
//

#if TARGET_OS_IPHONE

#import <UIKit/UIKit.h>

static inline CGSize L0SizeFromSizeNotLargerThan(CGSize r, CGSize maximum) {
	CGFloat ratio = r.width / r.height;
	
	if (r.width > r.height) {
		if (r.width > maximum.width) {
			r.width = maximum.width;
			r.height = maximum.width / ratio;
		}
	} else {
		if (r.height > maximum.height) {
			r.height = maximum.height;
			r.width = maximum.height * ratio;
		}
	}
	
	return r;
}

@interface UIImage (L0RenderingAdditions)

// Original code from badpirate at
// http://blog.logichigh.com/2008/06/05/uiimage-fix/

/*
 * Returns a new image which, when rendered upright, is the same as
 * the receiver except it is rotated in the direction of this image's
 * orientation (as returned by the imageOrientation property).
 * 
 * Additionally, the image is scaled so that no side is greater than
 * the given size parameter.
 * 
 */
- (UIImage*) imageByRenderingRotationAndScalingWithMaximumSide:(CGFloat) size;
- (UIImage*) imageByRenderingRotation;

@end

#endif