#import "LineupFillerPhotosViewController.h"
#import "LineupPhotoCell.h"
#import "Lineup.h"
#import "AddPhotoCell.h"
#import "ImportingPhotoPickerViewController.h"
#import "CedarAsync.h"
#import "PhotoAssetImporter.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(LineupFillerPhotosViewControllerSpec)

describe(@"LineupFillerPhotosViewController", ^{
    __block LineupFillerPhotosViewController *controller;
    __block Lineup *lineup;
    __block PhotoAssetImporter *photoAssetImporter;
    NSArray *maximumFillerPhotos = [[NSBundle bundleForClass:[self class]] URLsForResourcesWithExtension:@"jpg" subdirectory:@"SampleLineup"];
    NSArray *insufficientFillerPhotos = @[ maximumFillerPhotos[0], maximumFillerPhotos[1], maximumFillerPhotos[2] ];
    NSArray *sufficientFillerPhotos = @[ maximumFillerPhotos[0], maximumFillerPhotos[1], maximumFillerPhotos[2], maximumFillerPhotos[3], maximumFillerPhotos[4] ];

    void(^configureAndPresentController)() = ^{
        [controller configureWithLineup:lineup photoAssetImporter:photoAssetImporter];
        [UIApplication showViewController:controller];
    };

    void(^configureAndPresentControllerInEditingMode)() = ^{
        configureAndPresentController();
        controller.editing = YES;
    };

    AddPhotoCell *(^findAddPhotoCell)() = ^AddPhotoCell *{
        UICollectionViewCell *cell = [controller.photoCollectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:lineup.fillerPhotosFileURLs.count inSection:0]];
        if (cell) {
            cell should be_instance_of([AddPhotoCell class]);
        }
        return (AddPhotoCell *)cell;
    };

    NSArray *(^visiblePhotoCells)() = ^NSArray * {
        return [controller.photoCollectionView.visibleCells filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"class = %@", [LineupPhotoCell class]]];
    };

    beforeEach(^{
        maximumFillerPhotos.count should equal([Lineup maximumNumberOfFillerPhotos]);
        insufficientFillerPhotos.count should be_less_than([Lineup minimumNumberOfFillerPhotos]);
        sufficientFillerPhotos.count should be_gte([Lineup minimumNumberOfFillerPhotos]);
        sufficientFillerPhotos.count should be_less_than([Lineup maximumNumberOfFillerPhotos]);

        controller = [[UIStoryboard storyboardWithName:@"AdminFlow" bundle:nil] instantiateViewControllerWithIdentifier:@"LineupFillerPhotosViewController"];
        lineup = [[Lineup alloc] init];
        photoAssetImporter = nice_fake_for([PhotoAssetImporter class]);
    });

    sharedExamplesFor(@"displaying the photos from the lineup", ^(NSDictionary *sharedContext) {
        it(@"should display filler photos from the lineup", ^{
            in_time(visiblePhotoCells().count) should equal(lineup.fillerPhotosFileURLs.count);

            for (LineupPhotoCell *cell in visiblePhotoCells()) {
                NSInteger photoIndex = [controller.photoCollectionView indexPathForCell:cell].item;
                UIImage *expectedImage = [UIImage imageWithContentsOfFile:[lineup.fillerPhotosFileURLs[photoIndex] path]];
                [[cell imageView].image isEqualToByBytes:expectedImage] should be_truthy;
            }
        });
    });

    sharedExamplesFor(@"the validation message is shown", ^(NSDictionary *sharedContext) {
        it(@"should show the validation message", ^{
            controller.fillerPhotosRequiredLabel.hidden should be_falsy;
            NSString *requiredLabelText = [NSString stringWithFormat:@"AT LEAST %i FILLERS REQUIRED FOR PRESENTATION", [Lineup minimumNumberOfFillerPhotos]];
            controller.fillerPhotosRequiredLabel.text should equal(requiredLabelText);
        });
    });

    sharedExamplesFor(@"the validation message is not shown", ^(NSDictionary *sharedContext) {
        it(@"should not show the validation message", ^{
            controller.fillerPhotosRequiredLabel.hidden should be_truthy;
        });
    });

    describe(@"when there are insufficient lineup filler photos", ^{
        beforeEach(^{
            lineup.fillerPhotosFileURLs = insufficientFillerPhotos;
            configureAndPresentController();
        });

        itShouldBehaveLike(@"the validation message is shown");

        itShouldBehaveLike(@"displaying the photos from the lineup");
    });

    describe(@"when there are sufficient lineup filler photos", ^{
        beforeEach(^{
            lineup.fillerPhotosFileURLs = sufficientFillerPhotos;
            configureAndPresentController();
        });

        itShouldBehaveLike(@"the validation message is not shown");

        itShouldBehaveLike(@"displaying the photos from the lineup");
    });

    describe(@"when the controller enters editing mode", ^{
        sharedExamplesFor(@"putting all photo cells into edit mode", ^(NSDictionary *sharedContext) {
            it(@"should put all photo cells into editing mode", ^{
                visiblePhotoCells() should_not be_empty;
                for(LineupPhotoCell *cell in visiblePhotoCells()) {
                    cell.editing should be_truthy;
                }
            });
        });

        context(@"and the maximum number of fillers has been met", ^{
            beforeEach(^{
                lineup.fillerPhotosFileURLs = maximumFillerPhotos;
                configureAndPresentControllerInEditingMode();
            });

            itShouldBehaveLike(@"putting all photo cells into edit mode");

            it(@"should not show the add photo cell", ^{
                findAddPhotoCell() should be_nil;
            });

            describe(@"and a filler is removed", ^{
                void(^deleteFirstCell)() = ^{
                    UICollectionViewCell *cell = [controller.photoCollectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
                    cell should be_instance_of([LineupPhotoCell class]);
                    [[(LineupPhotoCell *)cell deleteButton] tap];
                };

                beforeEach(^{
                    deleteFirstCell();
                });

                context(@"and the minimum number of fillers has not been met", ^{
                    beforeEach(^{
                        while (controller.photoCollectionView.visibleCells.count - 1 >= [Lineup minimumNumberOfFillerPhotos]) {
                            deleteFirstCell();
                        }
                    });

                    itShouldBehaveLike(@"the validation message is shown");
                });

                itShouldBehaveLike(@"displaying the photos from the lineup");

                it(@"should update the lineup", ^{
                    lineup.fillerPhotosFileURLs should equal([maximumFillerPhotos subarrayWithRange:NSMakeRange(1, maximumFillerPhotos.count - 1)]);
                });

                it(@"should show the add photo cell", ^{
                    findAddPhotoCell() should_not be_nil;
                });
            });
        });

        context(@"the maximum number of fillers has not been met", ^{
            beforeEach(^{
                lineup.fillerPhotosFileURLs = insufficientFillerPhotos;
                configureAndPresentControllerInEditingMode();
            });

            itShouldBehaveLike(@"putting all photo cells into edit mode");

            it(@"should show the add photo cell", ^{
                findAddPhotoCell() should_not be_nil;
            });

            describe(@"and the add photo cell is tapped", ^{
                beforeEach(^{
                    [findAddPhotoCell() tap];
                });

                it(@"should select the add photo cell", ^{
                    findAddPhotoCell().selected should be_truthy;
                });

                it(@"should display a photo picker view controller", ^{
                    [(UINavigationController *)controller.presentedViewController topViewController] should be_instance_of([ImportingPhotoPickerViewController class]);
                });

                sharedExamplesFor(@"updating the model and displayed photos in response to selected assets", ^(NSDictionary *sharedContext) {
                    itShouldBehaveLike(@"displaying the photos from the lineup");

                    it(@"should dismiss the presented view controller", ^{
                        controller.presentedViewController should be_nil;
                    });

                    it(@"should update the lineup", ^{
                        lineup.fillerPhotosFileURLs should equal(sharedContext[@"importedPhotos"]);
                    });
                });

                describe(@"when the photo picker asks what the maximum number of photos is", ^{
                    it(@"should return the maximum number of filler photos", ^{
                        [controller maximumSelectionCountForPhotoPickerViewController:nil] should equal(Lineup.maximumNumberOfFillerPhotos);
                    });
                });

                describe(@"when the controller appears again", ^{
                    beforeEach(^{
                        [UIApplication redisplayViewController];
                    });

                    it(@"should deselect the add photo cell", ^{
                        findAddPhotoCell().selected should be_falsy;
                    });
                });

                describe(@"when the photo picker cancels", ^{
                    __block NSArray *visiblePhotoCellsBeforeCancelation;

                    beforeEach(^{
                        visiblePhotoCellsBeforeCancelation = visiblePhotoCells();
                        [controller photoPickerViewControllerDidCancel:nil];
                    });

                    it(@"should dismiss the presented view controller", ^{
                        controller.presentedViewController should be_nil;
                    });

                    it(@"should not change the displayed cells", ^{
                        visiblePhotoCells() should equal(visiblePhotoCellsBeforeCancelation);
                    });
                });

                describe(@"and the photo picker view controller returns", ^{
                    context(@"and the minimum number of fillers has been met", ^{
                        beforeEach(^{
                            SpecHelper.specHelper.sharedExampleContext[@"importedPhotos"] = sufficientFillerPhotos;
                            [controller photoPickerViewController:nil didImportPhotoURLs:sufficientFillerPhotos];
                        });

                        itShouldBehaveLike(@"updating the model and displayed photos in response to selected assets");

                        itShouldBehaveLike(@"the validation message is not shown");
                    });

                    context(@"and the minimum number of fillers has not been met", ^{
                        beforeEach(^{
                            SpecHelper.specHelper.sharedExampleContext[@"importedPhotos"] = insufficientFillerPhotos;
                            [controller photoPickerViewController:nil didImportPhotoURLs:insufficientFillerPhotos];
                        });

                        itShouldBehaveLike(@"updating the model and displayed photos in response to selected assets");

                        itShouldBehaveLike(@"the validation message is shown");
                    });

                    context(@"and the maximum number of fillers has been met", ^{
                        beforeEach(^{
                            SpecHelper.specHelper.sharedExampleContext[@"importedPhotos"] = maximumFillerPhotos;
                            [controller photoPickerViewController:nil didImportPhotoURLs:maximumFillerPhotos];
                        });

                        itShouldBehaveLike(@"updating the model and displayed photos in response to selected assets");

                        itShouldBehaveLike(@"the validation message is not shown");
                    });
                });
            });
        });
    });

    describe(@"when the lineup has been changed externally and the controller leaves editing mode", ^{
        context(@"and there are now an insufficient number of photos", ^{
            beforeEach(^{
                lineup.fillerPhotosFileURLs = sufficientFillerPhotos;
                configureAndPresentControllerInEditingMode();
                lineup.fillerPhotosFileURLs = insufficientFillerPhotos;
                controller.editing = NO;
            });

            itShouldBehaveLike(@"displaying the photos from the lineup");

            itShouldBehaveLike(@"the validation message is shown");
        });

        context(@"and there are now a sufficient number of photos ", ^{
            beforeEach(^{
                lineup.fillerPhotosFileURLs = insufficientFillerPhotos;
                configureAndPresentControllerInEditingMode();
                lineup.fillerPhotosFileURLs = sufficientFillerPhotos;
                controller.editing = NO;
            });

            itShouldBehaveLike(@"displaying the photos from the lineup");

            itShouldBehaveLike(@"the validation message is not shown");
        });
    });

    describe(@"when the controller leaves editing mode", ^{
        beforeEach(^{
            lineup.fillerPhotosFileURLs = insufficientFillerPhotos;
            configureAndPresentControllerInEditingMode();
            controller.editing = NO;
        });

        it(@"should hide the add photo cell", ^{
            findAddPhotoCell() should be_nil;
        });

        it(@"should take all photo cells out of editing mode", ^{
            in_time(visiblePhotoCells()) should_not be_empty;
            for(LineupPhotoCell *cell in visiblePhotoCells()) {
                cell.editing should be_falsy;
            }
        });
    });

    describe(@"when preparing for segue", ^{
        __block ImportingPhotoPickerViewController *photoPickerViewController;
        beforeEach(^{
            lineup.fillerPhotosFileURLs = sufficientFillerPhotos;
            configureAndPresentController();

            photoPickerViewController = [[ImportingPhotoPickerViewController alloc] init];
            spy_on(photoPickerViewController);

            UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:photoPickerViewController];
            UIStoryboardSegue *segue = [[UIStoryboardSegue alloc] initWithIdentifier:@"ShowPhotoPickerForFillers" source:controller destination:navController];
            [controller prepareForSegue:segue sender:nil];
        });

        it(@"should configure the photo picker controller with the selected asset urls", ^{
            photoPickerViewController should have_received(@selector(configureWithDelegate:assetLibrary:selectedPhotoURLs:photoAssetImporter:)).with(controller, Arguments::any([ALAssetsLibrary class]), lineup.fillerPhotosFileURLs, photoAssetImporter);
        });
    });
});

SPEC_END
