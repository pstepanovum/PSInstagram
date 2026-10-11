#import "PSIMathGame.h"

static NSString *const PSIMathLevelKey = @"math_game_level";
static NSString *const PSIMathProgressKey = @"math_game_progress";
static NSString *const PSIMathSolvedKey = @"math_game_solved";
static NSString *const PSIMathStreakKey = @"math_game_streak";
static NSString *const PSIMathBestStreakKey = @"math_game_best_streak";

@interface PSIMathProblem ()
@property (nonatomic, copy, readwrite) NSString *text;
@property (nonatomic, copy, readwrite) NSString *latex;
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

static PSIMathProblem *PSIProblem(NSString *text, NSString *latex, NSInteger answer) {
    PSIMathProblem *problem = [PSIMathProblem new];
    problem.text = text;
    problem.latex = latex;
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

    NSDictionary *latexOperations = @{@"+": @"+", @"-": @"-", @"×": @"\\times", @"÷": @"\\div"};

    return PSIProblem([NSString stringWithFormat:@"%ld %@ %ld", (long)a, operation, (long)b],
                      [NSString stringWithFormat:@"%ld %@ %ld", (long)a, latexOperations[operation], (long)b], answer);
}

// ? + 17 = 45
+ (PSIMathProblem *)missingNumberProblemForLevel:(NSInteger)level {
    NSInteger addMax = 10 + level * 15;

    if (arc4random_uniform(2)) {
        NSInteger missing = PSIRandom(1, addMax);
        NSInteger known = PSIRandom(1, addMax);

        return arc4random_uniform(2)
            ? PSIProblem([NSString stringWithFormat:@"? + %ld = %ld", (long)known, (long)(missing + known)],
                         [NSString stringWithFormat:@"\\square + %ld = %ld", (long)known, (long)(missing + known)], missing)
            : PSIProblem([NSString stringWithFormat:@"%ld + ? = %ld", (long)known, (long)(missing + known)],
                         [NSString stringWithFormat:@"%ld + \\square = %ld", (long)known, (long)(missing + known)], missing);
    }

    NSInteger missing = PSIRandom(2, 2 + level);
    NSInteger known = PSIRandom(2, 10 + level * 3);

    return PSIProblem([NSString stringWithFormat:@"%ld × ? = %ld", (long)known, (long)(missing * known)],
                      [NSString stringWithFormat:@"%ld \\times \\square = %ld", (long)known, (long)(missing * known)], missing);
}

// 12 + 4 × 7
+ (PSIMathProblem *)mixedProblemForLevel:(NSInteger)level {
    NSInteger a = PSIRandom(1, 10 + level * 5);
    NSInteger b = PSIRandom(2, 2 + level);
    NSInteger c = PSIRandom(2, 12);

    if (arc4random_uniform(2) && a > b * c) {
        return PSIProblem([NSString stringWithFormat:@"%ld - %ld × %ld", (long)a, (long)b, (long)c],
                          [NSString stringWithFormat:@"%ld - %ld \\times %ld", (long)a, (long)b, (long)c], a - b * c);
    }

    return PSIProblem([NSString stringWithFormat:@"%ld + %ld × %ld", (long)a, (long)b, (long)c],
                      [NSString stringWithFormat:@"%ld + %ld \\times %ld", (long)a, (long)b, (long)c], a + b * c);
}

// 13²
+ (PSIMathProblem *)squareProblemForLevel:(NSInteger)level {
    NSInteger n = PSIRandom(3, 5 + level);

    return PSIProblem([NSString stringWithFormat:@"%ld²", (long)n], [NSString stringWithFormat:@"%ld^{2}", (long)n], n * n);
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

    return PSIProblem([NSString stringWithFormat:@"%ld%@", (long)base, exponentText],
                      [NSString stringWithFormat:@"%ld^{%ld}", (long)base, (long)exponent], value);
}

