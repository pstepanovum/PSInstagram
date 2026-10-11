#import "../../Utils.h"
#import "../../Settings/PSISettingsBackup.h"
#import "PSIMathGame.h"
#import "PSIBrainBreak.h"
#import "PSIWordGameView.h"
#import "PSIPatternGameView.h"
#import "MTMathUILabel.h"
#import "MTFont.h"
#import "MTFontManager.h"

// Mental math game in place of the (hidden) home feed

// Problems are typeset from LaTeX with iosMath. A tweak has no bundle of its own, so iosMath would look for its
// fonts in Instagram's; dev.sh ships them in PSIMath.bundle inside the app instead
%hook MTFont
+ (NSBundle *)fontBundle {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"PSIMath" ofType:@"bundle"];
    return (path ? [NSBundle bundleWithPath:path] : nil) ?: %orig;
}
%end

static CGFloat const PSIMathFontSize = 40;
static CGFloat const PSIMathMinFontSize = 20;

@interface PSIMathGameView : UIView <UITextFieldDelegate>
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UIProgressView *progressView;
@property (nonatomic, strong) UILabel *problemLabel;
@property (nonatomic, strong) MTMathUILabel *mathLabel;
@property (nonatomic, strong) UITextField *answerField;
@property (nonatomic, strong) UILabel *feedbackLabel;
@property (nonatomic, strong) PSIMathProblem *problem;
@property (nonatomic) BOOL locked;
@end

@implementation PSIMathGameView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (!self) return nil;

    self.statusLabel = [UILabel new];
    self.statusLabel.font = [UIFont monospacedDigitSystemFontOfSize:13 weight:UIFontWeightRegular];
    self.statusLabel.textColor = [UIColor secondaryLabelColor];

    self.progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    self.progressView.tintColor = [UIColor systemBlueColor];
    [self.progressView.widthAnchor constraintEqualToConstant:180].active = YES;

    self.problemLabel = [UILabel new];
    self.problemLabel.font = [UIFont monospacedDigitSystemFontOfSize:44 weight:UIFontWeightBold];
    self.problemLabel.textColor = [UIColor labelColor];
    self.problemLabel.adjustsFontSizeToFitWidth = YES;
    self.problemLabel.minimumScaleFactor = 0.5;

    self.mathLabel = [MTMathUILabel new];
    self.mathLabel.labelMode = kMTMathUILabelModeDisplay;
    self.mathLabel.textAlignment = kMTTextAlignmentCenter;
    self.mathLabel.textColor = [UIColor labelColor];
    self.mathLabel.fontSize = PSIMathFontSize;

    self.answerField = [UITextField new];
    self.answerField.keyboardType = UIKeyboardTypeNumberPad;
    self.answerField.textAlignment = NSTextAlignmentCenter;
    self.answerField.font = [UIFont monospacedDigitSystemFontOfSize:32 weight:UIFontWeightSemibold];
    self.answerField.placeholder = @"?";
    self.answerField.backgroundColor = [UIColor secondarySystemBackgroundColor];
    self.answerField.layer.cornerRadius = 14;
    self.answerField.delegate = self;
    [self.answerField addTarget:self action:@selector(answerChanged) forControlEvents:UIControlEventEditingChanged];
    [self.answerField.widthAnchor constraintEqualToConstant:180].active = YES;
    [self.answerField.heightAnchor constraintEqualToConstant:60].active = YES;

    self.feedbackLabel = [UILabel new];
    self.feedbackLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
    self.feedbackLabel.text = @" ";

    UIButton *checkButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [checkButton setTitle:@"Check" forState:UIControlStateNormal];
    checkButton.titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
    [checkButton addTarget:self action:@selector(checkAnswer) forControlEvents:UIControlEventTouchUpInside];

    UIButton *skipButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [skipButton setTitle:@"Skip" forState:UIControlStateNormal];
    skipButton.tintColor = [UIColor secondaryLabelColor];
    [skipButton addTarget:self action:@selector(skipProblem) forControlEvents:UIControlEventTouchUpInside];

    UIStackView *buttons = [[UIStackView alloc] initWithArrangedSubviews:@[skipButton, checkButton]];
    buttons.spacing = 32;

    UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[self.statusLabel, self.progressView, self.mathLabel, self.problemLabel, self.answerField, self.feedbackLabel, buttons]];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.alignment = UIStackViewAlignmentCenter;
    stack.spacing = 12;
    [stack setCustomSpacing:24 afterView:self.progressView];
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:stack];

    [NSLayoutConstraint activateConstraints:@[
        [stack.topAnchor constraintEqualToAnchor:self.topAnchor],
        [stack.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
        [stack.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [stack.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [self.problemLabel.widthAnchor constraintLessThanOrEqualToAnchor:stack.widthAnchor],
        [self.mathLabel.widthAnchor constraintLessThanOrEqualToAnchor:stack.widthAnchor]
    ]];

    // Tapping around the game closes the keyboard
    [self addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)]];

    [self nextProblem];

    return self;
}

