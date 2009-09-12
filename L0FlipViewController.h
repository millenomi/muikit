//
//  L0FlipViewController.h
//  L0FlipViewController
//
//  Created by ∞ on 19/02/09.
//  Copyright 2009 Emanuele Vulcano. All rights reserved.
//

#if TARGET_OS_IPHONE

#import <UIKit/UIKit.h>

@interface L0FlipViewController : UIViewController {
	IBOutlet UIViewController* frontController;
	IBOutlet UIViewController* backController;
	
	BOOL isFlipped;
	BOOL cacheViewsDuringFlip;
}

- (id) initWithFrontController:(UIViewController*) front backController:(UIViewController*) back;

@property(retain) UIViewController* frontController;
@property(retain) UIViewController* backController;

@property(readonly) UIViewController* currentController;
@property(readonly) UIViewController* hiddenController;

@property(getter=isFlipped) BOOL flipped;
@property BOOL cacheViewsDuringFlip;
- (void) setFlipped:(BOOL) flipped animated:(BOOL) animated;

- (IBAction) showFront;
- (IBAction) showBack;

@end

#endif
