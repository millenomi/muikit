//
//  NSData+L0IPAddressTools.m
//  MuiKit
//
//  Created by ∞ on 19/08/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "NSData+L0IPAddressTools.h"
#import <sys/types.h>
#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>

@implementation NSData (L0IPAddressTools)

- (BOOL) socketAddressIsIPAddressOfVersion:(L0IPAddressVersion) v;
{
	struct sockaddr* addr = (struct sockaddr*) [self bytes];
	if (v == kL0IPAddressVersion4)
		return addr->sa_family == AF_INET;
	else if (v == kL0IPAddressVersion6)
		return addr->sa_family == AF_INET6;
	else
		return NO;
}

- (NSString*) socketAddressStringValue;
{
	struct sockaddr* addr = (struct sockaddr*) [self bytes];
	if ([self socketAddressIsIPAddressOfVersion:kL0IPAddressVersion4]) {
		struct sockaddr_in* addr4 = (struct sockaddr_in*) addr;
		char addr4CString[INET_ADDRSTRLEN];
		if (!inet_ntop(AF_INET, &addr4->sin_addr, addr4CString, INET_ADDRSTRLEN))
			return nil;
		else
			return [[[NSString alloc] initWithUTF8String:addr4CString] autorelease];
	} else if ([self socketAddressIsIPAddressOfVersion:kL0IPAddressVersion6]) {
		struct sockaddr_in6* addr6 = (struct sockaddr_in6*) addr;
		char addr6CString[INET6_ADDRSTRLEN];
		if (!inet_ntop(AF_INET6, &addr6->sin6_addr, addr6CString, INET6_ADDRSTRLEN))
			return nil;
		else
			return [[[NSString alloc] initWithUTF8String:addr6CString] autorelease];
	} else
		return nil;
}

@end
