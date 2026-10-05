#import <substrate.h>
#import "InstagramHeaders.h"
#import "Tweak.h"
#import "Utils.h"
#import "Settings/PSISettingsBackup.h"

///////////////////////////////////////////////////////////

// Screenshot handlers

#define VOID_HANDLESCREENSHOT(orig) [PSIUtils getBoolPref:@"remove_screenshot_alert"] ? nil : orig;
#define NONVOID_HANDLESCREENSHOT(orig) return VOID_HANDLESCREENSHOT(orig)

///////////////////////////////////////////////////////////

// * Tweak version *
NSString *PSIVersionString = @"v1.0.0";

// Variables that work across features
BOOL dmVisualMsgsViewedButtonEnabled = false;

// Settings are set up before any Instagram code runs, so no feature can read them unset
static void PSISetupSettings(void) {
    // Bring back settings from before a reinstall
    [PSISettingsBackup restoreIfNeeded];

    // Default PSInstagram config (strict: distraction-free unless changed by the user)
    NSDictionary *psiDefaults = @{
        @"hide_ads": @(YES),
        @"hide_meta_ai": @(YES),
        @"no_suggested_users": @(YES),
        @"no_suggested_chats": @(YES),
        @"hide_explore_grid": @(YES),
        @"hide_trending_searches": @(YES),
        @"no_recent_searches": @(YES),
        @"hide_search_null_state": @(YES),
        @"hide_explore_topics": @(YES),
        @"hide_stories_tray": @(YES),
        @"hide_entire_feed": @(YES),
        @"no_suggested_post": @(YES),
        @"no_suggested_account": @(YES),
        @"no_suggested_reels": @(YES),
        @"no_suggested_threads": @(YES),
        @"disable_feed_autoplay": @(YES),
        @"math_game": @(YES),
        @"disable_scrolling_reels": @(YES),
        @"prevent_doom_scrolling": @(YES),
        @"hide_reels_tab": @(YES),
        // Instagram's crash recovery resets the session after quick restarts, logging out sideloaded installs
        @"disable_safe_mode": @(YES),
        @"copy_description": @(YES),
        @"detailed_color_picker": @(YES),
        @"remove_screenshot_alert": @(YES),
        @"call_confirm": @(YES),
        @"keep_deleted_message": @(YES),
        @"dw_feed_posts": @(YES),
        @"dw_reels": @(YES),
        @"dw_story": @(YES),
        @"save_profile": @(YES),
        @"dw_finger_count": @(3),
        @"dw_finger_duration": @(0.5),
        @"reels_tap_control": @"default",
        @"nav_icon_ordering": @"default",
        @"swipe_nav_tabs": @"default",
        @"enable_notes_customization": @(YES),
        @"custom_note_themes": @(YES),
        @"disable_auto_unmuting_reels": @(YES),
        @"doom_scrolling_reel_count": @(1)
    };
    [[NSUserDefaults standardUserDefaults] registerDefaults:psiDefaults];
}

// Tweak first-time setup
%hook IGInstagramAppDelegate
- (_Bool)application:(UIApplication *)application willFinishLaunchingWithOptions:(id)arg2 {
    // Override instagram defaults
    if ([PSIUtils getBoolPref:@"liquid_glass_buttons"]) {
        [[NSUserDefaults standardUserDefaults] setValue:@(YES) forKey:@"instagram.override.project.lucent.navigation"];
    }
    else {
        [[NSUserDefaults standardUserDefaults] setValue:@(NO) forKey:@"instagram.override.project.lucent.navigation"];
    }

    return %orig;
}
- (_Bool)application:(UIApplication *)application didFinishLaunchingWithOptions:(id)arg2 {
    %orig;

    // Open settings for first-time users
    double openDelay = [PSIUtils getBoolPref:@"tweak_settings_app_launch"] ? 0.0 : 5.0;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(openDelay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (
            ![[[NSUserDefaults standardUserDefaults] objectForKey:@"PSInstagramFirstRun"] isEqualToString:PSIVersionString]
            || [PSIUtils getBoolPref:@"tweak_settings_app_launch"]
        ) {
            NSLog(@"[PSInstagram] First run, initializing");

            // Display settings modal on screen
            NSLog(@"[PSInstagram] Displaying PSInstagram first-time settings modal");
            [PSIUtils showSettingsVC:[self window]];
        }
    });

    // Keep the keychain backup in sync with the current settings
    [PSISettingsBackup save];

    if ([PSIUtils getBoolPref:@"clean_cache"]) {
        NSLog(@"[PSInstagram] Cleaning cache...");
        [PSIUtils cleanCache];
    }

    if ([PSIUtils getBoolPref:@"flex_app_launch"]) {
        [[objc_getClass("FLEXManager") sharedManager] showExplorer];
    }

    return true;
}

