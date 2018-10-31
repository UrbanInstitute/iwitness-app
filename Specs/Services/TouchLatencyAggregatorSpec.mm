#import "TouchLatencyAggregator.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(TouchLatencyAggregatorSpec)

describe(@"TouchLatencyAggregator", ^{
    __block TouchLatencyAggregator *aggregator;

    beforeEach(^{
        aggregator = [[TouchLatencyAggregator alloc] init];
    });

    describe(@"when touch latencies are recorded", ^{
        beforeEach(^{
            [aggregator recordTouchLatency:5.0];
            [aggregator recordTouchLatency:1.0];
            [aggregator recordTouchLatency:10.0];
            [aggregator recordTouchLatency:8.0];
            [aggregator recordTouchLatency:11.0];
            [aggregator recordTouchLatency:2.0];
            [aggregator recordTouchLatency:4.0];
            [aggregator recordTouchLatency:7.0];
            [aggregator recordTouchLatency:3.0];
            [aggregator recordTouchLatency:6.0];
            [aggregator recordTouchLatency:9.0];
        });

        it(@"should provide statistics about the recorded latencies", ^{
            [aggregator avgTouchLatency] should equal(6.0);
            [aggregator maxTouchLatency] should equal(11.0);
            [aggregator minTouchLatency] should equal(1.0);
            [aggregator ninetiethPercentileTouchLatency] should equal(10.0);
            [aggregator eightiethPercentileTouchLatency] should equal(9.0);
        });

        it(@"should provide a summary of the recorded latencies", ^{
            [aggregator reportResults] should equal(@"Touch Latency Summary\n"
                                                    @"\tNumber of recorded touches: 11\n"
                                                    @"\tMinimum latency: 1000.00ms\n"
                                                    @"\tMaximum latency: 11000.00ms\n"
                                                    @"\tAverage latency: 6000.00ms\n"
                                                    @"\t90%: 10000.00ms\n"
                                                    @"\t80%: 9000.00ms\n"
                                                    @"\n");
        });
    });
});

SPEC_END
