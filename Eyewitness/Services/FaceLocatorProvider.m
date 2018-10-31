#import "FaceLocatorProvider.h"
#import "FaceLocator.h"

@implementation FaceLocatorProvider

- (FaceLocator *)faceLocator {
    CIContext *context = [CIContext contextWithOptions:nil];
    NSDictionary *options = @{CIDetectorAccuracy : CIDetectorAccuracyLow};

    CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeFace context:context options:options];
    return [[FaceLocator alloc] initWithDetector:detector];
}

@end
