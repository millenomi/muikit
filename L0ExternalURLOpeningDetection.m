//
//  L0URLDetection.m
//  L0EntryTable
//
//  Created by ∞ on 18/07/08.
//  Copyright 2008 Emanuele Vulcano. All rights reserved.
//

#import "L0ExternalURLOpeningDetection.h"

// returns YES if it's desirable to display the URL in an inline
// web browsing component (that is, without leaving your application);
// NO if the URL should be opened via -[UIApplication openURL:] (to
// launch an appropriate application such as YouTube, App Store or the
// like).

BOOL L0ShouldNavigateToURL(NSURL* url) {
	// bizarre URL schemes eg. tel: or sms: go in their own apps.
	// javascript: is there for completeness.
	// forgotten any?
	if (!([[url scheme] isEqual:@"http"] || [[url scheme] isEqual:@"https"] || [[url scheme] isEqual:@"ftp"] || [[url scheme] isEqual:@"javascript"] || [[url scheme] isEqual:@"about"] || [[url scheme] isEqual:@"data"]))
		return NO;
	
	// http-based special URLs
	if ([[url scheme] isEqual:@"http"]) {
		// iTunes Store and App Store
		if ([[url host] isEqual:@"phobos.apple.com"])
			return NO;
		
		// iTunes Store and App Store (Dec '08 new-style URLs)
		if ([[url host] isEqual:@"itunes.apple.com"] || [[url host] hasSuffix:@".itunes.apple.com"])
			return NO;
		
		// Maps
		if ([[url host] isEqual:@"maps.google.com"])
			return NO;
		
		// YouTube -- this mimics Safari's behavior of navigating to international
		// sites (eg. it.youtube.com) or m.youtube.com without launching YouTube.app.
		if (([[url host] isEqual:@"youtube.com"] || [[url host] isEqual:@"www.youtube.com"]) && ([[url path] hasPrefix:@"/v/"] || [[url path] isEqual:@"/watch"]))
			return NO;
	}

	// https-based special URLs:
	if ([[url scheme] isEqual:@"https"]) {
		// iTunes Store and App Store (Dec '08 new-style URLs)
		if ([[url host] isEqual:@"itunes.apple.com"] || [[url host] hasSuffix:@".itunes.apple.com"])
			return NO;
	}
	
	// everything else is kosher.
	return YES;
}