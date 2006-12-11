//
//  LiveScraper.m
//  MacLive
//
//  Created by James Howard on 12/7/06.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import "LiveScraper.h"
#import "Friend.h"
#import "Game.h"

#define FRIENDS_PAGE	@"http://live.xbox.com/en-US/profile/Friends.aspx"
#define GAMES_PAGE		@"http://live.xbox.com/en-US/profile/Achievements/ViewAchievementSummary.aspx"
#define SIGN_IN_PAGE	@"login.live.com"

#define WRONG_LOGIN		@"The e-mail address or password is incorrect"
#define LOCKED_ACCOUNT	@"Sign in failed"

#define JS_LIB			\
	@"function elementsByClassName(tagName, className) {" \
	@"  var els = document.getElementsByTagName(tagName);" \
	@"  var ret = [];" \
	@"  for(var i = 0; i < els.length; i++) {" \
	@"    var el = els[i];" \
	@"    if(el.className == className) {" \
	@"      ret.push(el);" \
	@"    }" \
	@"  }" \
	@"  return ret;" \
	@"}"

@interface LiveScraper (Private)

- (void)jump: (NSString*)url;

- (void)nabFriends;
- (void)nabGames;


- (void)gotFriends;
- (void)gotGames;
- (void)gotSignIn;

@end

@interface LiveScraper (JSCallbacks)

- (void)sawFriend: (NSString*)gamertag
		  iconURL: (NSString*)url
		   status: (NSString*)status;

- (void)sawGame: (NSString*)name
		iconURL: (NSString*)url;

@end

@implementation LiveScraper

- (id)init
{
	if(self = [super init]) {	
		friends = [[NSMutableArray alloc] init];
		games = [[NSMutableArray alloc] init];
		username = nil;
		password = nil;
		delegate = nil;
	}
	return self;
}

- (void)setDelegate: (id<LiveScraperDelegate>)del
{
	// don't retain to avoid cycles
	delegate = del;
}

- (void)setWebView: (WebView*)webView
{
	if(view != webView) {
		[view release];
		view = [webView retain];
		[view setFrameLoadDelegate: self];
		[view setUIDelegate: self];
	}
}

- (void)dealloc
{
	[view release];
	[friends release];
	[games release];
	[super dealloc];
}

- (void)updateWithUsername: (NSString*)name
			   andPassword: (NSString*)pw
{
	[delegate loadStart];
	if(username != name) {
		[username release];
		username = [name retain];
	}
	if(password != pw) {
		[password release];
		password = [pw retain];
	}
	
	[self nabFriends];
	//[self webkitTestingBypass];
	// nabGames will be called at the conclusion of gotFriends
	// I don't do these things in parallel since I only have one
	// web view and what with cookies it probably wouldn't
	// work to do so anyway.
}

- (void)webkitTestingBypass {
	[self willChangeValueForKey: @"friends"];
	[self willChangeValueForKey: @"games"];
	
	[friends removeAllObjects];
	[games removeAllObjects];
	
	int i;
	for(i = 0; i < 20; i++) {
		Friend* f = [[Friend alloc] initWithGamertag: @"test"
											 iconURL: @"http://tiles.xbox.com/tiles/j4/0A/1mdsb2JgbC9CC1ZXV0oAGAFdL3RpbGUvMC8xMTAxNgAAAQAAAAD5L42v.jpg"
										  statusText: @"Playing Test"];
		[friends addObject: f];
		[f release];
		
		Game* g = [[Game alloc] initWithName: @"test" 
									 iconURL: @"http://tiles.xbox.com/tiles/j4/0A/1mdsb2JgbC9CC1ZXV0oAGAFdL3RpbGUvMC8xMTAxNgAAAQAAAAD5L42v.jpg"];
		[games addObject: g];
		[g release];
	}
	
	[self didChangeValueForKey: @"friends"];
	[self didChangeValueForKey: @"games"];
	
	[delegate loadComplete];
}

- (void)jump: (NSString*)to
{
	[[view mainFrame] stopLoading];
	[[view mainFrame] loadRequest:
		[NSURLRequest requestWithURL:
			[NSURL URLWithString: to]]];
}

- (void)nabFriends
{
	[self jump: FRIENDS_PAGE];
}

- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame
{
	NSString* url = [[[[frame dataSource] mainResource] URL] absoluteString];
	if(NSNotFound != [url rangeOfString: SIGN_IN_PAGE].location) {
		[self gotSignIn];
	} else if(NSNotFound != [url rangeOfString: FRIENDS_PAGE].location) {
		[self gotFriends];
	} else if(NSNotFound != [url rangeOfString: GAMES_PAGE].location) {
		[self gotGames];
	}
	// else it's an intermediate page, just do nothing
}

