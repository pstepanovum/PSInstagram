#import "PSIPatternGameView.h"
#import "PSIPatternGame.h"
#import "PSIBrainBreak.h"
#import "../../Settings/PSISettingsBackup.h"
#import "MTMathUILabel.h"
#import "MTFontManager.h"

static CGFloat const PSIPatternFontSize = 34;
static CGFloat const PSIPatternMinFontSize = 18;

@interface PSIPatternGameView () <UITextFieldDelegate>
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UIProgressView *progressView;
@property (nonatomic, strong) UILabel *instructionLabel;
@property (nonatomic, strong) MTMathUILabel *sequenceLabel;
@property (nonatomic, strong) UILabel *plainLabel;
@property (nonatomic, strong) UIProgressView *timerView;
@property (nonatomic, strong) UITextField *answerField;
@property (nonatomic, strong) UILabel *feedbackLabel;
@property (nonatomic, strong) PSIPatternPuzzle *puzzle;
@property (nonatomic) BOOL locked;
@property (nonatomic) NSInteger puzzleID;
@end

@implementation PSIPatternGameView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (!self) return nil;

    self.statusLabel = [UILabel new];
    self.statusLabel.font = [UIFont monospacedDigitSystemFontOfSize:13 weight:UIFontWeightRegular];
    self.statusLabel.textColor = [UIColor secondaryLabelColor];

    self.progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    self.progressView.tintColor = [UIColor systemOrangeColor];
    [self.progressView.widthAnchor constraintEqualToConstant:180].active = YES;

    self.instructionLabel = [UILabel new];
    self.instructionLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
    self.instructionLabel.textColor = [UIColor secondaryLabelColor];

    self.sequenceLabel = [MTMathUILabel new];
    self.sequenceLabel.labelMode = kMTMathUILabelModeDisplay;
    self.sequenceLabel.textAlignment = kMTTextAlignmentCenter;
    self.sequenceLabel.textColor = [UIColor labelColor];

    self.plainLabel = [UILabel new];
    self.plainLabel.font = [UIFont monospacedDigitSystemFontOfSize:40 weight:UIFontWeightBold];
    self.plainLabel.textColor = [UIColor labelColor];
    self.plainLabel.textAlignment = NSTextAlignmentCenter;
    self.plainLabel.adjustsFontSizeToFitWidth = YES;
    self.plainLabel.minimumScaleFactor = 0.4;

    self.timerView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
    self.timerView.tintColor = [UIColor systemOrangeColor];
    [self.timerView.widthAnchor constraintEqualToConstant:120].active = YES;

    self.answerField = [UITextField new];
    self.answerField.keyboardType = UIKeyboardTypeNumberPad;
    self.answerField.textAlignment = NSTextAlignmentCenter;
    self.answerField.font = [UIFont monospacedDigitSystemFontOfSize:28 weight:UIFontWeightSemibold];
    self.answerField.placeholder = @"?";
    self.answerField.backgroundColor = [UIColor secondarySystemBackgroundColor];
    self.answerField.layer.cornerRadius = 14;
    self.answerField.delegate = self;
    [self.answerField addTarget:self action:@selector(answerChanged) forControlEvents:UIControlEventEditingChanged];
    [self.answerField.widthAnchor constraintEqualToConstant:220].active = YES;
    [self.answerField.heightAnchor constraintEqualToConstant:60].active = YES;

    self.feedbackLabel = [UILabel new];
    self.feedbackLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
    self.feedbackLabel.numberOfLines = 2;
    self.feedbackLabel.textAlignment = NSTextAlignmentCenter;
    self.feedbackLabel.text = @" ";

    UIButton *checkButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [checkButton setTitle:@"Check" forState:UIControlStateNormal];
    checkButton.titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
    [checkButton addTarget:self action:@selector(checkAnswer) forControlEvents:UIControlEventTouchUpInside];

    UIButton *skipButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [skipButton setTitle:@"Skip" forState:UIControlStateNormal];
    skipButton.tintColor = [UIColor secondaryLabelColor];
    [skipButton addTarget:self action:@selector(skipPuzzle) forControlEvents:UIControlEventTouchUpInside];

    UIStackView *buttons = [[UIStackView alloc] initWithArrangedSubviews:@[skipButton, checkButton]];
    buttons.spacing = 32;

    UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[self.statusLabel, self.progressView, self.instructionLabel, self.sequenceLabel, self.plainLabel, self.timerView, self.answerField, self.feedbackLabel, buttons]];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.alignment = UIStackViewAlignmentCenter;
    stack.spacing = 12;
    [stack setCustomSpacing:20 afterView:self.progressView];
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:stack];

    [NSLayoutConstraint activateConstraints:@[
        [stack.topAnchor constraintEqualToAnchor:self.topAnchor],
        [stack.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
        [stack.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [stack.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [self.sequenceLabel.widthAnchor constraintLessThanOrEqualToAnchor:stack.widthAnchor],
        [self.plainLabel.widthAnchor constraintLessThanOrEqualToAnchor:stack.widthAnchor],
        [self.feedbackLabel.widthAnchor constraintLessThanOrEqualToAnchor:stack.widthAnchor]
    ]];

    // Tapping around the game closes the keyboard
    [self addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)]];

    [self nextPuzzle];

    return self;
}

