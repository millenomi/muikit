//
//  MvrWebViewController.h
//  MuiKit
//
//  Created by ∞ on 13/10/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#if TARGET_OS_IPHONE

#import <UIKit/UIKit.h>

/*
 This class manages a UIWebView, deallocating it when not shown to limit RAM use.
 The view this controller manages is a regular UIView (or whatever you shove into its .view outlet if you use a nib). When appearing, it will produce a web view and add it to the hierarchy through its -insertWebViewAsSubview method. The web view will be removed when the view disappears, and readded on demand later. (This instance is also automatically the web view's delegate for convenience.)
 */

@interface L0WebViewController : UIViewController <UIWebViewDelegate> {
	UIWebView* webView;
	NSURL* initialURL;
}

- (id) init; // calls initWithNibName:nil bundle:nil and sets up things to use a default UIView as self.view.

// is nil before viewWillAppear: and becomes nil again after viewDidDisappear:.
@property(readonly, retain) UIWebView* webView;

// if non-nil, the web view will be instructed to navigate here whenever it's created.
@property(copy) NSURL* initialURL;

// override points:

@property(readonly) CGRect webViewFrame; // The frame the web view will have on add. Default = self.view's bounds.
- (void) insertWebViewAsSubview; // Adds the web view to the hierarchy. The default is to add through addSubview: of self.view.

@end

#endif
