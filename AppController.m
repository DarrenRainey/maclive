#import "AppController.h"
#import "LiveScraper.h"
#import "Friend.h"
#import "Game.h"

// for keychain access
#include <CoreFoundation/CoreFoundation.h>
#include <Security/Security.h>
#include <CoreServices/CoreServices.h>

#define POLL_INTERVAL 60.0

@interface AppController (Private)

- (void)processNotifications;
- (Game*)gameFromFriend: (Friend*)f;
- (void)update;

@end

// wow, the keychain api is amazingly bad.
OSStatus GetPasswordKeychainImpl (void** passwordData,
							  UInt32* passwordLength,
							  SecKeychainItemRef* itemRef)
{
	OSStatus status1 ;
	
	
	status1 = SecKeychainFindGenericPassword (
											  NULL,           // default keychain
											  7,             // length of service name
											  "MacLive",   // service name
											  8,             // length of account name
											  "XboxLive",   // account name
											  passwordLength,  // length of password
											  passwordData,   // pointer to password data
											  itemRef         // the item reference
											  );
	return (status1);
}

OSStatus ChangePasswordKeychain (NSString* newPassword,
								 SecKeychainItemRef itemRef)
{
	OSStatus status;
    const char* password = [newPassword cString];
    UInt32 passwordLength = strlen(password);
	
    const char *account = "XboxLive";
    const char *service = "MacLive";
	
    // Set up attribute vector (each attribute consists of {tag, length, pointer}):
    SecKeychainAttribute attrs[] = {
	{ kSecAccountItemAttr, strlen(account), (char *)account },
	{ kSecServiceItemAttr, strlen(service), (char *)service }   };
    const SecKeychainAttributeList attributes = { sizeof(attrs) / sizeof(attrs[0]),                                                                    attrs };
	
	status = SecKeychainItemModifyAttributesAndData (
													 itemRef,        // the item reference
													 &attributes,    // no change to attributes
													 passwordLength,  // length of password
													 password        // pointer to password data
													 );
	return (status);	
}

OSStatus StorePasswordKeychain(NSString* pw) 
{
	SecKeychainItemRef itemRef;
	OSStatus status = GetPasswordKeychainImpl(NULL, 0, &itemRef);
	if(errSecItemNotFound == status) {
		return
		SecKeychainAddGenericPassword(NULL,
									  7,
									  "MacLive",
									  8,
									  "XboxLive",
									  [pw cStringLength],
									  [pw cString],
									  NULL);			
	} else {
		return ChangePasswordKeychain(pw, itemRef);
	}
}

NSString* GetPasswordKeychain() {
	SecKeychainItemRef itemRef;
	char* pwData = NULL;
	UInt32 pwLength = 255;
	OSStatus status = GetPasswordKeychainImpl((void**)&pwData, &pwLength, &itemRef);
	if(errSecItemNotFound == status) {
		return nil;
	} else {
		NSString* ret = [NSString stringWithCString: pwData length: pwLength];
		SecKeychainItemFreeContent(NULL, pwData);
		return ret;
	}
}


@implementation AppController

- (id)init
{
	if(self = [super init]) {
		scraper = [[LiveScraper alloc] init];
		[scraper setDelegate: self];
		previousNotableOnlineFriends =
			[[NSMutableSet alloc] init];
		previousNotableOnlineGames =
			[[NSMutableSet alloc] init];
	}
	return self;
}

- (IBAction)doIt:(id)sender
{
	NSLog(@"running ...");
	[[NSUserDefaults standardUserDefaults] setValue: [email stringValue] 
											 forKey: @"email"];
	
	StorePasswordKeychain([password stringValue]);
	
	[self update];
}

- (void)update
{
	[scraper updateWithUsername: [email stringValue]
					andPassword: [password stringValue]];
}

- (void)awakeFromNib
{
	[GrowlApplicationBridge setGrowlDelegate: self];
	[scraper setWebView: webView];
	
	NSString* savedEmail = [[NSUserDefaults standardUserDefaults] valueForKey: @"email"];
	if(savedEmail) {
		[email setStringValue: savedEmail];
	}
	NSString* pw = GetPasswordKeychain();
	if(pw) {
		[password setStringValue: pw];
	}
	
	if(pw && savedEmail) {
		[self update];
	}
}

- (void)dealloc 
{
	[scraper release];
	[previousNotableOnlineFriends release];
	[previousNotableOnlineGames release];
	[super dealloc];
}

- (void)setScraper: (LiveScraper*)newScraper
{
	NSLog(@"setting scraper");
	if(scraper != newScraper) {
		[scraper release];
		scraper = [newScraper retain];
	}
	NSLog(@"done setting scraper");
}
- (LiveScraper*)scraper
{
	NSLog(@"accessing scraper %x", (int)scraper);
	return scraper;
}

