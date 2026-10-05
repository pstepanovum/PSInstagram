#import <objc/runtime.h>
#import <UIKit/UIKit.h>
#import "TweakSettings.h"
#import "PSISetting.h"
#import "PSISymbol.h"
#import "../Utils.h"

NS_ASSUME_NONNULL_BEGIN

@interface PSISettingsViewController : UIViewController

- (instancetype)initWithTitle:(NSString *)title sections:(NSArray *)sections reduceMargin:(BOOL)reduceMargin;
- (instancetype)init;

@end

NS_ASSUME_NONNULL_END
