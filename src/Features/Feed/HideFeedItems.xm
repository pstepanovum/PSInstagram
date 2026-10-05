#import "../../Utils.h"
#import "../../InstagramHeaders.h"

static NSArray *removeItemsInList(NSArray *list, BOOL isFeed) {
    NSArray *originalObjs = list;
    NSMutableArray *filteredObjs = [NSMutableArray arrayWithCapacity:[originalObjs count]];

    for (id obj in originalObjs) {
        // Hide entire feed: drop everything but the story tray, so new feed units (e.g. "Expiring Stories") can't slip through
        if (isFeed && [PSIUtils getBoolPref:@"hide_entire_feed"]) {
            if ([obj isKindOfClass:%c(IGStoryDataController)] && ![PSIUtils getBoolPref:@"hide_stories_tray"]) {
                [filteredObjs addObject:obj];
            }
            else {
                NSLog(@"[PSInstagram] Hiding feed item %@", NSStringFromClass([obj class]));
            }

            continue;
        }

        // Remove suggested posts
        if (isFeed && [PSIUtils getBoolPref:@"no_suggested_post"]) {

            // Posts
            if (
                ([obj isKindOfClass:%c(IGMedia)] && [((IGMedia *)obj).explorePostInFeed isEqual:@YES])
                || ([obj isKindOfClass:%c(IGFeedGroupHeaderViewModel)] && [[obj title] isEqualToString:@"Suggested Posts"])
            ) {
                NSLog(@"[PSInstagram] Removing suggested posts");

                continue;
            }

            // Suggested stories (carousel)
            if ([obj isKindOfClass:%c(IGInFeedStoriesTrayModel)]) {
                NSLog(@"[PSInstagram] Hiding suggested stories carousel");

                continue;
            }

        }

        // Remove suggested reels (carousel)
        if (isFeed && [PSIUtils getBoolPref:@"no_suggested_reels"]) {
            if ([obj isKindOfClass:%c(IGFeedScrollableClipsModel)]) {
                NSLog(@"[PSInstagram] Hiding suggested reels carousel");

                continue;
            }
        }
        
        // Remove suggested for you (accounts)
        if ([PSIUtils getBoolPref:@"no_suggested_account"]) {
            
            // Feed
            if (isFeed && [obj isKindOfClass:%c(IGHScrollAYMFModel)]) {
                NSLog(@"[PSInstagram] Hiding accounts suggested for you (feed)");

                continue;
            }

            // Reels
            if ([obj isKindOfClass:%c(IGSuggestedUserInReelsModel)]) {
                NSLog(@"[PSInstagram] Hiding accounts suggested for you (reels)");

                continue;
            }
        }

        // Remove suggested threads posts
        if ([PSIUtils getBoolPref:@"no_suggested_threads"]) {

            // Feed (carousel)
            if (isFeed) {
                if ([obj isKindOfClass:%c(IGBloksFeedUnitModel)] || [obj isKindOfClass:objc_getClass("IGThreadsInFeedModels.IGThreadsInFeedModel")]) {
                    NSLog(@"[PSInstagram] Hiding suggested threads posts (carousel)");

                    continue;
                }
            }

            // Reels
            if ([obj isKindOfClass:%c(IGSundialNetegoItem)]) {
                NSLog(@"[PSInstagram] Hiding suggested threads posts (reels)");

                continue;
            }

        }        

        // Remove story tray
        if (isFeed && [PSIUtils getBoolPref:@"hide_stories_tray"]) {
            if ([obj isKindOfClass:%c(IGStoryDataController)]) {
                NSLog(@"[PSInstagram] Hiding stories tray");

                continue;
            }
        }

        // Remove ads
        if ([PSIUtils getBoolPref:@"hide_ads"]) {
            if (
                ([obj isKindOfClass:%c(IGFeedItem)] && ([obj isSponsored] || [obj isSponsoredApp]))
                || ([obj isKindOfClass:%c(IGDiscoveryGridItem)] && [[obj model] isKindOfClass:%c(IGAdItem)])
                || [obj isKindOfClass:%c(IGAdItem)]
            ) {
                NSLog(@"[PSInstagram] Removing ads");

                continue;
            }
        }

        [filteredObjs addObject:obj];
    }

    return [filteredObjs copy];
}

