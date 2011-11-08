//
//  MFMailComposeViewController+BlocksKit.m
//  BlocksKit
//

#import "MFMailComposeViewController+BlocksKit.h"
#import "NSObject+BlocksKit.h"
#import "BKDelegateProxy.h"

static char *kCompletionHandlerKey = "BKCompletionHandler";

#pragma mark Delegate

@interface BKMailComposeViewControllerDelegate : BKDelegateProxy <MFMailComposeViewControllerDelegate>
@end

@implementation BKMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    id delegate = controller.mailComposeDelegate;
    if (delegate && [delegate respondsToSelector:@selector(mailComposeController:didFinishWithResult:error:)])
        [controller.mailComposeDelegate mailComposeController:controller didFinishWithResult:result error:error];
    
    BKMailComposeBlock block = controller.completionHandler;
    if (block)
        block(result, error);
}

@end

#pragma mark Category

@implementation MFMailComposeViewController (BlocksKit)

+ (void)load {
    [self swizzleSelector:@selector(mailComposeDelegate) withSelector:@selector(bk_mailComposeDelegate)];
    [self swizzleSelector:@selector(setMailComposeDelegate:) withSelector:@selector(bk_setMailComposeDelegate:)];
}

#pragma mark Methods

- (id)bk_mailComposeDelegate {
    return [self associatedValueForKey:kBKDelegateKey];
}

- (void)bk_setMailComposeDelegate:(id)delegate {
    [self weaklyAssociateValue:delegate withKey:kBKDelegateKey];
    [self bk_setMailComposeDelegate:[BKMailComposeViewControllerDelegate shared]];
}

#pragma mark Properties
 
- (BKMailComposeBlock)completionHandler {
    return [self associatedValueForKey:kCompletionHandlerKey];
}

- (void)setCompletionHandler:(BKMailComposeBlock)handler {
    [self bk_setMailComposeDelegate:[BKMailComposeViewControllerDelegate shared]];
    [self associateCopyOfValue:handler withKey:kCompletionHandlerKey];
}

@end