- (void)loginIncorrect
{
	NSLog(@"loginIncorrect");
	[[NSAlert alertWithMessageText:
			@"Sign In Failed"
					defaultButton: @"OK"
				  alternateButton: nil 
					  otherButton: nil 
		informativeTextWithFormat: 
			@"Xbox Live was not particularly impressed with your login information.  "
			@"You should try again with the right email and password."] runModal];
	[password setStringValue: @""];
	[tabView selectTabViewItemWithIdentifier: @"setup"];
	[self loadComplete];
}
- (void)accountLocked
{
	NSLog(@"accountLocked");
	[[NSAlert alertWithMessageText:
		@"Bad News: Xbox Live is seriously vexed with you"
					defaultButton: @"OK"
				  alternateButton: nil
					  otherButton: nil
		informativeTextWithFormat:
			@"At this point I'm just going to take a hands off approach "
			@"and let you deal with them.  Press \"OK\" and you'll see what "
			@"I mean."] runModal];
	[webView setHidden: NO];
	[[webView window] makeKeyAndOrderFront: self];
	[self loadComplete];
}

- (void)loadComplete
{
	// necessary to prevent odd bleeding bug
	[webView setHidden: YES];
	[[webView window] close];
	[loginButton setEnabled: YES];
	[spinner stopAnimation: self];
	[spinner setHidden: YES];
	
	if([[[tabView selectedTabViewItem] identifier] isEqual: @"setup"]) {
		[tabView selectTabViewItemWithIdentifier: @"friends"];
	}
	
	[self processNotifications];
	
	[self performSelector: @selector(update)
			   withObject: self 
			   afterDelay: POLL_INTERVAL];
}
- (void)loadStart
{
	[loginButton setEnabled: NO];
	[spinner startAnimation: self];
	[spinner setHidden: NO];
}
- (void)loadFailed: (NSError*)error
{
	[[NSAlert alertWithError: error] runModal];
	[webView setHidden: YES];
	[[webView window] close];
	[loginButton setEnabled: YES];
	[spinner stopAnimation: self];
	[spinner setHidden: YES];
}
- (void)processNotifications
{
	Friend* f;
	NSEnumerator* e = [[scraper friends] objectEnumerator];
	NSMutableDictionary* notableGames = [NSMutableDictionary dictionary];
	NSMutableDictionary* notableGameIcons = [NSMutableDictionary dictionary];
	NSMutableArray* savedNotableGames = [NSMutableArray array];
	while(f = [e nextObject]) {
		if([f notify] &&
		   [f online] &&
		   ![previousNotableOnlineFriends containsObject: [f gamertag]]) 
		{
			[GrowlApplicationBridge
				notifyWithTitle: @"Friend Online"
					description: [NSString stringWithFormat: @"%@ is now online playing %@.", [f gamertag], [f currentGame]]
			   notificationName: @"Friend"
					   iconData: [[[[NSImage alloc] initWithContentsOfURL: [f icon]] autorelease] TIFFRepresentation]
					   priority: 0
					   isSticky: NO
				   clickContext: nil];
		}
		Game* g = [self gameFromFriend: f];
		if(g != nil &&
		   [g notify] &&
		   ![previousNotableOnlineGames containsObject: [g name]]) {
			NSNumber* c = [notableGames valueForKey: [g name]];
			if(!c) {
				c = [NSNumber numberWithInt: 1];
			} else {
				c = [NSNumber numberWithInt: [c intValue] + 1];
			}
			[notableGames setValue: c forKey: [g name]];
			[notableGameIcons setValue: [g icon] forKey: [g name]];
		} else if(g != nil && [g notify]) {
			[savedNotableGames addObject: [g name]];
		}
	}
	
	NSString* gameName;
	e = [notableGames keyEnumerator];
	while(gameName = [e nextObject]) {
		NSNumber* count = [notableGames valueForKey: gameName];
		NSData* iconData = 
			[[[[NSImage alloc] initWithContentsOfURL: [notableGameIcons valueForKey: gameName]] autorelease] TIFFRepresentation];
		[GrowlApplicationBridge
				notifyWithTitle: @"Game Online"
					description: [NSString stringWithFormat: @"%d friend%s now online playing %@.", 
							[count intValue],
							([count intValue] == 1
							? " is"
							: "s are"), gameName]
			   notificationName: @"Game"
					   iconData: iconData
					   priority: 0
					   isSticky: NO
				   clickContext: nil];
	}
	
	[previousNotableOnlineFriends removeAllObjects];
	e = [[scraper friends] objectEnumerator];
	while(f = [e nextObject]) {
		if([f notify] && [f online]) {
			[previousNotableOnlineFriends addObject: [f gamertag]];
		}
	}
	[previousNotableOnlineGames removeAllObjects];
	[previousNotableOnlineGames addObjectsFromArray: [notableGames allKeys]];
	[previousNotableOnlineGames addObjectsFromArray: savedNotableGames];
}
- (Game*)gameFromFriend: (Friend*)f
{
	if(![f online]) return nil;
	// search ...
	NSEnumerator* e = [[scraper games] objectEnumerator];
	Game* g;
	while(g = [e nextObject]) {
		if([[g name] isEqual: [f currentGame]]) {
			return g;
		}
	}
	return nil;
}
- (NSDictionary*)registrationDictionaryForGrowl
{
	NSArray* objs = [NSArray arrayWithObjects: @"Friend", @"Game", nil];
	NSDictionary* ret =
		[NSDictionary dictionaryWithObjectsAndKeys:
			objs, GROWL_NOTIFICATIONS_ALL,
			objs, GROWL_NOTIFICATIONS_DEFAULT,
			nil];
	return ret;
}

@end
