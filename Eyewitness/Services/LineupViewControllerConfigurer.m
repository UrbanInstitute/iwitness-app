#import "LineupViewControllerConfigurer.h"
#import "LineupViewController.h"
#import "SuspectSearchSplitViewControllerProvider.h"
#import "PerpetratorDescriptionViewControllerProvider.h"
#import "SuspectPortrayalsViewControllerProvider.h"
#import "PersonSearchServiceProvider.h"

@interface LineupViewControllerConfigurer ()
@property (nonatomic, strong) LineupStore *lineupStore;
@property (nonatomic, strong) PhotoAssetImporter *photoAssetImporter;
@property (nonatomic, weak) id<LineupViewControllerDelegate> delegate;
@end

@implementation LineupViewControllerConfigurer

- (instancetype)initWithLineupStore:(LineupStore *)lineupStore
                 photoAssetImporter:(PhotoAssetImporter *)photoAssetImporter
                           delegate:(id<LineupViewControllerDelegate>)delegate {
    if (self = [super init]) {
        self.lineupStore = lineupStore;
        self.photoAssetImporter = photoAssetImporter;
        self.delegate = delegate;
    }
    return self;
}

- (void)configureLineupViewControllerForLineupCreation:(LineupViewController *)lineupViewController {
    [self configureLineupViewController:lineupViewController forEditingLineup:nil];
}

- (void)configureLineupViewController:(LineupViewController *)lineupViewController forEditingLineup:(Lineup *)lineup {
    [lineupViewController configureWithLineupStore:self.lineupStore
                                            lineup:lineup
                                photoAssetImporter:self.photoAssetImporter
          suspectSearchSplitViewControllerProvider:[[SuspectSearchSplitViewControllerProvider alloc] init]
      perpetratorDescriptionViewControllerProvider:[[PerpetratorDescriptionViewControllerProvider alloc] init]
           suspectPortrayalsViewControllerProvider:[[SuspectPortrayalsViewControllerProvider alloc] init]
                       personSearchServiceProvider:[[PersonSearchServiceProvider alloc] init]
                                          delegate:self.delegate];
}

@end
