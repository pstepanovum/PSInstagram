#import "PSIWordGameView.h"
#import "PSIWordGame.h"
#import "../../Settings/PSISettingsBackup.h"

static CGFloat const PSITileSize = 44;
static CGFloat const PSITileSpacing = 5;
static CGFloat const PSIKeyHeight = 44;
static CGFloat const PSIKeySpacing = 5;

static NSString *const PSIEnterKey = @"ENTER";
static NSString *const PSIDeleteKey = @"DELETE";

static UIColor *PSIColorForState(PSILetterState state) {
    switch (state) {
        case PSILetterStateCorrect: return [UIColor systemGreenColor];
        case PSILetterStatePresent: return [UIColor systemOrangeColor];
        case PSILetterStateAbsent: return [UIColor systemGrayColor];
        default: return [UIColor tertiarySystemFillColor];
    }
}

@interface PSIWordGameView ()
@property (nonatomic, strong) UILabel *statusLabel;
@property (nonatomic, strong) NSArray<NSArray<UILabel *> *> *tiles;
@property (nonatomic, strong) UILabel *messageLabel;
@property (nonatomic, strong) UIButton *defineButton;
@property (nonatomic, strong) UIButton *nextButton;
@property (nonatomic, strong) UIStackView *roundOverButtons;
@property (nonatomic, strong) NSMutableDictionary<NSString *, UIButton *> *keys;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *keyStates;
@property (nonatomic, strong) NSMutableString *currentGuess;
@end

