#import "../../Utils.h"
#import "../../InstagramHeaders.h"

// Channels dms tab (header)
%hook IGDirectInboxHeaderSectionController
- (id)viewModel {
    if ([[%orig title] isEqualToString:@"Suggested"]) {

        if ([PSIUtils getBoolPref:@"no_suggested_chats"]) {
            NSLog(@"[PSInstagram] Hiding suggested chats (header: channels tab)");

            return nil;
        }

    }

    return %orig;
}
%end