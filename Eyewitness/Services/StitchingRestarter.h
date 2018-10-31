#import <Foundation/Foundation.h>

@class PresentationStore, StitchingQueue;
@interface StitchingRestarter : NSObject

- (instancetype)initWithPresentationStore:(PresentationStore *)presentationStore stitchingQueue:(StitchingQueue *)stitchingQueue;
- (void)restartIncompleteStitches;

@end
