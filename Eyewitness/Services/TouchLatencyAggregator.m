#import "TouchLatencyAggregator.h"

@interface TouchLatency : NSObject
@property (nonatomic, assign, readonly) NSTimeInterval latency;

- (instancetype)initWithLatency:(NSTimeInterval)latency;
@end

@interface TouchLatency ()
@property (nonatomic, assign, readwrite) NSTimeInterval latency;
@end

@implementation TouchLatency
- (instancetype)initWithLatency:(NSTimeInterval)latency {
    if (self = [super init]) {
        self.latency = latency;
    }
    return self;
}
@end

@interface TouchLatencyAggregator ()
@property (nonatomic, strong) NSMutableArray *touchLatencies;
@end

@implementation TouchLatencyAggregator

- (void)recordTouchLatency:(NSTimeInterval)latency {
    TouchLatency *touchLatency = [[TouchLatency alloc] initWithLatency:latency];
    NSUInteger index = [self.touchLatencies indexOfObject:touchLatency
                         inSortedRange:NSMakeRange(0, self.touchLatencies.count)
                               options:NSBinarySearchingInsertionIndex
                       usingComparator:^NSComparisonResult(TouchLatency *obj1, TouchLatency *obj2) {
                           if(obj1.latency < obj2.latency) {
                               return NSOrderedAscending;
                           } else if (obj1.latency > obj2.latency) {
                               return NSOrderedDescending;
                           } else {
                               return NSOrderedSame;
                           }
    }];
    [self.touchLatencies insertObject:touchLatency atIndex:index];
}

- (NSString *)reportResults {
    return [NSString stringWithFormat:@"Touch Latency Summary\n"
                                      @"\tNumber of recorded touches: %lu\n"
                                      @"\tMinimum latency: %.2fms\n"
                                      @"\tMaximum latency: %.2fms\n"
                                      @"\tAverage latency: %.2fms\n"
                                      @"\t90%%: %.2fms\n"
                                      @"\t80%%: %.2fms\n"
                                      @"\n",
            (unsigned long)self.touchLatencies.count,
            [self minTouchLatency] * 1000,
            [self maxTouchLatency] * 1000,
            [self avgTouchLatency] * 1000,
            [self ninetiethPercentileTouchLatency] * 1000,
            [self eightiethPercentileTouchLatency] * 1000
            ];
}

- (NSTimeInterval)minTouchLatency {
    return [[self.touchLatencies firstObject] latency];
}

- (NSTimeInterval)maxTouchLatency {
    return [[self.touchLatencies lastObject] latency];
}

- (NSTimeInterval)avgTouchLatency {
    NSTimeInterval latency;
    [[self.touchLatencies valueForKeyPath:@"@avg.latency"] getValue:&latency];
    return latency;
}

- (NSTimeInterval)ninetiethPercentileTouchLatency {
    return [[self.touchLatencies objectAtIndex:(ceil(0.9 * self.touchLatencies.count)-1)] latency];
}

- (NSTimeInterval)eightiethPercentileTouchLatency {
    return [[self.touchLatencies objectAtIndex:(ceil(0.8 * self.touchLatencies.count)-1)] latency];
}

#pragma mark - Accessors

- (NSMutableArray *)touchLatencies {
    if (!_touchLatencies) {
        _touchLatencies = [NSMutableArray array];
    }
    return _touchLatencies;
}

@end
