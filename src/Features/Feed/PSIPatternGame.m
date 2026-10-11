#import "PSIPatternGame.h"

static NSString *const PSIPatternLevelKey = @"pattern_game_level";
static NSString *const PSIPatternProgressKey = @"pattern_game_progress";
static NSString *const PSIPatternSolvedKey = @"pattern_game_solved";
static NSString *const PSIPatternStreakKey = @"pattern_game_streak";
static NSString *const PSIPatternBestStreakKey = @"pattern_game_best_streak";

@interface PSIPatternPuzzle ()
@property (nonatomic, readwrite) PSIPatternKind kind;
@property (nonatomic, copy, readwrite) NSString *text;
@property (nonatomic, copy, readwrite, nullable) NSString *latex;
@property (nonatomic, copy, readwrite) NSString *answer;
@property (nonatomic, copy, readwrite, nullable) NSString *rule;
@property (nonatomic, readwrite) NSTimeInterval displaySeconds;
@property (nonatomic, readwrite) BOOL reversed;
@end

@implementation PSIPatternPuzzle
@end

static NSInteger PSIRandom(NSInteger min, NSInteger max) {
    return min + (NSInteger)arc4random_uniform((uint32_t)(max - min + 1));
}

// The shown terms with a blank for the next one, which is the answer
static PSIPatternPuzzle *PSISequence(NSArray<NSNumber *> *terms, NSInteger next, NSString *rule) {
    PSIPatternPuzzle *puzzle = [PSIPatternPuzzle new];
    puzzle.kind = PSIPatternKindSequence;
    puzzle.text = [[terms componentsJoinedByString:@", "] stringByAppendingString:@", ?"];
    puzzle.latex = [[terms componentsJoinedByString:@",\\ "] stringByAppendingString:@",\\ \\square"];
    puzzle.answer = [@(next) stringValue];
    puzzle.rule = rule;

    return puzzle;
}

@implementation PSIPatternGame

+ (NSInteger)answersPerLevel {
    return 5;
}

+ (NSInteger)level {
    return MAX(1, [[NSUserDefaults standardUserDefaults] integerForKey:PSIPatternLevelKey]);
}

+ (NSInteger)levelProgress {
    return [[NSUserDefaults standardUserDefaults] integerForKey:PSIPatternProgressKey];
}

+ (NSInteger)totalSolved {
    return [[NSUserDefaults standardUserDefaults] integerForKey:PSIPatternSolvedKey];
}

+ (NSInteger)streak {
    return [[NSUserDefaults standardUserDefaults] integerForKey:PSIPatternStreakKey];
}

+ (NSInteger)bestStreak {
    return [[NSUserDefaults standardUserDefaults] integerForKey:PSIPatternBestStreakKey];
}

+ (NSArray<NSString *> *)progressKeys {
    return @[PSIPatternLevelKey, PSIPatternProgressKey, PSIPatternSolvedKey, PSIPatternStreakKey, PSIPatternBestStreakKey];
}

///////////////////////////////////////////////////////////

// Each step adds the same number: 7, 11, 15, 19, 23, ?
+ (PSIPatternPuzzle *)arithmeticSequence {
    NSInteger step = PSIRandom(2, 12);
    NSInteger start = PSIRandom(1, 30);
    BOOL down = arc4random_uniform(3) == 0;
    if (down) start += step * 6;

    NSMutableArray *terms = [NSMutableArray array];
    for (NSInteger i = 0; i < 5; i++) [terms addObject:@(start + (down ? -step : step) * i)];

    return PSISequence(terms, start + (down ? -step : step) * 5, [NSString stringWithFormat:@"%@%ld each time", down ? @"−" : @"+", (long)step]);
}

// Each step multiplies: 3, 6, 12, 24, 48, ?
+ (PSIPatternPuzzle *)geometricSequence {
    NSInteger ratio = PSIRandom(2, 3);
    NSInteger value = PSIRandom(1, ratio == 2 ? 6 : 3);

    NSMutableArray *terms = [NSMutableArray array];
    for (NSInteger i = 0; i < 5; i++) {
        [terms addObject:@(value)];
        value *= ratio;
    }

    return PSISequence(terms, value, [NSString stringWithFormat:@"×%ld each time", (long)ratio]);
}

