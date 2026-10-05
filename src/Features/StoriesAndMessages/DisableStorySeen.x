#import "../../Utils.h"
#import "../../InstagramHeaders.h"

%hook IGStorySeenStateUploader
- (id)initWithUserSessionPK:(id)arg1 networker:(id)arg2 {
    if ([PSIUtils getBoolPref:@"no_seen_receipt"]) {
        NSLog(@"[PSInstagram] Prevented seen receipt from being sent");

        return nil;
    }
    
    return %orig;
}

- (id)networker {
    if ([PSIUtils getBoolPref:@"no_seen_receipt"]) {
        NSLog(@"[PSInstagram] Prevented seen receipt from being sent");

        return nil;
    }
    
    return %orig;
}
%end