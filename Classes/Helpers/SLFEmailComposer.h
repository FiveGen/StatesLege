//
//  SLFEmailComposer.h
//  Created by Gregory Combs on 8/10/10.
//
//  OpenStates (iOS) by Sunlight Foundation Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

#import <MessageUI/MessageUI.h>

@interface SLFEmailComposer : NSObject <MFMailComposeViewControllerDelegate>
@property (nonatomic) BOOL isComposingMail;
+ (SLFEmailComposer *)sharedComposer;
- (void)presentMailComposerTo:(NSString*)recipient subject:(NSString*)subject body:(NSString*)body parent:(UIViewController *)parent;
- (void)presentAppSupportComposerFromParent:(UIViewController *)parent;
@end
