//
//  Message.m
//  MacLive
//
//  Created by James Howard on 1/1/07.
//  Copyright 2007 __MyCompanyName__. All rights reserved.
//

#import "Message.h"
#import "LiveScraper.h"
#import "Friend.h"

#define FRIEND_MSG @"%@ wants to be your friend."

@implementation Message

// TODO: be able to have messages know if they are read or not
// as defined by the css style on the ViewMessages page
- (id)initWithFrom: (Friend*)_from
		   content: (NSString*)_content
			  time: (NSString*)_timeAsString
		 messageID: (int)_messageID
		readStatus: (BOOL)_readStatus
	   fromScraper: (LiveScraper*)_scraper
{
	if(self = [super init]) {
		from = [_from retain];
		[self setContent: _content];
		[self setReadStatus: _readStatus];
		time = [[NSDate dateWithNaturalLanguageString: _timeAsString] retain];
		messageID = _messageID;
		// don't retain because the scraper retains us
		scraper = _scraper;
	}
	return self;
}

- (void)dealloc {
	[from release];
	[content release];
	[attributedContent release];
	[time release];
	[super dealloc];
}

- (Friend*)from
{
	return from;
}
- (void)setContent: (NSString*)newContent
{
	if(content != newContent) {
		[content release];
		[attributedContent release];
		content = [newContent retain];
		// the below will cause a hang ... apparently there's some
		// re-entrancy problem with webkit being used this way
		/*
		attributedContent = 
			[[NSAttributedString alloc] initWithHTML: [content dataUsingEncoding: NSUTF8StringEncoding] 
								  documentAttributes: nil];
		 */
		attributedContent =
			[[NSAttributedString alloc] initWithString: content];
	}
}
- (NSString*)content
{
	return content;
}
- (NSAttributedString*)contentAsAttributedString {
	return attributedContent;
}
- (NSDate*)time
{
	return time;
}
- (int)messageID
{
	return messageID;
}

- (BOOL)isFriendRequest
{
	NSString* gamertag = [from gamertag];
	return NSNotFound != 
		[content rangeOfString: 
			[NSString stringWithFormat: FRIEND_MSG, gamertag]].location;
}

- (void)sendReply: (NSString*)reply {
	[scraper queueMessage: reply 
				toFriends: [NSArray arrayWithObject: from]];
}

- (void)acceptRequest {
	[scraper acceptFriendRequest: self];
}

- (void)rejectRequest {
	[scraper rejectFriendRequest: self];
}

- (unsigned)hash {
	return messageID;
}

- (BOOL)readStatus {
	return readStatus;
}
- (void)setReadStatus: (BOOL)flag {
	readStatus = flag;
}

- (void)discard 
{
	NSLog(@"discard message %d", messageID);
	[scraper deleteMessage: self];
}


@end
