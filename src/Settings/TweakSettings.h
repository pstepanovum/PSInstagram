#import <Foundation/Foundation.h>
#import "PSISetting.h"
#import "PSISymbol.h"
#import "../Utils.h"
#import "../Tweak.h"

NS_ASSUME_NONNULL_BEGIN

@interface PSITweakSettings : NSObject

+ (NSArray *)sections;
+ (NSString *)title;
+ (NSDictionary *)menus;

@end

NS_ASSUME_NONNULL_END
