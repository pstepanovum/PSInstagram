#import "PSIMathGame.h"

static NSString *const PSIMathLevelKey = @"math_game_level";
static NSString *const PSIMathProgressKey = @"math_game_progress";
static NSString *const PSIMathSolvedKey = @"math_game_solved";
static NSString *const PSIMathStreakKey = @"math_game_streak";
static NSString *const PSIMathBestStreakKey = @"math_game_best_streak";

@interface PSIMathProblem ()
@property (nonatomic, copy, readwrite) NSString *text;
@property (nonatomic, readwrite) NSInteger answer;
@end

@implementation PSIMathProblem
@end

@implementation PSIMathGame

+ (NSInteger)answersPerLevel {
    return 5;
}

+ (NSInteger)level {
    return MAX(1, [[NSUserDefaults standardUserDefaults] integerForKey:PSIMathLevelKey]);
}

+ (NSInteger)levelProgress {
    return [[NSUserDefaults standardUserDefaults] integerForKey:PSIMathProgressKey];
}

+ (NSInteger)totalSolved {
    return [[NSUserDefaults standardUserDefaults] integerForKey:PSIMathSolvedKey];
}

+ (NSInteger)streak {
    return [[NSUserDefaults standardUserDefaults] integerForKey:PSIMathStreakKey];
}

+ (NSInteger)bestStreak {
    return [[NSUserDefaults standardUserDefaults] integerForKey:PSIMathBestStreakKey];
}

+ (NSArray<NSString *> *)progressKeys {
    return @[PSIMathLevelKey, PSIMathProgressKey, PSIMathSolvedKey, PSIMathStreakKey, PSIMathBestStreakKey];
}

static NSInteger PSIRandom(NSInteger min, NSInteger max) {
    return min + (NSInteger)arc4random_uniform((uint32_t)(max - min + 1));
}

static PSIMathProblem *PSIProblem(NSString *text, NSInteger answer) {
    PSIMathProblem *problem = [PSIMathProblem new];
    problem.text = text;
    problem.answer = answer;

    return problem;
}

// Plain arithmetic; operations unlock as the level rises: + (1), - (2), × (3), ÷ (5)
+ (PSIMathProblem *)arithmeticProblemForLevel:(NSInteger)level {
    NSMutableArray *operations = [NSMutableArray arrayWithObject:@"+"];
    if (level >= 2) [operations addObject:@"-"];
    if (level >= 3) [operations addObject:@"×"];
    if (level >= 5) [operations addObject:@"÷"];

    NSString *operation = operations[arc4random_uniform((uint32_t)operations.count)];

    // Operand sizes grow with the level
    NSInteger addMax = 10 + level * 15;
    NSInteger factorMax = 2 + level;
    NSInteger bigFactorMax = 10 + level * 25;

    NSInteger a, b, answer;

    if ([operation isEqualToString:@"+"]) {
        a = PSIRandom(1, addMax);
        b = PSIRandom(1, addMax);
        answer = a + b;
    }
    else if ([operation isEqualToString:@"-"]) {
        a = PSIRandom(1, addMax);
        b = PSIRandom(1, addMax);
        if (b > a) { NSInteger swap = a; a = b; b = swap; }
        answer = a - b;
    }
    else if ([operation isEqualToString:@"×"]) {
        a = PSIRandom(2, factorMax);
        b = PSIRandom(2, bigFactorMax);
        if (arc4random_uniform(2)) { NSInteger swap = a; a = b; b = swap; }
        answer = a * b;
    }
    else {
        b = PSIRandom(2, factorMax);
        answer = PSIRandom(2, 10 + level * 5);
        a = answer * b;
    }

    return PSIProblem([NSString stringWithFormat:@"%ld %@ %ld", (long)a, operation, (long)b], answer);
}

// ? + 17 = 45
+ (PSIMathProblem *)missingNumberProblemForLevel:(NSInteger)level {
    NSInteger addMax = 10 + level * 15;

    if (arc4random_uniform(2)) {
        NSInteger missing = PSIRandom(1, addMax);
        NSInteger known = PSIRandom(1, addMax);

        return arc4random_uniform(2)
            ? PSIProblem([NSString stringWithFormat:@"? + %ld = %ld", (long)known, (long)(missing + known)], missing)
            : PSIProblem([NSString stringWithFormat:@"%ld + ? = %ld", (long)known, (long)(missing + known)], missing);
    }

    NSInteger missing = PSIRandom(2, 2 + level);
    NSInteger known = PSIRandom(2, 10 + level * 3);

    return PSIProblem([NSString stringWithFormat:@"%ld × ? = %ld", (long)known, (long)(missing * known)], missing);
}