// Typeset the LaTeX version, shrinking it to fit; fall back to the plain text if it can't be typeset
- (void)showProblem {
    self.problemLabel.text = self.problem.text;

    self.mathLabel.fontSize = PSIMathFontSize;
    self.mathLabel.latex = self.problem.latex;

    CGFloat maxWidth = UIScreen.mainScreen.bounds.size.width - 48;
    while (self.mathLabel.intrinsicContentSize.width > maxWidth && self.mathLabel.fontSize > PSIMathMinFontSize) {
        self.mathLabel.fontSize -= 2;
    }

    // The display list is only built during layout, so check that the LaTeX parsed and the math font loaded
    BOOL typeset = self.problem.latex.length > 0 && !self.mathLabel.error && self.mathLabel.mathList && [MTFontManager fontManager].defaultFont;
    if (!typeset) PSILog(@"Showing plain text: latex error %@, font %@", self.mathLabel.error, [MTFontManager fontManager].defaultFont);
    self.mathLabel.hidden = !typeset;
    self.problemLabel.hidden = typeset;
}

// The label draws with a fixed color, so redraw it when switching between light and dark mode
- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];

    self.mathLabel.textColor = [[UIColor labelColor] resolvedColorWithTraitCollection:self.traitCollection];
}

- (void)updateStatus {
    self.statusLabel.text = [NSString stringWithFormat:@"Level %ld · %ld/%ld · streak %ld",
        (long)PSIMathGame.level, (long)PSIMathGame.levelProgress, (long)PSIMathGame.answersPerLevel, (long)PSIMathGame.streak];

    [self.progressView setProgress:(float)PSIMathGame.levelProgress / PSIMathGame.answersPerLevel animated:YES];
}

- (void)nextProblem {
    self.problem = [PSIMathGame newProblem];
    [self showProblem];
    self.answerField.text = @"";
    self.locked = NO;

    [self updateStatus];
}

- (void)showFeedback:(NSString *)text color:(UIColor *)color thenNextAfter:(NSTimeInterval)delay {
    self.locked = YES;
    self.feedbackLabel.text = text;
    self.feedbackLabel.textColor = color;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        self.feedbackLabel.text = @" ";
        [self nextProblem];
        [[NSNotificationCenter defaultCenter] postNotificationName:PSIBrainBreakPuzzleDoneNotification object:self];
    });
}

// A correct answer is accepted as soon as it's typed
- (void)answerChanged {
    if (self.locked || self.answerField.text.integerValue != self.problem.answer || self.answerField.text.length == 0) return;

    BOOL leveledUp = [PSIMathGame recordCorrectAnswer];
    [[UINotificationFeedbackGenerator new] notificationOccurred:UINotificationFeedbackTypeSuccess];

    if (leveledUp) {
        [PSISettingsBackup save];
        [self updateStatus];
        [self showFeedback:[NSString stringWithFormat:@"Level up! Level %ld", (long)PSIMathGame.level] color:[UIColor systemPurpleColor] thenNextAfter:1.2];
    }
    else {
        [self updateStatus];
        [self showFeedback:@"Nice!" color:[UIColor systemGreenColor] thenNextAfter:0.4];
    }
}