// 15% of 240
+ (PSIMathProblem *)percentProblemForLevel:(NSInteger)level {
    NSArray *percents = @[@5, @10, @15, @20, @25, @30, @40, @50, @60, @75, @80, @120, @150];
    NSInteger percent = [percents[arc4random_uniform((uint32_t)percents.count)] integerValue];

    // Pick a whole that makes the result whole
    NSInteger step = 100 / [self gcd:percent with:100];
    NSInteger whole = step * PSIRandom(1, MAX(2, (20 + level * 10) / step));

    return PSIProblem([NSString stringWithFormat:@"%ld%% of %ld", (long)percent, (long)whole],
                      [NSString stringWithFormat:@"%ld\\%%\\ \\text{of}\\ %ld", (long)percent, (long)whole], percent * whole / 100);
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

    return PSIProblem([NSString stringWithFormat:@"log%@ %ld", baseText[index], (long)value],
                      [NSString stringWithFormat:@"\\log_{%ld} %ld", (long)base, (long)value], exponent);
}

// √784
+ (PSIMathProblem *)rootProblemForLevel:(NSInteger)level {
    NSInteger root = PSIRandom(4, 10 + level);

    return PSIProblem([NSString stringWithFormat:@"√%ld", (long)(root * root)], [NSString stringWithFormat:@"\\sqrt{%ld}", (long)(root * root)], root);
}

// d/dx (3x²) at x = 4, or with a cubic term from level 20
+ (PSIMathProblem *)derivativeProblemForLevel:(NSInteger)level {
    NSInteger x = PSIRandom(1, 5);

    if (level >= 20 && arc4random_uniform(2)) {
        NSInteger a = PSIRandom(1, 3);
        NSInteger b = PSIRandom(1, 9);
        NSString *cubic = a == 1 ? @"x³" : [NSString stringWithFormat:@"%ldx³", (long)a];
        NSString *cubicLatex = a == 1 ? @"x^{3}" : [NSString stringWithFormat:@"%ldx^{3}", (long)a];

        // d/dx (ax³ + bx) = 3ax² + b
        return PSIProblem([NSString stringWithFormat:@"d/dx (%@ + %ldx) at x = %ld", cubic, (long)b, (long)x],
                          [NSString stringWithFormat:@"\\left.\\frac{d}{dx}\\left(%@ + %ldx\\right)\\right|_{x=%ld}", cubicLatex, (long)b, (long)x],
                          3 * a * x * x + b);
    }

    NSInteger a = PSIRandom(2, 9);
    NSInteger b = PSIRandom(1, 9);

    // d/dx (ax² + bx) = 2ax + b
    return PSIProblem([NSString stringWithFormat:@"d/dx (%ldx² + %ldx) at x = %ld", (long)a, (long)b, (long)x],
                      [NSString stringWithFormat:@"\\left.\\frac{d}{dx}\\left(%ldx^{2} + %ldx\\right)\\right|_{x=%ld}", (long)a, (long)b, (long)x],
                      2 * a * x + b);
}

// ∫₀³ 2x dx
+ (PSIMathProblem *)integralProblemForLevel:(NSInteger)level {
    NSArray *upperText = @[@"", @"¹", @"²", @"³", @"⁴", @"⁵", @"⁶"];
    NSInteger upper = PSIRandom(1, 6);
    NSInteger a = PSIRandom(1, 5);

    if (arc4random_uniform(2)) {
        // ∫₀ⁿ 3ax² dx = a·n³
        return PSIProblem([NSString stringWithFormat:@"∫₀%@ %ldx² dx", upperText[upper], (long)(3 * a)],
                          [NSString stringWithFormat:@"\\int_{0}^{%ld} %ldx^{2}\\,dx", (long)upper, (long)(3 * a)], a * upper * upper * upper);
    }

    // ∫₀ⁿ 2ax dx = a·n²
    NSString *coefficient = a == 1 ? @"2x" : [NSString stringWithFormat:@"%ldx", (long)(2 * a)];
    return PSIProblem([NSString stringWithFormat:@"∫₀%@ %@ dx", upperText[upper], coefficient],
                      [NSString stringWithFormat:@"\\int_{0}^{%ld} %@\\,dx", (long)upper, coefficient], a * upper * upper);
}

