#import "../../Utils.h"
#import "../../InstagramHeaders.h"

%hook IGExploreGridViewController
- (void)viewDidLoad {
    if ([PSIUtils getBoolPref:@"hide_explore_grid"]) {
        NSLog(@"[PSInstagram] Hiding explore grid");

        [[self view] removeFromSuperview];

        return;
    }
    
    return %orig;
}
%end

%hook IGExploreViewController
- (void)viewDidLoad {
    %orig;

    if ([PSIUtils getBoolPref:@"hide_explore_grid"]) {
        NSLog(@"[PSInstagram] Hiding explore grid");

        IGShimmeringGridView *shimmeringGridView = MSHookIvar<IGShimmeringGridView *>(self, "_shimmeringGridView");
        if (shimmeringGridView != nil) {
            [shimmeringGridView removeFromSuperview];
        }
    }
}
%end