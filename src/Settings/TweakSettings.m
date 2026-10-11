#import "TweakSettings.h"
#import "PSISettingsBackup.h"
#import "../Features/Feed/PSIMathGame.h"
#import "../Features/Feed/PSIWordGame.h"
#import "../Features/Feed/PSIPatternGame.h"

@implementation PSITweakSettings

// MARK: - Sections

///
/// This returns an array of sections, with each section consisting of a dictionary
///
/// `"title"`: The section title (leave blank for no title)
///
/// `"rows"`: An array of **PSISetting** classes, potentially containing a "navigationCellWithTitle" initializer to allow for nested setting pages.
///
/// `"footer`: The section footer (leave blank for no footer)

+ (NSArray *)sections {
    return @[
        @{
            @"header": @"",
            @"rows": @[
                [PSISetting navigationCellWithTitle:@"General"
                                           subtitle:@""
                                               icon:[PSISymbol symbolWithName:@"gear"]
                                        navSections:@[@{
                                            @"header": @"",
                                            @"rows": @[
                                                [PSISetting switchCellWithTitle:@"Hide ads" subtitle:@"Removes all ads from the Instagram app" defaultsKey:@"hide_ads"],
                                                [PSISetting switchCellWithTitle:@"Hide Meta AI" subtitle:@"Hides the meta ai buttons/functionality within the app" defaultsKey:@"hide_meta_ai"],
                                                [PSISetting switchCellWithTitle:@"Copy description" subtitle:@"Copy description text fields by long-pressing on them" defaultsKey:@"copy_description"],
                                                [PSISetting switchCellWithTitle:@"Do not save recent searches" subtitle:@"Search bars will no longer save your recent searches" defaultsKey:@"no_recent_searches"],
                                                [PSISetting switchCellWithTitle:@"Use detailed color picker" subtitle:@"Long press on the eyedropper tool in stories to customize the text color more precisely" defaultsKey:@"detailed_color_picker"],
                                                [PSISetting switchCellWithTitle:@"Enable liquid glass buttons" subtitle:@"Enables experimental liquid glass buttons within the app" defaultsKey:@"liquid_glass_buttons" requiresRestart:YES],
                                                [PSISetting switchCellWithTitle:@"Enable liquid glass surfaces" subtitle:@"Enables liquid glass for other elements, such as menus" defaultsKey:@"liquid_glass_surfaces" requiresRestart:YES],
                                                [PSISetting switchCellWithTitle:@"Enable teen app icons" subtitle:@"When enabled, hold down on the Instagram logo to change the app icon" defaultsKey:@"teen_app_icons" requiresRestart:YES]
                                            ]
                                        },
                                        @{
                                            @"header": @"Notes",
                                            @"rows": @[
                                                [PSISetting switchCellWithTitle:@"Hide notes tray" subtitle:@"Hides the notes tray in the dm inbox" defaultsKey:@"hide_notes_tray"],
                                                [PSISetting switchCellWithTitle:@"Hide friends map" subtitle:@"Hides the friends map icon in the notes tray" defaultsKey:@"hide_friends_map"],
                                                [PSISetting switchCellWithTitle:@"Enable note theming" subtitle:@"Enables the ability to use the notes theme picker" defaultsKey:@"enable_notes_customization"],
                                                [PSISetting switchCellWithTitle:@"Custom note themes" subtitle:@"Provides an option to set custom emojis and background/text colors" defaultsKey:@"custom_note_themes"],
                                            ]
                                        },
                                        @{
                                            @"header": @"Focus/distractions",
                                            @"rows": @[
                                                [PSISetting switchCellWithTitle:@"No suggested users" subtitle:@"Hides all suggested users for you to follow, outside your feed" defaultsKey:@"no_suggested_users"],
                                                [PSISetting switchCellWithTitle:@"No suggested chats" subtitle:@"Hides the suggested broadcast channels in direct messages" defaultsKey:@"no_suggested_chats"],
                                                [PSISetting switchCellWithTitle:@"Hide explore posts grid" subtitle:@"Hides the grid of suggested posts on the explore/search tab" defaultsKey:@"hide_explore_grid"],
                                                [PSISetting switchCellWithTitle:@"Hide trending searches" subtitle:@"Hides the trending searches under the explore search bar" defaultsKey:@"hide_trending_searches"],
                                                [PSISetting switchCellWithTitle:@"Hide search recents & suggestions" subtitle:@"Shows nothing under the search bar until you start typing" defaultsKey:@"hide_search_null_state"],
                                                [PSISetting switchCellWithTitle:@"Hide explore topics" subtitle:@"Hides the topic pills (For you, ...) at the top of explore" defaultsKey:@"hide_explore_topics"],
                                            ]
                                        }]
                ],
                [PSISetting navigationCellWithTitle:@"Feed"
                                           subtitle:@""
                                               icon:[PSISymbol symbolWithName:@"rectangle.stack"]
                                        navSections:@[@{
                                            @"header": @"",
                                            @"rows": @[
                                                [PSISetting switchCellWithTitle:@"Hide stories tray" subtitle:@"Hides the story tray at the top and within your feed" defaultsKey:@"hide_stories_tray"],
                                                [PSISetting switchCellWithTitle:@"Hide entire feed" subtitle:@"Removes all content from your home feed, including posts" defaultsKey:@"hide_entire_feed"],
                                                [PSISetting switchCellWithTitle:@"No suggested posts" subtitle:@"Removes suggested posts from your feed" defaultsKey:@"no_suggested_post"],
                                                [PSISetting switchCellWithTitle:@"No suggested for you" subtitle:@"Hides suggested accounts for you to follow" defaultsKey:@"no_suggested_account"],
                                                [PSISetting switchCellWithTitle:@"No suggested reels" subtitle:@"Hides suggested reels to watch" defaultsKey:@"no_suggested_reels"],
                                                [PSISetting switchCellWithTitle:@"No suggested threads posts" subtitle:@"Hides suggested threads posts" defaultsKey:@"no_suggested_threads"],
                                                [PSISetting switchCellWithTitle:@"Disable video autoplay" subtitle:@"Prevents videos on your feed from playing automatically" defaultsKey:@"disable_feed_autoplay"]
                                            ]
                                        }]
                ],
                [PSISetting navigationCellWithTitle:@"Brain break"
                                           subtitle:@""
                                               icon:[PSISymbol symbolWithName:@"function"]
                                        navSections:@[@{
                                            @"header": @"",
                                            @"footer": @"Shown on the home tab while the feed is hidden. Pick a game at the top, or Shuffle to get a different game after every puzzle.",
                                            @"rows": @[
                                                [PSISetting switchCellWithTitle:@"Show games on home" subtitle:@"Solve a problem or guess a word instead of scrolling" defaultsKey:@"math_game"]
                                            ]
                                        },
                                        @{
                                            @"header": @"Math",
                                            @"footer": @"Every 5 correct answers is a new level with harder problems.",
                                            @"rows": @[
                                                [PSISetting staticCellWithTitle:[NSString stringWithFormat:@"Level %ld", (long)PSIMathGame.level]
                                                                       subtitle:[NSString stringWithFormat:@"%ld solved · best streak %ld", (long)PSIMathGame.totalSolved, (long)PSIMathGame.bestStreak]
                                                                           icon:[PSISymbol symbolWithName:@"trophy"]],
                                                [PSISetting buttonCellWithTitle:@"Reset progress"
                                                                       subtitle:@""
                                                                           icon:nil
                                                                         action:^(void) { [PSIMathGame resetProgress]; [PSISettingsBackup save]; }
                                                ]
                                            ]
                                        },
                                        @{
                                            @"header": @"Words",
                                            @"footer": @"Guess the five-letter word in six tries. Green letters are in the right spot, orange ones are in the word but somewhere else. After each round, tap Define to look the word up in the iOS dictionary.",
                                            @"rows": @[
                                                [PSISetting staticCellWithTitle:[NSString stringWithFormat:@"%ld won", (long)PSIWordGame.won]
                                                                       subtitle:PSIWordGame.statsDescription
                                                                           icon:[PSISymbol symbolWithName:@"textformat.abc"]],
                                                [PSISetting buttonCellWithTitle:@"Reset progress"
                                                                       subtitle:@""
                                                                           icon:nil
                                                                         action:^(void) { [PSIWordGame resetProgress]; [PSISettingsBackup save]; }
                                                ]
                                            ]
                                        },
                                        @{
                                            @"header": @"IQ",
                                            @"footer": @"Find the next number in a sequence, or remember a number and type it back (sometimes backwards). New puzzles unlock as you level up.",
                                            @"rows": @[
                                                [PSISetting staticCellWithTitle:[NSString stringWithFormat:@"Level %ld", (long)PSIPatternGame.level]
                                                                       subtitle:PSIPatternGame.statsDescription
                                                                           icon:[PSISymbol symbolWithName:@"sparkles"]],
                                                [PSISetting buttonCellWithTitle:@"Reset progress"
                                                                       subtitle:@""
                                                                           icon:nil
                                                                         action:^(void) { [PSIPatternGame resetProgress]; [PSISettingsBackup save]; }
                                                ]
                                            ]
                                        }]
                ],
                [PSISetting navigationCellWithTitle:@"Reels"
                                           subtitle:@""
                                               icon:[PSISymbol symbolWithName:@"film.stack"]
                                        navSections:@[@{
                                            @"header": @"",
                                            @"rows": @[
                                                [PSISetting menuCellWithTitle:@"Tap Controls" subtitle:@"Change what happens when you tap on a reel" menu:[self menus][@"reels_tap_control"]],
                                                [PSISetting switchCellWithTitle:@"Always show progress scrubber" subtitle:@"Forces the progress bar to appear on every reel" defaultsKey:@"reels_show_scrubber"],
                                                [PSISetting switchCellWithTitle:@"Disable auto-unmuting reels" subtitle:@"Prevents reels from unmuting when the volume/silent button is pressed" defaultsKey:@"disable_auto_unmuting_reels" requiresRestart:YES],
                                                [PSISetting switchCellWithTitle:@"Confirm reel refresh" subtitle:@"Shows an alert when you trigger a reels refresh" defaultsKey:@"refresh_reel_confirm"],
                                            ]
                                        },
                                        @{
                                            @"header": @"Hiding",
                                            @"rows": @[
                                                [PSISetting switchCellWithTitle:@"Hide reels header" subtitle:@"Hides the top navigation bar when watching reels" defaultsKey:@"hide_reels_header"],
                                                [PSISetting switchCellWithTitle:@"Hide reels blend button" subtitle:@"Hides the button in DMs to open a reels blend" defaultsKey:@"hide_reels_blend"]
                                            ]
                                        },
                                        @{
                                            @"header": @"Limits",
                                            @"rows": @[
                                                [PSISetting switchCellWithTitle:@"Disable scrolling reels" subtitle:@"Prevents reels from being scrolled to the next video" defaultsKey:@"disable_scrolling_reels" requiresRestart:YES],
                                                [PSISetting switchCellWithTitle:@"Prevent doom scrolling" subtitle:@"Limits the amount of reels available to scroll at any given time, and prevents refreshing" defaultsKey:@"prevent_doom_scrolling"],
                                                [PSISetting stepperCellWithTitle:@"Doom scrolling limit" subtitle:@"Only loads %@ %@" defaultsKey:@"doom_scrolling_reel_count" min:1 max:100 step:1 label:@"reels" singularLabel:@"reel"]
                                            ]
                                        }]
                ],
                [PSISetting navigationCellWithTitle:@"Saving"
                                           subtitle:@""
                                               icon:[PSISymbol symbolWithName:@"tray.and.arrow.down"]
                                        navSections:@[@{
                                            @"header": @"",
                                            @"rows": @[
                                                [PSISetting switchCellWithTitle:@"Download feed posts" subtitle:@"Long-press with finger(s) to download posts in the home tab" defaultsKey:@"dw_feed_posts"],
                                                [PSISetting switchCellWithTitle:@"Download reels" subtitle:@"Long-press with finger(s) on a reel to download" defaultsKey:@"dw_reels"],
                                                [PSISetting switchCellWithTitle:@"Download stories" subtitle:@"Long-press with finger(s) while viewing someone's story to download" defaultsKey:@"dw_story"],
                                                [PSISetting switchCellWithTitle:@"Save profile picture" subtitle:@"On someone's profile, click their profile picture to enlarge it, then hold to download" defaultsKey:@"save_profile"]
                                            ]
                                        },
                                        @{
                                            @"header": @"Customize gestures",
                                            @"rows": @[
                                                [PSISetting stepperCellWithTitle:@"Finger count for long-press" subtitle:@"Downloads with %@ %@" defaultsKey:@"dw_finger_count" min:1 max:5 step:1 label:@"fingers" singularLabel:@"finger"],
                                                [PSISetting stepperCellWithTitle:@"Long-press hold time" subtitle:@"Press finger(s) for %@ %@" defaultsKey:@"dw_finger_duration" min:0 max:10 step:0.25 label:@"sec" singularLabel:@"sec"]
                                            ]
                                        }]
                ],
                [PSISetting navigationCellWithTitle:@"Stories and messages"
                                           subtitle:@""
                                               icon:[PSISymbol symbolWithName:@"rectangle.portrait.on.rectangle.portrait.angled"]
                                        navSections:@[@{
                                            @"header": @"Messages",
                                            @"rows": @[
                                                [PSISetting switchCellWithTitle:@"Keep deleted messages" subtitle:@"Saves deleted messages in chat conversations" defaultsKey:@"keep_deleted_message"],
                                                [PSISetting switchCellWithTitle:@"Manually mark messages as seen" subtitle:@"Adds a button to DM threads, which will mark messages as seen" defaultsKey:@"remove_lastseen"],
                                                [PSISetting switchCellWithTitle:@"Disable typing status" subtitle:@"Prevents the typing indicator from being shown to others when you're typing in DMs" defaultsKey:@"disable_typing_status"],
                                            ]
                                        },
                                        @{
                                            @"header": @"Visual messages & stories",
                                            @"rows": @[
                                                [PSISetting switchCellWithTitle:@"Unlimited replay of visual messages" subtitle:@"Replays direct visual messages normal/once stories unlimited times (toggle with image check icon)" defaultsKey:@"unlimited_replay"],
                                                [PSISetting switchCellWithTitle:@"Disable view-once limitations" subtitle:@"Makes view-once messages behave like normal visual messages (loopable/pauseable)" defaultsKey:@"disable_view_once_limitations"],
                                                [PSISetting switchCellWithTitle:@"Disable screenshot detection" subtitle:@"Removes the screenshot-prevention features for visual messages in DMs" defaultsKey:@"remove_screenshot_alert"],
                                                [PSISetting switchCellWithTitle:@"Disable story seen receipt" subtitle:@"Hides the notification for others when you view their story" defaultsKey:@"no_seen_receipt"],
                                                [PSISetting switchCellWithTitle:@"Disable instants creation" subtitle:@"Hides the functionality to create/send instants" defaultsKey:@"disable_instants_creation" requiresRestart:YES]
                                            ]
                                        }]
                ],
                [PSISetting navigationCellWithTitle:@"Navigation"
                                           subtitle:@""
                                               icon:[PSISymbol symbolWithName:@"hand.draw.fill"]
                                        navSections:@[@{
                                            @"header": @"",
                                            @"rows": @[
                                                [PSISetting menuCellWithTitle:@"Icon order" subtitle:@"The order of the icons on the bottom navigation bar" menu:[self menus][@"nav_icon_ordering"]],
                                                [PSISetting menuCellWithTitle:@"Swipe between tabs" subtitle:@"Lets you swipe to switch between navigation bar tabs" menu:[self menus][@"swipe_nav_tabs"]],
                                            ]
                                        },
                                        @{
                                            @"header": @"Hiding tabs",
                                            @"rows": @[
                                                [PSISetting switchCellWithTitle:@"Hide feed tab" subtitle:@"Hides the feed/home tab on the bottom navigation bar" defaultsKey:@"hide_feed_tab" requiresRestart:YES],
                                                [PSISetting switchCellWithTitle:@"Hide explore tab" subtitle:@"Hides the explore/search tab on the bottom navigation bar" defaultsKey:@"hide_explore_tab" requiresRestart:YES],
                                                [PSISetting switchCellWithTitle:@"Hide reels tab" subtitle:@"Hides the reels tab on the bottom navigation bar" defaultsKey:@"hide_reels_tab" requiresRestart:YES],
                                                [PSISetting switchCellWithTitle:@"Hide create tab" subtitle:@"Hides the create tab on the bottom navigation bar" defaultsKey:@"hide_create_tab" requiresRestart:YES]
                                            ]
                                        }]
                ],
                [PSISetting navigationCellWithTitle:@"Confirm actions"
                                           subtitle:@""
                                               icon:[PSISymbol symbolWithName:@"checkmark"]
                                        navSections:@[@{
                                            @"header": @"",
                                            @"rows": @[
                                                [PSISetting switchCellWithTitle:@"Confirm like: Posts/Stories" subtitle:@"Shows an alert when you click the like button on posts or stories to confirm the like" defaultsKey:@"like_confirm"],
                                                [PSISetting switchCellWithTitle:@"Confirm like: Reels" subtitle:@"Shows an alert when you click the like button on reels to confirm the like" defaultsKey:@"like_confirm_reels"]
                                            ]
                                        },
                                        @{
                                            @"header": @"",
                                            @"rows": @[
                                                [PSISetting switchCellWithTitle:@"Confirm follow" subtitle:@"Shows an alert when you click the follow button to confirm the follow" defaultsKey:@"follow_confirm"],
                                                [PSISetting switchCellWithTitle:@"Confirm repost" subtitle:@"Shows an alert when you click the repost button to confirm before resposting" defaultsKey:@"repost_confirm"],
                                                [PSISetting switchCellWithTitle:@"Confirm call" subtitle:@"Shows an alert when you click the audio/video call button to confirm before calling" defaultsKey:@"call_confirm"],
                                                [PSISetting switchCellWithTitle:@"Confirm voice messages" subtitle:@"Shows an alert to confirm before sending a voice message" defaultsKey:@"voice_message_confirm"],
                                                [PSISetting switchCellWithTitle:@"Confirm follow requests" subtitle:@"Shows an alert when you accept/decline a follow request" defaultsKey:@"follow_request_confirm"],
                                                [PSISetting switchCellWithTitle:@"Confirm shh mode" subtitle:@"Shows an alert to confirm before toggling disappearing messages" defaultsKey:@"shh_mode_confirm"],
                                                [PSISetting switchCellWithTitle:@"Confirm posting comment" subtitle:@"Shows an alert when you click the post comment button to confirm" defaultsKey:@"post_comment_confirm"],
                                                [PSISetting switchCellWithTitle:@"Confirm changing theme" subtitle:@"Shows an alert when you change a chat theme to confirm" defaultsKey:@"change_direct_theme_confirm"],
                                                [PSISetting switchCellWithTitle:@"Confirm sticker interaction" subtitle:@"Shows an alert when you click a sticker on someone's story to confirm the action" defaultsKey:@"sticker_interact_confirm"]
                                            ]
                                        }]
                ]
            ]
        },
        @{
            @"header": @"",
            @"rows": @[
                // [PSISetting navigationCellWithTitle:@"Experimental"
                //                            subtitle:@""
                //                                icon:[PSISymbol symbolWithName:@"testtube.2"]
                //                         navSections:@[@{
                //                             @"header": @"Warning",
                //                             @"footer": @"These features are unstable and cause the Instagram app to crash unexpectedly.\n\nUse at your own risk!"
                //                         },
                //                         @{
                //                             @"header": @"",
                //                             @"rows": @[

                //                             ]
                //                         }
                //                         ]
                // ],
                [PSISetting navigationCellWithTitle:@"Debug"
                                           subtitle:@""
                                               icon:[PSISymbol symbolWithName:@"ladybug"]
                                        navSections:@[@{
                                            @"header": @"FLEX",
                                            @"rows": @[
                                                [PSISetting switchCellWithTitle:@"Enable FLEX gesture" subtitle:@"Allows you to hold 5 fingers on the screen to open the FLEX explorer" defaultsKey:@"flex_instagram"],
                                                [PSISetting switchCellWithTitle:@"Open FLEX on app launch" subtitle:@"Automatically opens the FLEX explorer when the app launches" defaultsKey:@"flex_app_launch"],
                                                [PSISetting switchCellWithTitle:@"Open FLEX on app focus" subtitle:@"Automatically opens the FLEX explorer when the app is focused" defaultsKey:@"flex_app_start"]
                                            ]
                                        },
                                        @{
                                            @"header": @"PSInstagram",
                                            @"rows": @[
                                                [PSISetting switchCellWithTitle:@"Enable tweak settings quick-access" subtitle:@"Allows you to hold on the home tab to open the PSInstagram settings" defaultsKey:@"settings_shortcut" requiresRestart:YES],
                                                [PSISetting switchCellWithTitle:@"Show tweak settings on app launch" subtitle:@"Automatically opens the PSInstagram settings when the app launches" defaultsKey:@"tweak_settings_app_launch"],
                                                [PSISetting switchCellWithTitle:@"Clean cache on app launch" subtitle:@"Deletes Instagram's cache folders on every launch. May log you out on sideloaded installs" defaultsKey:@"clean_cache"],
                                                [PSISetting buttonCellWithTitle:@"Reset onboarding completion state"
                                                                           subtitle:@""
                                                                               icon:nil
                                                                             action:^(void) { [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"PSInstagramFirstRun"]; [PSIUtils showRestartConfirmation];}
                                                ],
                                            ]
                                        },
                                        @{
                                            @"header": @"Instagram",
                                            @"rows": @[
                                                [PSISetting switchCellWithTitle:@"Disable safe mode" subtitle:@"Makes Instagram not reset settings after subsequent crashes (at your own risk)" defaultsKey:@"disable_safe_mode"]
                                            ]
                                        },
                                        @{
                                            @"header": @"_ Example",
                                            @"rows": @[
                                                [PSISetting staticCellWithTitle:@"Static Cell" subtitle:@"" icon:[PSISymbol symbolWithName:@"tablecells"]],
                                                [PSISetting switchCellWithTitle:@"Switch Cell" subtitle:@"Tap the switch" defaultsKey:@"test_switch_cell"],
                                                [PSISetting switchCellWithTitle:@"Switch Cell (Restart)" subtitle:@"Tap the switch" defaultsKey:@"test_switch_cell_restart" requiresRestart:YES],
                                                [PSISetting stepperCellWithTitle:@"Stepper cell" subtitle:@"I have %@%@" defaultsKey:@"test_stepper_cell" min:-10 max:1000 step:5.5 label:@"$" singularLabel:@"$"],
                                                [PSISetting linkCellWithTitle:@"Link Cell" subtitle:@"Using icon" icon:[PSISymbol symbolWithName:@"link" color:[UIColor systemTealColor] size:20.0] url:@"https://google.com"],
                                                [PSISetting linkCellWithTitle:@"Link Cell" subtitle:@"Using image" imageUrl:@"https://i.imgur.com/c9CbytZ.png" url:@"https://google.com"],
                                                [PSISetting buttonCellWithTitle:@"Button Cell"
                                                                           subtitle:@""
                                                                               icon:[PSISymbol symbolWithName:@"oval.inset.filled"]
                                                                             action:^(void) { [PSIUtils showConfirmation:^(void){}]; }
                                                ],
                                                [PSISetting menuCellWithTitle:@"Menu Cell" subtitle:@"Change the value on the right" menu:[self menus][@"test"]],
                                                [PSISetting navigationCellWithTitle:@"Navigation Cell"
                                                                           subtitle:@""
                                                                               icon:[PSISymbol symbolWithName:@"rectangle.stack"]
                                                                        navSections:@[@{
                                                                            @"header": @"",
                                                                            @"rows": @[]
                                                                        }]
                                                ]
                                            ],
                                            @"footer": @"_ Example"
                                        }
                                        ]
                ]
            ]
        },
        @{
            @"header": @"About",
            @"rows": @[
                [PSISetting linkCellWithTitle:@"GitHub" subtitle:@"@pstepanovum" icon:[PSISymbol symbolWithName:@"person.crop.circle"] url:@"https://github.com/pstepanovum"],
                [PSISetting linkCellWithTitle:@"Repository" subtitle:@"pstepanovum/PSInstagram" icon:[PSISymbol symbolWithName:@"chevron.left.forwardslash.chevron.right"] url:@"https://github.com/pstepanovum/PSInstagram"]
            ],
            @"footer": [NSString stringWithFormat:@"PSInstagram %@\n\nInstagram v%@", PSIVersionString, [PSIUtils IGVersionString]]
        }
    ];
}


