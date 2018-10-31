#import "StitchingQueueObserver.h"

@class PresentationStore, RecordingTimeAvailableCalculator, StitchingQueue;

@interface PresentationsViewController : UITableViewController<StitchingQueueObserver>

- (void)configureWithPresentationStore:(PresentationStore *)presentationStore
      recordingTimeAvailableCalculator:(RecordingTimeAvailableCalculator *)timeAvailableCalculator
                        stitchingQueue:(StitchingQueue *)stitchingQueue;
@end