- (void)applicationDidBecomeActive:(id)arg1 {
    %orig;
    
    if ([PSIUtils getBoolPref:@"flex_app_start"]) {
        [[objc_getClass("FLEXManager") sharedManager] showExplorer];
    }
}
%end

%hook IGDSLauncherConfig
- (_Bool)isLiquidGlassInAppNotificationEnabled {
    return [PSIUtils liquidGlassEnabledBool:%orig];
}
- (_Bool)isLiquidGlassContextMenuEnabled{
    return [PSIUtils liquidGlassEnabledBool:%orig];
}
- (_Bool)isLiquidGlassToastEnabled {
    return [PSIUtils liquidGlassEnabledBool:%orig];
}
- (_Bool)isLiquidGlassToastPeekEnabled {
    return [PSIUtils liquidGlassEnabledBool:%orig];
}
- (_Bool)isLiquidGlassAlertDialogEnabled {
    return [PSIUtils liquidGlassEnabledBool:%orig];
}
%end

// Disable sending modded insta bug reports
%hook IGWindow
- (void)showDebugMenu {
    return;
}
%end

%hook IGBugReportUploader
- (id)initWithNetworker:(id)arg1
         pandoGraphQLService:(id)arg2
             analyticsLogger:(id)arg3
                userDefaults:(id)arg4
         launcherSetProvider:(id)arg5
shouldPersistLastBugReportId:(id)arg6
{
    return nil;
}
%end

// Disable anti-screenshot feature on visual messages
%hook IGStoryViewerContainerView
- (void)setShouldBlockScreenshot:(BOOL)arg1 viewModel:(id)arg2 { VOID_HANDLESCREENSHOT(%orig); }
%end

// Disable screenshot logging/detection
%hook IGDirectVisualMessageViewerSession
- (id)visualMessageViewerController:(id)arg1 didDetectScreenshotForVisualMessage:(id)arg2 atIndex:(NSInteger)arg3 { NONVOID_HANDLESCREENSHOT(%orig); }
%end

%hook IGDirectVisualMessageReplayService
- (id)visualMessageViewerController:(id)arg1 didDetectScreenshotForVisualMessage:(id)arg2 atIndex:(NSInteger)arg3 { NONVOID_HANDLESCREENSHOT(%orig); }
%end

%hook IGDirectVisualMessageReportService
- (id)visualMessageViewerController:(id)arg1 didDetectScreenshotForVisualMessage:(id)arg2 atIndex:(NSInteger)arg3 { NONVOID_HANDLESCREENSHOT(%orig); }
%end

%hook IGDirectVisualMessageScreenshotSafetyLogger
- (id)initWithUserSession:(id)arg1 entryPoint:(NSInteger)arg2 {
    if ([PSIUtils getBoolPref:@"remove_screenshot_alert"]) {
        NSLog(@"[PSInstagram] Disable visual message screenshot safety logger");
        return nil;
    }

    return %orig;
}
%end

%hook IGScreenshotObserver
- (id)initForController:(id)arg1 { NONVOID_HANDLESCREENSHOT(%orig); }
%end

%hook IGScreenshotObserverDelegate
- (void)screenshotObserverDidSeeScreenshotTaken:(id)arg1 { VOID_HANDLESCREENSHOT(%orig); }
- (void)screenshotObserverDidSeeActiveScreenCapture:(id)arg1 event:(NSInteger)arg2 { VOID_HANDLESCREENSHOT(%orig); }
%end

%hook IGDirectMediaViewerViewController
- (void)screenshotObserverDidSeeScreenshotTaken:(id)arg1 { VOID_HANDLESCREENSHOT(%orig); }
- (void)screenshotObserverDidSeeActiveScreenCapture:(id)arg1 event:(NSInteger)arg2 { VOID_HANDLESCREENSHOT(%orig); }
%end

%hook IGStoryViewerViewController
- (void)screenshotObserverDidSeeScreenshotTaken:(id)arg1 { VOID_HANDLESCREENSHOT(%orig); }
- (void)screenshotObserverDidSeeActiveScreenCapture:(id)arg1 event:(NSInteger)arg2 { VOID_HANDLESCREENSHOT(%orig); }
%end

