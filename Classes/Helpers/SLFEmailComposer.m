//
//  SLFEmailComposer.m
//  Created by Gregory Combs on 8/10/10.
//
//  StatesLege by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

#import "SLFEmailComposer.h"
#import "SLFReachable.h"
#import "SLFAlertView.h"

@interface SLFEmailComposer()
@property (nonatomic, retain) MFMailComposeViewController *composer;
@end

@implementation SLFEmailComposer

@synthesize composer = _composer;
@synthesize isComposingMail = _isComposingMail;

+ (id)sharedComposer
{
	static dispatch_once_t pred;
	static SLFEmailComposer *foo = nil;
	dispatch_once(&pred, ^{ foo = [[self alloc] init]; });
	return foo;
}

- (id) init
{
    if ((self = [super init]))
    {
		_isComposingMail = NO;
    }
    return self;
}

- (void)dealloc {
	self.composer = nil;
    [super dealloc];
}

- (BOOL)isNetworkAvailableForURL:(NSURL *)url {
    if (![[SLFReachable sharedReachable] isURLReachable:url])
        return NO;
    if (![[UIApplication sharedApplication] canOpenURL:url])
        return NO;
    return YES;
}

- (void)presentMailComposerTo:(NSString*)recipient subject:(NSString*)subject body:(NSString*)body parent:(UIViewController *)parent {
	if (!parent)
		return;
	if (!body)
		body = @"";
	if ([MFMailComposeViewController canSendMail]) {
		self.isComposingMail = YES;
        self.composer = nil;
		_composer = [[MFMailComposeViewController alloc] init];
		_composer.mailComposeDelegate = self;
		[_composer setSubject:subject];
		[_composer setToRecipients:[NSArray arrayWithObject:recipient]];
		[_composer setMessageBody:body isHTML:NO];
		[parent presentModalViewController:_composer animated:YES];
	}
	else {
		NSMutableString *message = [NSMutableString stringWithFormat:@"mailto:%@", recipient];
		if (!IsEmpty(subject))
			[message appendFormat:@"&subject=%@", subject];
		if (!IsEmpty(body))
			[message appendFormat:@"&body=%@", body];
		NSURL *mailto = [NSURL URLWithString:[message stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
		if ( ![self isNetworkAvailableForURL:mailto] ) {
			[SLFAlertView showWithTitle:NSLocalizedString(@"Network Unavailable", @"")
								message:NSLocalizedString(@"Cannot send an email at this time.  Please check your network settings and try again.", @"")
							buttonTitle:NSLocalizedString(@"Cancel", @"")];
            return;
		}			
        [[UIApplication sharedApplication] openURL:mailto];
	}
}

#pragma mark -
#pragma mark Mail Composer Delegate

- (void)mailComposeController:(MFMailComposeViewController*)mailController didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error {
	if (result == MFMailComposeResultFailed) {
		[SLFAlertView showWithTitle:NSLocalizedString(@"Failure, Message Not Sent", @"")
							message:NSLocalizedString(@"An error prevented successful transmission of your message. Check your email and network settings or try emailing manually.", @"")
						buttonTitle:NSLocalizedString(@"Cancel", @"")];
	}
	[self.composer dismissModalViewControllerAnimated:YES];
	self.isComposingMail = NO;
	self.composer = nil;
}


@end
