#import "VideoStitcher.h"

@class Presentation, VideoStitcherProvider;
@protocol StitchingQueueObserver;

@interface StitchingQueue : NSObject

- (instancetype)initWithVideoStitcherProvider:(VideoStitcherProvider *)videoStitcherProvider;

- (VideoStitcher *)stitcherForPresentation:(Presentation *)presentation;

- (void)addStitchingObserver:(id<StitchingQueueObserver>)observer;
- (void)removeStitchingObserver:(id<StitchingQueueObserver>)observer;

- (void)enqueueStitcherForPresentation:(Presentation *)presentation;
@end
