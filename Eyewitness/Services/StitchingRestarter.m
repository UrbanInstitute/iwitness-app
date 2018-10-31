#import "StitchingRestarter.h"
#import "PresentationStore.h"
#import "StitchingQueue.h"
#import "Presentation.h"

@interface StitchingRestarter ()
@property (nonatomic, strong) PresentationStore *presentationStore;
@property (nonatomic, strong) StitchingQueue *stitchingQueue;
@end

@implementation StitchingRestarter

- (instancetype)initWithPresentationStore:(PresentationStore *)presentationStore stitchingQueue:(StitchingQueue *)stitchingQueue {
    if (self = [super init]) {
        self.presentationStore = presentationStore;
        self.stitchingQueue = stitchingQueue;
    }
    return self;
}

- (void)restartIncompleteStitches {
    if (!self.presentationStore || !self.stitchingQueue) {
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"StitchingRestarter needs a presentation store and a stitching queue" userInfo:nil];
    }

    for (Presentation *presentation in self.presentationStore.allPresentations) {
        if (presentation.videoURL == nil && ![self.stitchingQueue stitcherForPresentation:presentation]) {
            [self.stitchingQueue enqueueStitcherForPresentation:presentation];
        }
    }
}

@end
