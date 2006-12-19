//
//  NSObject_QuickNSInvocation.h
//  MacLive
//
//  Created by James Howard on 12/17/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NSObject (QuickNSInvocation)

- (NSInvocation*)makeInvocationForSelector: (SEL)sel
								  withArgs: (NSArray*)args;

@end