- (void)checkAnswer {
    if (self.locked || self.answerField.text.length == 0) return;
    if (self.answerField.text.integerValue == self.problem.answer) {
        [self answerChanged];
        return;
    }

    [self revealAnswer];
}

- (void)skipProblem {
    if (self.locked) return;

    [self revealAnswer];
}

- (void)revealAnswer {
    [PSIMathGame recordWrongAnswer];
    [[UINotificationFeedbackGenerator new] notificationOccurred:UINotificationFeedbackTypeError];

    [self updateStatus];

    NSString *solution = [self.problem.text containsString:@"?"]
        ? [NSString stringWithFormat:@"? = %ld", (long)self.problem.answer]
        : [NSString stringWithFormat:@"= %ld", (long)self.problem.answer];
    [self showFeedback:solution color:[UIColor systemRedColor] thenNextAfter:1.5];
}

- (void)dismissKeyboard {
    [self endEditing:YES];
}

// Digits only, and nothing absurdly long
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSCharacterSet *nonDigits = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
    return [string rangeOfCharacterFromSet:nonDigits].location == NSNotFound && textField.text.length - range.length + string.length <= 9;
}

@end

///////////////////////////////////////////////////////////

// "Brain break" header: Shuffle (a random game after every puzzle), or one game to stay on
static NSString *const PSIBrainBreakModeKey = @"brain_break_mode";

typedef NS_ENUM(NSInteger, PSIBrainBreakMode) {
    PSIBrainBreakModeShuffle = 0,
    PSIBrainBreakModeMath,
    PSIBrainBreakModeWords,
    PSIBrainBreakModeIQ
};

@interface PSIBrainBreakView : UIView
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) NSArray<UIView *> *games;
// Games switched on in settings (indexes into games), and the modes the picker offers for them
@property (nonatomic, strong) NSArray<NSNumber *> *enabledGames;
@property (nonatomic, strong) NSArray<NSNumber *> *pickerModes;
@property (nonatomic) PSIBrainBreakMode mode;
@property (nonatomic) NSInteger currentGame;
@end

@implementation PSIBrainBreakView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (!self) return nil;

    self.titleLabel = [UILabel new];
    self.titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
    self.titleLabel.textColor = [UIColor secondaryLabelColor];

    // Games can be switched off in settings; with none on, Math stays
    NSArray *gameKeys = @[@"brain_break_math", @"brain_break_words", @"brain_break_iq"];
    NSArray *gameNames = @[@"Math", @"Words", @"IQ"];
    NSMutableArray *enabled = [NSMutableArray array];
    for (NSUInteger i = 0; i < gameKeys.count; i++) {
        if ([PSIUtils getBoolPref:gameKeys[i]]) [enabled addObject:@(i)];
    }
    if (enabled.count == 0) [enabled addObject:@0];
    self.enabledGames = enabled;

    // Shuffle only makes sense with two or more games; with one, there's no picker at all
    NSMutableArray *modes = [NSMutableArray array];
    NSMutableArray *items = [NSMutableArray array];
    if (enabled.count > 1) {
        [modes addObject:@(PSIBrainBreakModeShuffle)];
        [items addObject:@"Shuffle"];
    }
    for (NSNumber *game in enabled) {
        [modes addObject:@(game.integerValue + 1)];
        [items addObject:gameNames[game.integerValue]];
    }
    self.pickerModes = modes;

    NSInteger savedMode = [[NSUserDefaults standardUserDefaults] integerForKey:PSIBrainBreakModeKey];
    self.mode = [modes containsObject:@(savedMode)] ? savedMode : [modes.firstObject integerValue];

    UISegmentedControl *picker = [[UISegmentedControl alloc] initWithItems:items];
    picker.selectedSegmentIndex = [modes indexOfObject:@(self.mode)];
    picker.hidden = modes.count < 2;
    [picker addTarget:self action:@selector(modeChanged:) forControlEvents:UIControlEventValueChanged];
    [picker.widthAnchor constraintEqualToConstant:MIN(300, 75 * items.count)].active = YES;

    self.games = @[[PSIMathGameView new], [PSIWordGameView new], [PSIPatternGameView new]];

    UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:[@[self.titleLabel, picker] arrayByAddingObjectsFromArray:self.games]];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.alignment = UIStackViewAlignmentCenter;
    stack.spacing = 12;
    [stack setCustomSpacing:20 afterView:picker];
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:stack];

    NSMutableArray *constraints = [@[
        [stack.topAnchor constraintEqualToAnchor:self.topAnchor],
        [stack.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
        [stack.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [stack.trailingAnchor constraintEqualToAnchor:self.trailingAnchor]
    ] mutableCopy];
    for (UIView *game in self.games) [constraints addObject:[game.widthAnchor constraintEqualToAnchor:stack.widthAnchor]];
    [NSLayoutConstraint activateConstraints:constraints];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(puzzleDone) name:PSIBrainBreakPuzzleDoneNotification object:nil];

    self.currentGame = -1;
    [self applyMode];

    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)modeChanged:(UISegmentedControl *)picker {
    self.mode = [self.pickerModes[picker.selectedSegmentIndex] integerValue];
    [[NSUserDefaults standardUserDefaults] setInteger:self.mode forKey:PSIBrainBreakModeKey];
    [self applyMode];
}

