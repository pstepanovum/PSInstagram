#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, PSIPatternKind) {
    // "2, 6, 12, 20, 30, ?"
    PSIPatternKindSequence,
    // A number shown for a few seconds, then typed back from memory
    PSIPatternKindDigitSpan
};

@interface PSIPatternPuzzle : NSObject

@property (nonatomic, readonly) PSIPatternKind kind;

// Sequences: the terms with a blank at the end, as plain text and as LaTeX. Digit span: the number to remember
@property (nonatomic, copy, readonly) NSString *text;
@property (nonatomic, copy, readonly, nullable) NSString *latex;

@property (nonatomic, copy, readonly) NSString *answer;

// The rule behind a sequence, shown after a wrong answer ("n(n + 1)")
@property (nonatomic, copy, readonly, nullable) NSString *rule;

// Digit span: how long the number is shown, and whether it must be typed backwards
@property (nonatomic, readonly) NSTimeInterval displaySeconds;
@property (nonatomic, readonly) BOOL reversed;

@end

// Pattern and memory puzzles shown on the home feed, with levels kept in user defaults
@interface PSIPatternGame : NSObject

// Correct answers needed to reach the next level
@property (class, nonatomic, readonly) NSInteger answersPerLevel;

@property (class, nonatomic, readonly) NSInteger level;
@property (class, nonatomic, readonly) NSInteger levelProgress;
@property (class, nonatomic, readonly) NSInteger totalSolved;
@property (class, nonatomic, readonly) NSInteger streak;
@property (class, nonatomic, readonly) NSInteger bestStreak;

// Defaults keys holding progress, so it can be backed up with the settings
@property (class, nonatomic, readonly) NSArray<NSString *> *progressKeys;

+ (PSIPatternPuzzle *)newPuzzle;

// Returns YES when the answer levels the player up
+ (BOOL)recordCorrectAnswer;
+ (void)recordWrongAnswer;

+ (NSString *)statsDescription;
+ (void)resetProgress;

@end

NS_ASSUME_NONNULL_END
