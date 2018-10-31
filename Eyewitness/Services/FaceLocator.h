@interface FaceLocator : NSObject

- (instancetype)initWithDetector:(CIDetector *)detector;
- (NSArray *)locateAllFacesInImage:(UIImage *)image;
- (CGRect)locateLargestFaceInImage:(UIImage *)image;
@end
