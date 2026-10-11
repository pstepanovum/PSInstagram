#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// Mental math game shown on the home feed, with levels kept in user defaults
@interface PSIMathProblem : NSObject

@property (nonatomic, copy, readonly) NSString *text;
// The same problem as LaTeX, for typeset display
@property (nonatomic, copy, readonly) NSString *latex;
@property (nonatomic, readonly) NSInteger answer;

@end

@interface PSIMathGame : NSObject

// Correct answers needed to reach the next level
@property (class, nonatomic, readonly) NSInteger answersPerLevel;

@property (class, nonatomic, readonly) NSInteger level;
@property (class, nonatomic, readonly) NSInteger levelProgress;
@property (class, nonatomic, readonly) NSInteger totalSolved;
@property (class, nonatomic, readonly) NSInteger streak;
@property (class, nonatomic, readonly) NSInteger bestStreak;

// Defaults keys holding progress, so it can be backed up with the settings
@property (class, nonatomic, readonly) NSArray<NSString *> *progressKeys;

+ (PSIMathProblem *)newProblem;

// Returns YES when the answer levels the player up
+ (BOOL)recordCorrectAnswer;
+ (void)recordWrongAnswer;

+ (NSString *)statsDescription;
+ (void)resetProgress;

@end

NS_ASSUME_NONNULL_END
