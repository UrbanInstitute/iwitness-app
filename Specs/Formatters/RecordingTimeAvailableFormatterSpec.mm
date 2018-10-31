#import "RecordingTimeAvailableFormatter.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(RecordingTimeAvailableFormatterSpec)

describe(@"RecordingTimeAvailableFormatter", ^{
    __block RecordingTimeAvailableFormatter *formatter;

    beforeEach(^{
        formatter = [[RecordingTimeAvailableFormatter alloc] init];
    });

    describe(@"normal mode", ^{
        beforeEach(^{
            formatter.fullMode = NO;
        });

        it(@"should return 'More than an hour' for more than 1 hour", ^{
            [formatter stringFromTimeAvailable:61*60] should equal(@"More than an hour");
        });

        it(@"should include hours for 1 hour", ^{
            [formatter stringFromTimeAvailable:60*60] should equal(@"1h");
        });

        it(@"should not include hours for times less than 1 hour", ^{
            [formatter stringFromTimeAvailable:19*60] should equal(@"19m");
        });

        it(@"should include a minutes value even for very small times", ^{
            [formatter stringFromTimeAvailable:0] should equal(@"0m");
        });

        it(@"should round down to the nearest minute", ^{
            [formatter stringFromTimeAvailable:119] should equal(@"1m");
        });
    });

    describe(@"full mode", ^{
        beforeEach(^{
            formatter.fullMode = YES;
        });

        it(@"should return 'More than an hour' for more than 1 hour", ^{
            [formatter stringFromTimeAvailable:61*60] should equal(@"More than an hour");
        });

        it(@"should fully write out hours and minutes", ^{
            [formatter stringFromTimeAvailable:60*60] should equal(@"1 hour");
        });

        it(@"should pluralize minutes appropriately", ^{
            [formatter stringFromTimeAvailable:2*60] should equal(@"2 minutes");
        });

        it(@"should not include hours for times less than 1 hour", ^{
            [formatter stringFromTimeAvailable:60] should equal(@"1 minute");
        });

        it(@"should include a minutes value even for very small times", ^{
            [formatter stringFromTimeAvailable:0] should equal(@"0 minutes");
        });
    });
});

SPEC_END
