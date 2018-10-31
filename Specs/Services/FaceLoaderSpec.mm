#import "FaceLoader.h"
#import "FaceLocator.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(FaceLoaderSpec)

describe(@"FaceLoader", ^{
    NSURL *faceURL = [NSURL URLWithString:@"http://example.com/img.jpg"];
    __block FaceLoader *loader;
    __block FaceLocator *faceLocator;

    beforeEach(^{
        faceLocator = nice_fake_for([FaceLocator class]);
        loader = [[FaceLoader alloc] initWithFaceLocator:faceLocator];
    });

    describe(@"loadFaceWithURL:completion:", ^{
        __block UIImage *returnedImage;
        __block CGRect returnedRect;
        __block NSError *returnedError;

        beforeEach(^{
            returnedImage = nil;
            returnedRect = CGRectNull;
            returnedError = nil;
            [loader loadFaceWithURL:faceURL
                         completion:^(UIImage *image, CGRect faceRect, NSError *error) {
                             returnedImage = image;
                             returnedRect = faceRect;
                             returnedError = error;
                         }];
        });

        it(@"should make a network connection to retrieve the image data", ^{
            [[[NSURLConnection connections].lastObject request] URL] should equal(faceURL);
        });

        describe(@"when the server returns the image data", ^{
            __block UIImage *expectedImage;
            __block PSHKFakeHTTPURLResponse *successfulImageDataResponse;
            CGRect faceRect = CGRectMake(1, 2, 3, 4);

            beforeEach(^{
                faceLocator stub_method(@selector(locateLargestFaceInImage:)).and_return(faceRect);

                NSURL *imageURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"cathy"
                                                                           withExtension:@"jpg"
                                                                            subdirectory:@"SampleLineup"];
                NSData *imageData = [NSData dataWithContentsOfURL:imageURL];
                expectedImage = [UIImage imageWithData:imageData];

                successfulImageDataResponse = [[PSHKFakeHTTPURLResponse alloc] initWithStatusCode:200
                                                                                             andHeaders:@{}
                                                                                            andBodyData:imageData];
                [[NSURLConnection connections].lastObject receiveResponse:successfulImageDataResponse];
            });

            it(@"should ask the face detector to detect the largest face", ^{
                faceLocator should have_received(@selector(locateLargestFaceInImage:));
            });

            it(@"should call the completion block with the image and the rect of the largest face", ^{
                [returnedImage isEqualToByBytes:expectedImage] should be_truthy;
                returnedRect should equal(faceRect);
            });

            describe(@"on a subsequent request for the same face image URL that succeeds", ^{
                beforeEach(^{
                    returnedImage = nil;
                    returnedRect = CGRectNull;
                    [loader loadFaceWithURL:faceURL
                                 completion:^(UIImage *image, CGRect faceRect, NSError *error) {
                                     returnedImage = image;
                                     returnedRect = faceRect;
                                 }];
                    [(id<CedarDouble>)faceLocator reset_sent_messages];
                    [[NSURLConnection connections].lastObject receiveResponse:successfulImageDataResponse];
                });

                it(@"should not ask the face detector to detect the largest face because it was previously detected", ^{
                    faceLocator should_not have_received(@selector(locateLargestFaceInImage:));
                });

                it(@"should call the completion block with the image and the previously detected rect of the largest face", ^{
                    [returnedImage isEqualToByBytes:expectedImage] should be_truthy;
                    returnedRect should equal(faceRect);
                });
            });
        });

        describe(@"when the server returns a error code", ^{
            beforeEach(^{
                PSHKFakeHTTPURLResponse *errorResponse = [[PSHKFakeHTTPURLResponse alloc] initWithStatusCode:500 andHeaders:@{} andBody:@""];
                [[NSURLConnection connections].lastObject receiveResponse:errorResponse];
            });

            it(@"should call the completion block with an error with the error code", ^{
                returnedError.code should equal(500);
            });
        });

        describe(@"when the network connection fails with an error", ^{
            NSError *networkError = [NSError errorWithDomain:@"Furballs caught in router" code:1234 userInfo:nil];
            beforeEach(^{
                [[NSURLConnection connections].lastObject failWithError:networkError];
            });

            it(@"should call the completion block with the error", ^{
                returnedError should be_same_instance_as(networkError);
            });
        });
    });
});

SPEC_END
