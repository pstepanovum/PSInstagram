#import "../../Utils.h"

%hook IGCommentComposer.IGCommentComposerController
- (void)onSendButtonTap {
    if ([PSIUtils getBoolPref:@"post_comment_confirm"]) {
        NSLog(@"[PSInstagram] Confirm post comment triggered");

        [PSIUtils showConfirmation:^(void) { %orig; }];
    } else {
        return %orig;
    }
}
%end