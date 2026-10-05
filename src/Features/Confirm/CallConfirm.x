#import "../../Utils.h"

%hook IGDirectThreadCallButtonsCoordinator
// Voice Call
- (void)_didTapAudioButton:(id)arg1 {
    if ([PSIUtils getBoolPref:@"call_confirm"]) {
        NSLog(@"[PSInstagram] Call confirm triggered");

        [PSIUtils showConfirmation:^(void) { %orig; }];
    } else {
        return %orig;
    }
}

// Video Call
- (void)_didTapVideoButton:(id)arg1 {
    if ([PSIUtils getBoolPref:@"call_confirm"]) {
        NSLog(@"[PSInstagram] Call confirm triggered");
        
        [PSIUtils showConfirmation:^(void) { %orig; }];
    } else {
        return %orig;
    }
}
%end