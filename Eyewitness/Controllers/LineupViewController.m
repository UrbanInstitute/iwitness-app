#import "LineupViewController.h"
#import "LineupStore.h"
#import "Lineup.h"
#import "PhotoPickerViewController.h"
#import "LineupPhotosDataSource.h"
#import "PhotoAssetImporter.h"
#import "LineupPhotoCell.h"
#import "PhotoPickerDataSource.h"
#import "AlertView.h"
#import "FaceLocatorProvider.h"
#import "PhotoAssetMetadataManager.h"
#import "AnalyticsTracker.h"
#import "SuspectSearchSplitViewControllerProvider.h"
#import "SuspectSearchSplitViewController.h"
#import "FBTweakInline.h"
#import "SuspectPortrayalsViewController.h"
#import "SuspectCardView.h"
#import "Person.h"
#import "Portrayal.h"
#import "FaceLoader.h"
#import "PerpetratorDescriptionViewControllerProvider.h"
#import "LineupPerpetratorDescriptionViewController.h"
#import "PhotoPickerViewControllerDelegate.h"
#import "LineupFillerPhotosViewController.h"
#import "SuspectPortrayalsViewControllerProvider.h"
#import "PersonSearchServiceProvider.h"
#import "PersonSearchService.h"
#import "FeatureSwitches.h"

@interface LineupViewController () <PhotoPickerViewControllerDelegate, LineupPhotoCellDelegate, UICollectionViewDelegate>

@property (nonatomic, weak) id<LineupViewControllerDelegate> delegate;
@property (nonatomic, strong, readwrite) LineupStore *lineupStore;
@property (nonatomic, strong, readwrite) Lineup *lineup;
@property (nonatomic, strong) PhotoAssetImporter *photoAssetImporter;
@property (nonatomic, strong) SuspectSearchSplitViewControllerProvider *suspectSearchSplitViewControllerProvider;
@property (nonatomic, strong) PerpetratorDescriptionViewControllerProvider *perpetratorDescriptionViewControllerProvider;
@property (nonatomic, strong) SuspectPortrayalsViewControllerProvider *suspectPortrayalsViewControllerProvider;
@property (nonatomic, strong) PersonSearchServiceProvider *personSearchServiceProvider;

@property (weak, nonatomic, readwrite) IBOutlet UISwitch *audioOnlySwitch;
@property (weak, nonatomic, readwrite) IBOutlet UILabel *audioOnlySwitchLabel;
@property (weak, nonatomic) IBOutlet UITextField *caseIDTextField;
@property (weak, nonatomic) IBOutlet UITextField *suspectNameTextField;
@property (strong, nonatomic) UIBarButtonItem *cancelButton;
@property (strong, nonatomic) UIBarButtonItem *doneButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *deleteButton;
@property (weak, nonatomic, readwrite) IBOutlet UIButton *chooseFromDBButton;

@property (weak, nonatomic, readwrite) IBOutlet SuspectCardView *suspectCardView;

@property (weak, nonatomic) IBOutlet UICollectionView *suspectPhotoCollectionView;

@property (weak, nonatomic) IBOutlet UILabel *suspectPhotoRequiredLabel;

@property (strong, nonatomic) IBOutlet LineupPhotosDataSource *suspectPhotoDataSource;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *perpetratorDescriptionContainerHeightConstraint;

@property (strong, nonatomic) NSMutableSet *allImportedPhotoURLs;

@property (assign, nonatomic) BOOL editingCanceled;
@end

@implementation LineupViewController

- (void)awakeFromNib {
    [super awakeFromNib];

    PhotoAssetMetadataManager *metadataManager = [[PhotoAssetMetadataManager alloc] init];
    [self.suspectPhotoDataSource configureWithLineupPhotoCellDelegate:self metadataManager:metadataManager];
}