%hook IGSundialFeedViewController
- (void)screenshotObserverDidSeeScreenshotTaken:(id)arg1 { VOID_HANDLESCREENSHOT(%orig); }
- (void)screenshotObserverDidSeeActiveScreenCapture:(id)arg1 event:(NSInteger)arg2 { VOID_HANDLESCREENSHOT(%orig); }
%end

%hook IGDirectVisualMessageViewerController
- (void)screenshotObserverDidSeeScreenshotTaken:(id)arg1 { VOID_HANDLESCREENSHOT(%orig); }
- (void)screenshotObserverDidSeeActiveScreenCapture:(id)arg1 event:(NSInteger)arg2 { VOID_HANDLESCREENSHOT(%orig); }
%end

/////////////////////////////////////////////////////////////////////////////

// Hide items

// Direct suggested chats (in search bar)
%hook IGDirectInboxSearchListAdapterDataSource
- (id)objectsForListAdapter:(id)arg1 {
    NSArray *originalObjs = %orig();
    NSMutableArray *filteredObjs = [NSMutableArray arrayWithCapacity:[originalObjs count]];

    for (id obj in originalObjs) {
        BOOL shouldHide = NO;

        // Section header 
        if ([obj isKindOfClass:%c(IGLabelItemViewModel)]) {

            // Broadcast channels
            if ([[obj valueForKey:@"uniqueIdentifier"] isEqualToString:@"channels"]) {
                if ([PSIUtils getBoolPref:@"no_suggested_chats"]) {
                    NSLog(@"[PSInstagram] Hiding suggested chats (header)");

                    shouldHide = YES;
                }
            }

            // Ask Meta AI
            else if ([[obj valueForKey:@"labelTitle"] isEqualToString:@"Ask Meta AI"]) {
                if ([PSIUtils getBoolPref:@"hide_meta_ai"]) {
                    NSLog(@"[PSInstagram] Hiding meta ai suggested chats (header)");

                    shouldHide = YES;
                }
            }

            // AI
            else if ([[obj valueForKey:@"labelTitle"] isEqualToString:@"AI"]) {
                if ([PSIUtils getBoolPref:@"hide_meta_ai"]) {
                    NSLog(@"[PSInstagram] Hiding ai suggested chats (header)");

                    shouldHide = YES;
                }
            }
            
        }

        // AI agents section
        else if (
            [obj isKindOfClass:%c(IGDirectInboxSearchAIAgentsPillsSectionViewModel)]
         || [obj isKindOfClass:%c(IGDirectInboxSearchAIAgentsSuggestedPromptViewModel)]
         || [obj isKindOfClass:%c(IGDirectInboxSearchAIAgentsSuggestedPromptLoggingViewModel)]
        ) {

            if ([PSIUtils getBoolPref:@"hide_meta_ai"]) {
                NSLog(@"[PSInstagram] Hiding suggested chats (ai agents)");

                shouldHide = YES;
            }

        }

        // Recipients list
        else if ([obj isKindOfClass:%c(IGDirectRecipientCellViewModel)]) {

            // Broadcast channels
            if ([[obj recipient] isBroadcastChannel]) {
                if ([PSIUtils getBoolPref:@"no_suggested_chats"]) {
                    NSLog(@"[PSInstagram] Hiding suggested chats (broadcast channels recipient)");

                    shouldHide = YES;
                }
            }
            
            // Meta AI (special section types)
            else if (([obj sectionType] == 20) || [obj sectionType] == 18) {
                if ([PSIUtils getBoolPref:@"hide_meta_ai"]) {
                    NSLog(@"[PSInstagram] Hiding meta ai suggested chats (meta ai recipient)");

                    shouldHide = YES;
                }
            }

            // Meta AI (catch-all)
            else if ([[[obj recipient] threadName] isEqualToString:@"Meta AI"]) {
                if ([PSIUtils getBoolPref:@"hide_meta_ai"]) {
                    NSLog(@"[PSInstagram] Hiding meta ai suggested chats (meta ai recipient)");

                    shouldHide = YES;
                }
            }
        }

        // Populate new objs array
        if (!shouldHide) {
            [filteredObjs addObject:obj];
        }

    }

    return [filteredObjs copy];
}
%end

