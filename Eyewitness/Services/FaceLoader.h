#import <Foundation/Foundation.h>

typedef void (^LoadFaceCompletionBlock)(UIImage *image, CGRect faceRect, NSError *error);

@class FaceLocator;

@interface FaceLoader : NSObject

+ (instancetype)faceLoader;

- (instancetype)initWithFaceLocator:(FaceLocator *)locator;

- (void)loadFaceWithURL:(NSURL *)url completion:(LoadFaceCompletionBlock)completion;
@end