// lim_{x→a} (x² − a²)/(x − a) = 2a, or (x³ − a³)/(x − a) = 3a²
+ (PSIMathProblem *)limitProblem {
    if (arc4random_uniform(2)) {
        NSInteger a = PSIRandom(2, 6);

        return PSIProblem([NSString stringWithFormat:@"lim x→%ld (x³ − %ld)/(x − %ld)", (long)a, (long)(a * a * a), (long)a],
                          [NSString stringWithFormat:@"\\lim_{x \\to %ld} \\frac{x^{3} - %ld}{x - %ld}", (long)a, (long)(a * a * a), (long)a],
                          3 * a * a);
    }

    NSInteger a = PSIRandom(2, 12);

    return PSIProblem([NSString stringWithFormat:@"lim x→%ld (x² − %ld)/(x − %ld)", (long)a, (long)(a * a), (long)a],
                      [NSString stringWithFormat:@"\\lim_{x \\to %ld} \\frac{x^{2} - %ld}{x - %ld}", (long)a, (long)(a * a), (long)a],
                      2 * a);
}

// Σ k, Σ (2k − 1), Σ k²
+ (PSIMathProblem *)sumProblem {
    switch (arc4random_uniform(3)) {
        case 0: {
            NSInteger n = PSIRandom(5, 30);
            return PSIProblem([NSString stringWithFormat:@"Σ k for k = 1…%ld", (long)n],
                              [NSString stringWithFormat:@"\\sum_{k=1}^{%ld} k", (long)n], n * (n + 1) / 2);
        }
        case 1: {
            NSInteger n = PSIRandom(4, 15);
            return PSIProblem([NSString stringWithFormat:@"Σ (2k − 1) for k = 1…%ld", (long)n],
                              [NSString stringWithFormat:@"\\sum_{k=1}^{%ld} (2k - 1)", (long)n], n * n);
        }
        default: {
            NSInteger n = PSIRandom(3, 10);
            return PSIProblem([NSString stringWithFormat:@"Σ k² for k = 1…%ld", (long)n],
                              [NSString stringWithFormat:@"\\sum_{k=1}^{%ld} k^{2}", (long)n], n * (n + 1) * (2 * n + 1) / 6);
        }
    }
}

// (n choose k)
+ (PSIMathProblem *)binomialProblem {
    NSInteger n = PSIRandom(5, 12);
    NSInteger k = PSIRandom(2, MIN(4, n - 2));

    NSInteger value = 1;
    for (NSInteger i = 1; i <= k; i++) value = value * (n - k + i) / i;

    return PSIProblem([NSString stringWithFormat:@"C(%ld, %ld)", (long)n, (long)k],
                      [NSString stringWithFormat:@"\\binom{%ld}{%ld}", (long)n, (long)k], value);
}

// det of a 2×2 matrix, always positive
+ (PSIMathProblem *)determinant2Problem {
    NSInteger a, b, c, d;
    do {
        a = PSIRandom(2, 9); b = PSIRandom(1, 9); c = PSIRandom(1, 9); d = PSIRandom(2, 9);
    } while (a * d - b * c <= 0);

    return PSIProblem([NSString stringWithFormat:@"det [[%ld, %ld], [%ld, %ld]]", (long)a, (long)b, (long)c, (long)d],
                      [NSString stringWithFormat:@"\\det \\begin{pmatrix} %ld & %ld \\\\ %ld & %ld \\end{pmatrix}", (long)a, (long)b, (long)c, (long)d],
                      a * d - b * c);
}

// det of a 3×3 matrix with small entries, always positive
+ (PSIMathProblem *)determinant3Problem {
    NSInteger m[9];
    NSInteger det;
    do {
        for (int i = 0; i < 9; i++) m[i] = PSIRandom(0, 4);
        det = m[0] * (m[4] * m[8] - m[5] * m[7]) - m[1] * (m[3] * m[8] - m[5] * m[6]) + m[2] * (m[3] * m[7] - m[4] * m[6]);
    } while (det <= 0);

    return PSIProblem([NSString stringWithFormat:@"det [[%ld, %ld, %ld], [%ld, %ld, %ld], [%ld, %ld, %ld]]",
                          (long)m[0], (long)m[1], (long)m[2], (long)m[3], (long)m[4], (long)m[5], (long)m[6], (long)m[7], (long)m[8]],
                      [NSString stringWithFormat:@"\\det \\begin{pmatrix} %ld & %ld & %ld \\\\ %ld & %ld & %ld \\\\ %ld & %ld & %ld \\end{pmatrix}",
                          (long)m[0], (long)m[1], (long)m[2], (long)m[3], (long)m[4], (long)m[5], (long)m[6], (long)m[7], (long)m[8]],
                      det);
}

