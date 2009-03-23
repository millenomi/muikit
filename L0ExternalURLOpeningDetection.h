//
//  L0URLDetection.h
//  L0EntryTable
//
//  Created by ∞ on 18/07/08.
//  Copyright 2008 Emanuele Vulcano. All rights reserved.
//

#import <Foundation/Foundation.h>

// returns YES if it's desirable to display the URL in an inline
// web browsing component (that is, without leaving your application);
// NO if the URL should be opened via -[UIApplication openURL:] (to
// launch an appropriate application such as YouTube, App Store or the
// like).
extern BOOL L0ShouldNavigateToURL(NSURL* url);