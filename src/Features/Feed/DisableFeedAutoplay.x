#import "../../Utils.h"

// Demangled name: IGFeedPlayback.IGFeedPlaybackStrategy
%hook _TtC14IGFeedPlayback22IGFeedPlaybackStrategy
- (id)initWithShouldDisableAutoplay:(_Bool)autoplay {
    if ([PSIUtils getBoolPref:@"disable_feed_autoplay"]) return %orig(true);

    return %orig(autoplay);
}
%end