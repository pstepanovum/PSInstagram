#import <Security/Security.h>
#import "../../Utils.h"
#import "../../../modules/fishhook/fishhook.h"

// Fixes for running Instagram re-signed with a non-Meta certificate.
// Meta's app groups and keychain access groups are not in our entitlements,
// so we redirect them to storage the app is actually allowed to use.

///////////////////////////////////////////////////////////

// App group containers

static NSURL *PSIFallbackGroupContainer(NSString *groupIdentifier) {
    NSURL *library = [[[NSFileManager defaultManager] URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask] firstObject];
    NSURL *container = [[library URLByAppendingPathComponent:@"PSIAppGroups" isDirectory:YES] URLByAppendingPathComponent:groupIdentifier isDirectory:YES];

    [[NSFileManager defaultManager] createDirectoryAtURL:container withIntermediateDirectories:YES attributes:nil error:nil];

    return container;
}

%hook NSFileManager
- (NSURL *)containerURLForSecurityApplicationGroupIdentifier:(NSString *)groupIdentifier {
    NSURL *container = %orig;
    if (container || groupIdentifier.length == 0) return container;

    return PSIFallbackGroupContainer(groupIdentifier);
}
%end

// App group user defaults (crashes in CFPreferencesSynchronize without an entitled container)
%hook NSUserDefaults
- (instancetype)initWithSuiteName:(NSString *)suiteName {
    if ([suiteName hasPrefix:@"group."]) {
        NSURL *container = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:suiteName];

        // Only remap groups we are not entitled to
        if (![container.path containsString:@"/PSIAppGroups/"]) return %orig;

        return %orig([@"psi." stringByAppendingString:suiteName]);
    }

    return %orig;
}

// Private initializer used for app group suites; keep suites out of our fallback containers
- (instancetype)_initWithSuiteName:(NSString *)suiteName container:(NSURL *)container {
    if ([container.path containsString:@"/PSIAppGroups/"]) {
        NSString *mappedSuiteName = [suiteName hasPrefix:@"group."] ? [@"psi." stringByAppendingString:suiteName] : suiteName;
        return %orig(mappedSuiteName, nil);
    }

    return %orig;
}
%end

///////////////////////////////////////////////////////////

// Instagram works out which Meta app it is (Instagram, Threads, ...) from its bundle ID, and with an
// unknown one it doesn't restore the logged-in session on launch. Report the original bundle ID
// to Instagram's code; the app keeps its own bundle ID on the device.
static NSString *const PSIOriginalBundleIdentifier = @"com.burbn.instagram";

%hook NSBundle
- (NSString *)bundleIdentifier {
    if (self == [NSBundle mainBundle]) return PSIOriginalBundleIdentifier;

    return %orig;
}
%end

///////////////////////////////////////////////////////////

// Pretend to be an App Store build, otherwise Instagram treats itself as an
// outdated TestFlight beta and blocks the app with an update screen

%hook NSBundle
- (NSURL *)appStoreReceiptURL {
    NSURL *url = %orig;

    if ([url.lastPathComponent isEqualToString:@"sandboxReceipt"]) {
        return [[url URLByDeletingLastPathComponent] URLByAppendingPathComponent:@"receipt"];
    }

    return url;
}
%end

static BOOL PSIIsTestFlightNag(UIViewController *controller) {
    UIViewController *root = controller;
    if ([controller isKindOfClass:[UINavigationController class]]) {
        root = [(UINavigationController *)controller viewControllers].firstObject;
    }

    return [NSStringFromClass([controller class]) containsString:@"TestFlight"]
        || [NSStringFromClass([root class]) containsString:@"TestFlight"];
}

%hook UIViewController
- (void)presentViewController:(UIViewController *)controller animated:(BOOL)animated completion:(void (^)(void))completion {
    if (PSIIsTestFlightNag(controller)) {
        NSLog(@"[PSInstagram] Blocked TestFlight update screen: %@", controller);

        if (completion) completion();
        return;
    }

    %orig;
}
%end

// Fallback for when the update screen is shown without being presented
@interface _TtC29IGCoreRootTestFlightNagPlugin35TestFlightUpdateNudgeViewController : UIViewController
@end

%hook _TtC29IGCoreRootTestFlightNagPlugin35TestFlightUpdateNudgeViewController
- (void)viewDidAppear:(BOOL)animated {
    %orig;

    NSLog(@"[PSInstagram] Removing TestFlight update screen (presenting: %@, parent: %@)", self.presentingViewController, self.parentViewController);

    if (self.presentingViewController) {
        [self dismissViewControllerAnimated:NO completion:nil];
    }
    else if (self.parentViewController) {
        [self willMoveToParentViewController:nil];
        [self.view removeFromSuperview];
        [self removeFromParentViewController];
    }
}
%end

///////////////////////////////////////////////////////////

// Keychain access groups

// The access group this app is actually allowed to use (from the signing entitlements)
static NSString *PSIKeychainAccessGroup;

static NSString *PSIResolveKeychainAccessGroup(void) {
    NSDictionary *query = @{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService: @"PSInstagram",
        (__bridge id)kSecAttrAccount: @"PSInstagramAccessGroupProbe",
        (__bridge id)kSecReturnAttributes: @YES
    };

    CFTypeRef result = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &result);
    if (status == errSecItemNotFound) {
        status = SecItemAdd((__bridge CFDictionaryRef)query, &result);
    }

    if (status != errSecSuccess || !result) {
        NSLog(@"[PSInstagram] Could not resolve keychain access group (status %d)", (int)status);
        return nil;
    }

    NSDictionary *attributes = (__bridge_transfer NSDictionary *)result;
    return attributes[(__bridge id)kSecAttrAccessGroup];
}