// Direct suggested chats (thread creation view)
%hook IGDirectThreadCreationViewController
- (id)objectsForListAdapter:(id)arg1 {
    NSArray *originalObjs = %orig();
    NSMutableArray *filteredObjs = [NSMutableArray arrayWithCapacity:[originalObjs count]];

    for (id obj in originalObjs) {
        BOOL shouldHide = NO;

        // Meta AI suggested user in direct new message view
        if ([PSIUtils getBoolPref:@"hide_meta_ai"]) {
            
            if ([obj isKindOfClass:%c(IGDirectCreateChatCellViewModel)]) {

                // "AI Chats"
                if ([[obj valueForKey:@"title"] isEqualToString:@"AI chats"]) {
                    NSLog(@"[PSInstagram] Hiding meta ai: direct thread creation ai chats section");

                    shouldHide = YES;
                }

            }

            else if ([obj isKindOfClass:%c(IGDirectRecipientCellViewModel)]) {

                // Meta AI suggested user
                if ([[[obj recipient] threadName] isEqualToString:@"Meta AI"]) {
                    NSLog(@"[PSInstagram] Hiding meta ai: direct thread creation ai suggestion");

                    shouldHide = YES;
                }

            }
            
        }

        // Invite friends to insta contacts upsell
        if ([PSIUtils getBoolPref:@"no_suggested_users"]) {
            if ([obj isKindOfClass:%c(IGContactInvitesSearchUpsellViewModel)]) {
                NSLog(@"[PSInstagram] Hiding suggested users: invite contacts upsell");

                shouldHide = YES;
            }
        }

        // Populate new objs array
        if (!shouldHide) {
            [filteredObjs addObject:obj];
        }
    }

    return [filteredObjs copy];
}
%end

// Direct suggested chats (inbox view)
%hook IGDirectInboxListAdapterDataSource
- (id)objectsForListAdapter:(id)arg1 {
    NSArray *originalObjs = %orig();
    NSMutableArray *filteredObjs = [NSMutableArray arrayWithCapacity:[originalObjs count]];

    for (id obj in originalObjs) {
        BOOL shouldHide = NO;

        // Section header
        if ([obj isKindOfClass:%c(IGDirectInboxHeaderCellViewModel)]) {
            
            // "Suggestions" header
            if ([[obj title] isEqualToString:@"Suggestions"]) {
                if ([PSIUtils getBoolPref:@"no_suggested_users"]) {
                    NSLog(@"[PSInstagram] Hiding suggested chats (header: messages tab)");

                    shouldHide = YES;
                }
            }

            // "Accounts to follow/message" header
            else if ([[obj title] hasPrefix:@"Accounts to"]) {
                if ([PSIUtils getBoolPref:@"no_suggested_users"]) {
                    NSLog(@"[PSInstagram] Hiding suggested users: (header: inbox view)");

                    shouldHide = YES;
                }
            }

        }

        // Suggested recipients
        else if ([obj isKindOfClass:%c(IGDirectInboxSuggestedThreadCellViewModel)]) {
            if ([PSIUtils getBoolPref:@"no_suggested_users"]) {
                NSLog(@"[PSInstagram] Hiding suggested chats (recipients: channels tab)");

                shouldHide = YES;
            }
        }

        // "Accounts to follow" recipients
        else if ([obj isKindOfClass:%c(IGDiscoverPeopleItemConfiguration)] || [obj isKindOfClass:%c(IGDiscoverPeopleConnectionItemConfiguration)]) {
            if ([PSIUtils getBoolPref:@"no_suggested_users"]) {
                NSLog(@"[PSInstagram] Hiding suggested chats: (recipients: inbox view)");

                shouldHide = YES;
            }
        }

        // Hide notes tray
        else if ([obj isKindOfClass:%c(IGDirectNotesTrayRowViewModel)]) {
            if ([PSIUtils getBoolPref:@"hide_notes_tray"]) {
                NSLog(@"[PSInstagram] Hiding notes tray");

                shouldHide = YES;
            }
        }

        // Populate new objs array
        if (!shouldHide) {
            [filteredObjs addObject:obj];
        }

    }

    return [filteredObjs copy];
}
%end

