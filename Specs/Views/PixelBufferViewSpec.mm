#import "PixelBufferView.h"
#import <CoreVideo/CoreVideo.h>

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(PixelBufferViewSpec)

describe(@"PixelBufferView", ^{
    __block PixelBufferView *view;

    beforeEach(^{
        view = [[PixelBufferView alloc] init];
    });

    it(@"should use the Aspect Fit content mode", ^{
        view.contentMode should equal(UIViewContentModeScaleAspectFit);
    });

    describe(@"showing a pixel buffer", ^{
        UIImage *sourceImage = [UIImage imageWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:@"cathy"
                                                                                                                 ofType:@"jpg"
                                                                                                            inDirectory:@"SampleLineup"]];
        __block NSData *imageData;
        __block CVPixelBufferRef pixelBuffer;

        beforeEach(^{
            imageData = CFBridgingRelease(CGDataProviderCopyData(CGImageGetDataProvider(sourceImage.CGImage)));

            CVPixelBufferCreateWithBytes(NULL,
                                         sourceImage.size.width*sourceImage.scale,
                                         sourceImage.size.height*sourceImage.scale,
                                         kCVPixelFormatType_32BGRA,
                                         (void *)[imageData bytes],
                                         CGImageGetBytesPerRow(sourceImage.CGImage),
                                         NULL,
                                         NULL,
                                         NULL,
                                         &pixelBuffer);

            view.pixelBuffer = pixelBuffer;
        });

        afterEach(^{
            CVPixelBufferRelease(pixelBuffer);
        });

        it(@"should present the pixel buffer's contents", ^{
            [sourceImage isEqualToByBytes:[UIImage imageWithCGImage:(CGImageRef)view.layer.contents]] should be_truthy;
        });

        describe(@"clearing the pixel buffer", ^{
            beforeEach(^{
                view.pixelBuffer = NULL;
            });

            it(@"should clear the presented image", ^{
                view.layer.contents should be_nil;
            });

            it(@"should release the pixel buffer", ^{
                CFGetRetainCount(pixelBuffer) should equal(1);
            });
        });
    });
});

SPEC_END
