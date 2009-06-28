//
//  L0KVODictionaryAdditions.h
//  MuiKit
//
//  Created by ∞ on 10/06/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

static inline NSKeyValueChange L0KVOChangeKind(NSDictionary* self)
{
	NSNumber* n = [self objectForKey:NSKeyValueChangeKindKey];
	if (!n) return 0;
	
	return [n integerValue];
}

static inline id L0KVOChangedValue(NSDictionary* self)
{
	return [self objectForKey:NSKeyValueChangeNewKey];
}

static inline id L0KVOPreviousValue(NSDictionary* self)
{
	return [self objectForKey:NSKeyValueChangeOldKey];
}

static inline NSIndexSet* L0KVOChangedIndexes(NSDictionary* self)
{
	return [self objectForKey:NSKeyValueChangeIndexesKey];
}

static inline BOOL L0KVOIsPrior(NSDictionary* self)
{
	NSNumber* n = [self objectForKey:NSKeyValueChangeNotificationIsPriorKey];
	if (!n) return NO;
	
	return [n boolValue];
}
