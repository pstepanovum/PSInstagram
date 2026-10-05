#import "../../Utils.h"
#import "../../Settings/PSISettingsBackup.h"
#import "PSIMathGame.h"

// Mental math game in place of the (hidden) home feed

@interface PSIMathGameView : UIView <UITextFieldDelegate>
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) UIProgressView *progressView;
@property (nonatomic, strong) UILabel *problemLabel;
@property (nonatomic, strong) UITextField *answerField;
@property (nonatomic, strong) UILabel *feedbackLabel;
@property (nonatomic, strong) PSIMathProblem *problem;
@property (nonatomic) BOOL locked;
@end

@implementation PSIMathGameView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (!self) return nil;

    UILabel *titleLabel = [UILabel new];
    titleLabel.text = @"Brain break";
    titleLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
    titleLabel.textColor = [UIColor secondaryLabelColor];

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

    UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[titleLabel, self.statusLabel, self.progressView, self.problemLabel, self.answerField, self.feedbackLabel, buttons]];
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
        [self.problemLabel.widthAnchor constraintLessThanOrEqualToAnchor:stack.widthAnchor]
    ]];

    // Tapping around the game closes the keyboard
    [self addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)]];

    [self nextProblem];

    return self;
}

- (void)updateStatus {
    self.statusLabel.text = [NSString stringWithFormat:@"Level %ld · %ld/%ld · streak %ld",
        (long)PSIMathGame.level, (long)PSIMathGame.levelProgress, (long)PSIMathGame.answersPerLevel, (long)PSIMathGame.streak];

    [self.progressView setProgress:(float)PSIMathGame.levelProgress / PSIMathGame.answersPerLevel animated:YES];
}

- (void)nextProblem {
    self.problem = [PSIMathGame newProblem];
    self.problemLabel.text = self.problem.text;
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

    NSLog(@"[PSInstagram] Adding math game to home feed");

    PSIMathGameView *game = [PSIMathGameView new];
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