- (void)configureWithLineupStore:(LineupStore *)lineupStore
                          lineup:(Lineup *)lineup
              photoAssetImporter:(PhotoAssetImporter *)photoAssetImporter
        suspectSearchSplitViewControllerProvider:(SuspectSearchSplitViewControllerProvider *)suspectSearchSplitViewControllerProvider
        perpetratorDescriptionViewControllerProvider:(PerpetratorDescriptionViewControllerProvider *)perpetratorDescriptionViewControllerProvider
        suspectPortrayalsViewControllerProvider:(SuspectPortrayalsViewControllerProvider *)suspectPortrayalsViewControllerProvider
        personSearchServiceProvider:(PersonSearchServiceProvider *)personSearchServiceProvider
        delegate:(id<LineupViewControllerDelegate>)delegate {

    self.lineupStore = lineupStore;
    self.photoAssetImporter = photoAssetImporter;
    self.delegate = delegate;
    self.suspectSearchSplitViewControllerProvider = suspectSearchSplitViewControllerProvider;
    self.perpetratorDescriptionViewControllerProvider = perpetratorDescriptionViewControllerProvider;
    self.personSearchServiceProvider = personSearchServiceProvider;
    self.suspectPortrayalsViewControllerProvider = suspectPortrayalsViewControllerProvider;

    self.lineup = lineup ?: [[Lineup alloc] init];
    self.title = ([self.lineup.caseID length]==0) ? NSLocalizedString(@"New Lineup", @"New Lineup") : self.lineup.caseID;

    self.allImportedPhotoURLs = [NSMutableSet setWithArray:self.lineup.fillerPhotosFileURLs];
    if (self.lineup.suspect.selectedPortrayal.photoURL && !self.lineup.fromDB) {
        [self.allImportedPhotoURLs addObject:self.lineup.suspect.selectedPortrayal.photoURL];
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];

    if (![FeatureSwitches choosePhotosFromDBEnabled]) {
        [self.chooseFromDBButton removeFromSuperview];
    }
    if (![FeatureSwitches audioOnlyLineupsEnabled]) {
        [self.audioOnlySwitch removeFromSuperview];
        [self.audioOnlySwitchLabel removeFromSuperview];
    }
    if (![FeatureSwitches perpetratorDescriptionEnabled]) {
        self.perpetratorDescriptionContainerHeightConstraint.constant = 0;
    }

    self.cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                      target:self
                                                                      action:@selector(cancelTapped:)];
    self.doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneTapped:)];

    [self.suspectCardView.deleteButton addTarget:self action:@selector(deleteSuspectButtonTapped) forControlEvents:UIControlEventTouchUpInside];

    if ([self lineupExists]) {
        self.navigationItem.leftBarButtonItem = self.doneButton;
        self.navigationItem.rightBarButtonItems = [@[self.editButtonItem] arrayByAddingObjectsFromArray:self.navigationItem.rightBarButtonItems];
        [self setFieldsFromLineup];
        self.editing = NO;
    } else {
        self.navigationItem.rightBarButtonItem = self.editButtonItem;
        self.editing = YES;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self setFieldsFromLineup];
    [self updateSuspectPickerUI];
    for(NSIndexPath *indexPath in self.suspectPhotoCollectionView.indexPathsForSelectedItems) {
        [self.suspectPhotoCollectionView deselectItemAtIndexPath:indexPath animated:YES];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    if (!self.presentedViewController) {
        NSMutableSet *unusedPhotos = [NSMutableSet setWithSet:self.allImportedPhotoURLs];

        if (self.lineup.suspect.selectedPortrayal.photoURL) {
            [unusedPhotos removeObject:self.lineup.suspect.selectedPortrayal.photoURL];
        }

        [unusedPhotos minusSet:[NSSet setWithArray:self.lineup.fillerPhotosFileURLs]];
        for (NSURL *photoURL in unusedPhotos) {
            [[NSFileManager defaultManager] removeItemAtURL:photoURL error:nil];
        }
        self.allImportedPhotoURLs = [NSMutableSet set];
    }
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated {
    BOOL wasEditing = self.editing;

    [super setEditing:editing animated:animated];

    if (editing) {
        self.navigationItem.leftBarButtonItem = self.cancelButton;
    } else if (wasEditing) {
        self.navigationItem.leftBarButtonItem = self.doneButton;

        if ([self lineupExists]) {
            if (!self.editingCanceled) {
                [self updateLineupFromFields];
                [self.lineupStore updateLineup:self.lineup];
            }
            self.title = self.lineup.caseID;
            [self setFieldsFromLineup];
        } else {
            [self updateLineupFromFields];
            [self.lineupStore updateLineup:self.lineup];

            [[AnalyticsTracker sharedInstance] trackLineupCreation];
            [self.delegate lineupViewControllerDidComplete:self];
        }
    }

    [UIView animateWithDuration:animated ? 0.3f : 0.0f animations:^{
        [self updateEditingControls];
    }];

    for (UIViewController *viewController in self.childViewControllers) {
        [viewController setEditing:editing animated:animated];
    }

    self.editingCanceled = NO;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    [super prepareForSegue:segue sender:sender];

    if([segue.destinationViewController isKindOfClass:[LineupPerpetratorDescriptionViewController class]]) {
        LineupPerpetratorDescriptionViewController *controller = segue.destinationViewController;
        [controller configureWithLineup:self.lineup
                perpetratorDescriptionViewControllerProvider:self.perpetratorDescriptionViewControllerProvider];
    } else if([segue.destinationViewController isKindOfClass:[LineupFillerPhotosViewController class]]) {
        LineupFillerPhotosViewController *controller = segue.destinationViewController;
        [controller configureWithLineup:self.lineup photoAssetImporter:self.photoAssetImporter];
    } else if ([segue.identifier isEqualToString:@"ShowPhotoPickerForSuspect"]) {
        PhotoPickerDataSource *dataSource = [[PhotoPickerDataSource alloc] init];
        ALAssetsLibrary *assetsLibrary = [[ALAssetsLibrary alloc] init];
        FaceLocatorProvider *faceLocatorProvider = [[FaceLocatorProvider alloc] init];

        [dataSource configureWithAssetsLibrary:assetsLibrary faceLocator:[faceLocatorProvider faceLocator] faceCache:[[NSCache alloc] init]];

        PhotoPickerViewController *controller = (PhotoPickerViewController *) [[segue destinationViewController] topViewController];
        [controller configureWithDelegate:self dataSource:dataSource selectedAssetURLs:nil];
    }
}

#pragma mark - Actions

- (IBAction)audioOnlySwitchValueChanged:(id)sender {
    self.lineup.audioOnly = self.audioOnlySwitch.on;
}

- (IBAction)suspectCardTapped:(id)sender {
    [[[self.personSearchServiceProvider personSearchService] personResultsForFirstName:@"" lastName:@"" suspectID:self.lineup.suspect.systemID] then:^id(NSArray *searchResults) {
        if (searchResults.count > 0) {
            [searchResults.firstObject setSelectedPortrayal:self.lineup.suspect.selectedPortrayal];
            SuspectPortrayalsViewController *suspectPortrayalsController = [self.suspectPortrayalsViewControllerProvider suspectPortrayalsViewControllerWithPerson:searchResults.firstObject];
            UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:suspectPortrayalsController];
            [self presentViewController:navController animated:YES completion:nil];
        } else {
            [[[AlertView alloc] initWithTitle:NSLocalizedString(@"Suspect not found", nil)
                                      message:NSLocalizedString(@"This suspect is no longer in the database.", nil)
                            cancelButtonTitle:NSLocalizedString(@"OK", nil)
                            otherButtonTitles:nil
                                cancelHandler:nil
                          confirmationHandler:nil] show];
        }
        return nil;
    } error:^id(NSError *error) {
        //TODO: When we have a network based search service, we may need to catch errors here
        return nil;
    }];
}

