//
//  L0ActionSheet.h
//  MuiKit
//
//  Created by ∞ on 12/05/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface L0ActionSheet : UIActionSheet {
	NSMutableArray* buttonIdentifiers;
	NSMutableDictionary* additionalData;
}

- (NSInteger) addButtonWithTitle:(NSString*) title identifier:(id) identifier;
- (id) identifierForButtonAtIndex:(NSInteger) index;

// Also a generic KVO container.

@end