@implementation PSIWordGameView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (!self) return nil;

    self.currentGuess = [NSMutableString string];
    self.keys = [NSMutableDictionary dictionary];
    self.keyStates = [NSMutableDictionary dictionary];

    self.statusLabel = [UILabel new];
    self.statusLabel.font = [UIFont monospacedDigitSystemFontOfSize:13 weight:UIFontWeightRegular];
    self.statusLabel.textColor = [UIColor secondaryLabelColor];

    self.messageLabel = [UILabel new];
    self.messageLabel.font = [UIFont systemFontOfSize:15 weight:UIFontWeightSemibold];
    self.messageLabel.text = @" ";

    self.defineButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.defineButton.titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
    [self.defineButton addTarget:self action:@selector(defineAnswer) forControlEvents:UIControlEventTouchUpInside];

    self.nextButton = [UIButton buttonWithType:UIButtonTypeSystem];
    self.nextButton.titleLabel.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
    [self.nextButton setTitle:@"Next word" forState:UIControlStateNormal];
    [self.nextButton addTarget:self action:@selector(nextWord) forControlEvents:UIControlEventTouchUpInside];

    self.roundOverButtons = [[UIStackView alloc] initWithArrangedSubviews:@[self.defineButton, self.nextButton]];
    self.roundOverButtons.spacing = 32;

    UIView *keyboard = [self makeKeyboard];
    UIStackView *stack = [[UIStackView alloc] initWithArrangedSubviews:@[self.statusLabel, [self makeBoard], self.messageLabel, self.roundOverButtons, keyboard]];
    stack.axis = UILayoutConstraintAxisVertical;
    stack.alignment = UIStackViewAlignmentCenter;
    stack.spacing = 10;
    stack.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:stack];

    [NSLayoutConstraint activateConstraints:@[
        [stack.topAnchor constraintEqualToAnchor:self.topAnchor],
        [stack.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
        [stack.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [stack.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [keyboard.widthAnchor constraintEqualToAnchor:stack.widthAnchor]
    ]];

    [self reloadRound];

    return self;
}

- (UIView *)makeBoard {
    NSMutableArray *rows = [NSMutableArray array];
    NSMutableArray *rowViews = [NSMutableArray array];

    for (NSInteger row = 0; row < PSIWordGame.maxGuesses; row++) {
        NSMutableArray *rowTiles = [NSMutableArray array];

        for (NSInteger column = 0; column < PSIWordGame.wordLength; column++) {
            UILabel *tile = [UILabel new];
            tile.textAlignment = NSTextAlignmentCenter;
            tile.font = [UIFont systemFontOfSize:24 weight:UIFontWeightBold];
            tile.layer.cornerRadius = 6;
            tile.layer.borderWidth = 2;
            tile.clipsToBounds = YES;
            [tile.widthAnchor constraintEqualToConstant:PSITileSize].active = YES;
            [tile.heightAnchor constraintEqualToConstant:PSITileSize].active = YES;
            [rowTiles addObject:tile];
        }

        UIStackView *rowView = [[UIStackView alloc] initWithArrangedSubviews:rowTiles];
        rowView.spacing = PSITileSpacing;
        [rowViews addObject:rowView];
        [rows addObject:rowTiles];
    }

    self.tiles = rows;

    UIStackView *board = [[UIStackView alloc] initWithArrangedSubviews:rowViews];
    board.axis = UILayoutConstraintAxisVertical;
    board.spacing = PSITileSpacing;
    return board;
}

- (UIView *)makeKeyboard {
    NSArray *layout = @[@"QWERTYUIOP", @"ASDFGHJKL", @"ZXCVBNM"];
    NSMutableArray *rowViews = [NSMutableArray array];
    NSMutableArray<NSLayoutConstraint *> *widths = [NSMutableArray array];
    UIButton *referenceKey;

    for (NSUInteger rowIndex = 0; rowIndex < layout.count; rowIndex++) {
        NSString *letters = layout[rowIndex];
        NSMutableArray *rowKeys = [NSMutableArray array];

        if (rowIndex == layout.count - 1) [rowKeys addObject:[self makeKey:PSIEnterKey]];

        for (NSUInteger i = 0; i < letters.length; i++) {
            UIButton *key = [self makeKey:[letters substringWithRange:NSMakeRange(i, 1)]];

            // Every letter key is as wide as the first one, which the top row stretches to fit
            if (referenceKey) [widths addObject:[key.widthAnchor constraintEqualToAnchor:referenceKey.widthAnchor]];
            else referenceKey = key;

            [rowKeys addObject:key];
        }

        if (rowIndex == layout.count - 1) [rowKeys addObject:[self makeKey:PSIDeleteKey]];

        UIStackView *rowView = [[UIStackView alloc] initWithArrangedSubviews:rowKeys];
        rowView.spacing = PSIKeySpacing;
        [rowViews addObject:rowView];
    }

    for (NSString *special in @[PSIEnterKey, PSIDeleteKey]) {
        [widths addObject:[self.keys[special].widthAnchor constraintEqualToAnchor:referenceKey.widthAnchor multiplier:1.5 constant:PSIKeySpacing / 2]];
    }

    UIStackView *keyboard = [[UIStackView alloc] initWithArrangedSubviews:rowViews];
    keyboard.axis = UILayoutConstraintAxisVertical;
    keyboard.alignment = UIStackViewAlignmentCenter;
    keyboard.spacing = PSIKeySpacing + 3;

    // The top row spans the keyboard, which spans the view
    [rowViews.firstObject setDistribution:UIStackViewDistributionFillEqually];
    [widths addObject:[((UIView *)rowViews.firstObject).widthAnchor constraintEqualToAnchor:keyboard.widthAnchor]];

    // Only now do the keys share a superview
    [NSLayoutConstraint activateConstraints:widths];

    return keyboard;
}

- (UIButton *)makeKey:(NSString *)name {
    UIButton *key = [UIButton buttonWithType:UIButtonTypeSystem];
    key.backgroundColor = PSIColorForState(PSILetterStateUnknown);
    key.layer.cornerRadius = 6;
    key.tintColor = [UIColor labelColor];
    key.accessibilityLabel = name.capitalizedString;
    [key.heightAnchor constraintEqualToConstant:PSIKeyHeight].active = YES;

    if ([name isEqualToString:PSIDeleteKey]) {
        [key setImage:[UIImage systemImageNamed:@"delete.left"] forState:UIControlStateNormal];
    }
    else {
        [key setTitle:name forState:UIControlStateNormal];
        key.titleLabel.font = [UIFont systemFontOfSize:name.length > 1 ? 12 : 18 weight:UIFontWeightSemibold];
    }

    [key addTarget:self action:@selector(keyTapped:) forControlEvents:UIControlEventTouchUpInside];
    self.keys[name] = key;

    return key;
}

///////////////////////////////////////////////////////////

- (void)reloadRound {
    [self.currentGuess setString:@""];
    [self.keyStates removeAllObjects];

    for (UIButton *key in self.keys.allValues) {
        key.backgroundColor = PSIColorForState(PSILetterStateUnknown);
        key.tintColor = [UIColor labelColor];
    }

    NSArray<NSString *> *guesses = PSIWordGame.guesses;
    for (NSInteger row = 0; row < PSIWordGame.maxGuesses; row++) {
        NSString *guess = row < (NSInteger)guesses.count ? guesses[row] : nil;
        [self showWord:guess ?: @"" inRow:row states:guess ? [PSIWordGame statesForGuess:guess] : nil];
    }

    [self showRoundState];
}

- (void)showWord:(NSString *)word inRow:(NSInteger)row states:(nullable NSArray<NSNumber *> *)states {
    for (NSInteger column = 0; column < PSIWordGame.wordLength; column++) {
        UILabel *tile = self.tiles[row][column];
        BOOL hasLetter = column < (NSInteger)word.length;
        tile.text = hasLetter ? [word substringWithRange:NSMakeRange(column, 1)] : @"";

        if (states) {
            PSILetterState state = states[column].integerValue;
            tile.backgroundColor = PSIColorForState(state);
            tile.layer.borderColor = PSIColorForState(state).CGColor;
            tile.textColor = [UIColor whiteColor];

            // Keys show the best result a letter has had so far
            UIButton *key = self.keys[tile.text];
            if (state > self.keyStates[tile.text].integerValue) {
                self.keyStates[tile.text] = @(state);
                key.backgroundColor = PSIColorForState(state);
                key.tintColor = [UIColor whiteColor];
            }
        }
        else {
            tile.backgroundColor = [UIColor clearColor];
            tile.layer.borderColor = (hasLetter ? [UIColor secondaryLabelColor] : [UIColor tertiarySystemFillColor]).CGColor;
            tile.textColor = [UIColor labelColor];
        }
    }
}

- (void)showRoundState {
    self.statusLabel.text = [NSString stringWithFormat:@"%ld won · streak %ld", (long)PSIWordGame.won, (long)PSIWordGame.streak];

    BOOL over = PSIWordGame.isRoundOver;
    self.roundOverButtons.hidden = !over;
    [self.defineButton setTitle:[NSString stringWithFormat:@"Define %@", PSIWordGame.answer.lowercaseString] forState:UIControlStateNormal];

    if (!over) {
        self.messageLabel.text = @" ";
    }
    else if (PSIWordGame.isRoundWon) {
        NSArray *praise = @[@"Genius!", @"Brilliant!", @"Impressive!", @"Great!", @"Nice!", @"Phew!"];
        self.messageLabel.text = praise[MIN(PSIWordGame.guesses.count, praise.count) - 1];
        self.messageLabel.textColor = [UIColor systemGreenColor];
    }
    else {
        self.messageLabel.text = [NSString stringWithFormat:@"The word was %@", PSIWordGame.answer];
        self.messageLabel.textColor = [UIColor labelColor];
    }
}

- (void)showMessage:(NSString *)message {
    self.messageLabel.text = message;
    self.messageLabel.textColor = [UIColor systemRedColor];

    // Shake the row being typed
    UIView *row = self.tiles[PSIWordGame.guesses.count].firstObject.superview;
    CAKeyframeAnimation *shake = [CAKeyframeAnimation animationWithKeyPath:@"transform.translation.x"];
    shake.values = @[@0, @-8, @8, @-6, @6, @0];
    shake.duration = 0.35;
    [row.layer addAnimation:shake forKey:@"shake"];
    [[UINotificationFeedbackGenerator new] notificationOccurred:UINotificationFeedbackTypeError];
}

///////////////////////////////////////////////////////////

- (void)keyTapped:(UIButton *)key {
    if (PSIWordGame.isRoundOver) return;

    NSString *name = [self.keys allKeysForObject:key].firstObject;
    NSInteger row = PSIWordGame.guesses.count;

    if ([name isEqualToString:PSIEnterKey]) {
        [self submitGuess];
        return;
    }

    if ([name isEqualToString:PSIDeleteKey]) {
        if (self.currentGuess.length > 0) [self.currentGuess deleteCharactersInRange:NSMakeRange(self.currentGuess.length - 1, 1)];
    }
    else if ((NSInteger)self.currentGuess.length < PSIWordGame.wordLength) {
        [self.currentGuess appendString:name];
        [[UISelectionFeedbackGenerator new] selectionChanged];
    }

    self.messageLabel.text = @" ";
    [self showWord:self.currentGuess inRow:row states:nil];
}

- (void)submitGuess {
    if ((NSInteger)self.currentGuess.length < PSIWordGame.wordLength) {
        [self showMessage:@"Not enough letters"];
        return;
    }

    if (![PSIWordGame isValidWord:self.currentGuess]) {
        [self showMessage:@"Not in the dictionary"];
        return;
    }

    NSInteger row = PSIWordGame.guesses.count;
    NSString *guess = [self.currentGuess copy];
    NSArray *states = [PSIWordGame submitGuess:guess];
    [self.currentGuess setString:@""];

    [self showWord:guess inRow:row states:states];
    [self showRoundState];

    if (PSIWordGame.isRoundOver) {
        [PSISettingsBackup save];
        [[UINotificationFeedbackGenerator new] notificationOccurred:PSIWordGame.isRoundWon ? UINotificationFeedbackTypeSuccess : UINotificationFeedbackTypeWarning];
    }
}

- (void)nextWord {
    [PSIWordGame startNewRound];
    [self reloadRound];
}

// iOS's built-in dictionary, so every round teaches a word
- (void)defineAnswer {
    UIResponder *responder = self.nextResponder;
    while (responder && ![responder isKindOfClass:[UIViewController class]]) responder = responder.nextResponder;

    UIReferenceLibraryViewController *dictionary = [[UIReferenceLibraryViewController alloc] initWithTerm:PSIWordGame.answer.lowercaseString];
    [(UIViewController *)responder presentViewController:dictionary animated:YES completion:nil];
}

@end
