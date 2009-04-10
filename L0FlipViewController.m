//
//  L0FlipViewController.m
//  L0FlipViewController
//
//  Created by ∞ on 19/02/09.
//  Copyright 2009 Emanuele Vulcano. All rights reserved.
//

#import "L0FlipViewController.h"

@interface L0FlipViewController ()

- (void) _setFlippedWithoutChecking:(BOOL) flipped animated:(BOOL) animated;

@end



@implementation L0FlipViewController

@synthesize frontController, backController;
@synthesize cacheViewsDuringFlip;

- (id) initWithFrontController:(UIViewController*) front backController:(UIViewController*) back;
{	
	if (self = [self initWithNibName:nil bundle:nil]) {
		NSAssert(front && back, @"Both front and back must be set.");
		
		self.frontController = front;
		self.backController = back;
		
		self.cacheViewsDuringFlip = YES;
	}
	
	return self;
}

- (void) dealloc;
{
	[frontController release];
	[backController release];
	
	[super dealloc];
}

- (UIViewController*) hiddenController;
{
	return isFlipped? self.frontController : self.backController;
}

- (UIViewController*) currentController;
{
	return !isFlipped? self.frontController : self.backController;
}

- (void) setFlipped:(BOOL) flipped animated:(BOOL) animated;
{	
	if (isFlipped == flipped) return;
	[self _setFlippedWithoutChecking:flipped animated:animated];
}

- (void) _setFlippedWithoutChecking:(BOOL) flipped animated:(BOOL) animated;
{
	UIViewController* next = flipped? self.hiddenController : self.frontController;
	UIViewController* current = self.currentController;
	if (current == next) current = nil;
	
	[current viewWillDisappear:animated];
	UIView* nextView = next.view; // this loads it.
	nextView.frame = [self.view bounds];
	[next viewWillAppear:animated];
	
	if (animated) {
		[UIView beginAnimations:nil context:NULL];
		[UIView setAnimationTransition:(flipped ? UIViewAnimationTransitionFlipFromRight : UIViewAnimationTransitionFlipFromLeft) forView:self.view cache:self.cacheViewsDuringFlip];
		[UIView setAnimationDuration:1.0];
	}
	
	for (UIView* v in self.view.subviews)
		[v removeFromSuperview];
	[self.view addSubview:nextView];
	
	if (animated)
		[UIView commitAnimations];
	
	[current viewDidDisappear:animated];
	[next viewDidAppear:animated];
	
	isFlipped = flipped;
}

- (BOOL) isFlipped { return isFlipped; }
- (void) setFlipped:(BOOL) flipped { [self setFlipped:flipped animated:NO]; }

- (void) showFront { [self setFlipped:NO animated:YES]; }
- (void) showBack  { [self setFlipped:YES animated:YES]; }

- (void) loadView;
{
	if (self.nibName)
		[self.nibBundle loadNibNamed:self.nibName owner:self options:nil];
	
	NSAssert(self.frontController && self.backController, @"Both front and back must be set.");
	
	UIView* view = [[[UIView alloc] initWithFrame:[UIScreen mainScreen].applicationFrame] autorelease];
	self.view = view;
	
	[self _setFlippedWithoutChecking:NO animated:NO];
	[self viewDidLoad];
}

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation) interfaceOrientation;
{
	return [self.frontController shouldAutorotateToInterfaceOrientation:interfaceOrientation] && [self.backController shouldAutorotateToInterfaceOrientation:interfaceOrientation];
}

- (void) didReceiveMemoryWarning;
{
	[super didReceiveMemoryWarning];
	
	// this ensures the current controller's view is destroyed
	// along with ours, if ours was.
	[self.currentController didReceiveMemoryWarning];
}

@end
