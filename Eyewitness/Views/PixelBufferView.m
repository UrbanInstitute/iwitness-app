#import "PixelBufferView.h"

@implementation PixelBufferView

- (id)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.contentMode = UIViewContentModeScaleAspectFit;
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        self.contentMode = UIViewContentModeScaleAspectFit;
    }
    return self;
}

- (void)dealloc {
    self.pixelBuffer = NULL;
}

- (void)setPixelBuffer:(CVPixelBufferRef)pixelBuffer {
    CVPixelBufferRetain(pixelBuffer);
    CVPixelBufferRelease(_pixelBuffer);
    _pixelBuffer = pixelBuffer;

    CGImageRef image = NULL;
    if (pixelBuffer) {
        image = CGImageCreateWithPixelBuffer(pixelBuffer);
    }

    self.layer.contents = (id)CFBridgingRelease(image);
}

#pragma mark - private

static CGImageRef CGImageCreateWithPixelBuffer(CVPixelBufferRef pixelBuffer) {
    size_t width = CVPixelBufferGetWidth(pixelBuffer);
    size_t height = CVPixelBufferGetHeight(pixelBuffer);

    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    void *data = CVPixelBufferGetBaseAddress(pixelBuffer);
    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();

    CGDataProviderRef dataProvider = CGDataProviderCreateWithData(NULL, data, CVPixelBufferGetDataSize(pixelBuffer), NULL);

    CGImageRef cgImage = CGImageCreate(width,
                                       height,
                                       8, // bits per component
                                       32, // bits per pixel
                                       CVPixelBufferGetBytesPerRow(pixelBuffer),
                                       rgbColorSpace,
                                       (CGBitmapInfo)kCGBitmapByteOrder32Little|kCGImageAlphaNoneSkipFirst,
                                       dataProvider,
                                       NULL, // decode array
                                       NO, // should interpolate
                                       kCGRenderingIntentDefault);

    CFRelease(dataProvider);
    CGColorSpaceRelease(rgbColorSpace);
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);

    return cgImage;
}

@end
