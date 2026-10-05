#import "PSISettingsBackup.h"
#import <Security/Security.h>
#import "PSISetting.h"
#import "TweakSettings.h"
#import "../Features/Feed/PSIMathGame.h"

static NSString *const PSIBackupService = @"PSInstagram";
static NSString *const PSIBackupAccount = @"PSInstagramSettingsBackup";

// Set once settings exist in this install, so a backup is only restored into a fresh install
static NSString *const PSIBackupMarkerKey = @"PSInstagramSettingsBackupMarker";

@implementation PSISettingsBackup

+ (void)collectKeysFromSections:(NSArray *)sections into:(NSMutableSet *)keys {
    for (NSDictionary *section in sections) {
        for (PSISetting *row in section[@"rows"]) {
            if (row.defaultsKey.length > 0) [keys addObject:row.defaultsKey];
            if (row.navSections) [self collectKeysFromSections:row.navSections into:keys];
        }
    }
}

+ (NSSet *)settingsKeys {
    NSMutableSet *keys = [NSMutableSet set];

    [self collectKeysFromSections:[PSITweakSettings sections] into:keys];
    [keys addObjectsFromArray:[[PSITweakSettings menus] allKeys]];
    [keys addObjectsFromArray:PSIMathGame.progressKeys];

    return keys;
}

+ (NSDictionary *)keychainQuery {
    return @{
        (__bridge id)kSecClass: (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService: PSIBackupService,
        (__bridge id)kSecAttrAccount: PSIBackupAccount
    };
}

+ (void)save {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *stored = [defaults persistentDomainForName:[[NSBundle mainBundle] bundleIdentifier]];

    // Only values the user actually set; registered defaults are applied on every launch anyway
    NSMutableDictionary *values = [NSMutableDictionary dictionary];
    for (NSString *key in [self settingsKeys]) {
        if (stored[key] != nil) values[key] = stored[key];
    }

    NSData *data = [NSPropertyListSerialization dataWithPropertyList:values format:NSPropertyListBinaryFormat_v1_0 options:0 error:nil];
    if (!data) return;

    [defaults setBool:YES forKey:PSIBackupMarkerKey];

    NSDictionary *query = [self keychainQuery];
    NSDictionary *update = @{ (__bridge id)kSecValueData: data };

    OSStatus status = SecItemUpdate((__bridge CFDictionaryRef)query, (__bridge CFDictionaryRef)update);
    if (status == errSecItemNotFound) {
        NSMutableDictionary *item = [query mutableCopy];
        item[(__bridge id)kSecValueData] = data;
        item[(__bridge id)kSecAttrAccessible] = (__bridge id)kSecAttrAccessibleAfterFirstUnlock;

        status = SecItemAdd((__bridge CFDictionaryRef)item, NULL);
    }

    if (status != errSecSuccess) {
        NSLog(@"[PSInstagram] Failed to back up settings (status %d)", (int)status);
    }
}

+ (void)restoreIfNeeded {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults boolForKey:PSIBackupMarkerKey]) return;

    NSMutableDictionary *query = [[self keychainQuery] mutableCopy];
    query[(__bridge id)kSecReturnData] = @YES;
    query[(__bridge id)kSecMatchLimit] = (__bridge id)kSecMatchLimitOne;

    CFTypeRef result = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, &result);

    if (status == errSecSuccess && result) {
        NSData *data = (__bridge_transfer NSData *)result;
        NSDictionary *values = [NSPropertyListSerialization propertyListWithData:data options:0 format:nil error:nil];

        if ([values isKindOfClass:[NSDictionary class]]) {
            NSLog(@"[PSInstagram] Restoring %lu settings from keychain backup", (unsigned long)values.count);

            [values enumerateKeysAndObjectsUsingBlock:^(NSString *key, id value, BOOL *stop) {
                [defaults setObject:value forKey:key];
            }];
        }
    }

    [defaults setBool:YES forKey:PSIBackupMarkerKey];
}

@end