- (void)doneTapped:(id)sender {
    [self.delegate lineupViewControllerDidComplete:self];
}

- (void)cancelTapped:(id)sender {
    if ([self lineupIsDirty]) {
        [[[AlertView alloc] initWithTitle:NSLocalizedString(@"Are you sure you want to cancel?", nil)
                                  message:NSLocalizedString(@"Your changes will be discarded.", nil)
                        cancelButtonTitle:NSLocalizedString(@"Keep", nil)
                        otherButtonTitles:@[NSLocalizedString(@"Discard", nil)]
                            cancelHandler:^{
                            }
                      confirmationHandler:^(NSInteger otherButtonIndex) {
                          [self discardChanges];
                      }] show];
    } else {
        [self discardChanges];
    }
}

- (IBAction)deleteTapped:(id)sender {
    [[[AlertView alloc] initWithTitle:NSLocalizedString(@"Are you sure you want to delete this lineup?", nil)
                              message:nil
                    cancelButtonTitle:NSLocalizedString(@"Cancel", nil)
                    otherButtonTitles:@[NSLocalizedString(@"Delete", nil)]
                        cancelHandler:nil
                  confirmationHandler:^(NSInteger otherButtonIndex) {
                      [self.lineupStore deleteLineup:self.lineup];
                      [self.delegate lineupViewControllerDidComplete:self];
                  }] show];
}

