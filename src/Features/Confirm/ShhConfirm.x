#import "../../Utils.h"

%hook IGDirectThreadViewController
- (void)swipeableScrollManagerDidEndDraggingAboveSwipeThreshold:(id)arg1 {
    if ([PSIUtils getBoolPref:@"shh_mode_confirm"]) {
        NSLog(@"[PSInstagram] Confirm shh mode triggered");

        [PSIUtils showConfirmation:^(void) { %orig; }];
    } else {
        return %orig;
    }
}

- (void)shhModeTransitionButtonDidTap:(id)arg1 {
    if ([PSIUtils getBoolPref:@"shh_mode_confirm"]) {
        NSLog(@"[PSInstagram] Confirm shh mode triggered");

        [PSIUtils showConfirmation:^(void) { %orig; }];
    } else {
        return %orig;
    }
}

- (void)messageListViewControllerDidToggleShhMode:(id)arg1 {
    if ([PSIUtils getBoolPref:@"shh_mode_confirm"]) {
        NSLog(@"[PSInstagram] Confirm shh mode triggered");

        [PSIUtils showConfirmation:^(void) { %orig; }];
    } else {
        return %orig;
    }
}
%end