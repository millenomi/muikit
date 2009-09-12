//
//  L0ActionSheet.m
//  MuiKit
//
//  Created by ∞ on 12/05/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#if TARGET_OS_IPHONE

#import "L0ActionSheet.h"


@implementation L0ActionSheet


- (id)initWithTitle:(NSString *)title delegate:(id<UIActionSheetDelegate>)delegate cancelButtonTitle:(NSString *)cancelButtonTitle destructiveButtonTitle:(NSString *)destructiveButtonTitle otherButtonTitles:(NSString *)otherButtonTitles, ...;
{
	[NSException raise:@"L0MethodUnavailableException" format:@"You cannot use the convenience initializer with L0ActionSheet instances. Use init instead."];
}

- (id) init;
{	
	return [self initWithFrame:[UIScreen mainScreen].bounds];
}

- (id) initWithFrame:(CGRect) frame;
{
	if (self = [super initWithFrame:frame]) {
		buttonIdentifiers = [NSMutableArray new];
		additionalData = [NSMutableDictionary new];
	}
	
	return self;
}

- (NSInteger) addButtonWithTitle:(NSString*) title;
{
	[NSException raise:@"L0MethodUnavailableException" format:@"You cannot use this method with L0ActionSheet instances. Use addButtonWithTitle:identifier: instead."];
}

- (NSInteger) addButtonWithTitle:(NSString*) title identifier:(id) identifier;
{
	NSInteger i = [super addButtonWithTitle:title];
	[buttonIdentifiers addObject:identifier];
	return i;
}

- (id) identifierForButtonAtIndex:(NSInteger) index;
{
	return [buttonIdentifiers objectAtIndex:index];
}

- (void)dealloc {
	[buttonIdentifiers release];
	[additionalData release];
    [super dealloc];
}

- (id) valueForUndefinedKey:(NSString*) key;
{
	return [additionalData objectForKey:key];
}

- (void) setValue:(id) v forUndefinedKey:(NSString*) k;
{
	if (v)
		[additionalData setObject:v forKey:k];
	else
		[additionalData removeObjectForKey:k];
}

@end

#endif
