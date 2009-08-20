//
//  NSData+L0IPAddressTools.h
//  MuiKit
//
//  Created by ∞ on 19/08/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

enum {
	kL0IPAddressVersion4,
	kL0IPAddressVersion6,
};
typedef NSInteger L0IPAddressVersion;

@interface NSData (L0IPAddressTools)

- (BOOL) socketAddressIsIPAddressOfVersion:(L0IPAddressVersion) v;
- (NSString*) socketAddressStringValue;

@end