// 12 + 4 × 7
+ (PSIMathProblem *)mixedProblemForLevel:(NSInteger)level {
    NSInteger a = PSIRandom(1, 10 + level * 5);
    NSInteger b = PSIRandom(2, 2 + level);
    NSInteger c = PSIRandom(2, 12);

    if (arc4random_uniform(2) && a > b * c) {
        return PSIProblem([NSString stringWithFormat:@"%ld - %ld × %ld", (long)a, (long)b, (long)c], a - b * c);
    }

    return PSIProblem([NSString stringWithFormat:@"%ld + %ld × %ld", (long)a, (long)b, (long)c], a + b * c);
}

// 13²
+ (PSIMathProblem *)squareProblemForLevel:(NSInteger)level {
    NSInteger n = PSIRandom(3, 5 + level);

    return PSIProblem([NSString stringWithFormat:@"%ld²", (long)n], n * n);
}

// 2⁹
+ (PSIMathProblem *)powerProblemForLevel:(NSInteger)level {
    NSInteger base = PSIRandom(2, MIN(3 + level / 4, 9));
    NSInteger exponent = PSIRandom(2, base == 2 ? 12 : (base <= 4 ? 5 : 3));

    NSInteger value = 1;
    for (NSInteger i = 0; i < exponent; i++) value *= base;

    NSArray *superscripts = @[@"⁰", @"¹", @"²", @"³", @"⁴", @"⁵", @"⁶", @"⁷", @"⁸", @"⁹"];
    NSMutableString *exponentText = [NSMutableString string];
    for (NSUInteger i = 0; i < [@(exponent) stringValue].length; i++) {
        [exponentText appendString:superscripts[[[@(exponent) stringValue] characterAtIndex:i] - '0']];
    }

    return PSIProblem([NSString stringWithFormat:@"%ld%@", (long)base, exponentText], value);
}

// 15% of 240
+ (PSIMathProblem *)percentProblemForLevel:(NSInteger)level {
    NSArray *percents = @[@5, @10, @15, @20, @25, @30, @40, @50, @60, @75, @80, @120, @150];
    NSInteger percent = [percents[arc4random_uniform((uint32_t)percents.count)] integerValue];

    // Pick a whole that makes the result whole
    NSInteger step = 100 / [self gcd:percent with:100];
    NSInteger whole = step * PSIRandom(1, MAX(2, (20 + level * 10) / step));

    return PSIProblem([NSString stringWithFormat:@"%ld%% of %ld", (long)percent, (long)whole], percent * whole / 100);
}

+ (NSInteger)gcd:(NSInteger)a with:(NSInteger)b {
    while (b) { NSInteger t = a % b; a = b; b = t; }
    return a;
}

// log₂ 256
+ (PSIMathProblem *)logProblemForLevel:(NSInteger)level {
    NSArray *bases = @[@2, @3, @4, @5, @10];
    NSArray *baseText = @[@"₂", @"₃", @"₄", @"₅", @"₁₀"];
    NSArray *maxExponents = @[@12, @7, @6, @5, @6];

    NSUInteger index = arc4random_uniform((uint32_t)bases.count);
    NSInteger base = [bases[index] integerValue];
    NSInteger exponent = PSIRandom(2, [maxExponents[index] integerValue]);

    NSInteger value = 1;
    for (NSInteger i = 0; i < exponent; i++) value *= base;

    return PSIProblem([NSString stringWithFormat:@"log%@ %ld", baseText[index], (long)value], exponent);
}

// √784
+ (PSIMathProblem *)rootProblemForLevel:(NSInteger)level {
    NSInteger root = PSIRandom(4, 10 + level);

    return PSIProblem([NSString stringWithFormat:@"√%ld", (long)(root * root)], root);
}

// d/dx (3x²) at x = 4, or with a cubic term from level 20
+ (PSIMathProblem *)derivativeProblemForLevel:(NSInteger)level {
    NSInteger x = PSIRandom(1, 5);

    if (level >= 20 && arc4random_uniform(2)) {
        NSInteger a = PSIRandom(1, 3);
        NSInteger b = PSIRandom(1, 9);
        NSString *cubic = a == 1 ? @"x³" : [NSString stringWithFormat:@"%ldx³", (long)a];

        // d/dx (ax³ + bx) = 3ax² + b
        return PSIProblem([NSString stringWithFormat:@"d/dx (%@ + %ldx) at x = %ld", cubic, (long)b, (long)x], 3 * a * x * x + b);
    }

    NSInteger a = PSIRandom(2, 9);
    NSInteger b = PSIRandom(1, 9);

    // d/dx (ax² + bx) = 2ax + b
    return PSIProblem([NSString stringWithFormat:@"d/dx (%ldx² + %ldx) at x = %ld", (long)a, (long)b, (long)x], 2 * a * x + b);
}

