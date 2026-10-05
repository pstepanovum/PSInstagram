#import "../../Utils.h"

%hook IGStoryViewerTapTarget
- (void)_didTap:(id)arg1 forEvent:(id)arg2 {
    if ([PSIUtils getBoolPref:@"sticker_interact_confirm"]) {
        NSLog(@"[PSInstagram] Confirm sticker interact triggered");

        [PSIUtils showConfirmation:^(void) { %orig; }];
    } else {
        return %orig;
    }
}
%end