#import <Foundation/Foundation.h>

@class StitchingQueue;

@protocol StitchingQueueObserver <NSObject>
- (void)stitchingQueue:(StitchingQueue *)queue didUpdateProgress:(float)progress forPresentationUUID:(NSString *)presentationUUID;
- (void)stitchingQueue:(StitchingQueue *)queue didCompleteStitchingForPresentationUUID:(NSString *)presentationUUID;
- (void)stitchingQueue:(StitchingQueue *)queue didCancelStitchingForPresentationUUID:(NSString *)presentationUUID;
@end