// Explore page results
%hook IGSearchListKitDataSource
- (id)objectsForListAdapter:(id)arg1 {
    NSArray *originalObjs = %orig();
    NSMutableArray *filteredObjs = [NSMutableArray arrayWithCapacity:[originalObjs count]];

    for (id obj in originalObjs) {
        BOOL shouldHide = NO;

        // Meta AI
        if ([PSIUtils getBoolPref:@"hide_meta_ai"]) {

            // Section header 
            if ([obj isKindOfClass:%c(IGLabelItemViewModel)]) {

                // "Ask Meta AI" search results header
                if ([[obj valueForKey:@"labelTitle"] isEqualToString:@"Ask Meta AI"]) {
                    shouldHide = YES;
                }

            }

            // Empty search bar upsell view
            else if ([obj isKindOfClass:%c(IGSearchNullStateUpsellViewModel)]) {
                shouldHide = YES;
            }

            // Meta AI search suggestions
            else if ([obj isKindOfClass:%c(IGSearchResultNestedGroupViewModel)]) {
                shouldHide = YES;
            }

            // Meta AI suggested search results
            else if ([obj isKindOfClass:%c(IGSearchResultViewModel)]) {

                // itemType 6 is meta ai suggestions
                if ([obj itemType] == 6) {
                    if ([PSIUtils getBoolPref:@"hide_meta_ai"]) {
                        shouldHide = YES;
                    }
                    
                }

                // Meta AI user account in search results
                else if ([[[obj title] string] isEqualToString:@"meta.ai"]) {
                    if ([PSIUtils getBoolPref:@"hide_meta_ai"]) {
                        shouldHide = YES;
                    }
                }

            }
            
        }

        // No suggested users
        if ([PSIUtils getBoolPref:@"no_suggested_users"]) {

            // Section header 
            if ([obj isKindOfClass:%c(IGLabelItemViewModel)]) {

                // "Suggested for you" search results header
                if ([[obj valueForKey:@"labelTitle"] isEqualToString:@"Suggested for you"]) {
                    shouldHide = YES;
                }

            }

            // Instagram users
            else if ([obj isKindOfClass:%c(IGDiscoverPeopleItemConfiguration)]) {
                shouldHide = YES;
            }

            // See all suggested users
            else if ([obj isKindOfClass:%c(IGSeeAllItemConfiguration)] && ((IGSeeAllItemConfiguration *)obj).destination == 4) {
                shouldHide = YES;
            }

        }

        // Populate new objs array
        if (!shouldHide) {
            [filteredObjs addObject:obj];
        }

    }

    return [filteredObjs copy];
}
%end

// Story tray
%hook IGMainStoryTrayDataSource
- (id)allItemsForTrayUsingCachedValue:(BOOL)cached {
    NSArray *originalObjs = %orig(cached);
    NSMutableArray *filteredObjs = [NSMutableArray arrayWithCapacity:[originalObjs count]];

    for (IGStoryTrayViewModel *obj in originalObjs) {
        BOOL shouldHide = NO;

        if ([PSIUtils getBoolPref:@"no_suggested_users"]) {
            if ([obj isKindOfClass:%c(IGStoryTrayViewModel)]) {
                NSNumber *type = [((IGStoryTrayViewModel *)obj) valueForKey:@"type"];
                
                // 8/9 looks to be the types for recommended stories
                if ([type isEqual:@(8)] || [type isEqual:@(9)]) {
                    NSLog(@"[PSInstagram] Hiding suggested users: story tray");

                    shouldHide = YES;

                }
            }
        }

        if ([PSIUtils getBoolPref:@"hide_ads"]) {
            // "New!" account id is 3538572169
            if ([obj isKindOfClass:%c(IGStoryTrayViewModel)] && (obj.isUnseenNux == YES || [obj.pk isEqualToString:@"3538572169"])) {
                NSLog(@"[PSInstagram] Removing ads: story tray");

                shouldHide = YES;
            }
        }

        // Populate new objs array
        if (!shouldHide) {
            [filteredObjs addObject:obj];
        }
    }

    return [filteredObjs copy];
}
%end

// Story tray expanded footer (Suggested accounts to follow)
%hook IGStoryTraySectionController
- (void)storyTrayControllerShowSUPOGEducationBump {
    if ([PSIUtils getBoolPref:@"no_suggested_users"]) return;

    return %orig();
}
%end

// Modern IGDS app menus
%hook IGDSMenu
- (id)initWithMenuItems:(NSArray<IGDSMenuItem *> *)originalObjs edr:(BOOL)edr headerLabelText:(id)headerLabelText {
    NSMutableArray *filteredObjs = [NSMutableArray arrayWithCapacity:[originalObjs count]];

    for (id obj in originalObjs) {
        BOOL shouldHide = NO;

        // Meta AI
        if (
            [[obj valueForKey:@"title"] isEqualToString:@"AI images"]
            || [[obj valueForKey:@"title"] isEqualToString:@"Meta AI"]
        ) {
            
            if ([PSIUtils getBoolPref:@"hide_meta_ai"]) {
                NSLog(@"[PSInstagram] Hiding meta ai from IGDS menu");

                shouldHide = YES;
            }

        }

        // Populate new objs array
        if (!shouldHide) {
            [filteredObjs addObject:obj];
        }

    }

    return %orig([filteredObjs copy], edr, headerLabelText);
}
%end