// ∫₀³ 2x dx
+ (PSIMathProblem *)integralProblemForLevel:(NSInteger)level {
    NSArray *upperText = @[@"", @"¹", @"²", @"³", @"⁴", @"⁵", @"⁶"];
    NSInteger upper = PSIRandom(1, 6);
    NSInteger a = PSIRandom(1, 5);

    if (arc4random_uniform(2)) {
        // ∫₀ⁿ 3ax² dx = a·n³
        return PSIProblem([NSString stringWithFormat:@"∫₀%@ %ldx² dx", upperText[upper], (long)(3 * a)], a * upper * upper * upper);
    }

    // ∫₀ⁿ 2ax dx = a·n²
    NSString *coefficient = a == 1 ? @"2x" : [NSString stringWithFormat:@"%ldx", (long)(2 * a)];
    return PSIProblem([NSString stringWithFormat:@"∫₀%@ %@ dx", upperText[upper], coefficient], a * upper * upper);
}

+ (PSIMathProblem *)newProblem {
    NSInteger level = self.level;

    // Problem types unlock with the level; never the same type twice in a row (unless it's the only one)
    NSMutableArray<NSString *> *types = [NSMutableArray arrayWithObject:@"arithmetic"];
    if (level >= 4) [types addObject:@"missing"];
    if (level >= 6) [types addObject:@"mixed"];
    if (level >= 7) [types addObject:@"square"];
    if (level >= 10) [types addObject:@"power"];
    if (level >= 12) [types addObject:@"percent"];
    if (level >= 14) [types addObject:@"log"];
    if (level >= 16) [types addObject:@"root"];
    if (level >= 18) [types addObject:@"derivative"];
    if (level >= 22) [types addObject:@"integral"];

    static NSString *lastType;
    if (types.count > 1 && lastType) [types removeObject:lastType];

    NSString *type = types[arc4random_uniform((uint32_t)types.count)];
    lastType = type;

    if ([type isEqualToString:@"missing"]) return [self missingNumberProblemForLevel:level];
    if ([type isEqualToString:@"mixed"]) return [self mixedProblemForLevel:level];
    if ([type isEqualToString:@"square"]) return [self squareProblemForLevel:level];
    if ([type isEqualToString:@"power"]) return [self powerProblemForLevel:level];
    if ([type isEqualToString:@"percent"]) return [self percentProblemForLevel:level];
    if ([type isEqualToString:@"log"]) return [self logProblemForLevel:level];
    if ([type isEqualToString:@"root"]) return [self rootProblemForLevel:level];
    if ([type isEqualToString:@"derivative"]) return [self derivativeProblemForLevel:level];
    if ([type isEqualToString:@"integral"]) return [self integralProblemForLevel:level];

    return [self arithmeticProblemForLevel:level];
}

+ (BOOL)recordCorrectAnswer {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    NSInteger streak = self.streak + 1;
    [defaults setInteger:streak forKey:PSIMathStreakKey];
    [defaults setInteger:MAX(streak, self.bestStreak) forKey:PSIMathBestStreakKey];
    [defaults setInteger:self.totalSolved + 1 forKey:PSIMathSolvedKey];

    NSInteger progress = self.levelProgress + 1;
    if (progress >= self.answersPerLevel) {
        [defaults setInteger:self.level + 1 forKey:PSIMathLevelKey];
        [defaults setInteger:0 forKey:PSIMathProgressKey];

        return YES;
    }

    [defaults setInteger:progress forKey:PSIMathProgressKey];
    return NO;
}

+ (void)recordWrongAnswer {
    [[NSUserDefaults standardUserDefaults] setInteger:0 forKey:PSIMathStreakKey];
}

+ (NSString *)statsDescription {
    return [NSString stringWithFormat:@"Level %ld · %ld solved · best streak %ld", (long)self.level, (long)self.totalSolved, (long)self.bestStreak];
}

+ (void)resetProgress {
    for (NSString *key in self.progressKeys) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:key];
    }
}

@end