- (void)updateStatus {
    self.statusLabel.text = [NSString stringWithFormat:@"Level %ld · %ld/%ld · streak %ld",
        (long)PSIPatternGame.level, (long)PSIPatternGame.levelProgress, (long)PSIPatternGame.answersPerLevel, (long)PSIPatternGame.streak];

    [self.progressView setProgress:(float)PSIPatternGame.levelProgress / PSIPatternGame.answersPerLevel animated:YES];
}

- (void)nextPuzzle {
    self.puzzle = [PSIPatternGame newPuzzle];
    self.puzzleID++;
    self.answerField.text = @"";
    self.locked = NO;

    if (self.puzzle.kind == PSIPatternKindDigitSpan) [self showDigits];
    else [self showSequence];

    [self updateStatus];
}

// Typeset the terms, shrinking them to fit; fall back to plain text if they can't be typeset
- (void)showSequence {
    self.instructionLabel.text = @"What comes next?";
    self.timerView.hidden = YES;
    self.answerField.enabled = YES;
    self.plainLabel.text = self.puzzle.text;

    self.sequenceLabel.fontSize = PSIPatternFontSize;
    self.sequenceLabel.latex = self.puzzle.latex;

    CGFloat maxWidth = UIScreen.mainScreen.bounds.size.width - 48;
    while (self.sequenceLabel.intrinsicContentSize.width > maxWidth && self.sequenceLabel.fontSize > PSIPatternMinFontSize) {
        self.sequenceLabel.fontSize -= 2;
    }

    BOOL typeset = !self.sequenceLabel.error && self.sequenceLabel.mathList && [MTFontManager fontManager].defaultFont;
    self.sequenceLabel.hidden = !typeset;
    self.plainLabel.hidden = typeset;
}

// Show the number with a countdown, then hide it and ask for it
- (void)showDigits {
    self.instructionLabel.text = @"Remember this number";
    self.sequenceLabel.hidden = YES;
    self.plainLabel.hidden = NO;
    self.plainLabel.text = self.puzzle.text;

    self.answerField.enabled = NO;
    [self endEditing:YES];

    self.timerView.hidden = NO;
    [self.timerView setProgress:1 animated:NO];

    NSInteger puzzleID = self.puzzleID;
    NSDate *start = [NSDate date];
    NSTimeInterval duration = self.puzzle.displaySeconds;
    [NSTimer scheduledTimerWithTimeInterval:0.05 repeats:YES block:^(NSTimer *timer) {
        NSTimeInterval elapsed = -start.timeIntervalSinceNow;
        if (puzzleID != self.puzzleID || elapsed >= duration) {
            [timer invalidate];
            return;
        }

        [self.timerView setProgress:1 - elapsed / duration animated:NO];
    }];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(self.puzzle.displaySeconds * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // The player may have skipped or moved on in the meantime
        if (puzzleID != self.puzzleID) return;

        self.timerView.hidden = YES;
        self.plainLabel.text = [@"" stringByPaddingToLength:self.puzzle.text.length withString:@"•" startingAtIndex:0];
        self.instructionLabel.text = self.puzzle.reversed ? @"Now type it backwards" : @"Now type it";
        self.answerField.enabled = YES;
    });
}

