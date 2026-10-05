#import "../../InstagramHeaders.h"
#import "../../Settings/PSISettingsViewController.h"

// Show PSInstagram tweak settings by holding on the settings/more icon under profile for ~1 second
%hook IGBadgedNavigationButton
- (void)didMoveToWindow {
    %orig;

    if ([self.accessibilityIdentifier isEqualToString:@"profile-more-button"]) {
        [self addLongPressGestureRecognizer];
    }

    return;
}

%new - (void)addLongPressGestureRecognizer {
    if ([self.gestureRecognizers count] == 0) {
        NSLog(@"[PSInstagram] Adding tweak settings long press gesture recognizer");

        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
        [self addGestureRecognizer:longPress];
    }
}
%new - (void)handleLongPress:(UILongPressGestureRecognizer *)sender {
    if (sender.state != UIGestureRecognizerStateBegan) return;
    
    NSLog(@"[PSInstagram] Tweak settings gesture activated");

    [PSIUtils showSettingsVC:[self window]];
}
%end

// Quick access to tweak settings by holding on home tab button
%hook IGTabBarButton
- (void)didMoveToSuperview {
    %orig;

    // Only work on home/feed tab
    if (![self.accessibilityIdentifier isEqualToString:@"mainfeed-tab"]) return;
    
    if ([PSIUtils getBoolPref:@"settings_shortcut"]) {
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
        longPress.minimumPressDuration = 0.3;
        
        // Take precidence over existing gesture recognizers
        for (UIGestureRecognizer *existing in self.gestureRecognizers) {
            [existing requireGestureRecognizerToFail:longPress];
        }
        
        [self addGestureRecognizer:longPress];
    }
}
%new - (void)handleLongPress:(UILongPressGestureRecognizer *)sender {
    if (sender.state != UIGestureRecognizerStateBegan) return;

    [PSIUtils showSettingsVC:[self window]];
}
%end

// Open tweak settings by holding 4 fingers anywhere for ~1 second (independent of Instagram's UI)
@interface PSISettingsGestureHandler : NSObject
@end

@implementation PSISettingsGestureHandler
- (void)openSettings:(UIBarButtonItem *)sender {
    [PSIUtils showSettingsVC:[[UIApplication sharedApplication] keyWindow]];
}

- (void)handleLongPress:(UILongPressGestureRecognizer *)sender {
    if (sender.state != UIGestureRecognizerStateBegan) return;

    NSLog(@"[PSInstagram] Tweak settings 4-finger gesture activated");

    [PSIUtils showSettingsVC:sender.view.window];
}
@end

static PSISettingsGestureHandler *settingsGestureHandler;

%hook IGInstagramAppDelegate
- (void)applicationDidBecomeActive:(id)arg1 {
    %orig;

    UIWindow *window = [self window];
    if (!window || [objc_getAssociatedObject(window, @selector(handleLongPress:)) boolValue]) return;

    if (!settingsGestureHandler) settingsGestureHandler = [PSISettingsGestureHandler new];

    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:settingsGestureHandler action:@selector(handleLongPress:)];
    longPress.minimumPressDuration = 1;
    longPress.numberOfTouchesRequired = 4;
    longPress.cancelsTouchesInView = NO;
    [window addGestureRecognizer:longPress];

    objc_setAssociatedObject(window, @selector(handleLongPress:), @(YES), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}
%end

// PSInstagram button in the navigation bar of "Settings and activity"
static BOOL PSIIsSettingsRootController(UIViewController *controller) {
    if (![NSStringFromClass([controller class]) containsString:@"IGSettingsHostingController"]) return NO;

    // Only the first settings screen, not nested settings pages
    NSArray *stack = controller.navigationController.viewControllers;
    NSUInteger index = [stack indexOfObject:controller];
    if (index == NSNotFound || index == 0) return NO;

    return ![NSStringFromClass([stack[index - 1] class]) containsString:@"IGSettingsHostingController"];
}

%hook UIViewController
- (void)viewWillAppear:(BOOL)animated {
    %orig;

    if (!PSIIsSettingsRootController(self)) return;

    if (!settingsGestureHandler) settingsGestureHandler = [PSISettingsGestureHandler new];

    UIBarButtonItem *button = [[UIBarButtonItem alloc] initWithTitle:@"PSInstagram" style:UIBarButtonItemStylePlain target:settingsGestureHandler action:@selector(openSettings:)];
    self.navigationItem.rightBarButtonItem = button;
}
%end
