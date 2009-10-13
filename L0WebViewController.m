//
//  MvrWebViewController.m
//  MuiKit
//
//  Created by ∞ on 13/10/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#if TARGET_OS_IPHONE

#import "L0WebViewController.h"

@interface L0WebViewController ()

@property(retain) UIWebView* webView;

@end


@implementation L0WebViewController

- (id) init;
{
	return [self initWithNibName:nil bundle:nil];
}

@synthesize webView, initialURL;

- (void) dealloc;
{
	self.webView = nil;
	self.initialURL = nil;
    [super dealloc];
}

- (void) loadView;
{
	if (!self.nibName) {
		CGRect r = [UIScreen mainScreen].bounds;
		self.view = [[[UIView alloc] initWithFrame:r] autorelease];
		[self viewDidLoad];
	} else
		[super loadView];
}

- (CGRect) webViewFrame;
{
	return self.view.bounds;
}

- (void) viewDidUnload;
{
	self.webView = nil;
}

- (void) viewWillAppear:(BOOL) animated;
{
	[super viewWillAppear:animated];
	
	if (!self.webView) {
		self.webView = [[[UIWebView alloc] initWithFrame:self.webViewFrame] autorelease];
		self.webView.delegate = self;
		
		if (self.initialURL)
			[self.webView loadRequest:[NSURLRequest requestWithURL:self.initialURL]];
	}

	[self insertWebViewAsSubview];
}

- (void) insertWebViewAsSubview;
{
	if (!self.webView.superview)
		[self.view addSubview:self.webView];
}

- (void) viewDidDisappear:(BOOL) animated;
{
	[super viewWillAppear:animated];
	[self.webView removeFromSuperview];
	self.webView = nil;
}

@end

#endif
