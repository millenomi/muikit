//
//  L0SolicitReviewController.m
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

#import "L0SolicitReviewController.h"
#import "UIAlertView+L0Alert.h"

// The number of launches before we solicit the user for a review.
#define kL0SolicitReviewNumberofLaunchesBeforeSoliciting (5)

@interface L0SolicitReviewController ()

@property(retain) NSBundle* _resourcesBundle;

@end


@implementation L0SolicitReviewController

@synthesize applicationName, applicationAppStoreURL, savesDefaults, firstLaunchDate, numberOfLaunches, didSolicitAlready;

@synthesize _resourcesBundle;

+ (id) defaultController {
	static id myself = nil; if (!myself)
		myself = [self new];
	return myself;
}

- (id) init {
	if (self = [super init]) {
		NSBundle* b = [NSBundle mainBundle];
		
		// Finds the application name.
		NSString* appName = [b objectForInfoDictionaryKey:@"CFBundleDisplayName"];
		if (!appName)
			appName = [b objectForInfoDictionaryKey:@"CFBundleName"];
		if (!appName)
			appName = [[NSFileManager defaultManager] displayNameAtPath:[b bundlePath]];
		self.applicationName = appName;
		
		// Finds an App Store URL for this app, if any is specified in Info.plist.
		NSString* URLString = [b objectForInfoDictionaryKey:kL0SolicitReviewAppStoreURLKey];
		if (URLString)
			self.applicationAppStoreURL = [NSURL URLWithString:URLString];
		
		// Finds the first launch date from the user defaults.
		NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
		NSDate* firstLaunch = [ud objectForKey:kL0SolicitReviewFirstLaunchDateDefault];
		if ([firstLaunch isKindOfClass:[NSDate class]])
			self.firstLaunchDate = firstLaunch;
		
		// Finds the number of launches, likewise.
		id o = [ud objectForKey:kL0SolicitReviewNumberOfLaunchesDefault];
		if ([o respondsToSelector:@selector(integerValue)]) {
			int i = [o integerValue];
			if (i >= 0) self.numberOfLaunches = i;
		}
		
		// Did we do it already?
		self.didSolicitAlready = [ud boolForKey:kL0SolicitReviewDoneAlreadyDefault];
		
		// Saves the defaults by default (ha!)
		self.savesDefaults = YES;
		
		// Fetches the MuiKit.bundle resources bundle. If not existing,
		// the _resourcesBundle will be nil, which fetches our alert from
		// the main bundle (yay backward compatibility).
		NSString* pathToResourcesBundle = [b pathForResource:@"MuiKit" ofType:@"bundle"];
		if (pathToResourcesBundle)
			self._resourcesBundle = [NSBundle bundleWithPath:pathToResourcesBundle];
	}
	
	return self;
}

- (void) dealloc {
	self.applicationName = nil;
	self.applicationAppStoreURL = nil;
	self.firstLaunchDate = nil;
	[super dealloc];
}

- (void) update {
	if (!self.firstLaunchDate)
		self.firstLaunchDate = [NSDate date];
	
	if (self.numberOfLaunches < kL0SolicitReviewNumberofLaunchesBeforeSoliciting)
		self.numberOfLaunches = self.numberOfLaunches + 1;
	
	if (self.savesDefaults) {
		NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
		[ud setObject:self.firstLaunchDate forKey:kL0SolicitReviewFirstLaunchDateDefault];
		[ud setInteger:self.numberOfLaunches forKey:kL0SolicitReviewNumberOfLaunchesDefault];
	}
}

- (void) showAlertIfNeeded {
	// Shown already? done.
	if (self.didSolicitAlready) return;
	
	// Display the alert if five or more launches AND a week has passed.
	if (self.numberOfLaunches < kL0SolicitReviewNumberofLaunchesBeforeSoliciting || !self.firstLaunchDate) {
		[[NSNotificationCenter defaultCenter] postNotificationName:kL0SolicitReviewControllerDidFinishNotification object:self];
	}
	
	NSDate* oneWeekSinceLaunch = [self.firstLaunchDate addTimeInterval:(7 * 24 * 60 * 60 /* one week */)];
	if ([(NSDate*)[NSDate date] compare:oneWeekSinceLaunch] == NSOrderedDescending)
		[self showAlert];
	else
		[[NSNotificationCenter defaultCenter] postNotificationName:kL0SolicitReviewControllerDidFinishNotification object:self];
}
- (void) showAlert {
	// Only display the alert if we have all the pieces.
	if (!self.applicationName || !self.applicationAppStoreURL) {
		[[NSNotificationCenter defaultCenter] postNotificationName:kL0SolicitReviewControllerDidFinishNotification object:self];
		return;
	}
	
	// Mark the alert as shown, saving it to defaults if possible.
	self.didSolicitAlready = YES;
	if (self.savesDefaults)
		[[NSUserDefaults standardUserDefaults] setBool:YES forKey:kL0SolicitReviewDoneAlreadyDefault];
	
	// "Do you want to rate %@?" "Cancel"/"Review"
	UIAlertView* alert = [UIAlertView alertNamed:@"L0SolicitReview" inBundle:self._resourcesBundle];
	alert.cancelButtonIndex = 0;
	alert.delegate = self;
	[alert setTitleFormat:nil, self.applicationName];
	[alert show];
}

- (void) alertView:(UIAlertView*) alert clickedButtonAtIndex:(NSInteger) buttonIndex {
	// Redirect to the Store.
	if (buttonIndex != alert.cancelButtonIndex && self.applicationAppStoreURL)
		[[UIApplication sharedApplication] openURL:self.applicationAppStoreURL];
	alert.delegate = nil;
	[[NSNotificationCenter defaultCenter] postNotificationName:kL0SolicitReviewControllerDidFinishNotification object:self];
}

+ (void) solicit {
	id myself = [self defaultController];
	[myself solicit];
}

- (void) solicit {
	[self update];
	[self performSelector:@selector(showAlertIfNeeded) withObject:nil afterDelay:2.0];
}

@end

#endif