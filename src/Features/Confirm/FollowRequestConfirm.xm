#import "../../Utils.h"

%hook IGPendingRequestView
- (void)_onApproveButtonTapped {
    if ([PSIUtils getBoolPref:@"follow_request_confirm"]) {
        NSLog(@"[PSInstagram] Confirm follow request triggered");

        [PSIUtils showConfirmation:^(void) { %orig; }];
    } else {
        return %orig;
    }
}
- (void)_onIgnoreButtonTapped {
    if ([PSIUtils getBoolPref:@"follow_request_confirm"]) {
        NSLog(@"[PSInstagram] Confirm follow request triggered");

        [PSIUtils showConfirmation:^(void) { %orig; }];
    } else {
        return %orig;
    }
}
%end