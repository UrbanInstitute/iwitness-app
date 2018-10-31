#import "FaceLocator.h"

@interface FaceLocator ()

@property (nonatomic, strong) CIDetector *detector;

@end

@implementation FaceLocator

- (instancetype)init {
    @throw [NSException exceptionWithName:NSInvalidArgumentException
                                   reason:@"Must initialize the face locator with a CoreImage face detector"
                                 userInfo:nil];
}

- (instancetype)initWithDetector:(CIDetector *)detector {
    if ([super init]) {
        self.detector = detector;
    }
    return self;
}

- (NSArray *)locateAllFacesInImage:(UIImage *)image {
    CIImage *coreImage = [CIImage imageWithCGImage:image.CGImage];
    NSArray *features = [self.detector featuresInImage:coreImage options:nil];

    CGAffineTransform transform = CGAffineTransformScale(CGAffineTransformMakeTranslation(0, image.size.height), 1.0f/image.scale, -1.0f/image.scale);

    NSMutableArray *faceBounds = [NSMutableArray array];

    for (CIFaceFeature *feature in features) {
        CGRect featureBounds = feature.bounds;
        featureBounds.size.height *= 1.25;

        featureBounds = CGRectApplyAffineTransform(featureBounds, transform);
        [faceBounds addObject:[NSValue valueWithCGRect:featureBounds]];
    }

    return [NSArray arrayWithArray:faceBounds];
}

- (CGRect)locateLargestFaceInImage:(UIImage *)image {
    NSArray *faceBoundingRects = [self locateAllFacesInImage:image];
    if (faceBoundingRects.count > 0) {
        faceBoundingRects = [faceBoundingRects sortedArrayUsingComparator:^NSComparisonResult(NSValue *rect1Value, NSValue *rect2Value) {
            CGRect rect1 = [rect1Value CGRectValue];
            CGRect rect2 = [rect2Value CGRectValue];
            CGFloat rect1Area = CGRectGetWidth(rect1)*CGRectGetHeight(rect1);
            CGFloat rect2Area = CGRectGetWidth(rect2)*CGRectGetHeight(rect2);
            return  (rect1Area<rect2Area) ? NSOrderedAscending : (rect1Area>rect2Area) ? NSOrderedDescending : NSOrderedSame;
        }];

        return [faceBoundingRects.lastObject CGRectValue];
    } else {
        return CGRectNull;
    }
}

@end