// tr(AB) for two 2×2 matrices = ae + bg + cf + dh
+ (PSIMathProblem *)traceProblem {
    NSInteger a = PSIRandom(1, 6), b = PSIRandom(0, 5), c = PSIRandom(0, 5), d = PSIRandom(1, 6);
    NSInteger e = PSIRandom(1, 6), f = PSIRandom(0, 5), g = PSIRandom(0, 5), h = PSIRandom(1, 6);

    return PSIProblem([NSString stringWithFormat:@"tr([[%ld, %ld], [%ld, %ld]] · [[%ld, %ld], [%ld, %ld]])",
                          (long)a, (long)b, (long)c, (long)d, (long)e, (long)f, (long)g, (long)h],
                      [NSString stringWithFormat:@"\\mathrm{tr}\\left( \\begin{pmatrix} %ld & %ld \\\\ %ld & %ld \\end{pmatrix} \\begin{pmatrix} %ld & %ld \\\\ %ld & %ld \\end{pmatrix} \\right)",
                          (long)a, (long)b, (long)c, (long)d, (long)e, (long)f, (long)g, (long)h],
                      a * e + b * g + c * f + d * h);
}

// ℒ{k tⁿ} at s = 1 is k·n!; ℒ⁻¹{k·n!/sⁿ⁺¹} at t = t₀ is k·t₀ⁿ
+ (PSIMathProblem *)laplaceProblem {
    NSInteger n = PSIRandom(1, 3);
    NSInteger k = PSIRandom(1, 4);
    NSInteger factorial = n == 1 ? 1 : (n == 2 ? 2 : 6);
    NSString *term = [NSString stringWithFormat:@"%@t^{%ld}", k == 1 ? @"" : [@(k) stringValue], (long)n];

    if (arc4random_uniform(2)) {
        return PSIProblem([NSString stringWithFormat:@"L{%@} at s = 1", [term stringByReplacingOccurrencesOfString:@"^{" withString:@"^"]],
                          [NSString stringWithFormat:@"\\left. \\mathcal{L}\\left\\{ %@ \\right\\} \\right|_{s=1}", term],
                          k * factorial);
    }

    NSInteger t = PSIRandom(1, 4);
    NSInteger power = 1;
    for (NSInteger i = 0; i < n; i++) power *= t;

    return PSIProblem([NSString stringWithFormat:@"L⁻¹{%ld/s^%ld} at t = %ld", (long)(k * factorial), (long)(n + 1), (long)t],
                      [NSString stringWithFormat:@"\\left. \\mathcal{L}^{-1}\\left\\{ \\frac{%ld}{s^{%ld}} \\right\\} \\right|_{t=%ld}", (long)(k * factorial), (long)(n + 1), (long)t],
                      k * power);
}

// aᵏ mod m
+ (PSIMathProblem *)modularProblem {
    NSInteger base = PSIRandom(2, 9);
    NSInteger exponent = PSIRandom(3, 12);
    NSInteger modulus = PSIRandom(5, 13);

    NSInteger value = 1;
    for (NSInteger i = 0; i < exponent; i++) value = value * base % modulus;

    return PSIProblem([NSString stringWithFormat:@"%ld^%ld mod %ld", (long)base, (long)exponent, (long)modulus],
                      [NSString stringWithFormat:@"%ld^{%ld} \\bmod %ld", (long)base, (long)exponent, (long)modulus], value);
}

