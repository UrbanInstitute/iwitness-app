#import "RecordingTimeAvailableCalculator.h"
#import "NSFileManager+FreeDiskSpace.h"
#import "RecordingSpaceRequirements.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(RecordingTimeAvailableCalculatorSpec)

describe(@"RecordingTimeAvailableCalculator", ^{
    __block RecordingSpaceRequirements *recordingSpaceRequirements;
    __block RecordingTimeAvailableCalculator *calculator;
    __block NSFileManager *fileManager;
    unsigned long long freeDiskSpaceBytes = 1024 * 1024 * 1024;

    beforeEach(^{
        fileManager = fake_for([NSFileManager class]);
        fileManager stub_method(@selector(getFreeDiskSpaceBytes:totalDiskSpaceBytes:)).and_do(^(NSInvocation *invocation) {
            unsigned long long *freeDiskSpacePtr;
            [invocation getArgument:&freeDiskSpacePtr atIndex:2];
            *freeDiskSpacePtr = freeDiskSpaceBytes;
        });

        recordingSpaceRequirements = nice_fake_for([RecordingSpaceRequirements class]);

        calculator = [[RecordingTimeAvailableCalculator alloc] initWithFileManager:fileManager recordingSpaceRequirements:recordingSpaceRequirements];
    });

    describe(@"calculating how long of a recording can be made given the current available disk space", ^{
        __block NSUInteger expectedMinutes;

        beforeEach(^{
            expectedMinutes = 25;
            recordingSpaceRequirements stub_method(@selector(cameraBytesPerMinute)).and_return((NSUInteger)(freeDiskSpaceBytes / expectedMinutes));
        });

        it(@"should return the number of available minutes", ^{
            [calculator calculateAvailableMinutesOfRecordingTime] should equal(expectedMinutes);
        });
    });

    describe(@"categorizing the available recording time", ^{
        __block NSUInteger expectedMinutes;

        context(@"when less than an hour is available", ^{
            beforeEach(^{
                expectedMinutes = 59;
                recordingSpaceRequirements stub_method(@selector(cameraBytesPerMinute)).and_return((NSUInteger)(freeDiskSpaceBytes / expectedMinutes));
            });

            it(@"should report the warning state", ^{
                [calculator recordingTimeAvailableStatus] should equal(RecordingTimeAvailableStatusWarning);
            });
        });

        context(@"when an hour or more is available", ^{
            beforeEach(^{
                expectedMinutes = 61;
                recordingSpaceRequirements stub_method(@selector(cameraBytesPerMinute)).and_return((NSUInteger)(freeDiskSpaceBytes / expectedMinutes));
            });

            it(@"should report the normal state", ^{
                [calculator recordingTimeAvailableStatus] should equal(RecordingTimeAvailableStatusNormal);
            });
        });

    });
});

SPEC_END
