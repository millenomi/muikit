//
//  L0KVODispatcher+Test.h
//  MuiKit
//
//  Created by ∞ on 18/07/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//
//  See Also: http://developer.apple.com/iphone/library/documentation/Xcode/Conceptual/iphone_development/135-Unit_Testing_Applications/unit_testing_applications.html

#import <SenTestingKit/SenTestingKit.h>
#import <Foundation/Foundation.h>
#import "MuiKit.h"

@interface L0KVODispatcher_Test : SenTestCase {
	L0KVODispatcher* dispatcher;
	NSMutableArray* anArrayRelationship;
	NSMutableSet* aSetRelationship;
	
	NSInteger countOfInsertions, lastIndexOfInsertion;
	NSInteger countOfRemovals, lastIndexOfRemoval;
	NSInteger countOfReplacements, lastIndexOfReplacement;
	BOOL performedReplInsertion, performedReplRemoval;
}

@property(readonly) NSArray* anArrayRelationship;
@property(readonly) NSSet* aSetRelationship;

- (void) testArrayDispatch;
- (void) testSetDispatch;

@end
