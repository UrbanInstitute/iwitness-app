#import "CedarAsync.h"
#import "PhotoPickerDataSource.h"
#import "PhotoPickerCell.h"
#import "ALTestAsset.h"
#import "FaceLocator.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(PhotoPickerDataSourceSpec)

describe(@"PhotoPickerDataSource", ^{
    __block PhotoPickerDataSource *dataSource;
    __block UICollectionView *collectionView;
    __block ALAssetsLibrary *assetsLibrary;
    __block ALAsset *fakeAsset;
    __block FaceLocator *faceLocator;
    __block NSCache *faceCache;

    beforeEach(^{
        NSURL *imageURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"cathy" withExtension:@"jpg" subdirectory:@"SampleLineup"];
        NSURL *imageURL2 = [[NSBundle bundleForClass:[self class]] URLForResource:@"Brian" withExtension:@"jpg" subdirectory:@"SampleLineup"];
        fakeAsset = [[ALTestAsset alloc] initWithImageURL:imageURL];
        ALAsset *fakeAsset2 = [[ALTestAsset alloc] initWithImageURL:imageURL2];

        faceLocator = nice_fake_for([FaceLocator class]);
        faceCache = nice_fake_for([NSCache class]);

        void (^assetsGroupEnumeration)(ALAssetsGroupEnumerationResultsBlock, NSArray *) = ^(ALAssetsGroupEnumerationResultsBlock enumerationBlock, NSArray *assetsToReturn){
            BOOL stop;

            for (ALAsset *asset in assetsToReturn) {
                enumerationBlock(asset, 0, &stop);
            }
        };

        ALAssetsGroup *assetsGroup = nice_fake_for([ALAssetsGroup class]);
        assetsGroup stub_method(@selector(enumerateAssetsUsingBlock:)).and_do_block(^(ALAssetsGroupEnumerationResultsBlock enumerationBlock){
            assetsGroupEnumeration(enumerationBlock, @[fakeAsset, fakeAsset2]);
        });

        assetsGroup stub_method(@selector(valueForProperty:)).with(ALAssetsGroupPropertyName).and_return(@"Last Import");

        ALAssetsGroup *assetsGroup2 = nice_fake_for([ALAssetsGroup class]);
        assetsGroup2 stub_method(@selector(enumerateAssetsUsingBlock:)).and_do_block(^(ALAssetsGroupEnumerationResultsBlock enumerationBlock){
            assetsGroupEnumeration(enumerationBlock, @[fakeAsset2]);
        });

        assetsGroup2 stub_method(@selector(valueForProperty:)).with(ALAssetsGroupPropertyName).and_return(@"All Imported");

        assetsLibrary = nice_fake_for([ALAssetsLibrary class]);
        assetsLibrary stub_method(@selector(enumerateGroupsWithTypes:usingBlock:failureBlock:)).and_do_block(^(ALAssetsGroupType groupType, ALAssetsLibraryGroupsEnumerationResultsBlock enumerationBlock, ALAssetsLibraryAccessFailureBlock failureBlock){
            BOOL stop;
            enumerationBlock(assetsGroup, &stop);
            enumerationBlock(assetsGroup2, &stop);
            enumerationBlock(nil, &stop);
        });

        dataSource = [[PhotoPickerDataSource alloc] init];
        [dataSource configureWithAssetsLibrary:assetsLibrary
                                   faceLocator:faceLocator
                                     faceCache:faceCache];
        
        collectionView = nice_fake_for([UICollectionView class]);

        PhotoPickerCell *cell = nice_fake_for([PhotoPickerCell class]);
        PhotoPickerCell *cell2 = nice_fake_for([PhotoPickerCell class]);
        cell stub_method(@selector(imageView)).and_return(nice_fake_for([UIImageView class]));
        cell2 stub_method(@selector(imageView)).and_return(nice_fake_for([UIImageView class]));
        collectionView stub_method(@selector(dequeueReusableCellWithReuseIdentifier:forIndexPath:)).with(@"PhotoPickerCell", [NSIndexPath indexPathForItem:0 inSection:0]).and_return(cell);
        collectionView stub_method(@selector(dequeueReusableCellWithReuseIdentifier:forIndexPath:)).with(@"PhotoPickerCell", [NSIndexPath indexPathForItem:1 inSection:0]).and_return(cell2);
        collectionView stub_method(@selector(indexPathForCell:)).with(cell).and_return([NSIndexPath indexPathForItem:0 inSection:0]);
        collectionView stub_method(@selector(indexPathForCell:)).with(cell2).and_return([NSIndexPath indexPathForItem:1 inSection:0]);
    });

    context(@"when configured without an assets library", ^{
        beforeEach(^{
            dataSource = [[PhotoPickerDataSource alloc] init];
        });

        it(@"should blow up", ^{
            ^{ [dataSource assetsLibrary]; } should raise_exception;
        });
    });

    it(@"should provide one item per asset", ^{
        [dataSource collectionView:collectionView numberOfItemsInSection:0] should equal(2);
    });

    describe(@"configuring photo picker cells", ^{
        __block PhotoPickerCell *cell;
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:1 inSection:0];

        beforeEach(^{
            cell = (PhotoPickerCell *)[dataSource collectionView:collectionView
                                                           cellForItemAtIndexPath:indexPath];
        });

        it(@"should provide configured photo picker cells", ^{
            with_timeout(5, ^{
                in_time(cell.imageView) should have_received(@selector(setImage:)).with(Arguments::any([UIImage class]));
                in_time(faceLocator) should have_received(@selector(locateLargestFaceInImage:));
                in_time(faceCache) should have_received(@selector(setObject:forKey:)).with(Arguments::any([NSValue class]), indexPath);
            });
        });
    });

    describe(@"changing the album type", ^{
        __block PhotoPickerCell *cellFromInitialAlbum;
        __block KSPromise *changeAlbumPromise;

        beforeEach(^{
            cellFromInitialAlbum = (PhotoPickerCell *)[dataSource collectionView:collectionView
                                                          cellForItemAtIndexPath:[NSIndexPath indexPathForItem:1 inSection:0]];

            changeAlbumPromise = [dataSource changeAlbumType:PhotoPickerAlbumTypeAllImported];
        });

        it(@"should fulfill the promise when the assets have been loaded", ^{
            changeAlbumPromise.fulfilled should be_truthy;
        });

        it(@"should clear the faces cache", ^{
            faceCache should have_received(@selector(removeAllObjects));
        });

        it(@"should provide cells configured for assets from the new album", ^{
            PhotoPickerCell *cellFromNewAlbum = (PhotoPickerCell *)[dataSource collectionView:collectionView
                                                                       cellForItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
            with_timeout(5, ^{
                in_time(cellFromNewAlbum.imageView) should have_received(@selector(setImage:)).with(Arguments::any([UIImage class]));
            });

        });
    });
    
    describe(@"returning an asset", ^{
        __block ALAsset *returnedAsset;
        beforeEach(^{
            returnedAsset = [dataSource assetAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
        });
        
        it(@"should return a nice asset", ^{
            returnedAsset should be_same_instance_as(fakeAsset);
        });
    });

    describe(@"finding the index path for a given asset", ^{
        it(@"should return the correct index path", ^{
            [dataSource indexPathForAsset:fakeAsset] should equal([NSIndexPath indexPathForItem:0 inSection:0]);

            ALAsset *assetNotFound = nice_fake_for([ALAsset class]);
            [dataSource indexPathForAsset:assetNotFound] should be_nil;
        });
    });

    describe(@"getting assets for urls", ^{
        __block ALTestAsset *asset;

        beforeEach(^{
            asset = [[ALTestAsset alloc] init];
            dataSource.assetsLibrary stub_method(@selector(assetForURL:resultBlock:failureBlock:)).and_do_block(^(NSURL *url, ALAssetsLibraryAssetForURLResultBlock resultBlock, ALAssetsLibraryAccessFailureBlock failureBlock){
                resultBlock(asset);
            });
        });

        it(@"should return the correct asset for the given urls", ^{
            NSURL *assetURL = [NSURL URLWithString:@"assets://anAsset"];
            KSPromise *promise = [dataSource assetsForAssetURLs:@[assetURL]];

            promise.value should equal([NSSet setWithObject:asset]);
        });

        it(@"should return an empty resolved promise if no url is given", ^{
            KSPromise *promise = [dataSource assetsForAssetURLs:nil];

            promise.fulfilled should be_truthy;
            promise.value should be_nil;
        });
    });
});

SPEC_END
