#import "../../Utils.h"

// Leave search as a plain people finder: no recents/suggestions before typing,
// no topic pills on explore, no "Discover people" banners on profiles

static BOOL PSIViewIsInsideControllerNamed(UIView *view, NSString *className) {
    for (UIResponder *responder = view; responder; responder = responder.nextResponder) {
        if ([NSStringFromClass([responder class]) isEqualToString:className]) return YES;
    }

    return NO;
}

// Recent & suggested lists shown under an empty search bar
@interface IGSearchMainTypeaheadListViewController : UIViewController
- (BOOL)_isNullState;
@end

%hook IGSearchMainTypeaheadListViewController
- (NSArray *)objectsForListAdapter:(id)listAdapter {
    if ([PSIUtils getBoolPref:@"hide_search_null_state"] && [self _isNullState]) {
        NSLog(@"[PSInstagram] Hiding search recents & suggestions");

        return @[];
    }

    return %orig;
}
%end

// Topic pills (For you, ...) on the explore page
@interface IGTabPageSegmentedPillBarView : UIView
@end

%hook IGTabPageSegmentedPillBarView
- (void)layoutSubviews {
    %orig;

    if ([PSIUtils getBoolPref:@"hide_explore_topics"] && PSIViewIsInsideControllerNamed(self, @"IGExploreViewController")) {
        self.hidden = YES;
    }
}
%end

// "Discover people" and "Suggested for you" banners in profile headers
@interface IGHScrollBannerCell : UICollectionViewCell
@end

@interface IGHScrollAYMFCell : UICollectionViewCell
@end

%hook IGHScrollBannerCell
- (void)layoutSubviews {
    %orig;

    if ([PSIUtils getBoolPref:@"no_suggested_users"]) {
        self.hidden = YES;
    }
}
%end

%hook IGHScrollAYMFCell
- (void)layoutSubviews {
    %orig;

    if ([PSIUtils getBoolPref:@"no_suggested_users"]) {
        // Hide the whole carousel, including its header
        for (UIView *view = self; view; view = view.superview) {
            view.hidden = YES;
            if ([NSStringFromClass([view class]) isEqualToString:@"IGHScrollCollectionViewCell"]) break;
        }
    }
}
%end
