#import "FaceLocator.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(FaceLocatorSpec)

describe(@"FaceLocator", ^{
    __block FaceLocator *faceLocator;
    __block UIImage *imageWithFace;
    __block UIImage *imageWithNoFaces;
    __block CIDetector *detector;

    beforeEach(^{
        detector = nice_fake_for([CIDetector class]);
        faceLocator = [[FaceLocator alloc] initWithDetector:detector];

        NSURL *imageURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"cathy"
                                                                   withExtension:@"jpg"
                                                                    subdirectory:@"SampleLineup"];

        imageWithFace = [UIImage imageWithData:[NSData dataWithContentsOfURL:imageURL] scale:2];

        imageURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"ocean"
                                                            withExtension:@"jpg"
                                                             subdirectory:@"SampleLineup"];
        imageWithNoFaces = [UIImage imageWithContentsOfFile:[imageURL path]];
    });

    describe(@"return the bounds of faces found in a given image", ^{
        beforeEach(^{
            CIFaceFeature *feature1 = nice_fake_for([CIFaceFeature class]);
            feature1 stub_method(@selector(bounds)).and_return(CGRectMake(0, 0, 30, 30));

            CIFaceFeature *feature2 = nice_fake_for([CIFaceFeature class]);
            feature2 stub_method(@selector(bounds)).and_return(CGRectMake(30, 0, 40, 40));

            detector stub_method(@selector(featuresInImage:options:)).with(Arguments::any([CIImage class]), Arguments::anything).and_return(@[feature1, feature2]);

        });

        it(@"should return face bounds rect in the results", ^{
            NSArray *faceBoundingRects = [faceLocator locateAllFacesInImage:imageWithFace];
            faceBoundingRects.count should equal(2);
            [faceBoundingRects[0] CGRectValue] should equal(CGRectMake(0, 81.25, 15, 18.75));
            [faceBoundingRects[1] CGRectValue] should equal(CGRectMake(15, 75, 20, 25));
        });

        it(@"should return the bounding rect of the largest face", ^{
            CGRect largestFaceBoundingRect = [faceLocator locateLargestFaceInImage:imageWithFace];
            largestFaceBoundingRect should equal(CGRectMake(15, 75, 20, 25));
        });
    });

    describe(@"return no results when there are no faces in a given image", ^{
        __block NSArray *faceCenters;

        beforeEach(^{
            detector stub_method(@selector(featuresInImage:options:)).with(Arguments::any([CIImage class]), Arguments::anything).and_return(@[]);
            faceCenters = [faceLocator locateAllFacesInImage:imageWithNoFaces];
        });

        it(@"should return face bounds rects in the results", ^{
            faceCenters.count should equal(0);
        });

        it(@"should return a null rect for the largest face", ^{
            [faceLocator locateLargestFaceInImage:imageWithNoFaces] should equal(CGRectNull);
        });
    });
});

SPEC_END
