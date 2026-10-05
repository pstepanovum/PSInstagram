#import "PSISettingsViewController.h"
#import "PSISettingsBackup.h"

static char rowStaticRef[] = "row";

@interface PSISettingsViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, copy) NSArray *sections;
@property (nonatomic) BOOL reduceMargin;

@end

///

@implementation PSISettingsViewController

- (instancetype)initWithTitle:(NSString *)title sections:(NSArray *)sections reduceMargin:(BOOL)reduceMargin {
    self = [super init];
    
    if (self) {
        self.title = title;
        self.reduceMargin = reduceMargin;
        
        // Exclude development cells from release builds
        NSMutableArray *mutableSections = [sections mutableCopy];
        
        [mutableSections enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(NSDictionary *section, NSUInteger index, BOOL *stop) {
        
            if ([section[@"header"] hasPrefix:@"_"] && [section[@"footer"] hasPrefix:@"_"]) {
                if (![[PSIUtils IGVersionString] isEqualToString:@"0.0.0"]) {
                    [mutableSections removeObjectAtIndex:index];
                }
            }

            else if ([section[@"header"] isEqualToString:@"Experimental"]) {
                if (![[PSIUtils IGVersionString] hasSuffix:@"-dev"]) {
                    [mutableSections removeObjectAtIndex:index];
                }
            }
            
        }];
        
        self.sections = [mutableSections copy];
    }
    
    
    return self;
}

- (instancetype)init {
    return [self initWithTitle:[PSITweakSettings title] sections:[PSITweakSettings sections] reduceMargin:YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.navigationController.navigationBar.prefersLargeTitles = NO;
    self.view.backgroundColor = UIColor.systemBackgroundColor;

    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleInsetGrouped];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.dataSource = self;
    self.tableView.contentInset = UIEdgeInsetsMake(self.reduceMargin ? -30 : -10, 0, 0, 0);
    self.tableView.delegate = self;

    [self.view addSubview:self.tableView];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if (![[[NSUserDefaults standardUserDefaults] objectForKey:@"PSInstagramFirstRun"] isEqualToString:PSIVersionString]) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"PSInstagram Settings Info"
                                                                       message:@"In the future: Hold down on the three lines at the top right of your profile page, to re-open PSInstagram settings."
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"I understand!"
                                                  style:UIAlertActionStyleDefault
                                                handler:nil]];
        
        UIViewController *presenter = self.presentingViewController;
        [presenter presentViewController:alert animated:YES completion:nil];
        
        // Done with first-time setup for this version
        [[NSUserDefaults standardUserDefaults] setValue:PSIVersionString forKey:@"PSInstagramFirstRun"];
    }
}