// Squares, sometimes shifted: 5, 10, 17, 26, 37, ?  (n² + 1)
+ (PSIPatternPuzzle *)squareSequence {
    NSInteger n = PSIRandom(1, 7);
    NSInteger shift = arc4random_uniform(2) ? 0 : PSIRandom(1, 5) * (arc4random_uniform(2) ? 1 : -1);
    if (n * n + shift < 1) shift = 0;

    NSMutableArray *terms = [NSMutableArray array];
    for (NSInteger i = 0; i < 5; i++) [terms addObject:@((n + i) * (n + i) + shift)];

    NSString *rule = shift == 0 ? @"square numbers" : [NSString stringWithFormat:@"n² %@ %ld", shift > 0 ? @"+" : @"−", (long)labs(shift)];
    return PSISequence(terms, (n + 5) * (n + 5) + shift, rule);
}

// The gap grows by the same amount: 2, 6, 12, 20, 30, ?  (gaps 4, 6, 8, 10)
+ (PSIPatternPuzzle *)growingGapSequence {
    NSInteger value = PSIRandom(1, 15);
    NSInteger gap = PSIRandom(1, 6);
    NSInteger growth = PSIRandom(1, 4);

    NSMutableArray *terms = [NSMutableArray array];
    for (NSInteger i = 0; i < 5; i++) {
        [terms addObject:@(value)];
        value += gap;
        gap += growth;
    }

    return PSISequence(terms, value, [NSString stringWithFormat:@"the gap grows by %ld", (long)growth]);
}

// Each term is the sum of the two before: 2, 5, 7, 12, 19, ?
+ (PSIPatternPuzzle *)fibonacciSequence {
    NSInteger a = PSIRandom(1, 6);
    NSInteger b = PSIRandom(a, a + 6);

    NSMutableArray *terms = [NSMutableArray arrayWithObjects:@(a), @(b), nil];
    for (NSInteger i = 0; i < 3; i++) {
        NSInteger next = a + b;
        [terms addObject:@(next)];
        a = b;
        b = next;
    }

    return PSISequence(terms, a + b, @"add the previous two");
}

// Cubes or primes
+ (PSIPatternPuzzle *)specialSequence {
    if (arc4random_uniform(2)) {
        NSInteger n = PSIRandom(1, 4);

        NSMutableArray *terms = [NSMutableArray array];
        for (NSInteger i = 0; i < 5; i++) [terms addObject:@((n + i) * (n + i) * (n + i))];

        return PSISequence(terms, (n + 5) * (n + 5) * (n + 5), @"cube numbers");
    }

    NSArray *primes = @[@2, @3, @5, @7, @11, @13, @17, @19, @23, @29, @31, @37, @41, @43, @47, @53, @59, @61];
    NSInteger start = PSIRandom(0, (NSInteger)primes.count - 6);

    return PSISequence([primes subarrayWithRange:NSMakeRange(start, 5)], [primes[start + 5] integerValue], @"prime numbers");
}

// Two sequences taking turns: 3, 20, 6, 18, 9, 16, ?
+ (PSIPatternPuzzle *)interleavedSequence {
    NSInteger a = PSIRandom(1, 10), stepA = PSIRandom(2, 6);
    NSInteger b = PSIRandom(20, 40), stepB = PSIRandom(1, 4);

    NSMutableArray *terms = [NSMutableArray array];
    for (NSInteger i = 0; i < 3; i++) {
        [terms addObject:@(a + stepA * i)];
        [terms addObject:@(b - stepB * i)];
    }

    return PSISequence(terms, a + stepA * 3, [NSString stringWithFormat:@"two sequences taking turns: +%ld and −%ld", (long)stepA, (long)stepB]);
}

// A rule applied to the previous term: 2, 5, 11, 23, 47, ?  (×2 + 1)
+ (PSIPatternPuzzle *)recursiveSequence {
    NSInteger multiplier = PSIRandom(2, 3);
    NSInteger add = PSIRandom(1, 4) * (arc4random_uniform(2) ? 1 : -1);
    NSInteger value = PSIRandom(2, 4);

    // Every step has to grow (x·(m − 1) + add ≥ 1), so a subtraction never takes the terms down to zero
    if (add < 0) value = MAX(value, -add / (multiplier - 1) + 1);

    NSMutableArray *terms = [NSMutableArray array];
    for (NSInteger i = 0; i < 5; i++) {
        [terms addObject:@(value)];
        value = value * multiplier + add;
    }

    return PSISequence(terms, value, [NSString stringWithFormat:@"×%ld, then %@%ld", (long)multiplier, add > 0 ? @"+" : @"−", (long)labs(add)]);
}