// MARK: - Title

///
/// This is the title displayed on the initial settings page view controller
///

+ (NSString *)title {
    return @"PSInstagram Settings";
}


// MARK: - Menus

///
/// This returns a dictionary where each key corresponds to a certain menu that can be displayed.
/// Each "propertyList"  item is an NSDictionary containing the following items:
///
/// `"defaultsKey"`: The key to save the selected value under in NSUserDefaults
///
/// `"value"`: A unique string corresponding to the menu item which is selected
///
/// `"requiresRestart"`: (optional) Causes a popup to appear detailing you have to restart to use these features
///

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wundeclared-selector"

+ (NSDictionary *)menus {
    return @{
        @"reels_tap_control": [UIMenu menuWithChildren:@[
            [UICommand commandWithTitle:@"Default"
                                    image:nil
                                    action:@selector(menuChanged:)
                            propertyList:@{
                                @"defaultsKey": @"reels_tap_control",
                                @"value": @"default",
                                @"requiresRestart": @YES
                            }
            ],
            [UIMenu menuWithTitle:@""
                            image:nil
                        identifier:nil
                            options:UIMenuOptionsDisplayInline
                            children:@[
                                [UICommand commandWithTitle:@"Pause/Play"
                                                        image:nil
                                                        action:@selector(menuChanged:)
                                                propertyList:@{
                                                    @"defaultsKey": @"reels_tap_control",
                                                    @"value": @"pause",
                                                    @"requiresRestart": @YES
                                                }
                                ],
                                [UICommand commandWithTitle:@"Mute/Unmute"
                                                        image:nil
                                                        action:@selector(menuChanged:)
                                                propertyList:@{
                                                    @"defaultsKey": @"reels_tap_control",
                                                    @"value": @"mute",
                                                    @"requiresRestart": @YES
                                                }
                                ]
                            ]
            ]
        ]],

        @"nav_icon_ordering": [UIMenu menuWithChildren:@[
            [UICommand commandWithTitle:@"Default"
                                    image:nil
                                    action:@selector(menuChanged:)
                            propertyList:@{
                                @"defaultsKey": @"nav_icon_ordering",
                                @"value": @"default",
                                @"requiresRestart": @YES
                            }
            ],
            [UIMenu menuWithTitle:@""
                            image:nil
                        identifier:nil
                            options:UIMenuOptionsDisplayInline
                            children:@[
                                [UICommand commandWithTitle:@"Classic"
                                                        image:nil
                                                        action:@selector(menuChanged:)
                                                propertyList:@{
                                                    @"defaultsKey": @"nav_icon_ordering",
                                                    @"value": @"classic",
                                                    @"requiresRestart": @YES
                                                }
                                ],
                                [UICommand commandWithTitle:@"Standard"
                                                        image:nil
                                                        action:@selector(menuChanged:)
                                                propertyList:@{
                                                    @"defaultsKey": @"nav_icon_ordering",
                                                    @"value": @"standard",
                                                    @"requiresRestart": @YES
                                                }
                                ],
                                [UICommand commandWithTitle:@"Alternate"
                                                        image:nil
                                                        action:@selector(menuChanged:)
                                                propertyList:@{
                                                    @"defaultsKey": @"nav_icon_ordering",
                                                    @"value": @"alternate",
                                                    @"requiresRestart": @YES
                                                }
                                ]
                            ]
            ]
        ]],
        @"swipe_nav_tabs": [UIMenu menuWithChildren:@[
            [UICommand commandWithTitle:@"Default"
                                    image:nil
                                    action:@selector(menuChanged:)
                            propertyList:@{
                                @"defaultsKey": @"swipe_nav_tabs",
                                @"value": @"default",
                                @"requiresRestart": @YES
                            }
            ],
            [UIMenu menuWithTitle:@""
                            image:nil
                        identifier:nil
                            options:UIMenuOptionsDisplayInline
                            children:@[
                                [UICommand commandWithTitle:@"Enabled"
                                                        image:nil
                                                        action:@selector(menuChanged:)
                                                propertyList:@{
                                                    @"defaultsKey": @"swipe_nav_tabs",
                                                    @"value": @"enabled",
                                                    @"requiresRestart": @YES
                                                }
                                ],
                                [UICommand commandWithTitle:@"Disabled"
                                                        image:nil
                                                        action:@selector(menuChanged:)
                                                propertyList:@{
                                                    @"defaultsKey": @"swipe_nav_tabs",
                                                    @"value": @"disabled",
                                                    @"requiresRestart": @YES
                                                }
                                ]
                            ]
            ]
        ]],

        @"test": [UIMenu menuWithChildren:@[
            [UIMenu menuWithTitle:@""
                            image:nil
                        identifier:nil
                            options:UIMenuOptionsDisplayInline
                            children:@[
                                [UICommand commandWithTitle:@"ABC"
                                                        image:nil
                                                        action:@selector(menuChanged:)
                                                propertyList:@{
                                                    @"defaultsKey": @"test_menu_cell",
                                                    @"value": @"abc"
                                                }
                                ],
                                [UICommand commandWithTitle:@"123"
                                                        image:nil
                                                        action:@selector(menuChanged:)
                                                propertyList:@{
                                                    @"defaultsKey": @"test_menu_cell",
                                                    @"value": @"123"
                                                }
                                ]
                            ]
            ],
            [UICommand commandWithTitle:@"Requires restart"
                                  image:nil
                                 action:@selector(menuChanged:)
                           propertyList:@{
                               @"defaultsKey": @"test_menu_cell",
                               @"value": @"requires_restart",
                               @"requiresRestart": @YES
                           }
            ],
        ]]
    };
}

#pragma clang diagnostic pop

@end
