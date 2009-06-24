//
//  L0KVODictionaryAdditions.m
//  MuiKit
//
//  Created by ∞ on 10/06/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "L0KVODictionaryAdditions.h"


@implementation NSDictionary (L0KVODictionaryAdditions)

- (NSKeyValueChange) l0_changeKind;
{
	NSNumber* n = [self objectForKey:NSKeyValueChangeKindKey];
	if (!n) return 0;
	
	return [n integerValue];
}

- (id) l0_changedValue;
{
	return [self objectForKey:NSKeyValueChangeNewKey];
}

- (id) l0_previousValue;
{
	return [self objectForKey:NSKeyValueChangeOldKey];
}

- (NSIndexSet*) l0_changedIndexes;
{
	return [self objectForKey:NSKeyValueChangeIndexesKey];
}

- (BOOL) l0_isPrior;
{
	NSNumber* n = [self objectForKey:NSKeyValueChangeNotificationIsPriorKey];
	if (!n) return NO;
	
	return [n boolValue];
}

@end
