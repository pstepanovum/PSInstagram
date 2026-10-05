#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// How a guessed letter matches the answer
typedef NS_ENUM(NSInteger, PSILetterState) {
    PSILetterStateUnknown = 0,
    PSILetterStateAbsent,
    PSILetterStatePresent,
    PSILetterStateCorrect
};

// Five-letter word guessing game shown on the home feed, with the round and stats kept in user defaults
@interface PSIWordGame : NSObject

@property (class, nonatomic, readonly) NSInteger wordLength;
@property (class, nonatomic, readonly) NSInteger maxGuesses;

// The current round, kept across launches
@property (class, nonatomic, readonly) NSString *answer;
@property (class, nonatomic, readonly) NSArray<NSString *> *guesses;
@property (class, nonatomic, readonly) BOOL isRoundOver;
@property (class, nonatomic, readonly) BOOL isRoundWon;

@property (class, nonatomic, readonly) NSInteger played;
@property (class, nonatomic, readonly) NSInteger won;
@property (class, nonatomic, readonly) NSInteger streak;
@property (class, nonatomic, readonly) NSInteger bestStreak;

// Defaults keys holding progress, so it can be backed up with the settings
@property (class, nonatomic, readonly) NSArray<NSString *> *progressKeys;

// Whether a guess is an English word (lowercase or uppercase)
+ (BOOL)isValidWord:(NSString *)word;

// Records a valid guess; returns the state of each letter
+ (NSArray<NSNumber *> *)submitGuess:(NSString *)guess;
+ (NSArray<NSNumber *> *)statesForGuess:(NSString *)guess;

+ (void)startNewRound;

+ (NSString *)statsDescription;
+ (void)resetProgress;

@end

NS_ASSUME_NONNULL_END
