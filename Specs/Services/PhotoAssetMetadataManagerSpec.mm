#import "PhotoAssetMetadataManager.h"
#import "NSFileManager+CommonDirectories.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(PhotoAssetMetadataManagerSpec)

describe(@"PhotoAssetMetadataManager", ^{
    __block PhotoAssetMetadataManager *manager;
    NSURL *assetURL = [[[NSFileManager defaultManager] URLForApplicationSupportDirectory] URLByAppendingPathComponent:@"metadata_test"];

    NSURL *assetURLWithoutMetadata = [[[NSFileManager defaultManager] URLForApplicationSupportDirectory] URLByAppendingPathComponent:@"no_metadata_test"];

    beforeEach(^{
        manager = [[PhotoAssetMetadataManager alloc] init];

        [[NSFileManager defaultManager] removeItemAtURL:assetURL error:NULL];
        [[NSFileManager defaultManager] removeItemAtURL:assetURLWithoutMetadata error:NULL];
        [[NSData data] writeToURL:assetURL options:0 error:NULL];
        [[NSData data] writeToURL:assetURLWithoutMetadata options:0 error:NULL];
    });


    describe(@"returning library URLs for photo URLs", ^{
        NSURL *libraryImageURL = [NSURL URLWithString:@"/path/to/asset"];

        it(@"should return the correct library URLs for the given photo URLs", ^{
            [manager setLibraryURL:libraryImageURL forPhotoURL:assetURL];
            [manager libraryURLForPhotoURL:assetURL] should equal(libraryImageURL);
        });

        it(@"should return nil for a photo URL that does not have the library URL property set", ^{
            [manager libraryURLForPhotoURL:assetURLWithoutMetadata] should be_nil;
        });
    });

    describe(@"returning largest face rect for photo URLs", ^{
        it(@"should return the correct face rect for the given photo URLs", ^{
            [manager setLargestFaceRect:CGRectMake(1, 2, 3, 4) forPhotoURL:assetURL];
            [manager largestFaceRectForPhotoURL:assetURL] should equal(CGRectMake(1, 2, 3, 4));
        });

        it(@"should return the null rect for a photo URL that does not have the largest face rect property set", ^{
            [manager largestFaceRectForPhotoURL:assetURLWithoutMetadata] should equal(CGRectNull);
        });
    });
});

SPEC_END