- (IBAction)chooseFromDBTapped {
    [self updateLineupFromFields];
    SuspectSearchSplitViewController *viewController = [self.suspectSearchSplitViewControllerProvider suspectSearchSplitViewControllerWithCaseID:self.lineup.caseID];
    [self.navigationController pushViewController:viewController animated:YES];
}

- (void)deleteSuspectButtonTapped {
    self.lineup.fromDB = NO;
    self.lineup.suspect = [[Person alloc] init];
    [self.suspectCardView configureWithPerson:self.lineup.suspect faceLoader:[FaceLoader faceLoader]];

    [self updateSuspectPickerUI];
}

- (IBAction)exitToLineup:(UIStoryboardSegue *)sender {
    SuspectPortrayalsViewController *sourceController = (SuspectPortrayalsViewController *)sender.sourceViewController;
    Person *suspect = sourceController.person;

    self.lineup.suspect = suspect;
    self.lineup.fromDB = YES;
    [self setFieldsFromLineup];
    [self updateSuspectPickerUI];
}

#pragma mark - <UITextField>

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    if (textField == self.caseIDTextField) {
        self.lineup.caseID = [self.lineup.caseID ?: @"" stringByReplacingCharactersInRange:range withString:string];
    } else if (textField == self.suspectNameTextField) {
        self.lineup.suspect.firstName = [self.lineup.suspect.fullName ?: @"" stringByReplacingCharactersInRange:range withString:string];
    }
    return YES;
}

#pragma mark - <LineupPhotoCellDelegate>

- (void)lineupPhotoCellDidDelete:(LineupPhotoCell *)cell {
    NSIndexPath *indexPath = [self.suspectPhotoCollectionView indexPathForCell:cell];
    self.lineup.suspect = [[Person alloc] init];
    self.chooseFromDBButton.hidden = ![self shouldShowChooseFromDBButton];

    [self.suspectPhotoDataSource removePhotoURL:self.suspectPhotoDataSource.photoURLs[indexPath.item]];
    [self updateValidationLabels];
}

#pragma mark - <PhotoPickerViewControllerDelegate>

- (NSUInteger)maximumSelectionCountForPhotoPickerViewController:(PhotoPickerViewController *)controller {
    return self.suspectPhotoDataSource.maximumNumberOfPhotos;
}