// A digit span can start while the game is hidden (Shuffle shows another game first), so show the number again
// from the start once the game becomes visible, unless it's already been answered
- (void)setHidden:(BOOL)hidden {
    BOOL appearing = self.hidden && !hidden;
    [super setHidden:hidden];

    if (appearing && self.puzzle.kind == PSIPatternKindDigitSpan && !self.locked) {
        self.puzzleID++;
        self.answerField.text = @"";
        [self showDigits];
    }
}

// The label draws with a fixed color, so redraw it when switching between light and dark mode
- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];

    self.sequenceLabel.textColor = [[UIColor labelColor] resolvedColorWithTraitCollection:self.traitCollection];
}

- (void)showFeedback:(NSString *)text color:(UIColor *)color thenNextAfter:(NSTimeInterval)delay {
    self.locked = YES;
    self.feedbackLabel.text = text;
    self.feedbackLabel.textColor = color;

    NSInteger puzzleID = self.puzzleID;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (puzzleID != self.puzzleID) return;

        self.feedbackLabel.text = @" ";
        [self nextPuzzle];
        [[NSNotificationCenter defaultCenter] postNotificationName:PSIBrainBreakPuzzleDoneNotification object:self];
    });
}

// A correct answer is accepted as soon as it's typed
- (void)answerChanged {
    if (self.locked || ![self.answerField.text isEqualToString:self.puzzle.answer]) return;

    BOOL leveledUp = [PSIPatternGame recordCorrectAnswer];
    [[UINotificationFeedbackGenerator new] notificationOccurred:UINotificationFeedbackTypeSuccess];
    [self updateStatus];

    if (leveledUp) {
        [PSISettingsBackup save];
        [self showFeedback:[NSString stringWithFormat:@"Level up! Level %ld", (long)PSIPatternGame.level] color:[UIColor systemPurpleColor] thenNextAfter:1.2];
    }
    else {
        [self showFeedback:@"Nice!" color:[UIColor systemGreenColor] thenNextAfter:0.4];
    }
}

- (void)checkAnswer {
    if (self.locked || !self.answerField.enabled || self.answerField.text.length == 0) return;
    if ([self.answerField.text isEqualToString:self.puzzle.answer]) {
        [self answerChanged];
        return;
    }

    [self revealAnswer];
}

- (void)skipPuzzle {
    if (self.locked) return;

    [self revealAnswer];
}

- (void)revealAnswer {
    [PSIPatternGame recordWrongAnswer];
    [[UINotificationFeedbackGenerator new] notificationOccurred:UINotificationFeedbackTypeError];
    [self updateStatus];

    NSString *solution;
    if (self.puzzle.kind == PSIPatternKindDigitSpan) {
        self.plainLabel.text = self.puzzle.text;
        solution = self.puzzle.reversed ? [NSString stringWithFormat:@"Backwards: %@", self.puzzle.answer] : [NSString stringWithFormat:@"It was %@", self.puzzle.answer];
    }
    else {
        solution = [NSString stringWithFormat:@"%@ · %@", self.puzzle.answer, self.puzzle.rule];
    }

    [self showFeedback:solution color:[UIColor systemRedColor] thenNextAfter:2.2];
}

- (void)dismissKeyboard {
    [self endEditing:YES];
}

// Digits only, and nothing absurdly long
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSCharacterSet *nonDigits = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
    return [string rangeOfCharacterFromSet:nonDigits].location == NSNotFound && textField.text.length - range.length + string.length <= 14;
}

@end
