//
//  UIAlertView+L0Alert.h
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

#import <UIKit/UIKit.h>

#ifndef L0Log
#ifdef DEBUG

#define L0Log(x, args...) NSLog(@"<DEBUG: '%s'>: " x, __func__, args)
#define L0LogS(x) NSLog(@"<DEBUG: '%s'>: " x, __func__)

#else

#define L0Log(x, args...) do { {args;} } while(0)
#define L0LogS(x) do {} while(0)

#endif // DEBUG
#endif // L0Log

extern const NSString* kL0AlertFileExtension;
extern const NSString* kL0AlertInconsistencyException;

extern const NSString* kL0AlertMessage;
extern const NSString* kL0AlertInformativeText;
extern const NSString* kL0AlertButtons;
extern const NSString* kL0AlertShowsSuppressionButton;
extern const NSString* kL0AlertSuppressionButtonTitle;
extern const NSString* kL0AlertHelpAnchor;
extern const NSString* kL0AlertIconName;

@interface UIAlertView (L0Alert)

+ (id) alertNamed:(NSString*) name inBundle:(NSBundle*) bundle directory:(NSString*) directory;
+ (id) alertNamed:(NSString*) name inBundle:(NSBundle*) bundle;
+ (id) alertNamed:(NSString*) name;
+ (id) alertWithContentsOfDictionary:(NSDictionary*) dict name:(NSString*) name bundle:(NSBundle*) bundle;

- (void) setTitleFormat:(id) setMeToNil,...;
- (void) setMessageFormat:(id) setMeToNil,...;

@end
