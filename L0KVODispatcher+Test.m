//
//  L0KVODispatcher+Test.m
//  MuiKit
//
//  Created by ∞ on 18/07/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "L0KVODispatcher+Test.h"


@implementation L0KVODispatcher_Test

- (void) setUp;
{
	dispatcher = [[L0KVODispatcher alloc] initWithTarget:self];
	anArrayRelationship = [NSMutableArray new];
	aSetRelationship = [NSMutableSet new];
	
	countOfInsertions = 0; lastIndexOfInsertion = NSNotFound;
	countOfRemovals = 0; lastIndexOfRemoval = NSNotFound;
	countOfReplacements = 0; lastIndexOfReplacement = NSNotFound;
	
	performedReplRemoval = NO;
	performedReplInsertion = NO;
}

- (void) tearDown;
{
	[dispatcher release]; dispatcher = nil;
	[anArrayRelationship release]; anArrayRelationship = nil;
	[aSetRelationship release]; aSetRelationship = nil;
}

- (void) addASetRelationshipObject:(id) o;
{
	[aSetRelationship addObject:o];
}

- (void) removeASetRelationshipObject:(id) o;
{
	[aSetRelationship removeObject:o];
}

- (void) insertObject:(NSString*) object inAnArrayRelationshipAtIndex:(NSUInteger) i;
{
	[anArrayRelationship insertObject:object atIndex:i];
}

- (void) removeObjectFromAnArrayRelationshipAtIndex:(NSUInteger) i;
{
	[anArrayRelationship removeObjectAtIndex:i];
}

- (NSArray*) anArrayRelationship;
{
	return [NSArray arrayWithArray:anArrayRelationship];
}

- (NSSet*) aSetRelationship;
{
	return [NSSet setWithSet:aSetRelationship];
}

- (void) testArrayDispatch;
{
//	volatile goOn = NO; while (!goOn)
//		sleep(3);
	
	[dispatcher observe:@"anArrayRelationship" ofObject:self usingSelector:@selector(arrayRelationshipOfObject:changed:) options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld];
	
	[self insertObject:@"a" inAnArrayRelationshipAtIndex:0];
	STAssertTrue(countOfInsertions == 1, nil);
	STAssertTrue(lastIndexOfInsertion == 0, nil);
	
	[self insertObject:@"b" inAnArrayRelationshipAtIndex:0];
	STAssertTrue(countOfInsertions == 2, nil);
	STAssertTrue(lastIndexOfInsertion == 0, nil);

	[self removeObjectFromAnArrayRelationshipAtIndex:0];
	STAssertTrue(countOfRemovals == 1, nil);
	STAssertTrue(lastIndexOfRemoval == 0, nil);

	[[self mutableArrayValueForKey:@"anArrayRelationship"] replaceObjectAtIndex:0 withObject:@"c"];
	STAssertTrue(countOfReplacements == 1, nil);
	STAssertTrue(lastIndexOfReplacement == 0, nil);
}

- (void) arrayRelationshipOfObject:(id) me changed:(NSDictionary*) change;
{
	[dispatcher forEachArrayChange:change forObject:me invokeSelectorForInsertion:@selector(inArrayRelationshipOfObject:inserted:atIndex:) removal:@selector(inArrayRelationshipOfObject:removed:atIndex:) replacement:@selector(inArrayRelationshipOfObject:replaced:with:atIndex:)];
}

- (void) inArrayRelationshipOfObject:(id) me inserted:(id) o atIndex:(NSUInteger) i;
{
	countOfInsertions++;
	lastIndexOfInsertion = i;
	
	if (countOfInsertions == 1)
		STAssertEqualObjects(o, @"a", nil);
	else if (countOfInsertions == 2)
		STAssertEqualObjects(o, @"b", nil);
}

- (void) inArrayRelationshipOfObject:(id) me removed:(id) o atIndex:(NSUInteger) i;
{
	countOfRemovals++;
	lastIndexOfRemoval = i;
	
	if (countOfRemovals == 1)
		STAssertEqualObjects(o, @"b", nil);
}

- (void) inArrayRelationshipOfObject:(id) me replaced:(id) oldO with:(id) newO atIndex:(NSUInteger) i;
{
	countOfReplacements++;
	lastIndexOfReplacement = i;		
	
	if (countOfReplacements == 1) {
		STAssertEqualObjects(oldO, @"a", nil);
		STAssertEqualObjects(newO, @"c", nil);
	}
}