/////////////////////////////////////////////////////////////////////////////

// Confirm buttons

%hook IGFeedItemUFICell
- (void)UFIButtonBarDidTapOnLike:(id)arg1 {
    if ([PSIUtils getBoolPref:@"like_confirm"]) {
        NSLog(@"[PSInstagram] Confirm post like triggered");

        [PSIUtils showConfirmation:^(void) { %orig; }];
    }
    else {
        return %orig;
    }  
}

- (void)UFIButtonBarDidTapOnRepost:(id)arg1 {
    if ([PSIUtils getBoolPref:@"repost_confirm"]) {
        NSLog(@"[PSInstagram] Confirm repost triggered");

        [PSIUtils showConfirmation:^(void) { %orig; }];
    }
    else {
        return %orig;
    }
}

- (void)UFIButtonBarDidLongPressOnRepost:(id)arg1 {
    if ([PSIUtils getBoolPref:@"repost_confirm"]) {
        NSLog(@"[PSInstagram] Confirm repost triggered (long press ignored)");
    }
    else {
        return %orig;
    }
}
- (void)UFIButtonBarDidLongPressOnRepost:(id)arg1 withGestureRecognizer:(id)arg2 {
    if ([PSIUtils getBoolPref:@"repost_confirm"]) {
        NSLog(@"[PSInstagram] Confirm repost triggered (long press ignored)");
    }
    else {
        return %orig;
    }
}
%end

%hook IGSundialViewerVerticalUFI
- (void)_didTapLikeButton:(id)arg1 {
    if ([PSIUtils getBoolPref:@"like_confirm_reels"]) {
        NSLog(@"[PSInstagram] Confirm reels like triggered");

        [PSIUtils showConfirmation:^(void) { %orig; }];
    }
    else {
        return %orig;
    }
}

- (void)_didLongPressLikeButton:(id)arg1 {
    if ([PSIUtils getBoolPref:@"like_confirm_reels"]) {
        NSLog(@"[PSInstagram] Confirm repost triggered (long press ignored)");
    }
    else {
        return %orig;
    }
}

- (void)_didTapRepostButton:(id)arg1 {
    if ([PSIUtils getBoolPref:@"repost_confirm"]) {
        NSLog(@"[PSInstagram] Confirm repost triggered");

        [PSIUtils showConfirmation:^(void) { %orig; }];
    }
    else {
        return %orig;
    }
}

- (void)_didLongPressRepostButton:(id)arg1 {
    if ([PSIUtils getBoolPref:@"repost_confirm"]) {
        NSLog(@"[PSInstagram] Confirm repost triggered (long press ignored)");
    }
    else {
        return %orig;
    }
}
%end

/////////////////////////////////////////////////////////////////////////////

// FLEX explorer gesture handler
%hook IGRootViewController
- (void)viewDidLoad {
    %orig;
    
    // Recognize 5-finger long press
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    longPress.minimumPressDuration = 1;
    longPress.numberOfTouchesRequired = 5;
    [self.view addGestureRecognizer:longPress];
}
%new - (void)handleLongPress:(UILongPressGestureRecognizer *)sender {
    if (sender.state != UIGestureRecognizerStateBegan) return;

    if ([PSIUtils getBoolPref:@"flex_instagram"]) {
        [[objc_getClass("FLEXManager") sharedManager] showExplorer];
    }
}
%end

// Disable safe mode (defaults reset upon subsequent crashes)
// Checked before PSInstagram registers its defaults, so an unset value counts as enabled
static BOOL PSISafeModeDisabled(void) {
    id value = [[NSUserDefaults standardUserDefaults] objectForKey:@"disable_safe_mode"];
    return value ? [value boolValue] : YES;
}

%hook IGSafeModeChecker
- (id)initWithInstacrashCounterProvider:(void *)provider crashThreshold:(unsigned long long)threshold {
    if (PSISafeModeDisabled()) {
        NSLog(@"[PSInstagram] Disabled Instagram safe mode checker (threshold %llu)", threshold);
        return nil;
    }

    return %orig(provider, threshold);
}
- (unsigned long long)crashCount {
    if (PSISafeModeDisabled()) {
        return 0;
    }

    return %orig;
}
%end

%ctor {
    PSISetupSettings();

    %init;
}
