#import "../../Utils.h"
#import "../../InstagramHeaders.h"

// Disable story data source
%hook IGMainStoryTrayDataSource
- (id)initWithUserSession:(id)arg1 {
    if ([PSIUtils getBoolPref:@"hide_stories_tray"]) {
        NSLog(@"[PSInstagram] Hiding story tray");

        return nil;
    }
    
    return %orig;
}
%end