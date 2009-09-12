//
//  L0SolicitReviewController.h
//  L0SolicitReview
//
//  Created by ∞ on 13/12/08.

/*
 Copyright (c) 2008, Emanuele Vulcano (me@infinite-labs.net)
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
 
 Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.
 Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.
 Neither the name of the copyright holder or holders nor the names of their contributors may be used to endorse or promote products derived from this software without specific prior written permission.
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#if TARGET_OS_IPHONE

#import <UIKit/UIKit.h>

/*
 If a string with a URL is in the application's Info.plist at this key,
 new L0SolicitReviewControllers will have their applicationAppStoreURL
 property set to that URL.
 
 This is the URL where the user will be sent to review an app. This is
 -- CURRENTLY, as of iPhone OS 2.2 -- an URL of the form:
 http://itunes.apple.com/WebObjects/MZStore.woa/wa/viewContentsUserReviews?id=12233445&pageNumber=0&sortOrdering=1&type=Purple+Software
 where 12233445 is the application identifier on the store. This is not
 available before release, so you can point this to a URL on your web site
 for the initial release and set it to the correct Store URL with an update.
 
 This is the same link as the "show all %d reviews" link in the application page
 on the Store.
 */
#define kL0SolicitReviewAppStoreURLKey @"L0SolicitReviewAppStoreURL"

/*
 These are keys in your app's defaults where the controller stores its
 data. You can disable this behavior by changing the .savesDefaults
 property, explained below.
 */
#define kL0SolicitReviewNumberOfLaunchesDefault @"L0SolicitReviewNumberOfLaunches"
#define kL0SolicitReviewFirstLaunchDateDefault @"L0SolicitReviewFirstLaunchDate"
#define kL0SolicitReviewDoneAlreadyDefault @"L0SolicitReviewDoneAlready"


/*
 This notification is sent some time after you call -solicit, -showAlertIfNeeded
 or -showAlert to warn you that user interaction has ended. When you receive
 this notification, you can safely release the controller.
 
 The notification's object is the controller, and its userInfo dictionary contains no
 values.
 */
#define kL0SolicitReviewControllerDidFinishNotification @"L0SolicitReviewControllerDidFinish"

/*
 This controller solicits a user to review an application at the App Store
 after a certain time has passed. Currently, this class will solicit a
 review if the application was launched five or more times and a week
 has passed since the first launch.
 
 It should be enough to have:
	[L0SolicitReviewController solicit];
 in applicationDidFinishLaunching: for this to work.
 
 You can fine-tune this class by changing its properties, preventing it from changing
 the application's defaults and controlling the soliciting alert yourself by
 changing its properties. You can construct an instance of this class with
 alloc/init as usual, or get a default instance with the +defaultController
 method.
 */
@interface L0SolicitReviewController : NSObject <UIAlertViewDelegate> {
	// Stupid x86 runtime grr needs instance variables for properties grr
	NSString* applicationName;
	NSURL* applicationAppStoreURL;
	BOOL savesDefaults;
	NSDate* firstLaunchDate;
	NSUInteger numberOfLaunches;
	BOOL didSolicitAlready;
	
	NSBundle* _resourcesBundle;
}

/*
 The name of the application, displayed in the alert. For new instances,
 this is set to the application's name (as set in Info.plist if possible,
 or by reading it from the filesystem otherwise).
 
 If nil, the alert won't be shown.
 */
@property(copy) NSString* applicationName;

/*
 A URL that opens the App Store at the application's page. For new instances,
 the URL is retrieved by reading Info.plist at the L0SolicitReviewAppStoreURL key,
 if set.

 If nil, the alert won't be shown.
 */
@property(copy) NSURL* applicationAppStoreURL;

/*
 By default, updating the data with the -update method, or showing the
 alert with the -showAlert and -showAlertIfNeeded methods, change the
 app's user defaults to save the .firstLaunchDate, .numberOfLaunches
 and .didSolicitAlready property values. If this is undesirable, you can
 disable this behavior by changing this property to NO. Defaults to YES.
 
 Note that if you disable this, you will be responsible for setting the
 .firstLaunchDate, .numberOfLaunches and .didSolicitAlready properties to
 reasonable values; the +solicit method will *NOT* work in this case, as
 it relies on reading information from defaults. You'll have to call
 the -solicit method instead after changing the defaults.
 */
@property BOOL savesDefaults;

/*
 The date in which the application was first launched, or nil at first launch.
 Defaults to the value found in the application's defaults at the 
 L0SolicitReviewFirstLaunchDate key, if it's a date, or nil otherwise.
 */
@property(copy) NSDate* firstLaunchDate;

/*
 The number of times this application was launched. Note that this value will
 not increase when the number of launches before soliciting has been reached
 (currently five).
 Defaults to the value found in the application's defaults at the 
 L0SolicitReviewNumberOfLaunches key, if it can be converted to an unsigned integer,
 or 0 otherwise.
 */
@property NSUInteger numberOfLaunches;

/*
 Whether the alert has already been shown. If YES, no more alerts will be shown.
 Defaults to the value found in the application's defaults at the 
 L0SolicitReviewDoneAlready key, if it can be converted to a boolean,
 or NO otherwise.
 */
@property BOOL didSolicitAlready;

/*
 Returns a default instance of this class. This instance is privately retained
 by the class. If you want to control the lifetime of a controller, do not
 use this method; use alloc/init instead (you can rely on the
 L0SolicitReviewControllerDidFinish notification to know when the -solicit
 method has done its job and the instance can be released).
 */
+ (id) defaultController;

/*
 Updates values at .firstLaunchDate and .numberOfLaunches, optionally saving
 the new values in the app's defaults if .savesDefaults is set.
 */
- (void) update;

/*
 Shows the alert if the current values of .firstLaunchDate and .numberOfLaunches
 are appropriate.
 */
- (void) showAlertIfNeeded;

/*
 Shows the alert, ignoring the current values of .firstLaunchDate and .numberOfLaunches.
 Can be overridden to customize the alert. If you override this method, you must
 also override alertView:clickedButtonAtIndex: and correctly post the
 L0SolicitReviewControllerDidFinish notification when done.
 */
- (void) showAlert;

/*
 Updates the default controller, then shows the alert if needed after a delay. If the
 defaults are fine, then all you need to do with this class is to call this method
 at applicationDidFinishLaunching: time.
 */
+ (void) solicit;

/*
 Updates this controller instance, then shows the alert if needed after a delay.
 Use this method at applicationDidFinishLaunching: time if you had to change the defaults above.
 */
- (void) solicit;

@end

#endif