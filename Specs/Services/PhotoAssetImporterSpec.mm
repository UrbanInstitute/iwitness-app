#import "PhotoAssetImporter.h"
#import "ALTestAsset.h"
#import "FaceLocator.h"
#import "NSFileManager+CommonDirectories.h"
#import "PhotoAssetMetadataManager.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(PhotoAssetImporterSpec)

describe(@"PhotoAssetImporter", ^{
    __block PhotoAssetImporter *importer;
    __block NSURL *destinationDirectory;
    __block FaceLocator *faceLocator;
    __block PhotoAssetMetadataManager *metadataManager;
    __block NSURL *libraryImageURL;

    beforeEach(^{
        destinationDirectory = [[[NSFileManager defaultManager] URLForApplicationSupportDirectory] URLByAppendingPathComponent:@"TestImports"];
        [[NSFileManager defaultManager] createDirectoryAtURL:destinationDirectory withIntermediateDirectories:YES attributes:@{} error:NULL];
        libraryImageURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"cathy" withExtension:@"jpg" subdirectory:@"SampleLineup"];

        faceLocator = fake_for([FaceLocator class]);
        metadataManager = nice_fake_for([PhotoAssetMetadataManager class]);
        importer = [[PhotoAssetImporter alloc] initWithDestinationDirectory:destinationDirectory faceLocator:faceLocator metadataManager:metadataManager];
    });

    afterEach(^{
        [[NSFileManager defaultManager] removeItemAtURL:destinationDirectory error:NULL];
    });

    it(@"should blow up if not given a destination directory", ^{
        ^{ (void) [[PhotoAssetImporter alloc] initWithDestinationDirectory:nil faceLocator:nil metadataManager:nil]; } should raise_exception;
    });

    describe(@"import photos", ^{
        __block NSArray *assets;
        __block NSArray *importedAssetURLs;
        __block CGRect faceRect;

        beforeEach(^{
            faceRect = CGRectMake(1, 2, 3, 4);
            faceLocator stub_method(@selector(locateLargestFaceInImage:)).and_return(faceRect);

            ALTestAsset *fakeAsset = [[ALTestAsset alloc] initWithImageURL:libraryImageURL];
            assets = @[fakeAsset];

            importedAssetURLs = [importer importAssets:assets];
        });

        it(@"should have returned one URL for each imported asset", ^{
            [importedAssetURLs count] should equal([assets count]);
        });

        it(@"should have copied an image to the returned URLs", ^{
            NSURL *importedURL = [importedAssetURLs firstObject];
            UIImage *importedImage = [UIImage imageWithContentsOfFile:[importedURL path]];
            [importedImage isEqualToByBytes:[UIImage imageWithCGImage:[assets[0] defaultRepresentation].fullScreenImage]] should be_truthy;
        });

        it(@"should set the library URL on the imported photo", ^{
            metadataManager should have_received(@selector(setLibraryURL:forPhotoURL:)).with(libraryImageURL, importedAssetURLs[0]);
        });

        it(@"should set the largest face rect on the imported photo", ^{
            metadataManager should have_received(@selector(setLargestFaceRect:forPhotoURL:)).with(faceRect, importedAssetURLs[0]);
        });
    });

    describe(@"returning library URLs for imported photo URLs", ^{
        NSURL *importedAssetURL = [NSURL URLWithString:@"/a/url"];

        beforeEach(^{
            metadataManager stub_method(@selector(libraryURLForPhotoURL:)).and_return(libraryImageURL);
        });

        it(@"should return the correct library URLs for the given imported photo URLs", ^{
            [importer libraryURLsForImportedPhotoURLs:@[importedAssetURL]] should equal(@[libraryImageURL]);
        });
    });

    describe(@"returning focus rects for the largest face in imported photos", ^{
        NSURL *importedAssetURL = [NSURL URLWithString:@"/a/url"];

        context(@"when a face is present in the imported photo", ^{
            beforeEach(^{
                metadataManager stub_method(@selector(largestFaceRectForPhotoURL:)).and_return(CGRectMake(1, 2, 3, 4));
            });

            it(@"should return the correct focus rect for the given imported photo URLs", ^{
                NSArray *rectValues = [importer largestFaceRectsForImportedPhotoURLs:@[importedAssetURL]];
                CGRectEqualToRect([rectValues[0] CGRectValue], CGRectMake(1, 2, 3, 4)) should be_truthy;
            });
        });

        context(@"when no face is present in the imported photo", ^{
            beforeEach(^{
                metadataManager stub_method(@selector(largestFaceRectForPhotoURL:)).and_return(CGRectNull);
            });

            it(@"should return a null rect", ^{
                NSArray *rectValues = [importer largestFaceRectsForImportedPhotoURLs:@[importedAssetURL]];
                CGRectEqualToRect([rectValues[0] CGRectValue], CGRectNull) should be_truthy;
            });
        });
    });
});

SPEC_END
