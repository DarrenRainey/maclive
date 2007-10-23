//
//  IconNotable.m
//  MacLive
//
//  Created by James Howard on 10/21/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "IconNotable.h"

@interface IconNotable (Private_IconNotable)

- (void)downloadImage;

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response;
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data;
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error;
- (void)connectionDidFinishLoading:(NSURLConnection *)connection;



@end

@implementation IconNotable

- (id)init {
	if(self = [super init]) {
		iconImage = nil;
		imageData = nil;
	}
	return self;
}

- (NSURL*)icon {
	return nil;
}

- (void)dealloc {
	[iconImage release];
	[imageData release];
	[super dealloc];
}

- (NSImage*)iconImage {
	NSImage* ret = nil;
	if(iconImage) {
		ret = iconImage;
	} else {
		[self downloadImage];
		if(iconImage) {
			ret = iconImage;
		} else {
			//ret = [NSImage imageNamed: @"noIcon.tiff"];
			ret = nil;
		}
	}
	return ret;
}

- (void)downloadImage {
	if(imageData != nil) return;
		
	NSURLRequest* req = [NSURLRequest requestWithURL: [self icon] 
										 cachePolicy: NSURLRequestReturnCacheDataElseLoad 
									 timeoutInterval: 30.0];
	NSURLConnection* conn = [[NSURLConnection alloc] initWithRequest: req 
															delegate: self];
	if(conn != nil) {
		imageData = [[NSMutableData alloc] init];
	}
	
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    // this method is called when the server has determined that it
    // has enough information to create the NSURLResponse
	
    // it can be called multiple times, for example in the case of a 
    // redirect, so each time we reset the data.
    [imageData setLength:0];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    // append the new data to the receivedData
    [imageData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    // release the connection, and the data object
    [connection release];
    [imageData release]; imageData = nil;
	
    // inform the user
    NSLog(@"Connection failed! Error - %@ %@",
          [error localizedDescription],
          [[error userInfo] objectForKey:NSErrorFailingURLStringKey]);
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	[self willChangeValueForKey: @"iconImage"];
	iconImage = [[NSImage alloc] initWithData: imageData];
	
    // release the connection, and the data object
    [connection release];
    [imageData release]; imageData = nil;
	
	
	
	[self didChangeValueForKey: @"iconImage"];
}

@end