- (void) testArrayDispatchWithoutReplacementSelector;
{
	//	volatile goOn = NO; while (!goOn)
	//		sleep(3);
	
	[dispatcher observe:@"anArrayRelationship" ofObject:self usingSelector:@selector(arrayRelationshipOfObjectNoRepl:changed:) options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld];
	
	[self insertObject:@"a" inAnArrayRelationshipAtIndex:0];
	STAssertTrue(countOfInsertions == 1, nil);
	STAssertTrue(lastIndexOfInsertion == 0, nil);
	
	[self insertObject:@"b" inAnArrayRelationshipAtIndex:0];
	STAssertTrue(countOfInsertions == 2, nil);
	STAssertTrue(lastIndexOfInsertion == 0, nil);
	
	[self removeObjectFromAnArrayRelationshipAtIndex:0];
	STAssertTrue(countOfRemovals == 1, nil);
	STAssertTrue(lastIndexOfRemoval == 0, nil);
	
	[[self mutableArrayValueForKey:@"anArrayRelationship"] replaceObjectAtIndex:0 withObject:@"c"];
	STAssertTrue(countOfInsertions == 3, nil);
	STAssertTrue(lastIndexOfInsertion == 0, nil);
	STAssertTrue(countOfRemovals == 2, nil);
	STAssertTrue(lastIndexOfRemoval == 0, nil);

	STAssertTrue(performedReplInsertion, nil);
	STAssertTrue(performedReplRemoval, nil);
}

- (void) arrayRelationshipOfObjectNoRepl:(id) me changed:(NSDictionary*) change;
{
	[dispatcher forEachArrayChange:change forObject:me invokeSelectorForInsertion:@selector(inArrayRelationshipOfObjectNoRepl:inserted:atIndex:) removal:@selector(inArrayRelationshipOfObjectNoRepl:removed:atIndex:) replacement:NULL];
}

- (void) inArrayRelationshipOfObjectNoRepl:(id) me inserted:(id) o atIndex:(NSUInteger) i;
{
	countOfInsertions++;
	lastIndexOfInsertion = i;
	
	if (countOfInsertions == 1)
		STAssertEqualObjects(o, @"a", nil);
	else if (countOfInsertions == 2)
		STAssertEqualObjects(o, @"b", nil);
	else if (countOfInsertions == 3) {
		STAssertTrue(performedReplRemoval, @"Must insert after removing in a replacement.");
		performedReplInsertion = YES;
		STAssertEqualObjects(o, @"c", nil);
	}
}

- (void) inArrayRelationshipOfObjectNoRepl:(id) me removed:(id) o atIndex:(NSUInteger) i;
{
	countOfRemovals++;
	lastIndexOfRemoval = i;
	
	if (countOfRemovals == 1)
		STAssertEqualObjects(o, @"b", nil);
	else if (countOfRemovals == 2) {
		STAssertTrue(!performedReplInsertion, @"Must not insert before removing in a replacement.");
		performedReplRemoval = YES;
		STAssertEqualObjects(o, @"a", nil);
	}
}

- (void) testSetDispatch;
{
//	volatile goOn = NO; while (!goOn)
//		sleep(3);
	
	[dispatcher observe:@"aSetRelationship" ofObject:self usingSelector:@selector(setRelationshipOfObject:changed:) options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld];
	
	[self addASetRelationshipObject:@"a"];
	STAssertTrue(countOfInsertions == 1, nil);
	
	[self addASetRelationshipObject:@"b"];
	STAssertTrue(countOfInsertions == 2, nil);
	
	[self removeASetRelationshipObject:@"a"];
	STAssertTrue(countOfRemovals == 1, nil);
	
	STAssertTrue(countOfReplacements == 0, nil);
}

- (void) setRelationshipOfObject:(id) me changed:(NSDictionary*) change;
{
	[dispatcher forEachSetChange:change forObject:me invokeSelectorForInsertion:@selector(inSetRelationshipOfObject:inserted:) removal:@selector(inSetRelationshipOfObject:removed:)];
}

- (void) inSetRelationshipOfObject:(id) me inserted:(id) o;
{
	countOfInsertions++;
	
	if (countOfInsertions == 1)
		STAssertEqualObjects(o, @"a", nil);
	else if (countOfInsertions == 2)
		STAssertEqualObjects(o, @"b", nil);
}

- (void) inSetRelationshipOfObject:(id) me removed:(id) o;
{
	countOfRemovals++;
	
	if (countOfRemovals == 1)
		STAssertEqualObjects(o, @"a", nil);
}

@end
