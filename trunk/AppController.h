/* AppController */

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#import <Growl-WithInstaller/Growl.h>
@class LiveScraper;
@protocol LiveScraperDelegate;

@interface AppController : NSObject <GrowlApplicationBridgeDelegate, LiveScraperDelegate>
{
    IBOutlet NSTextField *email;
    IBOutlet NSSecureTextField *password;
    IBOutlet NSProgressIndicator *spinner;
    IBOutlet WebView *webView;
	IBOutlet NSTabView *tabView;
	IBOutlet NSButton *loginButton;
	IBOutlet NSWindow* addFriendSheet;
	IBOutlet NSTextField *newFriend;
	
	LiveScraper* scraper;
	
	NSMutableSet* previousNotableOnlineFriends;
	NSMutableSet* previousNotableOnlineGames;
	
}
- (IBAction)doIt:(id)sender;
- (IBAction)showAddFriendSheet: (id)sender;

- (IBAction)addFriendOK: (id)sender;
- (IBAction)addFriendCancel: (id)sender;

- (void)setScraper: (LiveScraper*)scraper;
- (LiveScraper*)scraper;

- (void)addFriend: (NSString*)gamertag;

- (void)doAddFriend: (NSPasteboard*)pboard
		   userData: (NSString*)userData
			  error: (NSString**)error;

@end
