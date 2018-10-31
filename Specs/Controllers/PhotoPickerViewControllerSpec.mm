#import "PhotoPickerViewControllerDelegate.h"
#import "PhotoPickerViewController.h"
#import "PhotoPickerDataSource.h"
#import "PhotoPickerCell.h"
#import "ALTestAsset.h"
#import "FaceLocator.h"
#import "CedarAsync.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

@interface PhotoPickerViewController ()
@property (nonatomic, strong) PhotoPickerDataSource *dataSource;
@end

@interface PhotoPickerDataSource (Spec)
@property (nonatomic, strong) NSArray *currentAlbumAssets;
@end

SPEC_BEGIN(PhotoPickerViewControllerSpec)

describe(@"PhotoPickerViewController", ^{
    __block PhotoPickerViewController *controller;
    __block id<PhotoPickerViewControllerDelegate> delegate;
    __block PhotoPickerDataSource *dataSource;

    __block NSURL *importedImage1URL;
    __block NSURL *importedImage2URL;
    __block NSURL *cameraRollImage1URL;
    __block NSURL *cameraRollImage2URL;

    __block ALTestAsset *fakeImportedAsset1;
    __block ALTestAsset *fakeImportedAsset2;
    __block ALTestAsset *fakeCameraRollAsset1;
    __block ALTestAsset *fakeCameraRollAsset2;

    __block PhotoPickerCell *photoPickerCell1;
    __block PhotoPickerCell *photoPickerCell2;

    __block KSDeferred *albumSelectionDeferred;

    void(^selectAlbumOfType)(PhotoPickerAlbumType index) = ^(PhotoPickerAlbumType index) {
        switch (index) {
            case PhotoPickerAlbumTypeLastImport:
                controller.dataSource.currentAlbumAssets = @[fakeImportedAsset1, fakeImportedAsset2];
                break;
            case PhotoPickerAlbumTypeAllImported:
                controller.dataSource.currentAlbumAssets = @[fakeImportedAsset1, fakeImportedAsset2];
                break;
            case PhotoPickerAlbumTypeCameraRoll:
                controller.dataSource.currentAlbumAssets = @[fakeCameraRollAsset1, fakeCameraRollAsset2];
                break;
            default:
                break;
        }

        albumSelectionDeferred = [KSDeferred defer];

        controller.albumTypeSegmentedControl.selectedSegmentIndex = index;
        [controller.albumTypeSegmentedControl sendActionsForControlEvents:UIControlEventValueChanged];

        [albumSelectionDeferred resolveWithValue:nil];
        [controller.photosCollectionView layoutIfNeeded];
        photoPickerCell1 = controller.photosCollectionView.visibleCells[0];
        photoPickerCell2 = controller.photosCollectionView.visibleCells[1];
    };

    beforeEach(^{
        controller = [[UIStoryboard storyboardWithName:@"AdminFlow" bundle:nil] instantiateViewControllerWithIdentifier:@"PhotoPickerViewController"];

        importedImage1URL = [[NSBundle bundleForClass:[self class]] URLForResource:@"cathy" withExtension:@"jpg" subdirectory:@"SampleLineup"];
        importedImage2URL = [[NSBundle bundleForClass:[self class]] URLForResource:@"Brian" withExtension:@"jpg" subdirectory:@"SampleLineup"];
        cameraRollImage1URL = [[NSBundle bundleForClass:[self class]] URLForResource:@"alex" withExtension:@"jpg" subdirectory:@"SampleLineup"];
        cameraRollImage2URL = [[NSBundle bundleForClass:[self class]] URLForResource:@"nathan" withExtension:@"jpg" subdirectory:@"SampleLineup"];

        fakeImportedAsset1 = [[ALTestAsset alloc] initWithImageURL:importedImage1URL];
        fakeImportedAsset2 = [[ALTestAsset alloc] initWithImageURL:importedImage2URL];

        fakeCameraRollAsset1 = [[ALTestAsset alloc] initWithImageURL:cameraRollImage1URL];
        fakeCameraRollAsset2 = [[ALTestAsset alloc] initWithImageURL:cameraRollImage2URL];

        dataSource = [[PhotoPickerDataSource alloc] init];
        spy_on(dataSource);

        ALAssetsLibrary *assetsLibrary = nice_fake_for([ALAssetsLibrary class]);
        [dataSource configureWithAssetsLibrary:assetsLibrary faceLocator:nil faceCache:nil];
        dataSource.assetsLibrary should_not be_nil;

        KSDeferred *assetsDeferred = [KSDeferred defer];
        dataSource stub_method(@selector(assetsForAssetURLs:)).and_return(assetsDeferred.promise);
        [assetsDeferred resolveWithValue:[NSSet setWithObject:fakeCameraRollAsset2]];

        delegate = nice_fake_for(@protocol(PhotoPickerViewControllerDelegate));

        [controller configureWithDelegate:delegate dataSource:dataSource selectedAssetURLs:@[cameraRollImage2URL]];

        controller.dataSource stub_method(@selector(changeAlbumType:)).and_do_block(^KSPromise *(PhotoPickerAlbumType albumType){
            return albumSelectionDeferred.promise;
        });

        selectAlbumOfType(PhotoPickerAlbumTypeLastImport);

        controller.view should_not be_nil;
    });

    describe(@"when the view loads", ^{
        beforeEach(^{
            selectAlbumOfType(PhotoPickerAlbumTypeLastImport);
        });

        it(@"should show the assets", ^{
            dataSource should have_received(@selector(collectionView:cellForItemAtIndexPath:)).with(Arguments::any([UICollectionView class]), [NSIndexPath indexPathForItem:0 inSection:0]);
        });

        context(@"with previously selected assets", ^{
            it(@"should initially select the items corresponding to the selected assets provided", ^{
                selectAlbumOfType(PhotoPickerAlbumTypeCameraRoll);
                [controller.photosCollectionView.visibleCells[1] isSelected] should be_truthy;
            });

            it(@"should show the selection button with the correct label", ^{
                controller.navigationItem.rightBarButtonItem.title should equal(@"Select Photo");
            });
        });
    });

    describe(@"when not configured with a delegate", ^{
        beforeEach(^{
            controller = [[UIStoryboard storyboardWithName:@"AdminFlow" bundle:nil] instantiateViewControllerWithIdentifier:@"PhotoPickerViewController"];
            [controller configureWithDelegate:nil dataSource:nice_fake_for([PhotoPickerDataSource class]) selectedAssetURLs:nil];
        });

        it(@"should blow up when its view is loaded", ^{
            ^{ [controller view]; } should raise_exception;
        });
    });

    describe(@"when not configured with a data source", ^{
        beforeEach(^{
            controller = [[UIStoryboard storyboardWithName:@"AdminFlow" bundle:nil] instantiateViewControllerWithIdentifier:@"PhotoPickerViewController"];
            [controller configureWithDelegate:nice_fake_for(@protocol(PhotoPickerViewControllerDelegate)) dataSource:nil selectedAssetURLs:nil];
        });

        it(@"should blow up when its view is loaded", ^{
            ^{ [controller view]; } should raise_exception;
        });
    });

    describe(@"album switching", ^{
        beforeEach(^{
            delegate stub_method(@selector(maximumSelectionCountForPhotoPickerViewController:)).and_return((NSUInteger)6);

            selectAlbumOfType(PhotoPickerAlbumTypeLastImport);

            [photoPickerCell1 tap];

            spy_on(controller.photosCollectionView);

            selectAlbumOfType(PhotoPickerAlbumTypeAllImported);
        });

        it(@"should switch to the All Imported album type", ^{
            controller.dataSource should have_received(@selector(changeAlbumType:)).with(PhotoPickerAlbumTypeAllImported);
        });

        context(@"when the album assets have finished loading", ^{
            it(@"should reload the collection view", ^{
                controller.photosCollectionView should have_received(@selector(reloadData));
            });
        });

        context(@"when the album switches back", ^{
            beforeEach(^{
                selectAlbumOfType(PhotoPickerAlbumTypeLastImport);
            });

            it(@"should preserve the selected index paths from the 'Last Import' album", ^{
                controller.photosCollectionView.indexPathsForSelectedItems should equal(@[[NSIndexPath indexPathForItem:0 inSection:0]]);
            });
        });

        context(@"when a cell is deselected", ^{
            beforeEach(^{
                selectAlbumOfType(PhotoPickerAlbumTypeLastImport);

                [photoPickerCell1 tap];

                selectAlbumOfType(PhotoPickerAlbumTypeAllImported);
                selectAlbumOfType(PhotoPickerAlbumTypeLastImport);
            });

            it(@"should not have that cell selected", ^{
                controller.selectedAssets should_not contain(fakeImportedAsset1);
            });
        });
    });

    describe(@"cancellation", ^{
        beforeEach(^{
            [controller.cancelItem tap];
        });

        it(@"should notify its delegate that the cancel button was tapped", ^{
            delegate should have_received(@selector(photoPickerViewControllerDidCancel:)).with(controller);
        });
    });

    describe(@"photo selection", ^{
        context(@"when the user has not yet selected the maximum number of photos", ^{
            beforeEach(^{
                selectAlbumOfType(PhotoPickerAlbumTypeLastImport);
                delegate stub_method(@selector(maximumSelectionCountForPhotoPickerViewController:)).and_return((NSUInteger)6);
                [photoPickerCell1 tap];
                [photoPickerCell2 tap];
            });

            it(@"should show a selection button when at least one photo is selected", ^{
                controller.navigationItem.rightBarButtonItem.title should equal(@"Select 3 Photos");
            });
        });

        context(@"when the user has already selected the maximum number of photos", ^{
            beforeEach(^{
                selectAlbumOfType(PhotoPickerAlbumTypeLastImport);
                delegate stub_method(@selector(maximumSelectionCountForPhotoPickerViewController:)).and_return((NSUInteger)1);
                [photoPickerCell1 tap];
                [photoPickerCell2 tap];
            });

            it(@"should only select the second photo", ^{
                controller.selectedAssets should equal(@[fakeImportedAsset2]);
            });
        });
    });

    describe(@"photo deselection", ^{
        beforeEach(^{
            selectAlbumOfType(PhotoPickerAlbumTypeLastImport);
            delegate stub_method(@selector(maximumSelectionCountForPhotoPickerViewController:)).and_return((NSUInteger)6);
            [photoPickerCell1 tap];
            [photoPickerCell2 tap];
            [photoPickerCell1 tap];
        });

        it(@"should show a selection button when at least one photo is still selected", ^{
            controller.selectedAssets should equal(@[fakeCameraRollAsset2, fakeImportedAsset2]);
            controller.navigationItem.rightBarButtonItem.title should equal(@"Select 2 Photos");
        });
    });

    describe(@"completing a selection", ^{
        beforeEach(^{
            selectAlbumOfType(PhotoPickerAlbumTypeLastImport);
            delegate stub_method(@selector(maximumSelectionCountForPhotoPickerViewController:)).and_return((NSUInteger)6);
            [photoPickerCell1 tap];

            selectAlbumOfType(PhotoPickerAlbumTypeCameraRoll);

            [photoPickerCell1 tap];

            [controller.navigationItem.rightBarButtonItem tap];
        });

        it(@"should notify its delegate that the select button was tapped", ^{
            delegate should have_received(@selector(photoPickerViewController:didSelectAssets:)).with(controller, @[fakeCameraRollAsset2, fakeImportedAsset1, fakeCameraRollAsset1]);
        });
    });
});

SPEC_END
