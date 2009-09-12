//
//  UIAlertView+L0Alert.m
//  Alerts
//

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

#import "UIAlertView+L0Alert.h"
#import <stdarg.h>

const NSString* kL0AlertFileExtension = @"alert";
const NSString* kL0AlertInconsistencyException = @"L0AlertInconsistencyException";

const NSString* kL0AlertMessage = @"L0AlertMessage";
const NSString* kL0AlertInformativeText = @"L0AlertInformativeText";
const NSString* kL0AlertButtons = @"L0AlertButtons";
const NSString* kL0AlertShowsSuppressionButton = @"L0AlertShowsSuppressionButton";
const NSString* kL0AlertSuppressionButtonTitle = @"L0AlertSuppressionButtonTitle";
const NSString* kL0AlertHelpAnchor = @"L0AlertHelpAnchor";
const NSString* kL0AlertIconName = @"L0AlertIconName";

#import <stdarg.h>

@implementation UIAlertView (L0Alert)

+ (id) alertWithContentsOfDictionary:(NSDictionary*) dict name:(NSString*) name bundle:(NSBundle*) bundle {
	
	L0Log(@"%@, %@, %@", name, bundle, dict);
	
	NSArray* buttons = [dict objectForKey:kL0AlertButtons];
	if (buttons && ![buttons isKindOfClass:[NSArray class]])
		[NSException raise:(NSString*) kL0AlertInconsistencyException format:@"Alert dictionary unreadable: %@", dict];
	
	UIAlertView* alert = [[[UIAlertView alloc] initWithFrame:CGRectZero] autorelease];
	NSString* messageText = [[dict objectForKey:kL0AlertMessage] description];
	if (bundle) messageText = [bundle localizedStringForKey:messageText value:messageText table:name];
	alert.title = messageText;
	
	
	NSString* informativeText = [[dict objectForKey:kL0AlertInformativeText] description];
	if (bundle) informativeText = [bundle localizedStringForKey:informativeText value:informativeText table:name];
	alert.message = informativeText;
	
	NSEnumerator* enu = [buttons objectEnumerator];
	NSString* button;
	while (button = [enu nextObject]) {
		if (bundle) button = [bundle localizedStringForKey:button value:button table:name];
		[alert addButtonWithTitle:button];
	}

	return alert;
}

+ (id) alertNamed:(NSString*) name inBundle:(NSBundle*) bundle directory:(NSString*) directory {
	NSString* path = [bundle pathForResource:name ofType:(NSString*) kL0AlertFileExtension inDirectory:directory];
	
	if (!path)
		[NSException raise:(NSString*) kL0AlertInconsistencyException format:@"Can't find alert named '%@' in bundle '%@', directory '%@'", name, bundle, directory];
	
	NSDictionary* dict = [NSDictionary dictionaryWithContentsOfFile:path];
	if (!dict)
		[NSException raise:(NSString*) kL0AlertInconsistencyException format:@"Alert file unreadable for alert named named '%@' in bundle '%@', directory '%@'", name, bundle, directory];
	
	return [self alertWithContentsOfDictionary:dict name:name bundle:bundle];
}

+ (id) alertNamed:(NSString*) name inBundle:(NSBundle*) bundle {
	return [self alertNamed:name inBundle:bundle directory:nil];
}

+ (id) alertNamed:(NSString*) name {
	return [self alertNamed:name inBundle:[NSBundle mainBundle]];
}

- (void) setTitleFormat:(id) setMeToNil,... {
	va_list arguments;
	va_start(arguments, setMeToNil);
	NSString* str = [[NSString alloc] initWithFormat:self.title arguments:arguments];
	va_end(arguments);
	self.title = [str autorelease];
}

- (void) setMessageFormat:(id) setMeToNil,... {
	va_list arguments;
	va_start(arguments, setMeToNil);
	NSString* str = [[NSString alloc] initWithFormat:self.message arguments:arguments];
	va_end(arguments);
	self.message = [str autorelease];
}

// -- -- -- -- -- -- -- --

@end

#endif