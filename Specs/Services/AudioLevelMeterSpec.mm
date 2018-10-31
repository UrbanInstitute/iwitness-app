#import "AudioLevelMeter.h"
#import "CedarAsync.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(AudioLevelMeterSpec)

describe(@"AudioLevelMeter", ^{
    __block AudioLevelMeter *audioLevelMeter;
    __block AVCaptureConnection *captureConnection;
    __block AVCaptureAudioChannel *audioChannel;

    beforeEach(^{
        AVCaptureSession *captureSession = nice_fake_for([AVCaptureSession class]);

        // Set up a chain of fake objects for the tests to use:
        //  AVCaptureAudioDataOutput -> AVCaptureConnection -> AVCaptureAudioChannel
        captureSession stub_method(@selector(addOutput:)).and_do_block(^(AVCaptureOutput *audioDataOutput) {
            spy_on(audioDataOutput);

            captureSession stub_method(@selector(outputs)).and_return(@[audioDataOutput]);

            captureConnection = nice_fake_for([AVCaptureConnection class]);
            audioDataOutput stub_method(@selector(connections)).and_return(@[captureConnection]);

            audioChannel = nice_fake_for([AVCaptureAudioChannel class]);
            captureConnection stub_method(@selector(audioChannels)).and_return(@[audioChannel]);

            __block BOOL captureConnectionEnabled = NO;
            captureConnection stub_method(@selector(isEnabled)).and_do_block(^BOOL{
                return captureConnectionEnabled;
            });

            captureConnection stub_method(@selector(setEnabled:)).and_do_block(^(BOOL enabled){
                captureConnectionEnabled = enabled;
            });
        });

        audioLevelMeter = [[AudioLevelMeter alloc] initWithCaptureSession:captureSession];
    });

    describe(@"when metering has started", ^{
        beforeEach(^{
            [audioLevelMeter startMetering];
        });

        afterEach(^{
            [audioLevelMeter stopMetering];
        });

        it(@"should have an enabled audio connection", ^{
            captureConnection should have_received(@selector(setEnabled:)).with(YES);
        });

        it(@"should update the power levels", ^{
            __block float currentPowerLevel = -20.f;

            audioChannel stub_method(@selector(averagePowerLevel)).and_do_block(^float{
                return currentPowerLevel;
            });

            with_timeout(0.2f, ^{
                in_time(audioLevelMeter.averagePowerLevel) should equal(0.5f);
            });

            currentPowerLevel = -40.f;

            with_timeout(0.2f, ^{
                in_time(audioLevelMeter.averagePowerLevel) should equal(0.0f);
            });
        });
    });

    describe(@"when metering has stopped", ^{
        beforeEach(^{
            [audioLevelMeter startMetering];
            [audioLevelMeter stopMetering];
        });

        it(@"should not have enabled audio connections", ^{
            captureConnection should have_received(@selector(setEnabled:)).with(NO);
        });
    });
});

SPEC_END
