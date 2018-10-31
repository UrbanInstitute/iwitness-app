#import <Foundation/Foundation.h>

@interface TouchLatencyAggregator : NSObject

- (void)recordTouchLatency:(NSTimeInterval)latency;
- (NSString *)reportResults;

- (NSTimeInterval)minTouchLatency;
- (NSTimeInterval)maxTouchLatency;
- (NSTimeInterval)avgTouchLatency;
- (NSTimeInterval)ninetiethPercentileTouchLatency;
- (NSTimeInterval)eightiethPercentileTouchLatency;
@end