- (void)applyMode {
    if (self.mode == PSIBrainBreakModeShuffle) [self showRandomGame];
    else [self showGame:self.mode - 1];
}

// Shuffle moves on to a different game after every puzzle
- (void)puzzleDone {
    if (self.mode == PSIBrainBreakModeShuffle) [self showRandomGame];
}

- (void)showRandomGame {
    NSInteger game;
    do {
        game = [self.enabledGames[arc4random_uniform((uint32_t)self.enabledGames.count)] integerValue];
    } while (game == self.currentGame && self.enabledGames.count > 1);

    [self showGame:game];
}

- (void)showGame:(NSInteger)index {
    [self endEditing:YES];
    self.currentGame = index;

    for (NSUInteger i = 0; i < self.games.count; i++) self.games[i].hidden = (NSInteger)i != index;

    NSArray *names = @[@"Math", @"Words", @"IQ"];
    self.titleLabel.text = self.mode == PSIBrainBreakModeShuffle ? [NSString stringWithFormat:@"Brain break · %@", names[index]] : @"Brain break";
}

@end

///////////////////////////////////////////////////////////

@interface IGMainFeedViewController_objc : UIViewController
@end

static NSInteger const PSIMathGameViewTag = 0x5C1;

%hook IGMainFeedViewController_objc
- (void)viewDidLayoutSubviews {
    %orig;

    UIView *existing = [self.view viewWithTag:PSIMathGameViewTag];
    BOOL enabled = [PSIUtils getBoolPref:@"math_game"] && [PSIUtils getBoolPref:@"hide_entire_feed"];

    if (!enabled) {
        [existing removeFromSuperview];
        return;
    }

    if (existing) {
        [self.view bringSubviewToFront:existing];
        return;
    }

    NSLog(@"[PSInstagram] Adding brain break games to home feed");

    PSIBrainBreakView *game = [PSIBrainBreakView new];
    game.tag = PSIMathGameViewTag;
    game.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:game];

    // A scroll view's content moves, so pin to its frame instead
    UILayoutGuide *guide = [self.view isKindOfClass:[UIScrollView class]]
        ? ((UIScrollView *)self.view).frameLayoutGuide
        : self.view.safeAreaLayoutGuide;

    [NSLayoutConstraint activateConstraints:@[
        [game.centerXAnchor constraintEqualToAnchor:guide.centerXAnchor],
        [game.centerYAnchor constraintEqualToAnchor:guide.centerYAnchor constant:-60],
        [game.widthAnchor constraintEqualToAnchor:guide.widthAnchor constant:-32]
    ]];
}
%end
