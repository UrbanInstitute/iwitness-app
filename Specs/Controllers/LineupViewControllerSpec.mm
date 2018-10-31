#import "LineupViewController.h"
#import "LineupStore.h"
#import "Lineup.h"
#import "PhotoPickerViewController.h"
#import "LineupPhotosDataSource.h"
#import "ALTestAsset.h"
#import "AddPhotoCell.h"
#import "LineupPhotoCell.h"
#import "UICollectionViewCell+SpecHelpers.h"
#import "PhotoAssetImporter.h"
#import "PortraitOnlyNavigationController.h"
#import "AnalyticsTracker.h"
#import "SuspectSearchSplitViewControllerProvider.h"
#import "SuspectSearchSplitViewController.h"
#import "SuspectPortrayalsViewController.h"
#import "SuspectCardView.h"
#import "Person.h"
#import "PersonFactory.h"
#import "Portrayal.h"
#import "FaceLoader.h"
#import "PerpetratorDescriptionViewControllerProvider.h"
#import "PerpetratorDescription.h"
#import "LineupPerpetratorDescriptionViewController.h"
#import "LineupFillerPhotosViewController.h"
#import "PhotoPickerViewControllerDelegate.h"
#import "SuspectPortrayalsViewControllerProvider.h"
#import "PersonSearchServiceProvider.h"
#import "PersonSearchService.h"
#import "UISwitch+SpecHelpers.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

@interface LineupViewController (Specs) <PhotoPickerViewControllerDelegate>
@property (strong, nonatomic) LineupPhotosDataSource *suspectPhotoDataSource;
@property (weak, nonatomic, readonly) UICollectionView *suspectPhotoCollectionView;
@property (strong, nonatomic) NSMutableSet *allImportedPhotoURLs;
@end

SPEC_BEGIN(LineupViewControllerSpec)

