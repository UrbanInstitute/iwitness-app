#import "ImportingPhotoPickerViewControllerDelegate.h"
#import "ImportingPhotoPickerViewController.h"
#import "PhotoAssetImporter.h"
#import "PhotoPickerDataSource.h"
#import "PhotoPickerCell.h"
#import "CedarAsync.h"
#import "ALTestAsset.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(ImportingPhotoPickerViewControllerSpec)

describe(@"ImportingPhotoPickerViewController", ^{
    __block ImportingPhotoPickerViewController *controller;
    __block id<ImportingPhotoPickerViewControllerDelegate> delegate;
    __block ALAssetsLibrary *assetsLibrary;
    __block PhotoAssetImporter *photoAssetImporter;
    __block NSArray *selectedPhotoURLs;

    NSArray *assetURLs = [[NSBundle bundleForClass:[self class]] URLsForResourcesWithExtension:@"jpg" subdirectory:@"SampleLineup"];
    NSArray *assets = [assetURLs collect:^ALAsset *(NSURL* url) {
        return [[ALTestAsset alloc] initWithImageURL:url];
    }];
    ALAsset *sharedAsset = assets[1];
    NSArray *lastImportAssets = @[assets[0], sharedAsset, assets[2]];
    NSArray *allImportedAssets = @[sharedAsset];

    NSUInteger maxNumberOfSelectedPhotos = 2;

    void(^configureAndPresentController)() = ^{
        [controller configureWithDelegate:delegate assetLibrary:assetsLibrary selectedPhotoURLs:selectedPhotoURLs photoAssetImporter:photoAssetImporter];
        [UIApplication showViewController:controller];
    };

    beforeEach(^{
        controller = [[UIStoryboard storyboardWithName:@"AdminFlow" bundle:nil] instantiateViewControllerWithIdentifier:@"ImportingPhotoPickerViewController"];

        delegate = nice_fake_for(@protocol(ImportingPhotoPickerViewControllerDelegate));
        delegate stub_method(@selector(maximumSelectionCountForPhotoPickerViewController:)).with(controller).and_return(maxNumberOfSelectedPhotos);

        photoAssetImporter = nice_fake_for([PhotoAssetImporter class]);

        assetsLibrary = nice_fake_for([ALAssetsLibrary class]);

        void (^assetsGroupEnumeration)(ALAssetsGroupEnumerationResultsBlock, NSArray *) = ^(ALAssetsGroupEnumerationResultsBlock enumerationBlock, NSArray *assetsToReturn){
            BOOL stop;

            for (ALAsset *asset in assetsToReturn) {
                enumerationBlock(asset, 0, &stop);
            }
        };

        ALAssetsGroup *assetsGroup = nice_fake_for([ALAssetsGroup class]);
        assetsGroup stub_method(@selector(enumerateAssetsUsingBlock:)).and_do_block(^(ALAssetsGroupEnumerationResultsBlock enumerationBlock){
            assetsGroupEnumeration(enumerationBlock, lastImportAssets);
        });

        assetsGroup stub_method(@selector(valueForProperty:)).with(ALAssetsGroupPropertyName).and_return(@"Last Import");

        ALAssetsGroup *assetsGroup2 = nice_fake_for([ALAssetsGroup class]);
        assetsGroup2 stub_method(@selector(enumerateAssetsUsingBlock:)).and_do_block(^(ALAssetsGroupEnumerationResultsBlock enumerationBlock){
            assetsGroupEnumeration(enumerationBlock, allImportedAssets);
        });

        assetsGroup2 stub_method(@selector(valueForProperty:)).with(ALAssetsGroupPropertyName).and_return(@"All Imported");

        assetsLibrary = nice_fake_for([ALAssetsLibrary class]);
        assetsLibrary stub_method(@selector(enumerateGroupsWithTypes:usingBlock:failureBlock:)).and_do_block(^(ALAssetsGroupType groupType, ALAssetsLibraryGroupsEnumerationResultsBlock enumerationBlock, ALAssetsLibraryAccessFailureBlock failureBlock){
            BOOL stop;
            enumerationBlock(assetsGroup, &stop);
            enumerationBlock(assetsGroup2, &stop);
            enumerationBlock(nil, &stop);
        });
    });

    describe(@"when configured without selected assets", ^{
        beforeEach(^{
            selectedPhotoURLs = @[];
            configureAndPresentController();
        });

        it(@"should display photos from the asset library", ^{
            in_time(controller.photosCollectionView.visibleCells.count) should equal(lastImportAssets.count);

            for (PhotoPickerCell *cell in controller.photosCollectionView.visibleCells) {
                NSInteger photoIndex = [controller.photosCollectionView indexPathForCell:cell].item;
                UIImage *expectedImage = [UIImage imageWithCGImage:[lastImportAssets[photoIndex] aspectRatioThumbnail]];
                in_time([[cell imageView].image isEqualToByBytes:expectedImage]) should be_truthy;
            }
        });

        it(@"should not show the 'Select Photo' navigation item", ^{
            controller.navigationItem.rightBarButtonItem should be_nil;
        });

        it(@"should show the default asset category (last import) is selected", ^{
            controller.albumTypeSegmentedControl.selectedSegmentIndex should equal(PhotoPickerAlbumTypeLastImport);
        });

        describe(@"when the cancel button is tapped", ^{
            beforeEach(^{
                [controller.cancelItem tap];
            });

            it(@"should inform the delegate", ^{
                delegate should have_received(@selector(photoPickerViewControllerDidCancel:)).with(controller);
            });
        });

        describe(@"when the another asset category is chosen", ^{
            beforeEach(^{
                controller.albumTypeSegmentedControl.selectedSegmentIndex should_not equal(PhotoPickerAlbumTypeCameraRoll);
                controller.albumTypeSegmentedControl.selectedSegmentIndex = PhotoPickerAlbumTypeAllImported;
                [controller.albumTypeSegmentedControl sendActionsForControlEvents:UIControlEventValueChanged];
            });

            it(@"should display the assets in that category", ^{
                in_time(controller.photosCollectionView.visibleCells.count) should equal(allImportedAssets.count);

                for (PhotoPickerCell *cell in controller.photosCollectionView.visibleCells) {
                    NSInteger photoIndex = [controller.photosCollectionView indexPathForCell:cell].item;
                    UIImage *expectedImage = [UIImage imageWithCGImage:[allImportedAssets[photoIndex] aspectRatioThumbnail]];
                    in_time([[cell imageView].image isEqualToByBytes:expectedImage]) should be_truthy;
                }
            });
        });

        describe(@"when selecting a filler", ^{
            NSIndexPath *selectedIndexPath = [NSIndexPath indexPathForItem:0 inSection:0];
            __block UICollectionViewCell *cell;

            beforeEach(^{
                in_time(controller.photosCollectionView.visibleCells.count) should equal(lastImportAssets.count);
                cell = [controller.photosCollectionView cellForItemAtIndexPath:selectedIndexPath];
                [cell tap];
            });

            it(@"should select the cell", ^{
                cell.selected should be_truthy;
            });

            it(@"should show a selection button indicating that one photo is selected", ^{
                controller.navigationItem.rightBarButtonItem.title should equal(@"Select Photo");
            });

            context(@"when selecting another filler", ^{
                beforeEach(^{
                    cell = [controller.photosCollectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:1 inSection:0]];
                    [cell tap];
                });

                it(@"should select the cell", ^{
                    cell.selected should be_truthy;
                });

                it(@"should show a selection button indicating that two photos are selected", ^{
                    controller.navigationItem.rightBarButtonItem.title should equal(@"Select 2 Photos");
                });

                context(@"when attempting to select more than the maximum number of fillers", ^{
                    beforeEach(^{
                        cell = [controller.photosCollectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:2 inSection:0]];
                        cell should_not be_nil;
                        [cell tap];
                    });

                    it(@"should not select the cell", ^{
                        cell.selected should be_falsy;
                    });
                });

                context(@"when deselecting a cell", ^{
                    beforeEach(^{
                        cell.selected should be_truthy;
                        [cell tap];
                    });

                    it(@"should deselect the cell", ^{
                        cell.selected should be_falsy;
                    });

                    it(@"should show a selection button indicating that one photo is selected", ^{
                        controller.navigationItem.rightBarButtonItem.title should equal(@"Select Photo");
                    });
                });
            });

            context(@"when completing a selection", ^{
                NSArray *importedURLs = @[[NSURL URLWithString:@"file:///an/imported/photo"]];

                beforeEach(^{
                    ALAsset *selectedAsset = lastImportAssets[selectedIndexPath.item];
                    photoAssetImporter stub_method(@selector(importAssets:)).with(@[selectedAsset]).and_return(importedURLs);
                    [controller.navigationItem.rightBarButtonItem tap];
                });

                it(@"should import photos and inform the delegate of the imported photos", ^{
                    delegate should have_received(@selector(photoPickerViewController:didImportPhotoURLs:)).with(controller, importedURLs);
                });
            });
        });
    });

    describe(@"when configured with selected assets", ^{
        NSUInteger indexOfSelectedPhotoURL = 1;
        beforeEach(^{
            selectedPhotoURLs = @[[NSURL URLWithString:@"file://some/local/path/to/awesomeimage2.jpg"]];
            NSArray *selectedAssetURLs = @[[lastImportAssets[indexOfSelectedPhotoURL] valueForProperty:ALAssetPropertyAssetURL]];

            assetsLibrary stub_method(@selector(assetForURL:resultBlock:failureBlock:)).and_do_block(^(NSURL *url, ALAssetsLibraryAssetForURLResultBlock resultBlock, ALAssetsLibraryAccessFailureBlock failureBlock){
                NSUInteger assetIndex = [assets indexOfObjectPassingTest:^BOOL(ALAsset *asset, NSUInteger idx, BOOL *stop) {
                    return [[asset valueForProperty:ALAssetPropertyAssetURL] isEqual:url];
                }];
                resultBlock(assetIndex==NSNotFound ? nil : assets[assetIndex]);
            });

            photoAssetImporter stub_method(@selector(libraryURLsForImportedPhotoURLs:)).with(selectedPhotoURLs).and_return(selectedAssetURLs);

            configureAndPresentController();
        });

        it(@"should select the asset for the selected photo URL", ^{
            in_time(controller.photosCollectionView.visibleCells.count) should equal(lastImportAssets.count);
            UICollectionViewCell *cell = [controller.photosCollectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:indexOfSelectedPhotoURL inSection:0]];
            cell.selected should be_truthy;
        });

        it(@"should show the 'Select Photo' navigation item", ^{
            controller.navigationItem.rightBarButtonItem.title should equal(@"Select Photo");
        });

        describe(@"when another asset category is chosen that shares the selected asset with the previous asset category", ^{
            beforeEach(^{
                controller.albumTypeSegmentedControl.selectedSegmentIndex should_not equal(PhotoPickerAlbumTypeCameraRoll);
                controller.albumTypeSegmentedControl.selectedSegmentIndex = PhotoPickerAlbumTypeAllImported;
                [controller.albumTypeSegmentedControl sendActionsForControlEvents:UIControlEventValueChanged];
                lastImportAssets[indexOfSelectedPhotoURL] should equal(sharedAsset);
                allImportedAssets should contain(sharedAsset);
            });

            it(@"should persist the selection of the selected asset", ^{
                in_time(controller.photosCollectionView.visibleCells.count) should equal(allImportedAssets.count);
                NSIndexPath *expectedPath = [NSIndexPath indexPathForItem:[allImportedAssets indexOfObject:sharedAsset] inSection:0];
                UICollectionViewCell *cell = [controller.photosCollectionView cellForItemAtIndexPath:expectedPath];
                cell.selected should be_truthy;
            });
        });
    });
});

SPEC_END
