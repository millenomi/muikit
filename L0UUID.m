//
//  L0UUID.m
//  Orma
//
//  Created by ∞ on 12/08/08.
//  Copyright 2008 Emanuele Vulcano. All rights reserved.
//

#import "L0UUID.h"


@implementation L0UUID

- (id) init {
	CFUUIDRef ref = CFUUIDCreate(kCFAllocatorDefault);
	self = [self initWithUUID:ref];
	CFRelease(ref);
	return self;
}

- (id) initWithUUID:(CFUUIDRef) u {
	if (self = [super init])
		uuid = CFMakeCollectable(CFRetain(u));
	
	return self;
}

- (id) initWithString:(NSString*) string {
	CFUUIDRef ref = CFUUIDCreateFromString(kCFAllocatorDefault, (CFStringRef) string);
	self = [self initWithUUID:ref];
	CFRelease(ref);
	return self;	
}

- (id) initWithData:(NSData*) data {
	return [self initWithBytes:(CFUUIDBytes*) [data bytes]];
}

- (id) initWithBytes:(CFUUIDBytes*) bytes {
	CFUUIDRef ref = CFUUIDCreateFromUUIDBytes(kCFAllocatorDefault, *bytes);
	self = [self initWithUUID:ref];
	CFRelease(ref);
	return self;
}

- (CFUUIDRef) CFUUID {
	return uuid;
}

- (NSString*) stringValue {
	NSString* r = [NSMakeCollectable(CFUUIDCreateString(kCFAllocatorDefault, uuid)) autorelease];
	return r;
}

- (NSData*) dataValue {
	CFUUIDBytes b = CFUUIDGetUUIDBytes(uuid);
	NSData* d = [[NSData alloc] initWithBytes:&b length:sizeof(CFUUIDBytes)];
	return [d autorelease];
}

- (CFUUIDBytes) UUIDBytes {
	return CFUUIDGetUUIDBytes(uuid);
}

- (BOOL) isEqual:(id) o {
	BOOL isOK = [o isKindOfClass:[self class]] &&
		CFEqual([o CFUUID], [self CFUUID]);
//	NSLog(@"Will test for equality: self %@ with %@ result %d", self, o, isOK);
	return isOK;
}

- (NSUInteger) hash {
	return [[self class] hash] ^ CFHash(uuid);
}

- (void) dealloc {
	CFRelease(uuid);
	[super dealloc];
}

+ (id) UUID {
	return [[[self alloc] init] autorelease];
}

+ (id) UUIDWithUUID:(CFUUIDRef) uuid {
	return [[[self alloc] initWithUUID:uuid] autorelease];	
}

+ (id) UUIDWithString:(NSString*) string {
	return [[[self alloc] initWithString:string] autorelease];
}

+ (id) UUIDWithBytes:(CFUUIDBytes*) bytes {
	return [[[self alloc] initWithBytes:bytes] autorelease];	
}

+ (id) UUIDWithData:(NSData*) data {
	return [[[self alloc] initWithData:data] autorelease];	
}

- (id) copyWithZone:(NSZone*) zone {
	return [[[self class] allocWithZone:zone] initWithUUID:[self CFUUID]];
}

- (id) copy {
	return [self retain];
}

- (void) encodeWithCoder:(NSCoder*) c {
	[c encodeObject:self.dataValue forKey:@"UUIDData"];
}

- (id) initWithCoder:(NSCoder*) c {
	NSData* d = [c decodeObjectForKey:@"UUIDData"];
	return [self initWithData:d];
}

@end
