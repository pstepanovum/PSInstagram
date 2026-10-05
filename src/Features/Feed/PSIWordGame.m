#import "PSIWordGame.h"
#import <UIKit/UIKit.h>

static NSString *const PSIWordAnswerKey = @"word_game_answer";
static NSString *const PSIWordGuessesKey = @"word_game_guesses";
static NSString *const PSIWordPlayedKey = @"word_game_played";
static NSString *const PSIWordWonKey = @"word_game_won";
static NSString *const PSIWordStreakKey = @"word_game_streak";
static NSString *const PSIWordBestStreakKey = @"word_game_best_streak";

@implementation PSIWordGame

// Common English words, so every answer is worth learning
+ (NSArray<NSString *> *)answers {
    static NSArray *answers;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        answers = [@"ABOUT ABOVE ACTOR ADULT AFTER AGAIN AGREE AHEAD ALARM ALBUM ALIVE ALLOW ALONE ALONG AMONG ANGLE ANGRY APART APPLE APPLY "
            "ARGUE ARISE ARROW ASIDE ASSET AUDIO AVOID AWARD AWARE AWFUL BACON BADGE BASIC BEACH BEARD BEAST BEGIN BEING BELOW BENCH "
            "BIRTH BLACK BLADE BLAME BLANK BLIND BLOCK BLOOD BOARD BOOST BRAIN BRAND BRAVE BREAD BREAK BRICK BRIDE BRIEF BRING BROAD "
            "BROWN BRUSH BUILD BUNCH BURST BUYER CABIN CABLE CANDY CARRY CATCH CAUSE CHAIN CHAIR CHALK CHARM CHART CHASE CHEAP CHECK "
            "CHEEK CHESS CHEST CHIEF CHILD CIVIL CLAIM CLASS CLEAN CLEAR CLERK CLICK CLIFF CLIMB CLOCK CLOSE CLOUD COACH COAST COLOR "
            "COUCH COUNT COURT COVER CRAFT CRASH CRAZY CREAM CRIME CROSS CROWD CROWN CRUEL CURVE CYCLE DAILY DANCE DELAY DEPTH DIARY "
            "DIRTY DOUBT DOZEN DRAFT DRAMA DREAM DRESS DRINK DRIVE EARLY EARTH EIGHT ELBOW ELDER EMPTY ENEMY ENJOY ENTER ENTRY EQUAL "
            "ERROR ESSAY EVENT EVERY EXACT EXIST EXTRA FAITH FALSE FANCY FAULT FEAST FENCE FEVER FIELD FIFTH FIFTY FIGHT FINAL FIRST "
            "FLAME FLASH FLEET FLOAT FLOOR FLOUR FLUID FOCUS FORCE FORTH FORTY FOUND FRAME FRESH FRONT FROST FRUIT FUNNY GHOST GIANT "
            "GIVEN GLASS GLOBE GLOVE GRACE GRADE GRAIN GRAND GRANT GRAPE GRASS GREAT GREEN GREET GROUP GUARD GUESS GUEST GUIDE HABIT "
            "HAPPY HEART HEAVY HOBBY HONEY HONOR HORSE HOTEL HOUSE HUMAN HUMOR IDEAL IMAGE INDEX INNER INPUT ISSUE JELLY JEWEL JOINT "
            "JUDGE JUICE KNIFE KNOCK KNOWN LABEL LARGE LASER LATER LAUGH LAYER LEARN LEAST LEAVE LEGAL LEMON LEVEL LIGHT LIMIT LOCAL "
            "LOGIC LOOSE LUCKY LUNCH MAGIC MAJOR MAKER MARCH MATCH MAYOR MEDAL METAL MINOR MODEL MONEY MONTH MORAL MOTOR MOUNT MOUSE "
            "MOUTH MOVIE MUSIC NERVE NEVER NIGHT NOISE NORTH NOVEL NURSE OCEAN OFFER OFTEN OLIVE ONION OPERA ORDER OTHER OUTER OWNER "
            "PAINT PANEL PAPER PARTY PASTA PATCH PEACE PEARL PHASE PHONE PHOTO PIANO PIECE PILOT PITCH PLACE PLAIN PLANE PLANT PLATE "
            "POINT PORCH POUND POWER PRESS PRICE PRIDE PRIME PRINT PRIZE PROOF PROUD PROVE PUPIL QUEEN QUICK QUIET QUITE QUOTE RADIO "
            "RAISE RANGE RAPID RATIO REACH REACT READY REPLY RIDER RIDGE RIGHT RIVER ROBOT ROUGH ROUND ROUTE ROYAL RURAL SALAD SAUCE "
            "SCALE SCENE SCOPE SCORE SENSE SERVE SEVEN SHADE SHAKE SHAPE SHARE SHARP SHEEP SHEET SHELF SHELL SHIFT SHINE SHIRT SHOCK "
            "SHOOT SHORT SHOUT SIGHT SKILL SLEEP SLICE SLIDE SMALL SMART SMILE SMOKE SNAKE SOLID SOLVE SOUND SOUTH SPACE SPARE SPEAK "
            "SPEED SPEND SPICE SPOON SPORT STAFF STAGE STAIR STAMP STAND START STATE STEAM STEEL STICK STILL STOCK STONE STORE STORM "
            "STORY STOVE STRAW STRIP STUDY STYLE SUGAR SUNNY SWEET SWING SWORD TABLE TASTE TEACH THANK THEME THICK THING THINK THIRD "
            "THREE THROW THUMB TIGER TIGHT TITLE TOAST TODAY TOPIC TOTAL TOUCH TOUGH TOWER TRACK TRADE TRAIL TRAIN TREAT TREND TRIAL "
            "TRIBE TRICK TRUCK TRULY TRUST TRUTH TWICE UNCLE UNDER UNION UNITY UNTIL UPPER UPSET URBAN USUAL VALID VALUE VIDEO VISIT "
            "VITAL VIVID VOICE WASTE WATCH WATER WHEEL WHERE WHILE WHITE WHOLE WOMAN WORLD WORRY WORTH WOUND WRITE WRONG YIELD YOUNG "
            "YOUTH ZEBRA" componentsSeparatedByString:@" "];
    });

    return answers;
}

