//
//  IconNotable.h
//  MacLive
//
//  Created by James Howard on 10/21/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "XBNotable.h"


@interface IconNotable : XBNotable {
	NSImage* iconImage;
	NSMutableData* imageData;
}

- (NSImage*)iconImage;
- (NSURL*)icon;

@end