// Suggested posts/reels
%hook IGMainFeedListAdapterDataSource
- (NSArray *)objectsForListAdapter:(id)arg1 {
    NSArray *filteredObjs = removeItemsInList(%orig, YES);

    // Remove loading spinner at end of feed (if 5 or less items in feed)
    NSUInteger arrayLength = [filteredObjs count];

    if (arrayLength <= 5) {
        filteredObjs = [filteredObjs filteredArrayUsingPredicate:
            [NSPredicate predicateWithBlock:^BOOL(id obj, NSDictionary *bindings) {
                return ![obj isKindOfClass:[%c(IGSpinnerLabelViewModel) class]];
            }]
        ];
    }

    return filteredObjs;
}
%end
%hook IGSundialFeedDataSource
- (NSArray *)objectsForListAdapter:(id)arg1 {
    NSArray *filteredList = removeItemsInList(%orig, NO);

    if ([PSIUtils getBoolPref:@"prevent_doom_scrolling"]) {
        double reelCount = [PSIUtils getDoublePref:@"doom_scrolling_reel_count"];
        return [filteredList subarrayWithRange:NSMakeRange(0, MIN((NSUInteger)reelCount, filteredList.count))];
    }

    return filteredList;
}
%end
%hook IGContextualFeedViewController
- (NSArray *)objectsForListAdapter:(id)arg1 {
    if ([PSIUtils getBoolPref:@"hide_ads"]) {
        return removeItemsInList(%orig, NO);
    }

    return %orig;
}
%end
%hook IGVideoFeedViewController
- (NSArray *)objectsForListAdapter:(id)arg1 {
    if ([PSIUtils getBoolPref:@"hide_ads"]) {
        return removeItemsInList(%orig, NO);
    }

    return %orig;
}
%end
%hook IGChainingFeedViewController
- (NSArray *)objectsForListAdapter:(id)arg1 {
    if ([PSIUtils getBoolPref:@"hide_ads"]) {
        return removeItemsInList(%orig, NO);
    }

    return %orig;
}
%end
%hook IGStoryAdPool
- (id)initWithUserSession:(id)arg1 {
    if ([PSIUtils getBoolPref:@"hide_ads"]) {
        NSLog(@"[PSInstagram] Removing ads");

        return nil;
    }

    return %orig;
}
%end
%hook IGStoryAdsManager
- (id)initWithUserSession:(id)arg1 storyViewerLoggingContext:(id)arg2 storyFullscreenSectionLoggingContext:(id)arg3 viewController:(id)arg4 {
    if ([PSIUtils getBoolPref:@"hide_ads"]) {
        NSLog(@"[PSInstagram] Removing ads");

        return nil;
    }

    return %orig;
}
%end
%hook IGStoryAdsFetcher
- (id)initWithUserSession:(id)arg1 delegate:(id)arg2 {
    if ([PSIUtils getBoolPref:@"hide_ads"]) {
        NSLog(@"[PSInstagram] Removing ads");

        return nil;
    }

    return %orig;
}
%end
// IG 148.0
%hook IGStoryAdsResponseParser
- (id)parsedObjectFromResponse:(id)arg1 {
    if ([PSIUtils getBoolPref:@"hide_ads"]) {
        NSLog(@"[PSInstagram] Removing ads");

        return nil;
    }

    return %orig;
}
- (id)initWithReelStore:(id)arg1 {
    if ([PSIUtils getBoolPref:@"hide_ads"]) {
        NSLog(@"[PSInstagram] Removing ads");

        return nil;
    }

    return %orig;
}
%end
%hook IGStoryAdsOptInTextView
- (id)initWithBrandedContentStyledString:(id)arg1 sponsoredPostLabel:(id)arg2 {
    if ([PSIUtils getBoolPref:@"hide_ads"]) {
        NSLog(@"[PSInstagram] Removing ads");

        return nil;
    }

    return %orig;
}
%end
%hook IGSundialAdsResponseParser
- (id)parsedObjectFromResponse:(id)arg1 {
    if ([PSIUtils getBoolPref:@"hide_ads"]) {
        NSLog(@"[PSInstagram] Removing ads");

        return nil;
    }

    return %orig;
}
- (id)initWithMediaStore:(id)arg1 userStore:(id)arg2 {
    if ([PSIUtils getBoolPref:@"hide_ads"]) {
        NSLog(@"[PSInstagram] Removing ads");
        
        return nil;
    }
    
    return %orig;
}
%end
// "Sponsored" posts on discover/search page
%hook IGExploreListKitDataSource
- (NSArray *)objectsForListAdapter:(id)arg1 {
    if ([PSIUtils getBoolPref:@"hide_ads"]) {
        return removeItemsInList(%orig, NO);
    }

    return %orig;
}
%end
// Demangled name: IGExploreViewControllerSwift.IGExploreListKitDataSource
%hook _TtC28IGExploreViewControllerSwift26IGExploreListKitDataSource
- (NSArray *)objectsForListAdapter:(id)arg1 {
    if ([PSIUtils getBoolPref:@"hide_ads"]) {
        return removeItemsInList(%orig, NO);
    }

    return %orig;
}
%end