+ (NSInteger)wordLength {
    return 5;
}

+ (NSInteger)maxGuesses {
    return 6;
}

+ (NSString *)answer {
    NSString *answer = [[NSUserDefaults standardUserDefaults] stringForKey:PSIWordAnswerKey];
    if (answer.length != self.wordLength) {
        [self startNewRound];
        answer = [[NSUserDefaults standardUserDefaults] stringForKey:PSIWordAnswerKey];
    }

    return answer;
}

+ (NSArray<NSString *> *)guesses {
    return [[NSUserDefaults standardUserDefaults] stringArrayForKey:PSIWordGuessesKey] ?: @[];
}

+ (BOOL)isRoundWon {
    return [self.guesses containsObject:self.answer];
}

+ (BOOL)isRoundOver {
    return self.isRoundWon || self.guesses.count >= self.maxGuesses;
}

+ (NSInteger)played {
    return [[NSUserDefaults standardUserDefaults] integerForKey:PSIWordPlayedKey];
}

+ (NSInteger)won {
    return [[NSUserDefaults standardUserDefaults] integerForKey:PSIWordWonKey];
}

+ (NSInteger)streak {
    return [[NSUserDefaults standardUserDefaults] integerForKey:PSIWordStreakKey];
}

+ (NSInteger)bestStreak {
    return [[NSUserDefaults standardUserDefaults] integerForKey:PSIWordBestStreakKey];
}

+ (NSArray<NSString *> *)progressKeys {
    return @[PSIWordAnswerKey, PSIWordGuessesKey, PSIWordPlayedKey, PSIWordWonKey, PSIWordStreakKey, PSIWordBestStreakKey];
}

+ (BOOL)isValidWord:(NSString *)word {
    NSString *upper = word.uppercaseString;
    if (upper.length != self.wordLength) return NO;
    if ([[self answers] containsObject:upper]) return YES;

    NSString *lower = word.lowercaseString;
    NSRange misspelled = [[UITextChecker new] rangeOfMisspelledWordInString:lower range:NSMakeRange(0, lower.length) startingAt:0 wrap:NO language:@"en_US"];
    return misspelled.location == NSNotFound;
}

// Greens first, then yellows only for letters the answer still has left over, so repeated letters are scored fairly
+ (NSArray<NSNumber *> *)statesForGuess:(NSString *)guess {
    NSString *answer = self.answer;
    NSInteger length = self.wordLength;

    NSMutableArray<NSNumber *> *states = [NSMutableArray arrayWithCapacity:length];
    NSCountedSet *remaining = [NSCountedSet set];

    for (NSInteger i = 0; i < length; i++) {
        unichar guessed = [guess characterAtIndex:i];
        unichar expected = [answer characterAtIndex:i];

        if (guessed == expected) {
            [states addObject:@(PSILetterStateCorrect)];
        }
        else {
            [states addObject:@(PSILetterStateAbsent)];
            [remaining addObject:@(expected)];
        }
    }

    for (NSInteger i = 0; i < length; i++) {
        if (states[i].integerValue == PSILetterStateCorrect) continue;

        NSNumber *letter = @([guess characterAtIndex:i]);
        if ([remaining countForObject:letter] > 0) {
            states[i] = @(PSILetterStatePresent);
            [remaining removeObject:letter];
        }
    }

    return states;
}

+ (NSArray<NSNumber *> *)submitGuess:(NSString *)guess {
    NSString *upper = guess.uppercaseString;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    [defaults setObject:[self.guesses arrayByAddingObject:upper] forKey:PSIWordGuessesKey];

    if (self.isRoundOver) {
        BOOL won = self.isRoundWon;
        NSInteger streak = won ? self.streak + 1 : 0;

        [defaults setInteger:self.played + 1 forKey:PSIWordPlayedKey];
        [defaults setInteger:self.won + (won ? 1 : 0) forKey:PSIWordWonKey];
        [defaults setInteger:streak forKey:PSIWordStreakKey];
        [defaults setInteger:MAX(streak, self.bestStreak) forKey:PSIWordBestStreakKey];
    }

    return [self statesForGuess:upper];
}

+ (void)startNewRound {
    NSArray *answers = [self answers];
    NSString *previous = [[NSUserDefaults standardUserDefaults] stringForKey:PSIWordAnswerKey];

    NSString *answer;
    do {
        answer = answers[arc4random_uniform((uint32_t)answers.count)];
    } while ([answer isEqualToString:previous]);

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:answer forKey:PSIWordAnswerKey];
    [defaults setObject:@[] forKey:PSIWordGuessesKey];
}

+ (NSString *)statsDescription {
    NSInteger percent = self.played > 0 ? (self.won * 100 / self.played) : 0;
    return [NSString stringWithFormat:@"%ld played · %ld%% won · best streak %ld", (long)self.played, (long)percent, (long)self.bestStreak];
}

+ (void)resetProgress {
    for (NSString *key in self.progressKeys) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:key];
    }
}

@end
