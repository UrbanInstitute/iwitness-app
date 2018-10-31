#import "OfficerCalibrationViewController.h"
#import "RecordingTimeAvailableCalculator.h"
#import "OfficerCalibrationViewControllerDelegate.h"
#import "CedarAsync.h"
#import "AnalyticsTracker.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(OfficerCalibrationViewControllerSpec)

describe(@"OfficerCalibrationViewControllerSpec", ^{
    __block OfficerCalibrationViewController *controller;
    __block RecordingTimeAvailableCalculator *recordingTimeAvailableCalculator;
    __block AVAudioSession *audioSession;
    __block id<OfficerCalibrationViewControllerDelegate> delegate;

    beforeEach(^{
        controller = [[UIStoryboard storyboardWithName:@"PresentationFlow" bundle:nil] instantiateViewControllerWithIdentifier:@"OfficerCalibrationViewController"];

        recordingTimeAvailableCalculator = nice_fake_for([RecordingTimeAvailableCalculator class]);

        audioSession = nice_fake_for([AVAudioSession class]);
        spy_on([AnalyticsTracker sharedInstance]);

        delegate = nice_fake_for(@protocol(OfficerCalibrationViewControllerDelegate));

        [controller configureWithAudioLevelMeter:nil audioSession:audioSession delegate:delegate];
        controller.view should_not be_nil;
    });

    context(@"when the view has appeared", ^{
        beforeEach(^{
            recordingTimeAvailableCalculator stub_method(@selector(calculateAvailableMinutesOfRecordingTime)).and_return((NSUInteger)94);
            controller = [[UIStoryboard storyboardWithName:@"PresentationFlow" bundle:nil] instantiateViewControllerWithIdentifier:@"OfficerCalibrationViewController"];
            [controller configureWithAudioLevelMeter:nil audioSession:audioSession delegate:delegate];
            controller.view should_not be_nil;
            [controller viewWillAppear:NO];
        });

        subjectAction(^{
            [controller viewDidAppear:NO];
        });

        describe(@"when the start button is enabled and then tapped", ^{
            beforeEach(^{
                controller.continueButton.enabled = YES;
                [controller.continueButton tap];
            });

            it(@"should inform the delegate", ^{
                delegate should have_received(@selector(officerCalibrationViewControllerDidContinue:)).with(controller);
            });
        });

        describe(@"preventing progressing with a disabled microphone", ^{
            it(@"should request microphone access", ^{
                audioSession should have_received(@selector(requestRecordPermission:));
            });

            it(@"should disable the Start button", ^{
                controller.continueButton.enabled should be_falsy;
            });

            context(@"when microphone access is granted", ^{
                beforeEach(^{
                    audioSession stub_method(@selector(requestRecordPermission:)).and_do_block(^(PermissionBlock permissionBlock){
                        permissionBlock(YES);
                    });
                });

                it(@"should enable the Start button", ^{
                    in_time(controller.continueButton.enabled) should be_truthy;
                });
            });

            context(@"when microphone access is denied", ^{
                beforeEach(^{
                    audioSession stub_method(@selector(requestRecordPermission:)).and_do_block(^(PermissionBlock permissionBlock){
                        permissionBlock(NO);
                    });
                });

                it(@"should prompt the user to turn on microphone access", ^{
                    in_time([UIAlertView currentAlertView]) should_not be_nil;
                    UIAlertView *alert = [UIAlertView currentAlertView];
                    alert should_not be_nil;
                    alert.title should equal(@"Need Microphone Access");
                    alert.message should equal(@"Please adjust your Privacy settings in the Settings app to enable microphone access for the Eyewitness app.");
                });

                it(@"should log an analytics event about the denial", ^{
                    in_time([AnalyticsTracker sharedInstance]) should have_received(@selector(trackMicrophoneAccessDenied));
                });

                describe(@"when the user dismisses the alert", ^{
                    it(@"should cancel the presentation", ^{
                        in_time([UIAlertView currentAlertView]) should_not be_nil;
                        [[UIAlertView currentAlertView] dismissWithCancelButton];
                        delegate should have_received(@selector(officerCalibrationViewControllerDidCancel:));
                    });
                });
            });
        });
    });
});

SPEC_END
