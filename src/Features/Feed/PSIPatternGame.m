#import "PSIPatternGame.h"
#import <math.h>

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
@property (nonatomic, copy, readwrite) NSString *prompt;
@property (nonatomic, copy, readwrite, nullable) NSArray<NSString *> *steps;
@property (nonatomic, readwrite) NSTimeInterval stepSeconds;
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
    puzzle.prompt = @"What comes next?";
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
    puzzle.prompt = @"Remember this number";
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

+ (PSIPatternPuzzle *)sequenceForLevel:(NSInteger)level {

    // Sequence families unlock with the level; never the same family twice in a row
    NSMutableArray<NSString *> *types = [NSMutableArray arrayWithObject:@"arithmetic"];
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

// 🍎 + 🍎 = 10, 🍎 + 🍌 = 8: two unknowns at first, then three with multiplication and order of operations
+ (PSIPatternPuzzle *)emojiPuzzleForLevel:(NSInteger)level {
    NSMutableArray *fruits = [@[@"🍎", @"🍌", @"🍒", @"🍇", @"🍊", @"🍓", @"🥝", @"🍋", @"🍑", @"🍍"] mutableCopy];
    NSString *(^pick)(void) = ^NSString *{
        NSUInteger index = arc4random_uniform((uint32_t)fruits.count);
        NSString *fruit = fruits[index];
        [fruits removeObjectAtIndex:index];
        return fruit;
    };
    NSString *A = pick(), *B = pick(), *C = pick();
    NSInteger maxValue = MIN(9 + level, 20);

    PSIPatternPuzzle *puzzle = [PSIPatternPuzzle new];
    puzzle.kind = PSIPatternKindEmoji;

    if (level < 4) {
        NSInteger a = PSIRandom(2, maxValue), b = PSIRandom(1, maxValue);
        NSString *first = arc4random_uniform(2) ? [NSString stringWithFormat:@"%@ + %@ = %ld", A, A, (long)(2 * a)]
                                                : [NSString stringWithFormat:@"%@ + %@ + %@ = %ld", A, A, A, (long)(3 * a)];
        puzzle.text = [NSString stringWithFormat:@"%@\n%@ + %@ = %ld\n%@ = ?", first, A, B, (long)(a + b), B];
        puzzle.prompt = [NSString stringWithFormat:@"Find %@", B];
        puzzle.answer = [@(b) stringValue];
        puzzle.rule = [NSString stringWithFormat:@"%@ = %ld, %@ = %ld", A, (long)a, B, (long)b];
        return puzzle;
    }

    NSInteger a = PSIRandom(2, maxValue), b = PSIRandom(2, MIN(maxValue, 12)), c = PSIRandom(2, MIN(maxValue, 12));
    NSString *lines = [NSString stringWithFormat:@"%@ + %@ = %ld\n%@ + %@ = %ld\n%@ × %@ = %ld", A, A, (long)(2 * a), A, B, (long)(a + b), B, C, (long)(b * c)];

    // From level 8: multiplication comes before addition
    if (level >= 8 && arc4random_uniform(2)) {
        puzzle.text = [lines stringByAppendingFormat:@"\n%@ + %@ × %@ = ?", A, B, C];
        puzzle.prompt = @"Solve the last line";
        puzzle.answer = [@(a + b * c) stringValue];
        puzzle.rule = [NSString stringWithFormat:@"%@ = %ld, %@ = %ld, %@ = %ld; × before +", A, (long)a, B, (long)b, C, (long)c];
    }
    else {
        puzzle.text = [lines stringByAppendingFormat:@"\n%@ = ?", C];
        puzzle.prompt = [NSString stringWithFormat:@"Find %@", C];
        puzzle.answer = [@(c) stringValue];
        puzzle.rule = [NSString stringWithFormat:@"%@ = %ld, %@ = %ld, %@ = %ld", A, (long)a, B, (long)b, C, (long)c];
    }

    return puzzle;
}

// A 3×3 grid following a rule along its rows or columns; the bottom-right number is missing
+ (PSIPatternPuzzle *)gridPuzzleForLevel:(NSInteger)level {
    NSMutableArray *rules = [NSMutableArray arrayWithObjects:@"sum", @"steps", nil];
    if (level >= 3) [rules addObjectsFromArray:@[@"product", @"columns"]];
    if (level >= 5) [rules addObject:@"geometric"];
    NSString *rule = rules[arc4random_uniform((uint32_t)rules.count)];

    NSInteger g[9];
    NSString *ruleText;
    NSInteger maxValue = MIN(9 + level, 20);

    if ([rule isEqualToString:@"sum"]) {
        for (int r = 0; r < 3; r++) { g[r * 3] = PSIRandom(1, maxValue); g[r * 3 + 1] = PSIRandom(1, maxValue); g[r * 3 + 2] = g[r * 3] + g[r * 3 + 1]; }
        ruleText = @"each row: first + second = third";
    }
    else if ([rule isEqualToString:@"product"]) {
        NSInteger maxFactor = MIN(5 + level / 3, 9);
        for (int r = 0; r < 3; r++) { g[r * 3] = PSIRandom(2, maxFactor); g[r * 3 + 1] = PSIRandom(2, maxFactor); g[r * 3 + 2] = g[r * 3] * g[r * 3 + 1]; }
        ruleText = @"each row: first × second = third";
    }
    else if ([rule isEqualToString:@"columns"]) {
        for (int col = 0; col < 3; col++) { g[col] = PSIRandom(1, maxValue); g[3 + col] = PSIRandom(1, maxValue); g[6 + col] = g[col] + g[3 + col]; }
        ruleText = @"each column: top + middle = bottom";
    }
    else if ([rule isEqualToString:@"geometric"]) {
        for (int r = 0; r < 3; r++) { NSInteger k = PSIRandom(2, 3); g[r * 3] = PSIRandom(1, 6); g[r * 3 + 1] = g[r * 3] * k; g[r * 3 + 2] = g[r * 3 + 1] * k; }
        ruleText = @"each row multiplies by the same number";
    }
    else {
        for (int r = 0; r < 3; r++) { NSInteger step = PSIRandom(2, 4 + level); g[r * 3] = PSIRandom(1, maxValue); g[r * 3 + 1] = g[r * 3] + step; g[r * 3 + 2] = g[r * 3 + 1] + step; }
        ruleText = @"each row goes up in equal steps";
    }

    NSMutableArray<NSString *> *cells = [NSMutableArray array];
    for (int i = 0; i < 9; i++) [cells addObject:i == 8 ? @"\\square" : [@(g[i]) stringValue]];

    PSIPatternPuzzle *puzzle = [PSIPatternPuzzle new];
    puzzle.kind = PSIPatternKindGrid;
    puzzle.prompt = @"Find the missing number";
    puzzle.text = [NSString stringWithFormat:@"%ld %ld %ld / %ld %ld %ld / %ld %ld ?", (long)g[0], (long)g[1], (long)g[2], (long)g[3], (long)g[4], (long)g[5], (long)g[6], (long)g[7]];
    puzzle.latex = [NSString stringWithFormat:@"\\begin{matrix} %@ & %@ & %@ \\\\ %@ & %@ & %@ \\\\ %@ & %@ & %@ \\end{matrix}",
        cells[0], cells[1], cells[2], cells[3], cells[4], cells[5], cells[6], cells[7], cells[8]];
    puzzle.answer = [@(g[8]) stringValue];
    puzzle.rule = ruleText;

    return puzzle;
}

static BOOL PSIIsPrime(NSInteger n) {
    if (n < 2) return NO;
    for (NSInteger d = 2; d * d <= n; d++) if (n % d == 0) return NO;
    return YES;
}

static BOOL PSIIsSquare(NSInteger n) {
    NSInteger r = (NSInteger)llround(sqrt((double)n));
    return r * r == n;
}

static BOOL PSIIsCube(NSInteger n) {
    NSInteger r = (NSInteger)llround(cbrt((double)n));
    return r * r * r == n;
}

static BOOL PSIIsPowerOfTwo(NSInteger n) {
    return n > 0 && (n & (n - 1)) == 0;
}

// Five numbers in order, four of a kind; the answer is the position of the odd one
+ (PSIPatternPuzzle *)oddOneOutForLevel:(NSInteger)level {
    NSMutableArray *categories = [NSMutableArray arrayWithObjects:@"even", @"multiples", nil];
    if (level >= 2) [categories addObject:@"squares"];
    if (level >= 3) [categories addObject:@"powers"];
    if (level >= 4) [categories addObject:@"primes"];
    if (level >= 5) [categories addObject:@"cubes"];
    NSString *category = categories[arc4random_uniform((uint32_t)categories.count)];

    NSMutableOrderedSet<NSNumber *> *members = [NSMutableOrderedSet orderedSet];
    NSInteger outlier = 0;
    NSString *rule;

    if ([category isEqualToString:@"even"]) {
        while (members.count < 4) [members addObject:@(2 * PSIRandom(1, 20 + level * 5))];
        do { outlier = 2 * PSIRandom(1, 20 + level * 5) + 1; } while ([members containsObject:@(outlier)]);
        rule = [NSString stringWithFormat:@"%ld is the only odd number", (long)outlier];
    }
    else if ([category isEqualToString:@"multiples"]) {
        NSInteger k = PSIRandom(3, 9);
        while (members.count < 4) [members addObject:@(k * PSIRandom(2, 12))];
        do { outlier = k * PSIRandom(2, 12) + PSIRandom(1, k - 1); } while ([members containsObject:@(outlier)]);
        rule = [NSString stringWithFormat:@"%ld isn't a multiple of %ld", (long)outlier, (long)k];
    }
    else if ([category isEqualToString:@"squares"]) {
        while (members.count < 4) { NSInteger n = PSIRandom(2, 12); [members addObject:@(n * n)]; }
        do { NSInteger n = PSIRandom(3, 12); outlier = n * n + (arc4random_uniform(2) ? 1 : -1) * PSIRandom(1, 3); } while (PSIIsSquare(outlier) || [members containsObject:@(outlier)]);
        rule = [NSString stringWithFormat:@"%ld isn't a square", (long)outlier];
    }
    else if ([category isEqualToString:@"powers"]) {
        while (members.count < 4) [members addObject:@(1 << PSIRandom(1, 9))];
        do { outlier = 2 * PSIRandom(3, 200); } while (PSIIsPowerOfTwo(outlier) || [members containsObject:@(outlier)]);
        rule = [NSString stringWithFormat:@"%ld isn't a power of 2", (long)outlier];
    }
    else if ([category isEqualToString:@"primes"]) {
        NSArray *primes = @[@3, @5, @7, @11, @13, @17, @19, @23, @29, @31, @37, @41, @43, @47, @53, @59, @61, @67, @71];
        while (members.count < 4) [members addObject:primes[arc4random_uniform((uint32_t)primes.count)]];
        NSArray *composites = @[@9, @15, @21, @25, @27, @33, @35, @39, @45, @49, @51, @55, @57, @63, @65, @69];
        outlier = [composites[arc4random_uniform((uint32_t)composites.count)] integerValue];
        rule = [NSString stringWithFormat:@"%ld isn't prime", (long)outlier];
    }
    else {
        while (members.count < 4) { NSInteger n = PSIRandom(1, 6); [members addObject:@(n * n * n)]; }
        do { outlier = PSIRandom(10, 220); } while (PSIIsCube(outlier) || [members containsObject:@(outlier)]);
        rule = [NSString stringWithFormat:@"%ld isn't a cube", (long)outlier];
    }

    NSArray<NSNumber *> *numbers = [[members.array arrayByAddingObject:@(outlier)] sortedArrayUsingSelector:@selector(compare:)];

    PSIPatternPuzzle *puzzle = [PSIPatternPuzzle new];
    puzzle.kind = PSIPatternKindOddOneOut;
    puzzle.prompt = @"Which one doesn't fit? Type its position, 1–5";
    puzzle.text = [numbers componentsJoinedByString:@", "];
    puzzle.latex = [numbers componentsJoinedByString:@",\\ \\ "];
    puzzle.answer = [@([numbers indexOfObject:@(outlier)] + 1) stringValue];
    puzzle.rule = rule;

    return puzzle;
}

// 3 → 9, 5 → 25, 7 → ?: find the rule from two examples
+ (PSIPatternPuzzle *)analogyForLevel:(NSInteger)level {
    NSMutableArray *rules = [NSMutableArray arrayWithObjects:@"double", @"add", nil];
    if (level >= 2) [rules addObject:@"square"];
    if (level >= 3) [rules addObjectsFromArray:@[@"triple", @"divide"]];
    if (level >= 4) [rules addObject:@"pronic"];
    if (level >= 5) [rules addObjectsFromArray:@[@"cube", @"squareMinus"]];
    if (level >= 6) [rules addObjectsFromArray:@[@"reverse", @"digitSum"]];
    NSString *rule = rules[arc4random_uniform((uint32_t)rules.count)];

    NSInteger k = PSIRandom(2, 9);
    NSInteger (^f)(NSInteger) = nil;
    NSInteger (^input)(void) = ^NSInteger { return PSIRandom(2, 12); };
    NSString *ruleText;

    if ([rule isEqualToString:@"double"]) { f = ^NSInteger(NSInteger x) { return 2 * x; }; ruleText = @"×2"; }
    else if ([rule isEqualToString:@"add"]) { f = ^NSInteger(NSInteger x) { return x + k; }; ruleText = [NSString stringWithFormat:@"+%ld", (long)k]; }
    else if ([rule isEqualToString:@"square"]) { f = ^NSInteger(NSInteger x) { return x * x; }; ruleText = @"x²"; }
    else if ([rule isEqualToString:@"triple"]) { f = ^NSInteger(NSInteger x) { return 3 * x - 1; }; ruleText = @"3x − 1"; }
    else if ([rule isEqualToString:@"divide"]) {
        input = ^NSInteger { return k * PSIRandom(2, 12); };
        f = ^NSInteger(NSInteger x) { return x / k; };
        ruleText = [NSString stringWithFormat:@"÷%ld", (long)k];
    }
    else if ([rule isEqualToString:@"pronic"]) { f = ^NSInteger(NSInteger x) { return x * (x + 1); }; ruleText = @"x(x + 1)"; }
    else if ([rule isEqualToString:@"cube"]) {
        input = ^NSInteger { return PSIRandom(2, 6); };
        f = ^NSInteger(NSInteger x) { return x * x * x; };
        ruleText = @"x³";
    }
    else if ([rule isEqualToString:@"squareMinus"]) { f = ^NSInteger(NSInteger x) { return x * x - 1; }; ruleText = @"x² − 1"; }
    else if ([rule isEqualToString:@"reverse"]) {
        input = ^NSInteger { return PSIRandom(1, 9) * 10 + PSIRandom(1, 9); };
        f = ^NSInteger(NSInteger x) { return (x % 10) * 10 + x / 10; };
        ruleText = @"the digits swap";
    }
    else {
        input = ^NSInteger { return PSIRandom(11, 99); };
        f = ^NSInteger(NSInteger x) { return x / 10 + x % 10; };
        ruleText = @"add the digits";
    }

    NSMutableOrderedSet<NSNumber *> *inputs = [NSMutableOrderedSet orderedSet];
    while (inputs.count < 3) [inputs addObject:@(input())];
    NSInteger x1 = inputs[0].integerValue, x2 = inputs[1].integerValue, x3 = inputs[2].integerValue;

    PSIPatternPuzzle *puzzle = [PSIPatternPuzzle new];
    puzzle.kind = PSIPatternKindAnalogy;
    puzzle.prompt = @"Same rule, what's missing?";
    puzzle.text = [NSString stringWithFormat:@"%ld → %ld, %ld → %ld, %ld → ?", (long)x1, (long)f(x1), (long)x2, (long)f(x2), (long)x3];
    puzzle.latex = [NSString stringWithFormat:@"%ld \\to %ld,\\ \\ %ld \\to %ld,\\ \\ %ld \\to \\square", (long)x1, (long)f(x1), (long)x2, (long)f(x2), (long)x3];
    puzzle.answer = [@(f(x3)) stringValue];
    puzzle.rule = ruleText;

    return puzzle;
}

// 5, + 7, × 2, − 3 … shown one at a time; more and faster steps as the level rises
+ (PSIPatternPuzzle *)runningTotalForLevel:(NSInteger)level {
    NSInteger value = PSIRandom(2, 9);
    NSMutableArray *steps = [NSMutableArray arrayWithObject:[@(value) stringValue]];
    NSInteger count = MIN(3 + level / 2, 8);

    for (NSInteger i = 0; i < count; i++) {
        NSMutableArray *operations = [NSMutableArray arrayWithObjects:@"+", @"-", nil];
        if (level >= 3 && value <= 30) [operations addObject:@"×"];
        if (level >= 6 && (value % 2 == 0 || value % 3 == 0) && value > 3) [operations addObject:@"÷"];
        NSString *operation = operations[arc4random_uniform((uint32_t)operations.count)];

        NSInteger n;
        if ([operation isEqualToString:@"+"]) { n = PSIRandom(2, 9 + level); value += n; }
        else if ([operation isEqualToString:@"-"]) {
            if (value <= 2) { n = PSIRandom(2, 9); value += n; operation = @"+"; }
            else { n = PSIRandom(1, MIN(value - 1, 9 + level)); value -= n; }
        }
        else if ([operation isEqualToString:@"×"]) { n = PSIRandom(2, 3); value *= n; }
        else { n = value % 3 == 0 && arc4random_uniform(2) ? 3 : (value % 2 == 0 ? 2 : 3); value /= n; }

        NSString *symbol = [operation isEqualToString:@"-"] ? @"−" : operation;
        [steps addObject:[NSString stringWithFormat:@"%@ %ld", symbol, (long)n]];
    }

    PSIPatternPuzzle *puzzle = [PSIPatternPuzzle new];
    puzzle.kind = PSIPatternKindRunningTotal;
    puzzle.prompt = @"Keep a running total";
    puzzle.steps = steps;
    puzzle.stepSeconds = MAX(0.8, 1.6 - level * 0.05);
    puzzle.text = [steps componentsJoinedByString:@"  "];
    puzzle.answer = [@(value) stringValue];
    puzzle.rule = [steps componentsJoinedByString:@" "];

    return puzzle;
}

// Every game in the IQ tab, shuffled; never the same game twice in a row
+ (PSIPatternPuzzle *)newPuzzle {
    NSInteger level = self.level;

    NSMutableArray<NSString *> *games = [@[@"sequence", @"digits", @"emoji", @"grid", @"oddOne", @"analogy", @"running"] mutableCopy];

    static NSString *lastGame;
    if (lastGame) [games removeObject:lastGame];

    NSString *game = games[arc4random_uniform((uint32_t)games.count)];
    lastGame = game;

    if ([game isEqualToString:@"digits"]) return [self digitSpanForLevel:level];
    if ([game isEqualToString:@"emoji"]) return [self emojiPuzzleForLevel:level];
    if ([game isEqualToString:@"grid"]) return [self gridPuzzleForLevel:level];
    if ([game isEqualToString:@"oddOne"]) return [self oddOneOutForLevel:level];
    if ([game isEqualToString:@"analogy"]) return [self analogyForLevel:level];
    if ([game isEqualToString:@"running"]) return [self runningTotalForLevel:level];

    return [self sequenceForLevel:level];
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
