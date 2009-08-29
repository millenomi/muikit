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

#define L0IPv6AddressIsEqual(a, b) (\
(a).__u6_addr.__u6_addr32[0] == (b).__u6_addr.__u6_addr32[0] && \
(a).__u6_addr.__u6_addr32[1] == (b).__u6_addr.__u6_addr32[1] && \
(a).__u6_addr.__u6_addr32[2] == (b).__u6_addr.__u6_addr32[2] && \
(a).__u6_addr.__u6_addr32[3] == (b).__u6_addr.__u6_addr32[3])

@implementation NSData (L0IPAddressTools)

- (BOOL) socketAddressIsEqualToAddress:(NSData*) d;
{
	const struct sockaddr* s = [d bytes];
	if ([d socketAddressIsIPAddressOfVersion:kL0IPAddressVersion4] && [self socketAddressIsIPAddressOfVersion:kL0IPAddressVersion4]) {
		const struct sockaddr_in* sIPv4 = (const struct sockaddr_in*) s;
		const struct sockaddr_in* selfIPv4 = (const struct sockaddr_in*) [self bytes];
		if (selfIPv4->sin_addr.s_addr == sIPv4->sin_addr.s_addr)
			return YES;
	} else if ([d socketAddressIsIPAddressOfVersion:kL0IPAddressVersion6] && [self socketAddressIsIPAddressOfVersion:kL0IPAddressVersion6]) {
		const struct sockaddr_in6* sIPv6 = (const struct sockaddr_in6*) s;
		const struct sockaddr_in6* selfIPv6 = (const struct sockaddr_in6*) [self bytes];
		if (L0IPv6AddressIsEqual(selfIPv6->sin6_addr, sIPv6->sin6_addr))
			return YES;
	}
	
	return NO;
}

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
