//
//  L0Keyboard.m
//  MuiKit
//
//  Created by ∞ on 30/01/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#if TARGET_OS_IPHONE

#import "L0Keyboard.h"

@implementation L0Keyboard

+ sharedInstance;
{
	static id me = nil; if (!me)
		me = [self new];
	
	return me;
}

- (id) init
{
	self = [super init];
	if (self != nil) {
		observers = [NSMutableSet new];
		
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidShow:) name:UIKeyboardDidShowNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardDidHideNotification object:nil];
	}
	return self;
}

@synthesize shown, animating, bounds, center, animationStartCenter, animationDuration, animationCurve;

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[observers release];
	[super dealloc];
}


- (void) addObserver:(id <L0KeyboardObserver>) o;
{
	[observers addObject:o];
}

- (void) removeObserver:(id <L0KeyboardObserver>) o;
{
	[observers removeObject:o];
}


#define L0KeyboardDispatch(selector) \
	for (id <L0KeyboardObserver> o in observers) { \
		if ([o respondsToSelector:selector]) \
			[o performSelector:selector withObject:self]; \
	}
#define L0KeyboardSetFromUserInfoKey(variable, key, message, default) \
	id variable ## Object = [[n userInfo] objectForKey:key]; \
	variable = !variable ## Object? default : [variable ## Object message];

#define L0KeyboardSetVariablesFromCommonKeys() \
	L0KeyboardSetFromUserInfoKey(bounds, UIKeyboardBoundsUserInfoKey, CGRectValue, CGRectZero) \
	L0KeyboardSetFromUserInfoKey(center, UIKeyboardCenterEndUserInfoKey, CGPointValue, CGPointZero)

#define L0KeyboardSetVariablesFromAnimationKeys() \
	L0KeyboardSetFromUserInfoKey(animationDuration, UIKeyboardAnimationDurationUserInfoKey, doubleValue, 0.0) \
	L0KeyboardSetFromUserInfoKey(animationCurve, UIKeyboardAnimationCurveUserInfoKey, unsignedIntegerValue, UIViewAnimationCurveLinear) \
	L0KeyboardSetFromUserInfoKey(animationStartCenter, UIKeyboardCenterBeginUserInfoKey, CGPointValue, CGPointZero)

- (void) keyboardWillShow:(NSNotification*) n;
{
	L0KeyboardSetVariablesFromCommonKeys();
	L0KeyboardSetVariablesFromAnimationKeys();
	
	shown = YES;
	animating = YES;
	
	L0KeyboardDispatch(@selector(keyboardWillAppear:));
}
- (void) keyboardWillHide:(NSNotification*) n;
{
	L0KeyboardSetVariablesFromCommonKeys();
	L0KeyboardSetVariablesFromAnimationKeys();
	
	shown = NO;
	animating = YES;
	
	L0KeyboardDispatch(@selector(keyboardWillDisappear:));
}
- (void) keyboardDidShow:(NSNotification*) n;
{
	L0KeyboardSetVariablesFromCommonKeys();
	
	shown = YES;
	animating = NO;
	
	L0KeyboardDispatch(@selector(keyboardDidAppear:));
}
- (void) keyboardDidHide:(NSNotification*) n;
{
	L0KeyboardSetVariablesFromCommonKeys();
	
	shown = NO;
	animating = NO;
	
	L0KeyboardDispatch(@selector(keyboardDidDisappear:));
}


- (CGRect) resizedFrameOfViewToPreventCovering:(UIView*) v originalFrame:(CGRect) original;
{
	if (!self.shown || !self.animating)
		return original;
	
	NSAssert(v.superview, @"To calculate the intersection between a view and the keyboard, the view MUST be in a view hierarchy (added to a superview)!");
	CGRect adjustedBounds = [v.superview convertRect:self.bounds fromView:nil];
	adjustedBounds.origin = CGPointMake(center.x - adjustedBounds.size.width / 2,			
										center.y - adjustedBounds.size.height / 2);
	CGRect r = CGRectIntersection(adjustedBounds, original);
	if (!CGRectIsEmpty(r))
		original.size.height -= r.size.height;
	return original;
}

- (void) resizeViewToPreventCovering:(UIView*) v originalFrame:(CGRect) original animated:(BOOL) ani;
{
	if (ani && self.animating) {
		[UIView beginAnimations:nil context:NULL];
		[UIView setAnimationDuration:self.animationDuration];
		[UIView setAnimationCurve:self.animationCurve];
	}
	
	v.frame = [self resizedFrameOfViewToPreventCovering:v originalFrame:original];
	
	if (ani && self.animating)
		[UIView commitAnimations];
}

@end


@implementation L0KeyboardRubberBand

@synthesize originalFrame, view, animated;

- (void) dealloc
{
	[view release];
	[super dealloc];
}

- (void) keyboardWillAppear:(L0Keyboard *)k;
{
	if (animated && self.view.superview)
		[k resizeViewToPreventCovering:self.view originalFrame:self.originalFrame animated:YES];
}

- (void) keyboardDidAppear:(L0Keyboard *)k;
{
	if (!animated && self.view.superview)
		[k resizeViewToPreventCovering:self.view originalFrame:self.originalFrame animated:NO];
}

- (void) keyboardWillDisappear:(L0Keyboard*) k;
{
	if (self.view.superview)
		[k resizeViewToPreventCovering:self.view originalFrame:self.originalFrame animated:self.animated];
}


+ keyboardRubberBandForView:(UIView*) v;
{
	return [self keyboardRubberBandForView:v originalFrame:v.frame];
}

+ keyboardRubberBandForView:(UIView*) v originalFrame:(CGRect) f;
{
	L0KeyboardRubberBand* me = [[self new] autorelease];
	me.view = v;
	me.originalFrame = f;
	me.animated = YES;
	return me;
}

@end


#endif