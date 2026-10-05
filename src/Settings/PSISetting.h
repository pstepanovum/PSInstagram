#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "PSISymbol.h"

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, PSITableCell) {
        PSITableCellStatic,
        PSITableCellLink,
        PSITableCellSwitch,
        PSITableCellStepper,
        PSITableCellButton,
        PSITableCellMenu,
        PSITableCellNavigation,
};

///

@interface PSISetting : NSObject

@property (nonatomic, readonly) PSITableCell type;

@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSString *subtitle;

@property (nonatomic, strong, nullable) PSISymbol *icon;
@property (nonatomic, strong) NSString *defaultsKey;

@property (nonatomic, strong) NSURL *url;
@property (nonatomic, strong) NSURL *imageUrl;

@property (nonatomic) BOOL requiresRestart;

@property (nonatomic) double min;
@property (nonatomic) double max;
@property (nonatomic) double step;
@property (nonatomic, copy) NSString *label;
@property (nonatomic, copy) NSString *singularLabel;

@property (nonatomic, copy) void (^action)(void);

@property (nonatomic, strong) UIMenu *baseMenu;

@property (nonatomic, strong) NSArray *navSections;
@property (nonatomic, strong) UIViewController *navViewController;

+ (instancetype)staticCellWithTitle:(NSString *)title
                           subtitle:(NSString *)subtitle
                               icon:(nullable PSISymbol *)icon;

+ (instancetype)linkCellWithTitle:(NSString *)title
                         subtitle:(NSString *)subtitle
                             icon:(nullable PSISymbol *)icon
                              url:(NSString *)url;

+ (instancetype)linkCellWithTitle:(NSString *)title
                         subtitle:(NSString *)subtitle
                         imageUrl:(NSString *)imageUrl
                              url:(NSString *)url;

+ (instancetype)switchCellWithTitle:(NSString *)title
                           subtitle:(NSString *)subtitle
                        defaultsKey:(NSString *)defaultsKey;

+ (instancetype)switchCellWithTitle:(NSString *)title
                           subtitle:(NSString *)subtitle
                        defaultsKey:(NSString *)defaultsKey
                    requiresRestart:(BOOL)requiresRestart;

+ (instancetype)stepperCellWithTitle:(NSString *)title
                            subtitle:(NSString *)subtitle
                         defaultsKey:(NSString *)defaultsKey
                                 min:(double)min
                                 max:(double)max
                                step:(double)step
                               label:(NSString *)label
                       singularLabel:(NSString *)singularLabel;

+ (instancetype)buttonCellWithTitle:(NSString *)title
                           subtitle:(NSString *)subtitle
                               icon:(nullable PSISymbol *)icon
                             action:(void (^)(void))action;

+ (instancetype)menuCellWithTitle:(NSString *)title
                         subtitle:(NSString *)subtitle
                             menu:(UIMenu *)menu;

+ (instancetype)navigationCellWithTitle:(NSString *)title
                               subtitle:(NSString *)subtitle
                                   icon:(nullable PSISymbol *)icon
                            navSections:(NSArray *)navSections;

+ (instancetype)navigationCellWithTitle:(NSString *)title
                               subtitle:(NSString *)subtitle
                                   icon:(nullable PSISymbol *)icon
                         viewController:(UIViewController *)viewController;


# pragma mark - Instance methods

- (UIMenu *)menuForButton:(UIButton *)button;

@end

NS_ASSUME_NONNULL_END
