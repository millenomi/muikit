//
//  NSURL_L0URLParsing.h
//  Diceshaker
//
//  Created by ∞ on 11/02/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSURL (L0URLParsing)

- (NSDictionary*) dictionaryByDecodingQueryString;

@end

@interface NSDictionary (L0URLParsing)

- (NSString*) queryString;

@end
