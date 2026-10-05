#import "../../Utils.h"

%hook IGDirectTypingStatusService
- (void)updateOutgoingStatusIsActive:(_Bool)active threadKey:(id)key threadMetadata:(id)metadata typingStatusType:(long long)type {
    if ([PSIUtils getBoolPref:@"disable_typing_status"]) return;

    return %orig(active, key, metadata, type);
}
%end