// Two operations taking turns: 1, 3, 6, 8, 16, 18, ?  (+2, ×2)
+ (PSIPatternPuzzle *)alternatingOperationSequence {
    NSInteger add = PSIRandom(1, 5);
    NSInteger multiplier = PSIRandom(2, 3);
    NSInteger value = PSIRandom(1, 4);

    NSMutableArray *terms = [NSMutableArray array];
    for (NSInteger i = 0; i < 6; i++) {
        [terms addObject:@(value)];
        value = i % 2 == 0 ? value + add : value * multiplier;
    }

    return PSISequence(terms, value, [NSString stringWithFormat:@"+%ld and ×%ld, taking turns", (long)add, (long)multiplier]);
}

// Remember a number: it starts at 4 digits and grows with the level; from level 5 some have to be typed backwards
+ (PSIPatternPuzzle *)digitSpanForLevel:(NSInteger)level {
    NSInteger length = MIN(4 + level / 2, 12);

    NSMutableString *digits = [NSMutableString stringWithFormat:@"%ld", (long)PSIRandom(1, 9)];
    while ((NSInteger)digits.length < length) [digits appendFormat:@"%ld", (long)PSIRandom(0, 9)];

    PSIPatternPuzzle *puzzle = [PSIPatternPuzzle new];
    puzzle.kind = PSIPatternKindDigitSpan;
    puzzle.text = digits;
    puzzle.reversed = level >= 5 && arc4random_uniform(3) == 0;
    puzzle.displaySeconds = 1.0 + 0.4 * length;

    if (puzzle.reversed) {
        NSMutableString *backwards = [NSMutableString string];
        for (NSInteger i = digits.length - 1; i >= 0; i--) [backwards appendFormat:@"%C", [digits characterAtIndex:i]];
        puzzle.answer = backwards;
    }
    else {
        puzzle.answer = digits;
    }

    return puzzle;
}

+ (PSIPatternPuzzle *)newPuzzle {
    NSInteger level = self.level;

    // Puzzle types unlock with the level; never the same type twice in a row
    NSMutableArray<NSString *> *types = [NSMutableArray arrayWithObjects:@"arithmetic", @"digits", nil];
    if (level >= 2) [types addObject:@"geometric"];
    if (level >= 3) [types addObject:@"square"];
    if (level >= 4) [types addObject:@"growing"];
    if (level >= 5) [types addObject:@"fibonacci"];
    if (level >= 6) [types addObject:@"special"];
    if (level >= 7) [types addObject:@"interleaved"];
    if (level >= 8) [types addObject:@"recursive"];
    if (level >= 9) [types addObject:@"alternating"];

    // Past the first levels, the easiest sequences mostly step aside for harder ones
    if (level >= 6 && arc4random_uniform(3)) [types removeObject:@"arithmetic"];

    static NSString *lastType;
    if (types.count > 1 && lastType) [types removeObject:lastType];

    NSString *type = types[arc4random_uniform((uint32_t)types.count)];
    lastType = type;

    if ([type isEqualToString:@"digits"]) return [self digitSpanForLevel:level];
    if ([type isEqualToString:@"geometric"]) return [self geometricSequence];
    if ([type isEqualToString:@"square"]) return [self squareSequence];
    if ([type isEqualToString:@"growing"]) return [self growingGapSequence];
    if ([type isEqualToString:@"fibonacci"]) return [self fibonacciSequence];
    if ([type isEqualToString:@"special"]) return [self specialSequence];
    if ([type isEqualToString:@"interleaved"]) return [self interleavedSequence];
    if ([type isEqualToString:@"recursive"]) return [self recursiveSequence];
    if ([type isEqualToString:@"alternating"]) return [self alternatingOperationSequence];

    return [self arithmeticSequence];
}

///////////////////////////////////////////////////////////

+ (BOOL)recordCorrectAnswer {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    NSInteger streak = self.streak + 1;
    [defaults setInteger:streak forKey:PSIPatternStreakKey];
    [defaults setInteger:MAX(streak, self.bestStreak) forKey:PSIPatternBestStreakKey];
    [defaults setInteger:self.totalSolved + 1 forKey:PSIPatternSolvedKey];

    NSInteger progress = self.levelProgress + 1;
    if (progress >= self.answersPerLevel) {
        [defaults setInteger:self.level + 1 forKey:PSIPatternLevelKey];
        [defaults setInteger:0 forKey:PSIPatternProgressKey];

        return YES;
    }

    [defaults setInteger:progress forKey:PSIPatternProgressKey];
    return NO;
}

+ (void)recordWrongAnswer {
    [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:PSIPatternStreakKey];
}

+ (NSString *)statsDescription {
    return [NSString stringWithFormat:@"%ld solved · best streak %ld", (long)self.totalSolved, (long)self.bestStreak];
}

+ (void)resetProgress {
    for (NSString *key in self.progressKeys) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:key];
    }
}

@end