- (void)gotSignIn
{
	// check to make sure that there isn't a warning complaining
	// of an incorrect login.  if there is then the best thing to do
	// is to stop and inform the delegate.  Continuing to provide
	// an incorrect login is a good way to get the account locked.
	NSString* documentHTML = 
	[(DOMHTMLElement*)[[[view mainFrame] DOMDocument] documentElement] outerHTML];
	if(NSNotFound != [documentHTML rangeOfString: WRONG_LOGIN].location) {
		NSLog(@"wrong login");
		[delegate loginIncorrect];
		return;
	} else if(NSNotFound != [documentHTML rangeOfString: LOCKED_ACCOUNT].location) {
		NSLog(@"account locked");
		[delegate accountLocked];
		return;
	}
	
	// fill in the form fields with the username and password and
	// submit the form
	NSString* script = 
		[NSString stringWithFormat:
			@"var emailEl = document.getElementById('i0116');\n"
			@"var passwordEl = document.getElementById('i0118');\n"
			@"var email = '%@'; var password='%@';\n"
			@"emailEl.value = email; passwordEl.value=password;\n"
			@"document.forms[0].submit();\n", 
			username, password];
	[view stringByEvaluatingJavaScriptFromString: script];
}

- (void)gotFriends
{
	[self willChangeValueForKey: @"friends"];
	[friends removeAllObjects];
	
	id window = [view windowScriptObject];
	[window setValue: self forKey: @"scraper"];
	
	NSString* script = 
		JS_LIB
		@"var imgs = elementsByClassName('td', 'XbcGamerTile');\n"
		@"var names = elementsByClassName('td', 'XbcGamerTag');\n"
		@"var statuses = elementsByClassName('td', 'XbcGamerDescription');\n"
		@"for(var i = 0; i < imgs.length; i++) {\n"
		@"	var url = null;\n"
		@"	for(var j = 0; j < imgs[i].childNodes.length; j++) {\n"
		@"	  var e = imgs[i].childNodes[j];\n"
		@"	  if(e.tagName == 'IMG') {\n"
		@"      url = e.src;\n"
		@"		break;\n"
		@"    }\n"
		@"  }\n"
		@"  scraper.sawFriend_iconURL_status_(names[i].innerText, url, statuses[i].innerText);\n"
		@"}\n";
	
	[view stringByEvaluatingJavaScriptFromString: script];
	
	NSLog(@"Saw %d friends", [friends count]);
	[self didChangeValueForKey: @"friends"];
	
	[self jump: GAMES_PAGE];
}

- (void)sawFriend: (NSString*)gamertag
		  iconURL: (NSString*)url
		   status: (NSString*)status
{
	NSLog(@"saw friend: %@ icon: %@ status: %@", gamertag, url, status);
	Friend* f = [[Friend alloc] initWithGamertag: gamertag 
										 iconURL: url 
									  statusText: status];
	[friends addObject: f];
	[f release];
}


- (void)gotGames
{
	[self willChangeValueForKey: @"games"];
	[games removeAllObjects];
	
	id window = [view windowScriptObject];
	[window setValue: self forKey: @"scraper"];
	
	NSString* script = 
		JS_LIB
		@"var imgs = elementsByClassName('img', 'AchievementsGameIcon');\n"
		@"var names = elementsByClassName('strong', 'XbcAchievementsTitle');\n"
		@"for(var i = 0; i < imgs.length; i++) {\n"
		@"  scraper.sawGame_iconURL_(names[i].innerText, imgs[i].src);\n"
		@"}\n";
	[view stringByEvaluatingJavaScriptFromString: script];
	NSLog(@"Saw %d games", [games count]);
	[self didChangeValueForKey: @"games"];
	
	[delegate loadComplete];
}

- (void)sawGame: (NSString*)name
		iconURL: (NSString*)url
{
	NSLog(@"saw game: %@ icon: %@", name, url);
	Game* g = [[Game alloc] initWithName: name
								 iconURL: url];
	[games addObject: g];
	[g release];
}

- (NSArray*)games 
{
	NSLog(@"accessing games %x", (int)games);
	return games;
}

- (NSArray*)friends
{
	NSLog(@"accessing friends %x", (int)friends);
	return friends;
}

- (void)webView:(WebView *)sender runJavaScriptAlertPanelWithMessage:(NSString *)message
{
	NSLog(@"JS Alert: %@", message);
}

- (void)webView:(WebView *)sender didFailLoadWithError:(NSError *)error forFrame:(WebFrame *)frame
{
	if([error code] != -999) { // spurious error
		[delegate loadFailed: error];
	}
}


+ (BOOL)isSelectorExcludedFromWebScript:(SEL)aSelector
{
	return NO;
}

@end
