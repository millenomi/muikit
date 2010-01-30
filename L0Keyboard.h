//
//  L0Keyboard.h
//  MuiKit
//
//  Created by ∞ on 30/01/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#if TARGET_OS_IPHONE

#import <UIKit/UIKit.h>

@class L0KeyboardRubberBand;
@protocol L0KeyboardObserver;

@interface L0Keyboard : NSObject {
	NSMutableSet* observers;
	
	BOOL shown;
	
	CGRect bounds;
	CGPoint center;
	
	BOOL animating;
	CGPoint animationStartCenter;
	NSTimeInterval animationDuration;
	UIViewAnimationCurve animationCurve;
}

+ (L0Keyboard*) sharedInstance;

/* Adding an observer retains it! Be wary. */
- (void) addObserver:(id <L0KeyboardObserver>) o;
- (void) removeObserver:(id <L0KeyboardObserver>) o;

/* 'original' is the frame the view has when there is no keyboard around.
 If the keyboard isn't shown, then the original frame will be returned (or the view resized to it). */
- (CGRect) resizedFrameOfViewToPreventCovering:(UIView*) v originalFrame:(CGRect) original;

/* Resizes the view as per the above method. animated:YES will animate the resizing with the same duration and curve as the keyboard; it only works while the keyboard is animating (in a will... observer method, while self.animating == YES). */
- (void) resizeViewToPreventCovering:(UIView*) v originalFrame:(CGRect) original animated:(BOOL) ani;

@property(readonly, getter=isShown) BOOL shown;
@property(readonly, getter=isAnimating) BOOL animating;

@property(readonly) CGRect bounds;
@property(readonly) CGPoint center;

@property(readonly) CGPoint animationStartCenter;
@property(readonly) NSTimeInterval animationDuration;
@property(readonly) UIViewAnimationCurve animationCurve;

@end


@protocol L0KeyboardObserver <NSObject>

@optional

- (void) keyboardWillAppear:(L0Keyboard*) k;
- (void) keyboardWillDisappear:(L0Keyboard*) k;

- (void) keyboardDidAppear:(L0Keyboard*) k;
- (void) keyboardDidDisappear:(L0Keyboard*) k;

@end

/* Keyboard rubber bands are keyboard observers that automatically resize their associated views when the keyboard appears and disappears. */
@interface L0KeyboardRubberBand : NSObject <L0KeyboardObserver> {
	CGRect originalFrame;
	UIView* view;
	BOOL animated;
}

@property CGRect originalFrame;
@property(retain) UIView* view;
@property BOOL animated; // defaults to YES

+ keyboardRubberBandForView:(UIView*) v;
+ keyboardRubberBandForView:(UIView*) v originalFrame:(CGRect) o;

@end

#endif