// |a + bi| with a Pythagorean triple, so the modulus is whole
+ (PSIMathProblem *)complexProblem {
    NSArray *triples = @[@[@3, @4, @5], @[@5, @12, @13], @[@8, @15, @17], @[@7, @24, @25], @[@20, @21, @29], @[@9, @40, @41]];
    NSArray *triple = triples[arc4random_uniform((uint32_t)triples.count)];
    NSInteger scale = PSIRandom(1, 3);
    NSInteger a = [triple[0] integerValue] * scale, b = [triple[1] integerValue] * scale, c = [triple[2] integerValue] * scale;
    if (arc4random_uniform(2)) { NSInteger swap = a; a = b; b = swap; }

    return PSIProblem([NSString stringWithFormat:@"|%ld + %ldi|", (long)a, (long)b],
                      [NSString stringWithFormat:@"\\left| %ld + %ldi \\right|", (long)a, (long)b], c);
}

// Integrals that look hard but come out whole: Gamma, a double integral, Cauchy, and ln x / x
+ (PSIMathProblem *)advancedIntegralProblem {
    switch (arc4random_uniform(4)) {
        case 0: {
            // ∫₀^∞ xⁿ e⁻ˣ dx = Γ(n + 1) = n!
            NSInteger n = PSIRandom(2, 5);
            NSInteger factorial = 1;
            for (NSInteger i = 2; i <= n; i++) factorial *= i;

            return PSIProblem([NSString stringWithFormat:@"∫₀^∞ x^%ld e^(−x) dx", (long)n],
                              [NSString stringWithFormat:@"\\int_{0}^{\\infty} x^{%ld} e^{-x}\\,dx", (long)n], factorial);
        }
        case 1: {
            // ∫₀ᵃ ∫₀ᵇ (2x + y) dy dx = a²b + ab²/2
            NSInteger a, b;
            do { a = PSIRandom(1, 4); b = PSIRandom(1, 4); } while ((a * b) % 2);

            return PSIProblem([NSString stringWithFormat:@"∫₀^%ld ∫₀^%ld (2x + y) dy dx", (long)a, (long)b],
                              [NSString stringWithFormat:@"\\int_{0}^{%ld} \\int_{0}^{%ld} (2x + y)\\,dy\\,dx", (long)a, (long)b],
                              a * a * b + a * b * b / 2);
        }
        case 2: {
            // (1/π) ∫₋∞^∞ c/(1 + x²) dx = c
            NSInteger c = PSIRandom(2, 9);

            return PSIProblem([NSString stringWithFormat:@"(1/π) ∫ %ld/(1 + x²) dx over ℝ", (long)c],
                              [NSString stringWithFormat:@"\\frac{1}{\\pi} \\int_{-\\infty}^{\\infty} \\frac{%ld}{1 + x^{2}}\\,dx", (long)c], c);
        }
        default: {
            // ∫₁^{eᵏ} (ln x)/x dx = k²/2, with k even
            NSInteger k = 2 * PSIRandom(1, 3);

            return PSIProblem([NSString stringWithFormat:@"∫₁^(e^%ld) ln x / x dx", (long)k],
                              [NSString stringWithFormat:@"\\int_{1}^{e^{%ld}} \\frac{\\ln x}{x}\\,dx", (long)k], k * k / 2);
        }
    }
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
    if (level >= 23) [types addObject:@"limit"];
    if (level >= 24) [types addObjectsFromArray:@[@"sum", @"binomial", @"determinant2"]];
    if (level >= 25) [types addObjectsFromArray:@[@"laplace", @"advancedIntegral"]];
    if (level >= 26) [types addObject:@"modular"];
    if (level >= 27) [types addObject:@"complex"];
    if (level >= 28) [types addObjectsFromArray:@[@"determinant3", @"trace"]];

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
    if ([type isEqualToString:@"limit"]) return [self limitProblem];
    if ([type isEqualToString:@"sum"]) return [self sumProblem];
    if ([type isEqualToString:@"binomial"]) return [self binomialProblem];
    if ([type isEqualToString:@"determinant2"]) return [self determinant2Problem];
    if ([type isEqualToString:@"determinant3"]) return [self determinant3Problem];
    if ([type isEqualToString:@"trace"]) return [self traceProblem];
    if ([type isEqualToString:@"laplace"]) return [self laplaceProblem];
    if ([type isEqualToString:@"advancedIntegral"]) return [self advancedIntegralProblem];
    if ([type isEqualToString:@"modular"]) return [self modularProblem];
    if ([type isEqualToString:@"complex"]) return [self complexProblem];

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
