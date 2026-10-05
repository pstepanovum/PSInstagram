#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// Mirrors PSInstagram's settings into the keychain, which survives reinstalling the app
@interface PSISettingsBackup : NSObject

+ (void)save;
+ (void)restoreIfNeeded;

@end

NS_ASSUME_NONNULL_END