// MARK: - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    PSISetting *row = self.sections[indexPath.section][@"rows"][indexPath.row];
    if (!row) return nil;
    
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    UIListContentConfiguration *cellContentConfig = cell.defaultContentConfiguration;
    
    cellContentConfig.text = row.title;
    
    // Subtitle
    if (row.subtitle.length) {
        cellContentConfig.secondaryText = row.subtitle;
        cellContentConfig.textToSecondaryTextVerticalPadding = 4.5;
    }
    
    // Icon
    if (row.icon != nil) {
        cellContentConfig.image = [row.icon image];
        cellContentConfig.imageProperties.tintColor = row.icon.color;
    }
    
    // Image url
    if (row.imageUrl != nil) {
        [self loadImageFromURL:row.imageUrl atIndexPath:indexPath forTableView:tableView];
        
        cellContentConfig.imageToTextPadding = 14;
    }
    
    switch (row.type) {
        case PSITableCellStatic: {
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            break;
        }
            
        case PSITableCellLink: {
            cellContentConfig.textProperties.color = [UIColor systemBlueColor];
            cellContentConfig.textProperties.font = [UIFont systemFontOfSize:[UIFont preferredFontForTextStyle:UIFontTextStyleBody].pointSize
                                                                      weight:UIFontWeightMedium];
            
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
            
            UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"safari"]];
            imageView.tintColor = [UIColor systemGray3Color];
            cell.accessoryView = imageView;
            
            break;
        }
            
        case PSITableCellSwitch: {
            UISwitch *toggle = [UISwitch new];
            toggle.on = [[NSUserDefaults standardUserDefaults] boolForKey:row.defaultsKey];
            toggle.onTintColor = [PSIUtils PSIColor_Primary];
            
            objc_setAssociatedObject(toggle, rowStaticRef, row, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            
            [toggle addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
            
            cell.accessoryView = toggle;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            break;
        }
            
        case PSITableCellStepper: {
            UIStepper *stepper = [UIStepper new];
            stepper.minimumValue = row.min;
            stepper.maximumValue = row.max;
            stepper.stepValue = row.step;
            stepper.value = [[NSUserDefaults standardUserDefaults] doubleForKey:row.defaultsKey];
            
            objc_setAssociatedObject(stepper, rowStaticRef, row, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            
            [stepper addTarget:self
                        action:@selector(stepperChanged:)
              forControlEvents:UIControlEventValueChanged];
            
            // Template subtitle
            if (row.subtitle.length) {
                cellContentConfig.secondaryText = [self formatString:row.subtitle withValue:stepper.value label:row.label singularLabel:row.singularLabel];
            }
            
            cell.accessoryView = stepper;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            break;
        }
            
        case PSITableCellButton: {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;
        }
            
        case PSITableCellMenu: {
            UIButton *menuButton = [UIButton buttonWithType:UIButtonTypeSystem];
            [menuButton setTitle:@"•••" forState:UIControlStateNormal];
            menuButton.menu = [row menuForButton:menuButton];
            menuButton.showsMenuAsPrimaryAction = YES;
            menuButton.titleLabel.font = [UIFont systemFontOfSize:[UIFont preferredFontForTextStyle:UIFontTextStyleBody].pointSize
                                                           weight:UIFontWeightMedium];
            
            UIButtonConfiguration *config = menuButton.configuration ?: [UIButtonConfiguration plainButtonConfiguration];
            menuButton.configuration.contentInsets = NSDirectionalEdgeInsetsMake(8, 8, 8, 8);
            menuButton.configuration = config;

            [menuButton sizeToFit];
            
            cell.accessoryView = menuButton;
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            break;
        }
            
        case PSITableCellNavigation: {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            break;
        }
    }
    
    cell.contentConfiguration = cellContentConfig;

    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.sections[section][@"rows"] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    return self.sections[section][@"header"];
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section {
    return self.sections[section][@"footer"];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.sections.count;
}

// MARK: - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    PSISetting *row = self.sections[indexPath.section][@"rows"][indexPath.row];
    if (!row) return;

    if (row.type == PSITableCellLink) {
        [[UIApplication sharedApplication] openURL:row.url options:@{} completionHandler:nil];
    }
    else if (row.type == PSITableCellButton) {
        if (row.action != nil) {
            row.action();
        }
    }
    else if (row.type == PSITableCellNavigation) {
        if (row.navSections.count > 0) {
            UIViewController *vc = [[PSISettingsViewController alloc] initWithTitle:row.title sections:row.navSections reduceMargin:NO];
            vc.title = row.title;
            [self.navigationController pushViewController:vc animated:YES];
        }
        else if (row.navViewController) {
            [self.navigationController pushViewController:row.navViewController animated:YES];
        }
    }

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

// MARK: - Actions

- (void)switchChanged:(UISwitch *)sender {
    PSISetting *row = objc_getAssociatedObject(sender, rowStaticRef);
    [[NSUserDefaults standardUserDefaults] setBool:sender.isOn forKey:row.defaultsKey];
    [PSISettingsBackup save];
    
    NSLog(@"Switch changed: %@", sender.isOn ? @"ON" : @"OFF");
    
    if (row.requiresRestart) {
        [PSIUtils showRestartConfirmation];
    }
}

- (void)stepperChanged:(UIStepper *)sender {
    PSISetting *row = objc_getAssociatedObject(sender, rowStaticRef);
    [[NSUserDefaults standardUserDefaults] setDouble:sender.value forKey:row.defaultsKey];
    [PSISettingsBackup save];
    
    NSLog(@"Stepper changed: %f", sender.value);
    
    [self reloadCellForView:sender];
}

- (void)menuChanged:(UICommand *)command {
    NSDictionary *properties = command.propertyList;
    
    [[NSUserDefaults standardUserDefaults] setValue:properties[@"value"] forKey:properties[@"defaultsKey"]];
    [PSISettingsBackup save];
    
    NSLog(@"Menu changed: %@", command.propertyList[@"value"]);
    
    [self reloadCellForView:command.sender animated:YES];
    
    if (properties[@"requiresRestart"]) {
        [PSIUtils showRestartConfirmation];
    }
}

// MARK: - Helper

- (NSString *)formatString:(NSString *)template withValue:(double)value label:(NSString *)label singularLabel:(NSString *)singularLabel {
    // Singular or plural labels
    NSString *applicableLabel = fabs(value - 1.0) < 0.00001 ? singularLabel : label;
    
    // Force value to 0 to prevent it being -0
    if (fabs(value) < 0.00001) {
        value = 0.0;
    }

    // Get correct decimal value based on step value
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterDecimalStyle;
    formatter.minimumFractionDigits = 0;
    formatter.maximumFractionDigits = [PSIUtils decimalPlacesInDouble:value];

    NSString *stringValue = [formatter stringFromNumber:@(value)];

    return [NSString stringWithFormat:template, stringValue, applicableLabel];
}

- (void)reloadCellForView:(UIView *)view animated:(BOOL)animated {
    UITableViewCell *cell = (UITableViewCell *)view.superview;
    while (cell && ![cell isKindOfClass:[UITableViewCell class]]) {
        cell = (UITableViewCell *)cell.superview;
    }
    if (!cell) return;

    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    if (!indexPath) return;
    
    [self.tableView reloadRowsAtIndexPaths:@[indexPath]
                          withRowAnimation:animated ? UITableViewRowAnimationAutomatic : UITableViewRowAnimationNone];
}
- (void)reloadCellForView:(UIView *)view {
    [self reloadCellForView:view animated:NO];
}

- (void)loadImageFromURL:(NSURL *)url atIndexPath:(NSIndexPath *)indexPath forTableView:(UITableView *)tableView
{
    if (!url) return;

    NSURLSessionDataTask *task = [[NSURLSession sharedSession] dataTaskWithURL:url
                                                             completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
    {
        if (!data || error) return;

        UIImage *image = [UIImage imageWithData:data];
        if (!image) return;

        dispatch_async(dispatch_get_main_queue(), ^{
            UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
            if (!cell) return;

            UIListContentConfiguration *config = (UIListContentConfiguration *)cell.contentConfiguration;
            config.image = image;
            config.imageProperties.maximumSize = CGSizeMake(45, 45);
            cell.contentConfiguration = config;
        });
    }];

    [task resume];
}

@end
