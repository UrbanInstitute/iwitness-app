#import "LanguagesViewController.h"
#import "NSLocale+LanguageDescription.h"

@interface LanguagesViewController ()
@property (nonatomic, strong) NSMutableArray *languageCodes;
@property (nonatomic, weak) id<LanguagesViewControllerDelegate> delegate;
@end

@implementation LanguagesViewController

- (instancetype)initWithDelegate:(id<LanguagesViewControllerDelegate>)delegate {
    if (self = [super init]) {
        self.delegate = delegate;
    }
    return self;
}

#pragma mark - <UITableViewDataSource>

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"LanguageCell"];
    self.languageCodes = [NSMutableArray array];

    NSArray *knownLanguageCodes = [NSLocale ISOLanguageCodes];
    NSArray *languageBundleURLs = [[NSBundle mainBundle] URLsForResourcesWithExtension:@"lproj" subdirectory:nil];
    for (NSURL *languageBundleURL in languageBundleURLs) {
        NSString *languageCode = [[languageBundleURL URLByDeletingPathExtension] lastPathComponent];
        if ([knownLanguageCodes containsObject:languageCode]) {
            [self.languageCodes addObject:languageCode];
        }
    }

    self.preferredContentSize = CGSizeMake(300, MIN([self.languageCodes count]*self.tableView.rowHeight, 600));
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.languageCodes.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"LanguageCell"];
    cell.textLabel.text = [NSLocale languageDescriptionForCode:self.languageCodes[indexPath.row]];
    return cell;
}

#pragma mark - <UITableViewDelegate>

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *selectedLanguageCode = self.languageCodes[indexPath.row];
    [WitnessLocalization setWitnessLanguageCode:selectedLanguageCode];
    [self.delegate languagesViewController:self didSelectLanguageWithCode:selectedLanguageCode];
}

@end