// Every item ends up in the single access group we have, so items Instagram puts in
// Meta's groups are tagged with their original group. Queries for a group then only
// see that group's items, as they would with real separate groups.
static NSString *PSIGroupTag(NSString *group) {
    return [@"psi:" stringByAppendingString:group];
}

static BOOL PSIShouldRemapGroup(NSString *group) {
    return group && ![group isEqualToString:PSIKeychainAccessGroup] && ![group isEqualToString:@"com.apple.token"];
}

static NSDictionary *PSIRemapAccessGroup(CFDictionaryRef query) {
    if (!query || !CFDictionaryContainsKey(query, kSecAttrAccessGroup)) return nil;

    NSMutableDictionary *mutableQuery = [(__bridge NSDictionary *)query mutableCopy];
    NSString *group = mutableQuery[(__bridge id)kSecAttrAccessGroup];
    if (!PSIShouldRemapGroup(group)) return nil;

    if (PSIKeychainAccessGroup) {
        mutableQuery[(__bridge id)kSecAttrAccessGroup] = PSIKeychainAccessGroup;
    }
    else {
        [mutableQuery removeObjectForKey:(__bridge id)kSecAttrAccessGroup];
    }

    // Only password items have a description attribute (keys and certificates don't)
    id itemClass = mutableQuery[(__bridge id)kSecClass];
    if ([itemClass isEqual:(__bridge id)kSecClassGenericPassword] || [itemClass isEqual:(__bridge id)kSecClassInternetPassword]) {
        mutableQuery[(__bridge id)kSecAttrDescription] = PSIGroupTag(group);
    }

    return mutableQuery;
}

static void PSILogKeychainStatus(const char *function, OSStatus status, CFDictionaryRef query) {
    if (status == errSecSuccess || status == errSecItemNotFound || status == errSecDuplicateItem) return;

    id group = query ? ((__bridge NSDictionary *)query)[(__bridge id)kSecAttrAccessGroup] : nil;
    NSLog(@"[PSInstagram] %s failed with status %d (requested access group: %@)", function, (int)status, group);
}

static OSStatus (*orig_SecItemAdd)(CFDictionaryRef, CFTypeRef *);
static OSStatus hook_SecItemAdd(CFDictionaryRef attributes, CFTypeRef *result) {
    NSDictionary *remapped = PSIRemapAccessGroup(attributes);
    OSStatus status = orig_SecItemAdd(remapped ? (__bridge CFDictionaryRef)remapped : attributes, result);

    PSILogKeychainStatus("SecItemAdd", status, attributes);
    return status;
}

static OSStatus (*orig_SecItemCopyMatching)(CFDictionaryRef, CFTypeRef *);
static OSStatus hook_SecItemCopyMatching(CFDictionaryRef query, CFTypeRef *result) {
    NSDictionary *remapped = PSIRemapAccessGroup(query);
    OSStatus status = orig_SecItemCopyMatching(remapped ? (__bridge CFDictionaryRef)remapped : query, result);

    PSILogKeychainStatus("SecItemCopyMatching", status, query);
    return status;
}

static OSStatus (*orig_SecItemUpdate)(CFDictionaryRef, CFDictionaryRef);
static OSStatus hook_SecItemUpdate(CFDictionaryRef query, CFDictionaryRef attributesToUpdate) {
    NSDictionary *remappedQuery = PSIRemapAccessGroup(query);
    NSDictionary *remappedAttributes = PSIRemapAccessGroup(attributesToUpdate);

    OSStatus status = orig_SecItemUpdate(
        remappedQuery ? (__bridge CFDictionaryRef)remappedQuery : query,
        remappedAttributes ? (__bridge CFDictionaryRef)remappedAttributes : attributesToUpdate
    );

    PSILogKeychainStatus("SecItemUpdate", status, query);
    return status;
}

static OSStatus (*orig_SecItemDelete)(CFDictionaryRef);
static OSStatus hook_SecItemDelete(CFDictionaryRef query) {
    NSDictionary *remapped = PSIRemapAccessGroup(query);
    OSStatus status = orig_SecItemDelete(remapped ? (__bridge CFDictionaryRef)remapped : query);

    PSILogKeychainStatus("SecItemDelete", status, query);
    return status;
}

%ctor {
    // Must run before rebinding, so these calls reach the real keychain functions
    PSIKeychainAccessGroup = PSIResolveKeychainAccessGroup();
    NSLog(@"[PSInstagram] Keychain access group: %@", PSIKeychainAccessGroup);

    // Rebind symbol pointers instead of patching Security's code,
    // which iOS kills the process for on non-jailbroken devices
    rebind_symbols((struct rebinding[4]){
        {"SecItemAdd", (void *)hook_SecItemAdd, (void **)&orig_SecItemAdd},
        {"SecItemCopyMatching", (void *)hook_SecItemCopyMatching, (void **)&orig_SecItemCopyMatching},
        {"SecItemUpdate", (void *)hook_SecItemUpdate, (void **)&orig_SecItemUpdate},
        {"SecItemDelete", (void *)hook_SecItemDelete, (void **)&orig_SecItemDelete},
    }, 4);

    %init;
}