describe(@"LineupViewController", ^{
    __block UINavigationController *navController;
    __block LineupViewController *controller;
    __block LineupStore *lineupStore;
    __block id<LineupViewControllerDelegate> delegate;
    __block PhotoAssetImporter *photoAssetImporter;
    __block SuspectSearchSplitViewControllerProvider *suspectSearchSplitViewControllerProvider;
    __block SuspectSearchSplitViewController *suspectSearchSplitViewController;
    __block PerpetratorDescriptionViewControllerProvider *perpetratorDescriptionViewControllerProvider;
    __block SuspectPortrayalsViewControllerProvider *suspectPortrayalsViewControllerProvider;
    __block PersonSearchServiceProvider *personSearchServiceProvider;

    AddPhotoCell *(^findAddPhotoCell)() = ^AddPhotoCell *{
        NSInteger cellCount = [controller.suspectPhotoCollectionView numberOfItemsInSection:0];
        NSIndexPath *lastCellIndexPath = [NSIndexPath indexPathForItem:(cellCount - 1) inSection:0];
        UICollectionViewCell *cell = [controller.suspectPhotoCollectionView cellForItemAtIndexPath:lastCellIndexPath];
        if (cell) {
            cell should be_instance_of([AddPhotoCell class]);
        }
        return (AddPhotoCell *)cell;
    };

    void(^tapAddPhotoFromLibraryForSuspect)() = ^{
        AddPhotoCell *photoCell = findAddPhotoCell();
        if (photoCell != nil) {
            [photoCell tap];
        } else {
            @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                           reason:@"Can't tap add photo for suspect because it's not visible"
                                         userInfo:nil];
        }
    };

    void(^editField)(UITextField *, NSString *) = ^(UITextField *field, NSString *newText) {
        if ([field.delegate textField:field shouldChangeCharactersInRange:NSMakeRange(0, field.text.length) replacementString:newText]) {
            field.text = newText;
        }
    };

    beforeEach(^{
        photoAssetImporter = nice_fake_for([PhotoAssetImporter class]);
        photoAssetImporter stub_method(@selector(importAssets:)).and_do_block(^NSArray *(NSArray *assets) {
            NSMutableArray *URLs = [NSMutableArray array];
            for (ALAsset *asset in assets) {
                [URLs addObject:[asset valueForProperty:ALAssetPropertyAssetURL]];
            }
            return URLs;
        });

        suspectSearchSplitViewControllerProvider = fake_for([SuspectSearchSplitViewControllerProvider class]);

        personSearchServiceProvider = fake_for([PersonSearchServiceProvider class]);

        spy_on([AnalyticsTracker sharedInstance]);

        navController = [[UIStoryboard storyboardWithName:@"AdminFlow" bundle:nil] instantiateViewControllerWithIdentifier:@"LineupNavigationController"];
        controller = (LineupViewController *)navController.topViewController;
        controller should be_instance_of([LineupViewController class]);

        lineupStore = nice_fake_for([LineupStore class]);

        perpetratorDescriptionViewControllerProvider = fake_for([PerpetratorDescriptionViewControllerProvider class]);

        suspectPortrayalsViewControllerProvider = fake_for([SuspectPortrayalsViewControllerProvider class]);

        delegate = nice_fake_for(@protocol(LineupViewControllerDelegate));
        [controller configureWithLineupStore:lineupStore
                                      lineup:nil
                          photoAssetImporter:photoAssetImporter
    suspectSearchSplitViewControllerProvider:suspectSearchSplitViewControllerProvider
perpetratorDescriptionViewControllerProvider:perpetratorDescriptionViewControllerProvider
     suspectPortrayalsViewControllerProvider:suspectPortrayalsViewControllerProvider
                 personSearchServiceProvider:personSearchServiceProvider
                                    delegate:delegate];

        controller.view should_not be_nil;

        [controller.view setNeedsLayout];
        [controller.view layoutIfNeeded];
    });

    it(@"should set the right bar button item to the controller's edit button", ^{
        controller.navigationItem.rightBarButtonItem should be_same_instance_as(controller.editButtonItem);
    });

    sharedExamplesFor(@"saving a lineup", ^(NSDictionary *) {
        it(@"should update the lineup store", ^{
            lineupStore should have_received(@selector(updateLineup:)).with(controller.lineup);
        });
    });

    sharedExamplesFor(@"editing controls are enabled", ^(NSDictionary *sharedContext) {
        beforeEach(^{
            controller.editing should be_truthy;
        });

        it(@"should have enabled the audio only switch", ^{
            controller.audioOnlySwitch.enabled should be_truthy;
        });

        describe(@"toggling the audio only switch", ^{
            it(@"should toggle whether the lineup is audio only or not", ^{
                BOOL originalState = controller.lineup.audioOnly;
                [controller.audioOnlySwitch toggle];
                controller.lineup.audioOnly should_not equal(originalState);
                [controller.audioOnlySwitch toggle];
                controller.lineup.audioOnly should equal(originalState);
            });
        });

        it(@"should have enabled the case ID text field", ^{
            controller.caseIDTextField.enabled should be_truthy;
        });

        describe(@"editing the case ID text field", ^{
            beforeEach(^{
                editField(controller.caseIDTextField, @"A new case ID for the modern criminal");
            });

            it(@"should update the case ID of the lineup", ^{
                controller.lineup.caseID should equal(@"A new case ID for the modern criminal");
            });
        });

        it(@"should have enabled the suspect name text field", ^{
            controller.suspectNameTextField.enabled should be_truthy;
        });

        describe(@"editing the suspect name text field", ^{
            beforeEach(^{
                editField(controller.suspectNameTextField, @"Harvey Birdman");
            });

            it(@"should update the suspect name of the lineup but we test containing because DB chosen suspects have first and last names, but side-loaded suspects only have a single name which we repurpose the first name field for. We should make these congruent.", ^{
                controller.lineup.suspect.firstName should contain(@"Harvey Birdman");
            });
        });

        it(@"should put all child view controllers into edit mode", ^{
            [controller.childViewControllers valueForKey:@"editing"] should_not contain(@NO);
        });
    });

    sharedExamplesFor(@"editing controls are disabled", ^(NSDictionary *sharedContext) {
        beforeEach(^{
            controller.editing should_not be_truthy;
        });

        it(@"should have enabled the audio only switch", ^{
            controller.audioOnlySwitch.enabled should be_falsy;
        });

        it(@"should have disabled the case ID text field", ^{
            controller.caseIDTextField.enabled should be_falsy;
        });

        it(@"should have disabled the suspect name text field", ^{
            controller.suspectNameTextField.enabled should be_falsy;
        });

        it(@"should not allow the user to add suspect photos", ^{
            [controller.suspectPhotoCollectionView.visibleCells filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"class = %@", [AddPhotoCell class]]] should be_empty;
        });

        it(@"should take all child view controllers out of edit mode", ^{
            [controller.childViewControllers valueForKey:@"editing"] should_not contain(@YES);
        });

        it(@"should not show the 'CHOOSE FROM DB' button", ^{
            controller.chooseFromDBButton.hidden should be_truthy;
        });

        it(@"should not show the portrayal view's delete button", ^{
            controller.suspectCardView.deleteButton.hidden should be_truthy;
        });
    });

    sharedExamplesFor(@"the DB suspect photo can be removed", ^(NSDictionary *sharedContext) {
        beforeEach(^{
            controller.editing should be_truthy;
        });

        it(@"should show the the portrayal view delete button", ^{
            controller.suspectCardView.deleteButton.hidden should_not be_truthy;
        });

        describe(@"when the photo is removed", ^{
            beforeEach(^{
                spy_on(controller.suspectCardView);
                [controller.suspectCardView.deleteButton tap];
            });

            it(@"should not show the portrayal view", ^{
                controller.suspectCardView.hidden should be_truthy;
            });

            it(@"should show the 'CHOOSE FROM DB' button", ^{
                controller.chooseFromDBButton.hidden should_not be_truthy;
            });

            it(@"should show the suspect photo required label", ^{
                controller.suspectPhotoRequiredLabel.hidden should be_falsy;
            });

            it(@"should only display the add photo cell in the suspect collection view", ^{
                controller.suspectPhotoCollectionView.visibleCells.count should equal(1);
                [controller.suspectPhotoCollectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]] should be_instance_of([AddPhotoCell class]);
            });

            it(@"should reassign the lineup's suspect to be a person with no information", ^{
                controller.lineup.suspect should equal([[Person alloc] init]);
            });

            it(@"should reconfigure the portrayal view with a person with no information", ^{
               controller.suspectCardView should have_received(@selector(configureWithPerson:faceLoader:)).with([[Person alloc] init], Arguments::any([FaceLoader class]));
            });

            it(@"should flip the bool on the lineup", ^{
                controller.lineup.fromDB should_not be_truthy;
            });
        });
    });

    sharedExamplesFor(@"the sideloaded suspect photo can be removed", ^(NSDictionary *sharedContext) {
        beforeEach(^{
            controller.editing should be_truthy;
        });

        it(@"should have enabled editing on the suspect photo cell", ^{
            [(LineupPhotoCell *)[controller.suspectPhotoCollectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]] isEditing] should be_truthy;
        });

        it(@"should not show the 'CHOOSE FROM DB' button", ^{
            controller.chooseFromDBButton.hidden should be_truthy;
        });

        describe(@"when the photo cell is removed", ^{
            __block LineupPhotoCell *photoCell;

            beforeEach(^{
                photoCell = (LineupPhotoCell *)[controller.suspectPhotoCollectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
                [photoCell.deleteButton tap];
            });

            it(@"should remove the item", ^{
                controller.suspectPhotoCollectionView.visibleCells should_not contain(photoCell);
            });

            it(@"should show the suspect photo required label", ^{
                controller.suspectPhotoRequiredLabel.hidden should be_falsy;
            });

            it(@"should show the 'CHOOSE FROM DB' button", ^{
                controller.chooseFromDBButton.hidden should_not be_truthy;
            });
        });
    });

    sharedExamplesFor(@"the suspect photo can be added", ^(NSDictionary *sharedContext) {
        beforeEach(^{
            controller.editing should be_truthy;
            [controller.suspectPhotoCollectionView layoutIfNeeded];
        });

        it(@"should only display the add photo cell in the suspect collection view", ^{
            controller.suspectPhotoCollectionView.visibleCells.count should equal(1);
            [controller.suspectPhotoCollectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]] should be_instance_of([AddPhotoCell class]);
        });

        it(@"should not show the portrayal view", ^{
            controller.suspectCardView.hidden should be_truthy;
        });

        it(@"should show the 'CHOOSE FROM DB' button", ^{
            controller.chooseFromDBButton.hidden should_not be_truthy;
        });

        describe(@"when the add photo cell is tapped", ^{
            beforeEach(^{
                [[controller.suspectPhotoCollectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]] tapInternal];
            });

            it(@"should configure the suspect photo data source to allow adding one photo", ^{
                controller.suspectPhotoDataSource.maximumNumberOfPhotos should equal(1);
            });

            it(@"should provide the correct maximum selection count to the photo picker", ^{
                [controller maximumSelectionCountForPhotoPickerViewController:nil] should equal(1);
            });

            it(@"should present a photo picker controller", ^{
                controller.presentedViewController should be_instance_of([PortraitOnlyNavigationController class]);
                [(UINavigationController *)controller.presentedViewController topViewController] should be_instance_of([PhotoPickerViewController class]);
                [[(UINavigationController *)controller.presentedViewController topViewController] view] should_not be_nil;
            });

            it(@"should dismiss the photo picker controller when it receives a cancellation message", ^{
                [controller photoPickerViewControllerDidCancel:nil];
                controller.presentedViewController should be_nil;
            });

            describe(@"after finishing selecting a suspect photo", ^{
                __block NSArray *assets;
                __block NSURL *selectedPhotoURL;

                beforeEach(^{
                    spy_on(controller);

                    selectedPhotoURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"nathan" withExtension:@"jpg" subdirectory:@"SampleLineup"];
                    ALAsset *fakeAsset1 = [[ALTestAsset alloc] initWithImageURL:selectedPhotoURL];
                    assets = @[fakeAsset1];

                    [controller photoPickerViewController:nil didSelectAssets:assets];
                    [controller viewWillAppear:NO];
                    [controller.suspectPhotoCollectionView layoutIfNeeded];
                });

                itShouldBehaveLike(@"the sideloaded suspect photo can be removed");

                it(@"should dismiss the photo picker controller", ^{
                    controller should have_received(@selector(dismissViewControllerAnimated:completion:));
                });

                it(@"should copy the selected images into the app sandbox when it receives a completion message", ^{
                    photoAssetImporter should have_received(@selector(importAssets:)).with(assets);
                });

                it(@"should present each selected photo to the user", ^{
                    LineupPhotoCell *cell = (LineupPhotoCell *)[controller.suspectPhotoCollectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
                    cell should be_instance_of([LineupPhotoCell class]);
                    [cell.imageView.image isEqualToByBytes:[UIImage imageWithCGImage:[assets[0] defaultRepresentation].fullScreenImage]] should be_truthy;
                });

                it(@"should not display the add photo cell anymore", ^{
                    controller.suspectPhotoCollectionView.visibleCells.count should equal(1);
                });

                it(@"should not show the suspect photo required label", ^{
                    controller.suspectPhotoRequiredLabel.hidden should be_truthy;
                });

                it(@"should add the photo url to the all imported photos arary", ^{
                    controller.allImportedPhotoURLs should contain(selectedPhotoURL);
                });
            });

            describe(@"after finish selecting nothing", ^{
                beforeEach(^{
                    [controller photoPickerViewControllerDidCancel:nil];
                });

                it(@"should only display the add photo cell in the suspect collection view", ^{
                    controller.suspectPhotoCollectionView.visibleCells.count should equal(1);
                    controller.suspectPhotoCollectionView.visibleCells.firstObject should be_instance_of([AddPhotoCell class]);
                });
            });
        });

        describe(@"when the choose from db button is tapped", ^{
            beforeEach(^{
                suspectSearchSplitViewController = [[SuspectSearchSplitViewController alloc] init];
                spy_on(suspectSearchSplitViewController);

                suspectSearchSplitViewControllerProvider stub_method(@selector(suspectSearchSplitViewControllerWithCaseID:)).and_do_block(^SuspectSearchSplitViewController *(NSString *caseID){
                    if (caseID == controller.lineup.caseID) {
                        return suspectSearchSplitViewController;
                    }
                    return nil;
                });

                [controller.chooseFromDBButton tap];
            });

            it(@"should push the provided suspect search view controller", ^{
                controller.navigationController.topViewController should equal(suspectSearchSplitViewController);
            });

            itShouldBehaveLike(@"the DB suspect photo can be removed");
        });
    });

    describe(@"configuring embedded child view controllers", ^{
        context(@"when the destination controller is a LineupPerpetratorDescriptionViewController", ^{
           __block LineupPerpetratorDescriptionViewController *destinationController;

           beforeEach(^{
               controller.view should_not be_nil;
               destinationController = nice_fake_for([LineupPerpetratorDescriptionViewController class]);
               UIStoryboardSegue *segue  = [UIStoryboardSegue segueWithIdentifier:@"" source:controller destination:destinationController performHandler:^{}];
               [controller prepareForSegue:segue sender:controller];
           });

           it(@"configures the destination controller", ^{
               destinationController should have_received(@selector(configureWithLineup:perpetratorDescriptionViewControllerProvider:)).with(controller.lineup, perpetratorDescriptionViewControllerProvider);
           });
       });

        context(@"when the destination controller is a LineupFillerPhotosViewController", ^{
            __block LineupFillerPhotosViewController *destinationController;

            beforeEach(^{
                controller.view should_not be_nil;
                destinationController = nice_fake_for([LineupFillerPhotosViewController class]);
                UIStoryboardSegue *segue  = [UIStoryboardSegue segueWithIdentifier:@"" source:controller destination:destinationController performHandler:^{}];
                [controller prepareForSegue:segue sender:controller];
            });

            it(@"configures the destination controller", ^{
                destinationController should have_received(@selector(configureWithLineup:photoAssetImporter:)).with(controller.lineup, photoAssetImporter);
            });
        });
    });

    describe(@"creating a new lineup", ^{
        beforeEach(^{
            [controller viewWillAppear:NO];
        });

        it(@"should show a non-specific title for new lineups", ^{
            controller.navigationItem.title should equal(@"New Lineup");
        });

        it(@"should not allow the user to delete a new lineup", ^{
            controller.navigationItem.rightBarButtonItems should_not contain(controller.deleteButton);
        });

        it(@"should not have any prepopulated data", ^{
            controller.caseIDTextField.text.length should equal(0);
            controller.suspectNameTextField.text.length should equal(0);
        });

        it(@"should be in edit mode", ^{
            controller.editing should be_truthy;
        });

        it(@"should indicate that a suspect photo is required", ^{
            controller.suspectPhotoRequiredLabel.hidden should be_falsy;
        });

        it(@"should have the 'audio only' switch off", ^{
            controller.audioOnlySwitch.isOn should be_falsy;
        });

        itShouldBehaveLike(@"editing controls are enabled");

        itShouldBehaveLike(@"the suspect photo can be added");

        describe(@"when the cancel button is tapped", ^{
            context(@"no information is entered", ^{
                beforeEach(^{
                    [controller.cancelButton tap];
                });

                it(@"should not show a confirmation alert", ^{
                    [UIAlertView currentAlertView] should be_nil;
                });
            });

            context(@"some information is entered", ^{
                beforeEach(^{
                    editField(controller.caseIDTextField, @"some information");
                    [controller.cancelButton tap];
                });

                it(@"should show a confirmation alert", ^{
                    UIAlertView *alert = [UIAlertView currentAlertView];
                    alert should_not be_nil;
                    alert.title should equal(@"Are you sure you want to cancel?");
                });

                describe(@"when the user aborts cancellation", ^{
                    beforeEach(^{
                        [[UIAlertView currentAlertView] dismissWithCancelButton];
                    });

                    it(@"should not notifiy its delegate about completion", ^{
                        delegate should_not have_received(@selector(lineupViewControllerDidComplete:));
                    });
                });

                describe(@"when the user confirms cancellation", ^{
                    beforeEach(^{
                        [(id<CedarDouble>)lineupStore reset_sent_messages];
                        [[UIAlertView currentAlertView] dismissWithOkButton];
                    });

                    it(@"should not save the lineup", ^{
                        lineupStore should_not have_received(@selector(updateLineup:));
                    });

                    it(@"should notify the delegate", ^{
                        delegate should have_received(@selector(lineupViewControllerDidComplete:)).with(controller);
                    });
                });
            });
        });

        describe(@"when the done button is tapped", ^{
            beforeEach(^{
                controller.lineup.caseID = @"1234789";
                controller.lineup.suspect.firstName = @"Johnny";
                controller.lineup.suspect.lastName = @"Doe";
                controller.lineup.suspect.portrayals =  @[[[Portrayal alloc] initWithPhotoURL:[NSURL fileURLWithPath:@"/photo1.jpg"] date:[NSDate date]]];

                [controller.navigationItem.rightBarButtonItem tap];
            });

            itShouldBehaveLike(@"saving a lineup");

            it(@"should track the lineup creation", ^{
                [AnalyticsTracker sharedInstance] should have_received(@selector(trackLineupCreation));
            });

            it(@"should not update the title", ^{
                controller.title should equal(@"New Lineup");
            });
        });
    });

    describe(@"editing an existing lineup", ^{
        __block Lineup *lineup;
        NSURL *suspectPhotoURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"alex" withExtension:@"jpg" subdirectory:@"SampleLineup"];
        NSURL *fillerPhotoURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"Brian" withExtension:@"jpg" subdirectory:@"SampleLineup"];

        beforeEach(^{
            [[NSFileManager defaultManager] fileExistsAtPath:[suspectPhotoURL path]] should be_truthy;
            [NSData dataWithContentsOfURL:suspectPhotoURL] should_not be_nil;
            [UIImage imageWithContentsOfFile:[suspectPhotoURL path]] should_not be_nil;

            navController = [[UIStoryboard storyboardWithName:@"AdminFlow" bundle:nil] instantiateViewControllerWithIdentifier:@"LineupNavigationController"];
            controller = (LineupViewController *)navController.topViewController;
            controller should be_instance_of([LineupViewController class]);

            lineup = [[Lineup alloc] init];
            lineup.caseID = @"1234";
            lineup.suspect = [[Person alloc] initWithFirstName:@"Jane" lastName:@"Doe" dateOfBirth:nil systemID:@"98765" portrayals:@[]];
            lineup.perpetratorDescription.additionalNotes = @"He had a really cool tattoo.";
            lineup.suspect.selectedPortrayal = [[Portrayal alloc] initWithPhotoURL:suspectPhotoURL date:[NSDate date]];
            lineup.audioOnly = YES;

            NSURL *secondFillerURL = [NSURL URLWithString:@"a/url"];
            NSURL *thirdFillerURL = [NSURL URLWithString:@"a/url"];
            NSURL *fourthFillerURL = [NSURL URLWithString:@"a/url"];
            NSURL *fifthFillerURL = [NSURL URLWithString:@"a/url"];
            lineup.fillerPhotosFileURLs = @[fillerPhotoURL, secondFillerURL, thirdFillerURL, fourthFillerURL, fifthFillerURL];
            spy_on(lineup);

            lineupStore stub_method(@selector(lineupWithUUID:)).with(lineup.UUID).and_return([lineup copy]);
        });

        context(@"when the lineup's suspect comes from the database", ^{
            beforeEach(^{
                lineup.fromDB = YES;

                [controller configureWithLineupStore:lineupStore lineup:lineup photoAssetImporter:photoAssetImporter suspectSearchSplitViewControllerProvider:suspectSearchSplitViewControllerProvider perpetratorDescriptionViewControllerProvider:perpetratorDescriptionViewControllerProvider suspectPortrayalsViewControllerProvider:suspectPortrayalsViewControllerProvider personSearchServiceProvider:personSearchServiceProvider delegate:delegate];

                controller.view should_not be_nil;
                spy_on(controller.suspectCardView);

                [controller viewWillAppear:NO];
                [controller.view setNeedsLayout];
                [controller.view layoutIfNeeded];
            });

            it(@"should show the suspect portrayal view", ^{
                controller.suspectPhotoCollectionView.hidden should be_truthy;
                controller.suspectCardView.hidden should_not be_truthy;
            });

            it(@"should configure the portrayal view to display the lineup's suspect", ^{
                controller.suspectCardView should have_received(@selector(configureWithPerson:faceLoader:)).with(lineup.suspect, Arguments::any([FaceLoader class]));
            });

            it(@"should not add the suspect photo to the all imported photos array", ^{
                controller.allImportedPhotoURLs should_not contain(suspectPhotoURL);
            });

            describe(@"tapping the edit button", ^{
                beforeEach(^{
                    [controller.editButtonItem tap];
                });

                itShouldBehaveLike(@"the DB suspect photo can be removed");

                itShouldBehaveLike(@"editing controls are enabled");
            });
        });

        context(@"when the lineup's suspect comes from the side-load", ^{
            beforeEach(^{
                lineup.fromDB = NO;

                [controller configureWithLineupStore:lineupStore lineup:lineup photoAssetImporter:photoAssetImporter suspectSearchSplitViewControllerProvider:suspectSearchSplitViewControllerProvider perpetratorDescriptionViewControllerProvider:perpetratorDescriptionViewControllerProvider suspectPortrayalsViewControllerProvider:suspectPortrayalsViewControllerProvider personSearchServiceProvider:personSearchServiceProvider delegate:delegate];

                controller.isViewLoaded should_not be_truthy;
                controller.view should_not be_nil;
                [controller viewWillAppear:NO];
                [controller.view layoutIfNeeded];
            });

            it(@"should show the suspect side-load UI", ^{
                controller.suspectPhotoCollectionView.hidden should_not be_truthy;
                controller.suspectCardView.hidden should be_truthy;
            });

            it(@"should prepopulate the fields with the lineup's data", ^{
                controller.caseIDTextField.text should equal(@"1234");
                controller.suspectNameTextField.text should equal(@"Jane Doe");
                LineupPhotoCell *suspectPhotoCell = [[controller.suspectPhotoCollectionView visibleCells] firstObject];
                [suspectPhotoCell.imageView.image isEqualToByBytes:[UIImage imageWithContentsOfFile:[suspectPhotoURL path]]] should be_truthy;
            });


            it(@"should add the suspect photo to the all imported photos array", ^{
                controller.allImportedPhotoURLs should contain(suspectPhotoURL);
            });

            describe(@"tapping the edit button", ^{
                beforeEach(^{
                    [controller.editButtonItem tap];
                });

                itShouldBehaveLike(@"the sideloaded suspect photo can be removed");

                itShouldBehaveLike(@"editing controls are enabled");
            });
        });

        describe(@"when the view appears", ^{
            __block Lineup *originalLineup;
            __block Lineup *originalLineupInstance;
            beforeEach(^{
                lineup.audioOnly = YES;
                originalLineupInstance = lineup;
                originalLineup = [lineup copy];
                [controller configureWithLineupStore:lineupStore lineup:lineup photoAssetImporter:photoAssetImporter suspectSearchSplitViewControllerProvider:suspectSearchSplitViewControllerProvider perpetratorDescriptionViewControllerProvider:perpetratorDescriptionViewControllerProvider suspectPortrayalsViewControllerProvider:suspectPortrayalsViewControllerProvider personSearchServiceProvider:personSearchServiceProvider delegate:delegate];

                controller.view should_not be_nil;
                [controller viewWillAppear:NO];
                [controller.view layoutIfNeeded];
            });

            itShouldBehaveLike(@"editing controls are disabled");

            it(@"should put the done button in the top-left corner", ^{
                controller.navigationItem.leftBarButtonItem should equal(controller.doneButton);
            });

            it(@"should allow the user to delete a new lineup", ^{
                controller.navigationItem.rightBarButtonItems should contain(controller.deleteButton);
            });

            it(@"should show the Case ID as the title", ^{
                controller.navigationItem.title should equal(@"1234");
            });

            it(@"should not show the suspect photo required label", ^{
                controller.suspectPhotoRequiredLabel.hidden should be_truthy;
            });

            it(@"should show whether the lineup is audio only", ^{
                controller.audioOnlySwitch.isOn should be_truthy;
            });

            describe(@"when the edit button is tapped", ^{
                beforeEach(^{
                    [controller.editButtonItem tap];
                });

                itShouldBehaveLike(@"editing controls are enabled");

                it(@"should put the cancel button in the top-left corner", ^{
                    controller.navigationItem.leftBarButtonItem should equal(controller.cancelButton);
                });

                describe(@"when the done button is tapped", ^{
                    beforeEach(^{
                        editField(controller.caseIDTextField, @"987654");
                        editField(controller.suspectNameTextField, @"Dubb Beh");
                        [controller.editButtonItem tap];
                    });

                    itShouldBehaveLike(@"editing controls are disabled");

                    it(@"should put the done button back in the top-left corner", ^{
                        controller.navigationItem.leftBarButtonItem should equal(controller.doneButton);
                    });

                    it(@"should update the title", ^{
                        controller.title should equal(@"987654");
                    });

                    itShouldBehaveLike(@"saving a lineup");
                });

                describe(@"when the cancel button is tapped", ^{
                    context(@"and no changes have been made", ^{
                        beforeEach(^{
                            [controller.cancelButton tap];
                            [controller.suspectPhotoCollectionView layoutIfNeeded];
                        });

                        it(@"should not show a confirmation alert", ^{
                            [UIAlertView currentAlertView] should be_nil;
                        });

                        itShouldBehaveLike(@"editing controls are disabled");

                        it(@"should not save the changes", ^{
                            lineupStore should_not have_received(@selector(updateLineup:));
                        });

                        it(@"should not notify the delegate", ^{
                            delegate should_not have_received(@selector(lineupViewControllerDidComplete:)).with(controller);
                        });

                        it(@"should revert the validation labels to their prior state", ^{
                            controller.suspectPhotoRequiredLabel.hidden should be_truthy;
                        });

                        it(@"should revert any modifications made to the lineup", ^{
                            controller.lineup should equal(originalLineup);
                            controller.lineup should be_same_instance_as(originalLineupInstance);
                        });
                    });

                    context(@"and changes have been made", ^{
                        beforeEach(^{
                            editField(controller.caseIDTextField, @"987654");
                            editField(controller.suspectNameTextField, @"Dubb Beh");

                            controller.lineup.fromDB = YES;
                            controller.suspectCardView.hidden = NO;

                            NSBundle *testBundle = [NSBundle bundleForClass:[self class]];
                            NSURL *cathyPhotoURL = [testBundle URLForResource:@"cathy" withExtension:@"jpg" subdirectory:@"SampleLineup"];

                            controller.suspectPhotoDataSource.photoURLs = @[ cathyPhotoURL ];

                            [controller.cancelButton tap];
                        });

                        it(@"should show a confirmation alert", ^{
                            UIAlertView *alert = [UIAlertView currentAlertView];
                            alert should_not be_nil;
                            alert.title should equal(@"Are you sure you want to cancel?");
                        });

                        describe(@"when the user aborts cancellation", ^{
                            beforeEach(^{
                                [[UIAlertView currentAlertView] dismissWithCancelButton];
                            });

                            itShouldBehaveLike(@"editing controls are enabled");

                            it(@"should still be in editing mode", ^{
                                controller.editing should be_truthy;
                            });

                            it(@"should not save the changes", ^{
                                lineupStore should_not have_received(@selector(updateLineup:));
                            });

                            it(@"should not notifiy its delegate about completion", ^{
                                delegate should_not have_received(@selector(lineupViewControllerDidComplete:));
                            });
                        });

                        describe(@"when the user confirms cancellation", ^{
                            beforeEach(^{
                                [[UIAlertView currentAlertView] dismissWithOkButton];

                                [controller.suspectPhotoCollectionView layoutIfNeeded];
                            });

                            itShouldBehaveLike(@"editing controls are disabled");

                            it(@"should go out of editing mode", ^{
                                controller.editing should be_falsy;
                            });

                            it(@"should not save the changes", ^{
                                lineupStore should_not have_received(@selector(updateLineup:));
                            });

                            it(@"should revert any modifications made to the lineup", ^{
                                controller.lineup should equal(originalLineup);
                                controller.lineup should be_same_instance_as(originalLineupInstance);
                            });

                            it(@"should not notify the delegate", ^{
                                delegate should_not have_received(@selector(lineupViewControllerDidComplete:)).with(controller);
                            });

                            it(@"should revert the validation labels to their prior state", ^{
                                controller.suspectPhotoRequiredLabel.hidden should be_truthy;
                            });

                            it(@"should revert the fields to their prior state", ^{
                                controller.caseIDTextField.text should equal(originalLineup.caseID);
                                controller.suspectNameTextField.text should equal(originalLineup.suspect.fullName);
                                controller.suspectCardView.hidden should be_truthy;
                            });
                        });
                    });
                });
            });

            describe(@"when the done button is tapped", ^{
                beforeEach(^{
                    [controller.doneButton tap];
                });

                it(@"should notifiy its delegate about completion", ^{
                    delegate should have_received(@selector(lineupViewControllerDidComplete:)).with(controller);
                });
            });
        });
    });

    describe(@"deleting a lineup", ^{
        __block Lineup *lineup;
        __block Lineup *deletedLineup;

        beforeEach(^{
            controller = [[UIStoryboard storyboardWithName:@"AdminFlow" bundle:nil] instantiateViewControllerWithIdentifier:@"LineupViewController"];

            deletedLineup = nil;
            lineup = [[Lineup alloc] init];
            lineup.caseID = @"4567";
            lineup.suspect.firstName = @"John";
            lineup.suspect.lastName = @"Smith";

            lineupStore stub_method(@selector(lineupWithUUID:)).with(lineup.UUID).and_return([lineup copy]);

            [controller configureWithLineupStore:lineupStore lineup:lineup photoAssetImporter:nil suspectSearchSplitViewControllerProvider:nil perpetratorDescriptionViewControllerProvider:nil suspectPortrayalsViewControllerProvider:nil personSearchServiceProvider:nil delegate:delegate];
            controller.view should_not be_nil;

            lineupStore stub_method(@selector(deleteLineup:)).and_do_block(^(Lineup *lineupToDelete){
               deletedLineup = lineupToDelete;
            });

            [controller.deleteButton tap];
        });

        it(@"should prompt the user for confirmation", ^{
            [UIAlertView currentAlertView] should_not be_nil;
            [UIAlertView currentAlertView].title should equal(@"Are you sure you want to delete this lineup?");
        });

        context(@"the user confirms the delete action", ^{
            beforeEach(^{
                [[UIAlertView currentAlertView] dismissWithOkButton];
            });

            it(@"should tell the store to remove the lineup from its storage", ^{
                deletedLineup.UUID should equal(lineup.UUID);
            });

            it(@"should indicate that it's finished with this lineup", ^{
                delegate should have_received(@selector(lineupViewControllerDidComplete:)).with(controller);
            });
        });

        context(@"the user aborts the delete action", ^{
            beforeEach(^{
                [[UIAlertView currentAlertView] dismissWithCancelButton];
            });

            it(@"should not tell the store to do anything", ^{
                deletedLineup should be_nil;
            });

            it(@"should return to lineup editing", ^{
                delegate should_not have_received(@selector(lineupViewControllerDidComplete:));
            });
        });
    });

    describe(@"selecting a suspect photo from photo library", ^{
        beforeEach(^{
            tapAddPhotoFromLibraryForSuspect();
        });

        it(@"should select the add photo cell", ^{
            findAddPhotoCell().selected should be_truthy;
        });

        it(@"should configure the suspect photo data source to allow adding one photo", ^{
            controller.suspectPhotoDataSource.maximumNumberOfPhotos should equal(1);
        });

        it(@"should provide the correct maximum selection count to the photo picker", ^{
            [controller maximumSelectionCountForPhotoPickerViewController:nil] should equal(1);
        });

        it(@"should present a photo picker controller", ^{
            controller.presentedViewController should be_instance_of([PortraitOnlyNavigationController class]);
            [(UINavigationController *)controller.presentedViewController topViewController] should be_instance_of([PhotoPickerViewController class]);
            [[(UINavigationController *)controller.presentedViewController topViewController] view] should_not be_nil;
        });

        it(@"should dismiss the photo picker controller when it receives a cancellation message", ^{
            spy_on(controller);
            [controller photoPickerViewControllerDidCancel:nil];
            controller should have_received(@selector(dismissViewControllerAnimated:completion:));
        });

        describe(@"when the controller appears again", ^{
            beforeEach(^{
                [controller viewWillAppear:NO];
            });

            it(@"should deselect the add photo cell", ^{
                findAddPhotoCell().selected should be_falsy;
            });
        });

        describe(@"after finishing selecting photos", ^{
            __block NSArray *assets;

            beforeEach(^{
                spy_on(controller);

                ALAsset *fakeAsset1 = [[ALTestAsset alloc] initWithImageURL:[[NSBundle bundleForClass:[self class]] URLForResource:@"nathan" withExtension:@"jpg" subdirectory:@"SampleLineup"]];
                assets = @[fakeAsset1];

                [controller photoPickerViewController:nil didSelectAssets:assets];
                [controller.suspectPhotoCollectionView layoutIfNeeded];
            });

            it(@"should dismiss the photo picker controller", ^{
                controller should have_received(@selector(dismissViewControllerAnimated:completion:));
            });

            it(@"should copy the selected images into the app sandbox when it receives a completion message", ^{
                photoAssetImporter should have_received(@selector(importAssets:)).with(assets);
            });

            it(@"should present each selected photo to the user", ^{
                LineupPhotoCell *cell = (LineupPhotoCell *)[controller.suspectPhotoCollectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
                cell should be_instance_of([LineupPhotoCell class]);
                [cell.imageView.image isEqualToByBytes:[UIImage imageWithCGImage:[assets[0] defaultRepresentation].fullScreenImage]] should be_truthy;
            });
        });
    });

    describe(@"when the view disappears", ^{
        beforeEach(^{
            controller = [[UIStoryboard storyboardWithName:@"AdminFlow" bundle:nil] instantiateViewControllerWithIdentifier:@"LineupViewController"];

            Lineup *lineup = [[Lineup alloc] init];
            lineupStore stub_method(@selector(lineupWithUUID:)).with(lineup.UUID).and_return([lineup copy]);
            lineup.suspect.portrayals = @[[[Portrayal alloc] initWithPhotoURL:[NSURL URLWithString:@"/original/suspect/photo"] date:[NSDate date]]];

            [controller configureWithLineupStore:lineupStore lineup:lineup photoAssetImporter:nil suspectSearchSplitViewControllerProvider:nil perpetratorDescriptionViewControllerProvider:nil suspectPortrayalsViewControllerProvider:nil personSearchServiceProvider:nil delegate:delegate];

            controller.lineup.suspect.portrayals = @[[[Portrayal alloc] initWithPhotoURL:[NSURL URLWithString:@"/suspect/photo"] date:[NSDate date]]];
            controller.lineup.fillerPhotosFileURLs = @[[NSURL URLWithString:@"/filler/photo"]];

            [controller.allImportedPhotoURLs addObject:[NSURL URLWithString:@"/unused/photo"]];
            [controller.allImportedPhotoURLs addObject:[controller.lineup.suspect.portrayals.firstObject photoURL]];
            [controller.allImportedPhotoURLs addObjectsFromArray:controller.lineup.fillerPhotosFileURLs];

            controller.view should_not be_nil;
            spy_on([NSFileManager defaultManager]);

            [controller viewWillDisappear:NO];
        });

        it(@"should remove photos that were previously part of the lineup but were removed", ^{
            [NSFileManager defaultManager] should have_received(@selector(removeItemAtURL:error:)).with([NSURL URLWithString:@"/original/suspect/photo"], Arguments::anything);
        });

        it(@"should remove photos selected during editing but not in the final lineup", ^{
            [NSFileManager defaultManager] should have_received(@selector(removeItemAtURL:error:)).with([NSURL URLWithString:@"/unused/photo"], Arguments::anything);
        });
    });

    describe(@"when coming from a suspect search", ^{
        __block Person *person;

        beforeEach(^{
            person = [PersonFactory leon];

            SuspectPortrayalsViewController *suspectPortrayalsViewController = nice_fake_for([SuspectPortrayalsViewController class]);
            suspectPortrayalsViewController stub_method(@selector(person)).and_return(person);

            UIStoryboardSegue *segue = fake_for([UIStoryboardSegue class]);
            segue stub_method(@selector(sourceViewController)).and_return(suspectPortrayalsViewController);

            Lineup *lineup = [[Lineup alloc] init];
            lineupStore stub_method(@selector(lineupWithUUID:)).with(lineup.UUID).and_return([lineup copy]);

            [controller configureWithLineupStore:lineupStore lineup:lineup photoAssetImporter:photoAssetImporter suspectSearchSplitViewControllerProvider:suspectSearchSplitViewControllerProvider perpetratorDescriptionViewControllerProvider:perpetratorDescriptionViewControllerProvider suspectPortrayalsViewControllerProvider:suspectPortrayalsViewControllerProvider personSearchServiceProvider:personSearchServiceProvider delegate:delegate];

            controller.view should_not be_nil;
            spy_on(controller.suspectCardView);

            [controller exitToLineup:segue];
            [controller viewWillAppear:NO];
        });

        context(@"tapping the supect card view", ^{
            __block PersonSearchService *personSearchService;
            __block KSDeferred *personSearchDeferred;

            beforeEach(^{
                personSearchService = fake_for([PersonSearchService class]);
                personSearchDeferred = [KSDeferred defer];
                personSearchService stub_method(@selector(personResultsForFirstName:lastName:suspectID:)).with(@"", @"", person.systemID).and_return(personSearchDeferred.promise);
                personSearchServiceProvider stub_method(@selector(personSearchService)).and_return(personSearchService);
                [controller.suspectCardView tap];
            });

            describe(@"when the search service returns the person", ^{
                __block Person *personFromDatabase;
                __block SuspectPortrayalsViewController *suspectPortrayalsViewController;

                beforeEach(^{
                    personFromDatabase = [PersonFactory larry];
                    suspectPortrayalsViewController = [[SuspectPortrayalsViewController alloc] init];
                    suspectPortrayalsViewControllerProvider stub_method(@selector(suspectPortrayalsViewControllerWithPerson:)).with(personFromDatabase).and_return(suspectPortrayalsViewController);
                    [personSearchDeferred resolveWithValue:@[personFromDatabase]];
                });

                it(@"should display the suspect portrayals view controller in a navigation controller", ^{
                    [(UINavigationController *)controller.presentedViewController topViewController] should be_same_instance_as(suspectPortrayalsViewController);
                });

                it(@"should set the selected portrayal on the search result", ^{
                    personFromDatabase.selectedPortrayal should be_same_instance_as(person.selectedPortrayal);
                });
            });

            describe(@"when the search service doesn't return the person", ^{
                beforeEach(^{
                    [personSearchDeferred resolveWithValue:@[]];
                });

                it(@"should alert the user", ^{
                    [UIAlertView currentAlertView] should_not be_nil;
                });
            });
        });

        it(@"should set the suspect and mark the lineup source", ^{
            controller.lineup.suspect should be_same_instance_as(person);
            controller.lineup.isFromDB should be_truthy;
        });

        it(@"should configure the suspect card view with the person", ^{
            controller.suspectCardView should have_received(@selector(configureWithPerson:faceLoader:)).with(person, Arguments::any([FaceLoader class]));
        });

        it(@"should hide the suspect side-load UI", ^{
            controller.suspectPhotoCollectionView.hidden should be_truthy;
        });

        it(@"should not add the suspect's photo to the all imported photo array", ^{
            controller.allImportedPhotoURLs should_not contain(person.selectedPortrayal.photoURL);
        });
    });
});

SPEC_END
