//
//  NSURL+L0URLResolvingRedirects.m
//  MuiKit
//
//  Created by ∞ on 17/07/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "NSURL+L0URLResolvingRedirects.h"

@interface L0URLRedirectsResolver : NSObject {
	NSURLConnection* connection;
	id delegate;
	SEL selector;
#if __BLOCKS__
	L0URLResolvingDidEndBlock block;
#endif
	
	NSURL* lastSeenURL;
}

- (id) initWithURL:(NSURL*) url delegate:(id) delegate selector:(SEL) selector;
#if __BLOCKS__
- (id) initWithURL:(NSURL*) url didEndBlock:(L0URLResolvingDidEndBlock) block;
#endif

- (void) startWithURL:(NSURL*) u;
- (void) finish;

@property(copy) NSURL* lastSeenURL;

@end


// ------------------

@implementation NSURL (L0URLResolvingRedirects)

- (void) beginResolvingRedirectsWithDelegate:(id) delegate selector:(SEL) selector;
{
	[[[L0URLRedirectsResolver alloc] initWithURL:self delegate:delegate selector:selector] autorelease];
}

#if __BLOCKS__
- (void) beginResolvingRedirectsAndInvoke:(L0URLResolvingDidEndBlock) block;
{
	[[[L0URLRedirectsResolver alloc] initWithURL:self didEndBlock:block] autorelease];
}
#endif

@end

@implementation L0URLRedirectsResolver

- (id) initWithURL:(NSURL*) url delegate:(id) d selector:(SEL) s;
{
	if (self = [super init]) {
		delegate = d;
		selector = s;
		[self startWithURL:url];
	}
	
	return self;
}

#if __BLOCKS__
- (id) initWithURL:(NSURL*) url didEndBlock:(L0URLResolvingDidEndBlock) b;
{
	if (self = [super init]) {
		block = [b copy];
		[self startWithURL:url];
	}
	
	return self;
}
#endif

- (void) startWithURL:(NSURL*) u;
{
	self.lastSeenURL = u;
	connection = [[NSURLConnection alloc] initWithRequest:[NSURLRequest requestWithURL:u] delegate:self];
	[self retain]; // balanced in -finish
}

- (NSURLRequest*) connection:(NSURLConnection*) c willSendRequest:(NSURLRequest*) request redirectResponse:(NSURLResponse*) response;
{
	self.lastSeenURL = [response URL];
    return request;
}

- (void) connectionDidFinishLoading:(NSURLConnection*) c;
{
	[self finish];
}

- (void) connection:(NSURLConnection*) c didFailWithError:(NSError*) e;
{
	self.lastSeenURL = nil;
	[self finish];
}

- (void) finish;
{
	if (delegate && selector)
		[delegate performSelector:selector withObject:self.lastSeenURL];
	
#if __BLOCKS__
	if (block)
		block(self.lastSeenURL);
#endif
	
	[connection release];
	connection = nil;
	
	[self autorelease]; // balances the retain in -startWithURL:
}

@synthesize lastSeenURL;

- (void) dealloc;
{
	[connection release];
	self.lastSeenURL = nil;
#if __BLOCKS__
	[block release];
#endif
	[super dealloc];
}

@end
