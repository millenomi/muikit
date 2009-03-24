//
//  L0UUID.h
//  Orma
//
//  Created by ∞ on 12/08/08.
//  Copyright 2008 Emanuele Vulcano. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreFoundation/CoreFoundation.h>

@interface L0UUID : NSObject <NSCopying, NSCoding> {
	__strong CFUUIDRef uuid;
}

// Creates a newly generated UUID.
- (id) init;

// Creates a UUID that wraps an existing Core Fondation UUID object.
- (id) initWithUUID:(CFUUIDRef) uuid;

// Creates a UUID from a correctly formatted string.
- (id) initWithString:(NSString*) string;

// Creates a UUID from the given bytes. They will be copied.
- (id) initWithBytes:(CFUUIDBytes*) bytes;

// Creates a UUID from the contents of NSData, which must wrap a
// CFUUIDBytes structure.
- (id) initWithData:(NSData*) data;

// Retrieves the wrapped Core Foundation UUID object.
- (CFUUIDRef) CFUUID;

// Returns a string of the kind '68753A44-4D6F-1226-9C60-0050E4C00067' for
// this UUID.
@property(readonly) NSString* stringValue;

// Returns the bytes this UUID is made of.
@property(readonly) CFUUIDBytes UUIDBytes;

// Returns a NSData object wrapping what would be returned by
// a call to -bytes.
@property(readonly) NSData* dataValue;

+ (id) UUID;
+ (id) UUIDWithUUID:(CFUUIDRef) uuid;
+ (id) UUIDWithString:(NSString*) string;
+ (id) UUIDWithBytes:(CFUUIDBytes*) bytes;
+ (id) UUIDWithData:(NSData*) data;

@end
