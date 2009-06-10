//
//  L0KVODictionaryAdditions.h
//  MuiKit
//
//  Created by ∞ on 10/06/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSDictionary (L0KVODictionaryAdditions)

- (NSKeyValueChange) l0_changeKind;
- (id) l0_changedValue;
- (id) l0_previousValue;
- (NSIndexSet*) l0_changedIndexes;

@end
