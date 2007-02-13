//
//  Message.h
//  MacLive
//
//  Created by James Howard on 1/1/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class LiveScraper;
@class Friend;

@interface Message : NSObject {

	Friend* from;
	NSString* content;
	NSAttributedString* attributedContent;
	NSDate* time;
	BOOL readStatus;
	
	LiveScraper* scraper;
	
	int messageID;
}

- (id)initWithFrom: (Friend*)_from
		   content: (NSString*)_content
			  time: (NSString*)_timeAsString
		 messageID: (int)_messageID
		readStatus: (BOOL)_readStatus
	   fromScraper: (LiveScraper*)_scraper;

- (Friend*)from;
- (void)setContent: (NSString*)newContent;
- (NSAttributedString*)contentAsAttributedString;
- (NSString*)content;
- (NSDate*)time;
- (int)messageID;
- (BOOL)readStatus;
- (void)setReadStatus: (BOOL)flag;

- (void)setContent: (NSString*)content;

- (BOOL)isFriendRequest;

- (void)sendReply: (NSString*)reply;

- (void)acceptRequest;
- (void)rejectRequest;

@end