// Hide shopping carousel in reel comments
// Demangled name: IGCommentThreadCommerceCarouselPill.IGCommentThreadCommerceCarousel
%hook _TtC35IGCommentThreadCommerceCarouselPill31IGCommentThreadCommerceCarousel
- (id)initWithFrame:(CGRect)frame pillText:(id)text pillStyle:(NSInteger)style {
    if ([PSIUtils getBoolPref:@"hide_ads"]) {
        return nil;
    }

    return %orig(frame, text, style);
}
%end

// Hide suggested search/shopping on reels

// Demangled name: IGShoppableEverythingCommon.IGRapEntrypointResolver
%hook _TtC27IGShoppableEverythingCommon23IGRapEntrypointResolver
- (id)initWithLauncherSet:(id)arg1 {
    if ([PSIUtils getBoolPref:@"hide_ads"]) {
        return nil;
    }

    return %orig(arg1);
}
%end
// Demangled name: IGSundialOrganicCTAContainerView.IGSundialOrganicCTAContainerView
%hook _TtC32IGSundialOrganicCTAContainerView32IGSundialOrganicCTAContainerView
- (void)didMoveToWindow {
    %orig;

    if ([PSIUtils getBoolPref:@"hide_ads"]) {
        [self removeFromSuperview];
    }
}
%end


// Hide "suggested for you" text at end of feed
%hook IGEndOfFeedDemarcatorCellTopOfFeed
- (void)configureWithViewConfig:(id)arg1 {
    %orig;

    if ([PSIUtils getBoolPref:@"no_suggested_post"]) {
        NSLog(@"[PSInstagram] Hiding end of feed message");

        // Hide suggested for you text
        UILabel *_titleLabel = MSHookIvar<UILabel *>(self, "_titleLabel");

        if (_titleLabel != nil) {
            [_titleLabel setText:@""];
        }
    }

    return;
}
%end
// "No posts yet": shown by the home feed once every item in it is hidden. Profiles use the same view, so only the home feed's is hidden
static BOOL PSIIsInMainFeed(UIView *view) {
    for (UIResponder *responder = view.nextResponder; responder; responder = responder.nextResponder) {
        if ([responder isKindOfClass:%c(IGMainFeedViewController_objc)]) return YES;
        if ([responder isKindOfClass:[UINavigationController class]]) return NO;
    }

    return NO;
}

@interface IGEmptyFeedView : UIView
@end

%hook IGEmptyFeedView
- (void)didMoveToWindow {
    %orig;

    if (self.window && [PSIUtils getBoolPref:@"hide_entire_feed"] && PSIIsInMainFeed(self)) self.hidden = YES;
}

- (void)layoutSubviews {
    %orig;

    if ([PSIUtils getBoolPref:@"hide_entire_feed"] && PSIIsInMainFeed(self)) self.hidden = YES;
}
%end