- (void)photoPickerViewController:(PhotoPickerViewController *)controller didSelectAssets:(NSArray *)assets {
    NSArray *importedPhotoURLs = [self.photoAssetImporter importAssets:assets];
    self.suspectPhotoDataSource.photoURLs = importedPhotoURLs;
    self.lineup.suspect.portrayals = [self photoURLsToPortrayals:importedPhotoURLs];
    [self.allImportedPhotoURLs addObjectsFromArray:importedPhotoURLs];

    [self dismissViewControllerAnimated:YES completion:nil];
    [self updateValidationLabels];
}

- (void)photoPickerViewControllerDidCancel:(PhotoPickerViewController *)controller {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Private

- (NSArray *)photoURLsToPortrayals:(NSArray *) photoURLs {
    return [photoURLs collect:^Portrayal *(NSURL * photoURL) {
        return [[Portrayal alloc] initWithPhotoURL:photoURL date:nil];
    }];
}

- (void)updateEditingControls {
    self.caseIDTextField.enabled = self.editing;
    self.suspectNameTextField.enabled = self.editing;
    self.chooseFromDBButton.hidden = ![self shouldShowChooseFromDBButton];
    self.suspectCardView.deleteButton.hidden = !self.editing;
    self.audioOnlySwitch.enabled = self.editing;

    [self.suspectPhotoDataSource setEditing:self.editing];
}

- (void)updateLineupFromFields {
    //TODO: unify first/last vs full name
    self.lineup.caseID = self.caseIDTextField.text;
    if (!self.lineup.fromDB) {
        self.lineup.suspect.firstName = self.suspectNameTextField.text;
        self.lineup.suspect.portrayals = [self photoURLsToPortrayals:self.suspectPhotoDataSource.photoURLs];
    }
}

- (void)setFieldsFromLineup {
    self.caseIDTextField.text = self.lineup.caseID;
    self.audioOnlySwitch.on = self.lineup.audioOnly;

    if (self.lineup.isFromDB) {
        [self.suspectCardView configureWithPerson:self.lineup.suspect faceLoader:[FaceLoader faceLoader]];
    } else {
        self.suspectNameTextField.text = self.lineup.suspect.fullName;
        if (self.lineup.suspect.selectedPortrayal) {
            self.suspectPhotoDataSource.photoURLs = @[self.lineup.suspect.selectedPortrayal.photoURL];
        } else {
            self.suspectPhotoDataSource.photoURLs = @[];
        }
    }

    [self updateSuspectPickerUI];
}

- (void)updateValidationLabels {
    self.suspectPhotoRequiredLabel.hidden = self.lineup.suspect.selectedPortrayal.photoURL != nil;
}

- (void)updateSuspectPickerUI {
    self.suspectCardView.hidden = !self.lineup.isFromDB;
    self.suspectPhotoCollectionView.hidden = self.lineup.isFromDB;
    self.chooseFromDBButton.hidden = ![self shouldShowChooseFromDBButton];
    [self updateValidationLabels];
}

- (BOOL)shouldShowChooseFromDBButton {
    return !self.lineup.suspect.selectedPortrayal.photoURL && self.editing;
}

- (void)discardChanges {
    self.editingCanceled = YES;

    if ([self lineupExists]) {
        [self.lineup updateToMatchLineup:[self.lineupStore lineupWithUUID:self.lineup.UUID]];
        self.editing = NO;
    } else {
        [self.delegate lineupViewControllerDidComplete:self];
    }
}

- (BOOL)lineupIsDirty {
    Lineup *lineupToCompareTo;

    if ([self lineupExists]) {
        lineupToCompareTo = [self.lineupStore lineupWithUUID:self.lineup.UUID];
    } else {
        lineupToCompareTo = [[Lineup alloc] initWithCreationDate:self.lineup.creationDate suspect:[[Person alloc] init]];
    }
    return ![self.lineup isEqual:lineupToCompareTo];
}

- (BOOL)lineupExists {
    return [self.lineupStore lineupWithUUID:self.lineup.UUID] != nil;
}
@end
