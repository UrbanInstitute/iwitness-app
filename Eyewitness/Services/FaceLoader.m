#import "FaceLoader.h"
#import "FaceLocator.h"
#import "FaceLocatorProvider.h"

@interface FaceLoader ()
@property (strong, nonatomic) FaceLocator *locator;
@property (strong, nonatomic) NSMutableDictionary *faceRectsForURLs;
@end

@implementation FaceLoader

+ (instancetype)faceLoader {
    FaceLocatorProvider *provider = [[FaceLocatorProvider alloc] init];
    return [[self alloc] initWithFaceLocator:provider.faceLocator];
}

- (instancetype)initWithFaceLocator:(FaceLocator *)locator {
    if (self = [super init]) {
        self.locator = locator;
        self.faceRectsForURLs = [@{} mutableCopy];
    }
    return self;
}

- (void)loadFaceWithURL:(NSURL *)url completion:(LoadFaceCompletionBlock)completion {
    [NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:url]
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                               if (connectionError) {
                                   completion(nil, CGRectNull, connectionError);
                               } else if ([(NSHTTPURLResponse *)response statusCode] / 100 != 2) {
                                   NSError *error = [NSError errorWithDomain:NSInternalInconsistencyException
                                                                        code:[(NSHTTPURLResponse *)response statusCode]
                                                                    userInfo:@{}];
                                   completion(nil, CGRectNull, error);
                               } else {
                                   UIImage *image = [UIImage imageWithData:data];
                                   CGRect rect;
                                   if (self.faceRectsForURLs[url]) {
                                       rect = [self.faceRectsForURLs[url] CGRectValue];
                                   } else {
                                       rect = [self.locator locateLargestFaceInImage:image];
                                       self.faceRectsForURLs[url] = [NSValue valueWithCGRect:rect];
                                   }
                                   completion(image, rect, nil);
                               }
                           }];
}

@end
