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

@synthesize shown, animating, bounds, center, animationStartCenter, animationDuration, animationCurve, barHeight;

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
	[observers release];
	[super dealloc];
}


- (CGPoint) animationStartOrigin;
{
	return CGPointMake(animationStartCenter.x - bounds.size.width / 2,
					   animationStartCenter.y - bounds.size.height / 2);
}

- (CGPoint) origin;
{
	return CGPointMake(center.x - bounds.size.width / 2,
					   center.y - bounds.size.height / 2);
}

- (void) addObserver:(id <L0KeyboardObserver>) o;
{
	[observers addObject:o];
	if ([o respondsToSelector:@selector(keyboardDidAddObserver:)])
		[o keyboardDidAddObserver:self];
}

- (void) removeObserver:(id <L0KeyboardObserver>) o;
{
	[observers removeObject:o];
	if ([o respondsToSelector:@selector(keyboardDidRemoveObserver:)])
		[o keyboardDidRemoveObserver:self];
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
	CGRect frame = self.bounds;
	frame.origin = self.origin;
	frame.origin.y -= barHeight;
	frame.size.height += barHeight;
	
	CGRect adjustedFrame = [v.superview convertRect:frame fromView:nil];
	CGRect r = CGRectIntersection(adjustedFrame, original);
	if (!CGRectIsEmpty(r))
		original.size.height -= r.size.height;
	return original;
}

- (void) resizeViewToPreventCovering:(UIView*) v originalFrame:(CGRect) original animated:(BOOL) ani;
{
	CGRect newFrame = [self resizedFrameOfViewToPreventCovering:v originalFrame:original];
	if (CGRectEqualToRect(v.frame, newFrame))
		return;
	
	if (ani) 
		[self beginViewAnimationsAlongsideKeyboard:nil context:NULL];
	
	v.frame = newFrame;
	
	if (ani)
		[UIView commitAnimations];
}

- (void) beginViewAnimationsAlongsideKeyboard:(NSString*) name context:(void*) context;
{
	[UIView beginAnimations:nil context:NULL];
	if (self.animating) {
		[UIView setAnimationDuration:self.animationDuration];
		[UIView setAnimationCurve:self.animationCurve];
	}
}

- (void) setBarHeight:(CGFloat) f;
{
	if (f != barHeight) {
		barHeight = f;
		L0KeyboardDispatch(@selector(keyboardDidChangeBarHeight:));
	}
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

- (void) keyboardDidAddObserver:(L0Keyboard *)k;
{
	if (k.shown)
		[k resizeViewToPreventCovering:self.view originalFrame:self.originalFrame animated:self.animated];
}

- (void) keyboardDidChangeBarHeight:(L0Keyboard *)k;
{
	if (k.shown)
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


@implementation L0KeyboardBarController

@synthesize view, window, overlapsContent;

- (void) dealloc
{
	[view release];
	[window release];
	[super dealloc];
}


- (void) setView:(UIView*) v;
{
	if (v != view) {
		[view release];
		view = [v retain];
		[self updateBarHeight];
	}
}

- (void) setViewHeight:(CGFloat) h;
{
	CGRect frame = self.view.frame;
	frame.size.height = h;
	self.view.frame = frame;
	[self updateBarHeight];
}

- (void) setOverlapsContent:(BOOL) c;
{
	overlapsContent = c;
	[self updateBarHeight];
}

- (void) updateBarHeight;
{
	if (!active)
		return;
	
	L0Keyboard* k = [L0Keyboard sharedInstance];
	
	CGRect r = self.view.frame;
	CGFloat oldHeight = height;
	height = r.size.height;
	
	k.barHeight = overlapsContent? 0.0 : height;
	
	if (k.shown) {
		r.origin.y += oldHeight;
		r.origin.y -= height;
		self.view.frame = r;
	}
}

- (void) keyboardDidAddObserver:(L0Keyboard *)k;
{
	active = YES;
	[self updateBarHeight];
}

- (void) keyboardDidRemoveObserver:(L0Keyboard *)k;
{
	active = NO;
	k.barHeight = 0.0;
}

- (void) keyboardWillAppear:(L0Keyboard *)k;
{
	UIWindow* w = self.window;
	if (!w)
		w = [[UIApplication sharedApplication] keyWindow];
	
	[self updateBarHeight];

	CGRect r = self.view.frame;
	r.size.width = k.bounds.size.width;
	r.origin = k.animating? k.animationStartOrigin : k.origin;
	self.view.frame = r;
	[w addSubview:self.view];

	[k beginViewAnimationsAlongsideKeyboard:nil context:NULL];
	
	r.origin = k.origin;
	r.origin.y -= r.size.height;
	self.view.frame = r;
	
	[UIView commitAnimations];
}

- (void) keyboardWillDisappear:(L0Keyboard *)k;
{
	[k beginViewAnimationsAlongsideKeyboard:nil context:NULL];
	[self retain]; // balanced in the stop selector
	[UIView setAnimationDelegate:self];
	[UIView setAnimationDidStopSelector:@selector(disappearAnimation:finished:context:)];
	
	CGRect r = self.view.frame;
	r.origin = k.origin;
	self.view.frame = r;
	
	[UIView commitAnimations];
}

- (void) disappearAnimation:(NSString*) ani finished:(BOOL) fin context:(void*) none;
{
	[self.view removeFromSuperview];
	[self autorelease]; // balances the one in keyboardWillDisappear:
}

+ keyboardBarControllerWithView:(UIView*) v;
{
	return [self keyboardBarControllerWithView:v window:nil];
}

+ keyboardBarControllerWithView:(UIView *)v window:(UIWindow *)w;
{
	L0KeyboardBarController* me = [[self new] autorelease];
	me.view = v;
	me.window = w;
	
	if (v.superview)
		[v removeFromSuperview];
	
	me.overlapsContent = 
		([v isKindOfClass:[UIToolbar class]] || [v isKindOfClass:[UINavigationBar class]] || [v isKindOfClass:[UISearchBar class]]) && [(id)v isTranslucent];
	
	return me;
}

@end


#endif
