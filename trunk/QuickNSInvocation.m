//
//  NSObject_QuickNSInvocation.m
//  MacLive
//
//  Created by James Howard on 12/17/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "QuickNSInvocation.h"


@implementation NSObject (QuickNSInvocation)

- (NSInvocation*)makeInvocationForSelector: (SEL)sel
								  withArgs: (NSArray*)args
{
	NSMethodSignature* sig = [self methodSignatureForSelector: sel];
	NSInvocation* ivk = [NSInvocation invocationWithMethodSignature: sig];
	[ivk setTarget: self];
	[ivk setSelector: sel];
	
	NSEnumerator* e = [args objectEnumerator];
	id obj = nil;
	int i = 2;
	while(obj = [e nextObject]) {
		[ivk setArgument: &obj atIndex: i];
		i++;
	}
	
	[ivk retainArguments];
	return ivk;
}

@end
