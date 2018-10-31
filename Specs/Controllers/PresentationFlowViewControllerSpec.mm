#import "PresentationFlowViewController.h"
#import "Presentation.h"
#import "PhotoIDViewController.h"
#import "Lineup.h"
#import "PresentationRecorder.h"
#import "ScreenCaptureService.h"
#import "PresentationFlowViewControllerDelegate.h"
#import "RecordingTimeAvailableCalculator.h"
#import "AudioLevelMeter.h"
#import "PasswordValidator.h"
#import "UIGestureRecognizer+Spec.h"
#import "AudioPlayerService.h"
#import "KioskModeService.h"
#import "AnalyticsTracker.h"
#import "VideoPreviewView.h"
#import "PreparationViewController.h"
#import "AudioWarningViewController.h"
#import "CedarAsync.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(PresentationFlowViewControllerSpec)

describe(@"PresentationFlowViewController", ^{
    __block PresentationFlowViewController *controller;
    __block id<PresentationFlowViewControllerDelegate> flowDelegate;
    __block Presentation *presentation;
    __block PresentationRecorder *recorder;
    __block PasswordValidator *passwordValidator;
    __block VideoPreviewView *videoPreviewView;
    __block AudioLevelMeter *audioLevelMeter;
    __block KioskModeService *kioskModeService;
    __block UIApplication *application;
    __block AVAudioSession *audioSession;
    __block KSDeferred *stopRecordingDeferred;
    __block AVCaptureSession *captureSession;
    __block AudioWarningViewController *audioWarningViewController;
    __block Lineup *lineup;

    void (^beginRecordingPresentation)() = ^{
        PreparationViewController *preparationViewController = nice_fake_for([PreparationViewController class]);
        [controller preparationViewControllerDidPresentOfficerIdentification:preparationViewController];
        recorder should have_received(@selector(startRecordingWithStartTime:));
    };

    beforeEach(^{
        [UIGestureRecognizer whitelistClassForGestureSnooping:[PresentationFlowViewController class]];

        controller = [[UIStoryboard storyboardWithName:@"PresentationFlow" bundle:nil] instantiateViewControllerWithIdentifier:@"PresentationFlowViewController"];
        controller.topViewController should be_instance_of([AudioWarningViewController class]);
        audioWarningViewController = (AudioWarningViewController *)controller.topViewController;
        spy_on(audioWarningViewController);

        flowDelegate = nice_fake_for(@protocol(PresentationFlowViewControllerDelegate));

        lineup = nice_fake_for([Lineup class]);
        lineup stub_method(@selector(caseID)).and_return(@"something relatively unique");

        presentation = nice_fake_for([Presentation class]);
        presentation stub_method(@selector(date)).and_return([NSDate date]);
        presentation stub_method(@selector(lineup)).and_return(lineup);

        recorder = nice_fake_for([PresentationRecorder class]);
        stopRecordingDeferred = [KSDeferred defer];
        recorder stub_method(@selector(stopRecording)).and_return(stopRecordingDeferred.promise);

        captureSession = nice_fake_for([AVCaptureSession class]);
        videoPreviewView = nice_fake_for([VideoPreviewView class]);

        passwordValidator = nice_fake_for([PasswordValidator class]);
        passwordValidator stub_method(@selector(isValidPassword:)).with(@"officer").and_return(YES);

        audioLevelMeter = nice_fake_for([AudioLevelMeter class]);

        kioskModeService = nice_fake_for([KioskModeService class]);
        application = [UIApplication sharedApplication];

        audioSession = nice_fake_for([AVAudioSession class]);
        audioSession stub_method(@selector(setActive:withOptions:error:));

        spy_on([AnalyticsTracker sharedInstance]);

        [controller configureWithPresentation:presentation
                         presentationRecorder:recorder
                            passwordValidator:passwordValidator
                             videoPreviewView:videoPreviewView
                               captureSession:captureSession
                              audioLevelMeter:audioLevelMeter
                             kioskModeService:kioskModeService
                                 audioSession:audioSession
                                 flowDelegate:flowDelegate];

        controller.view should_not be_nil;
    });

    it(@"should only support portrait upside-right orientation", ^{
        [controller supportedInterfaceOrientations] should equal(UIInterfaceOrientationMaskPortrait);
    });

    describe(@"when the view appears", ^{
        beforeEach(^{
            [controller viewWillAppear:NO];
            [controller viewDidAppear:NO];
        });

        it(@"should enable kiosk mode", ^{
            kioskModeService should have_received(@selector(enableKioskMode));
        });

        it(@"should disable the application's idle timer", ^{
            application.idleTimerDisabled should be_truthy;
        });

        it(@"should start the capture session", ^{
            captureSession should have_received(@selector(startRunning));
        });

        it(@"should configure the audio warning view controller appropriately", ^{
            audioWarningViewController should have_received(@selector(configureWithAudioSession:)).with(audioSession);
        });
    });

    describe(@"when the view disappears", ^{
        subjectAction(^{
            [controller viewWillDisappear:NO];
            [controller viewDidDisappear:NO];
        });

        it(@"should disable kiosk mode", ^{
            kioskModeService should have_received(@selector(disableKioskMode));
        });

        it(@"should enable the application's idle timer", ^{
            application.idleTimerDisabled should be_falsy;
        });

        context(@"when recording hasn't started but the capture session is still running", ^{
            beforeEach(^{
                captureSession stub_method(@selector(isRunning)).and_return(YES);
            });

            it(@"should stop the capture session", ^{
                in_time(captureSession) should have_received(@selector(stopRunning));
            });

            it(@"should deactivate the audio session", ^{
                in_time(audioSession) should have_received(@selector(setActive:withOptions:error:)).with(NO, 0, Arguments::anything);
            });
        });
    });

    describe(@"when the presentation flow is notified the officer identifcation was shown", ^{
        beforeEach(^{
            spy_on(presentation);
            beginRecordingPresentation();
        });

        it(@"should start the new recording", ^{
            recorder should have_received(@selector(startRecordingWithStartTime:));
        });

        it(@"should track the presentation having started", ^{
            [AnalyticsTracker sharedInstance] should have_received(@selector(trackPresentationStarted));
        });
    });

    describe(@"when the presentation flow is about to show the preparation view controller", ^{
        __block PreparationViewController *preparationViewController;
        subjectAction(^{
            preparationViewController = [[UIStoryboard storyboardWithName:@"PresentationFlow" bundle:nil] instantiateViewControllerWithIdentifier:@"PreparationViewController"];
            spy_on(preparationViewController);
            [controller pushViewController:preparationViewController animated:NO];
        });

        context(@"when the presentation is audio only", ^{
            beforeEach(^{
                lineup stub_method(@selector(isAudioOnly)).and_return(YES);
            });

            it(@"should configure the controller appropriately", ^{
                preparationViewController should have_received(@selector(configureWithCaseID:videoPreviewView:audioLevelMeter:audioSession:delegate:recordingTimeAvailableCalculator:)).with(@"something relatively unique", nil, audioLevelMeter, audioSession, controller, Arguments::any([RecordingTimeAvailableCalculator class]));
            });
        });

        context(@"when the presentation is not audio only", ^{
            beforeEach(^{
                lineup stub_method(@selector(isAudioOnly)).and_return(NO);
            });

            it(@"should configure the controller appropriately", ^{
                preparationViewController should have_received(@selector(configureWithCaseID:videoPreviewView:audioLevelMeter:audioSession:delegate:recordingTimeAvailableCalculator:)).with(@"something relatively unique", videoPreviewView, audioLevelMeter, audioSession, controller, Arguments::any([RecordingTimeAvailableCalculator class]));
            });
        });

        it(@"should start metering audio", ^{
            audioLevelMeter should have_received(@selector(startMetering));
        });
    });

    describe(@"when the presentation flow is about to show a witness instructions view controller", ^{
        __block WitnessInstructionsViewController *witnessInstructionsViewController;

        beforeEach(^{
            witnessInstructionsViewController = [[UIStoryboard storyboardWithName:@"PresentationFlow" bundle:nil] instantiateViewControllerWithIdentifier:@"WitnessInstructionsViewController"];
            spy_on(witnessInstructionsViewController);
            [controller pushViewController:witnessInstructionsViewController animated:NO];
        });

        it(@"should configure itself as the instruction view controller delegate with a moviePlayerController", ^{
            witnessInstructionsViewController should have_received(@selector(configureWithDelegate:screenCaptureService:avPlayer:)).with(controller, Arguments::any([ScreenCaptureService class]), Arguments::any([AVPlayer class]));
        });
    });

    describe(@"when the presentation flow is about to show a photo ID view controller", ^{
        __block PhotoIDViewController *photoIDViewController;

        beforeEach(^{
            photoIDViewController = [[UIStoryboard storyboardWithName:@"PresentationFlow" bundle:nil] instantiateViewControllerWithIdentifier:@"PhotoIDViewController"];
            spy_on(photoIDViewController);
            [controller pushViewController:photoIDViewController animated:NO];
        });

        it(@"should configure it with a presentation and capture session provider", ^{
            photoIDViewController should have_received(@selector(configureWithPresentation:audioLevelMeter:audioPlayerService:)).with(presentation, audioLevelMeter, Arguments::any([AudioPlayerService class]));
        });
    });

    describe(@"when the presentation flow is about to show a PresentationCompleteViewController", ^{
        __block PresentationCompleteViewController *presentationCompleteViewController;

        beforeEach(^{
            presentationCompleteViewController = [[UIStoryboard storyboardWithName:@"PresentationFlow" bundle:nil] instantiateViewControllerWithIdentifier:@"PresentationCompleteViewController"];
            spy_on(presentationCompleteViewController);
            [controller pushViewController:presentationCompleteViewController animated:NO];
        });

        it(@"should configure itself as the delegate of the presentation complete view controller", ^{
            presentationCompleteViewController should have_received(@selector(configureWithPasswordValidator:delegate:audioPlayerService:)).with(Arguments::any([PasswordValidator class]), controller, Arguments::any([AudioPlayerService class]));
        });
    });

    sharedExamplesFor(@"ending the presentation", ^(NSDictionary *) {
        it(@"should display the modal spinner covering all child views", ^{
            controller.view.subviews.lastObject should be_same_instance_as(controller.modalSpinnerContainer);
            controller.modalSpinnerContainer.frame should equal(controller.view.bounds);
        });

        it(@"should stop the recording", ^{
            recorder should have_received(@selector(stopRecording));
        });

        it(@"should stop metering audio", ^{
            audioLevelMeter should have_received(@selector(stopMetering));
        });

        it(@"should track the finished presentation", ^{
            [AnalyticsTracker sharedInstance] should have_received(@selector(trackPresentationCompleted));
        });

        describe(@"when the recording finishes", ^{
            __block NSArray *outputs;
            __block NSArray *inputs;

            beforeEach(^{
                inputs = @[
                        fake_for([AVCaptureInput class]),
                        fake_for([AVCaptureInput class]),
                        fake_for([AVCaptureInput class])
                ];

                outputs = @[
                        fake_for([AVCaptureOutput class]),
                        fake_for([AVCaptureOutput class])
                ];

                captureSession stub_method(@selector(isRunning)).and_return(YES);
                captureSession stub_method(@selector(inputs)).and_return(inputs);
                captureSession stub_method(@selector(outputs)).and_return(outputs);

                [stopRecordingDeferred resolveWithValue:nil];
            });

            it(@"should stop the capture session", ^{
                in_time(captureSession) should have_received(@selector(stopRunning));
            });

            it(@"should remove all inputs", ^{
                for(AVCaptureInput *input in inputs) {
                    in_time(captureSession) should have_received(@selector(removeInput:)).with(input);
                }
            });

            it(@"should remove all outputs", ^{
                for(AVCaptureInput *output in outputs) {
                    in_time(captureSession) should have_received(@selector(removeOutput:)).with(output);
                }
            });

            it(@"should deactivate the audio session", ^{
                in_time(audioSession) should have_received(@selector(setActive:withOptions:error:)).with(NO, 0, Arguments::anything);
            });

            it(@"should notify its delegate on the main thread", ^{
                flowDelegate stub_method(@selector(presentationFlowViewControllerDidFinish:)).and_do_block(^(PresentationFlowViewController *arg){
                    [NSThread mainThread] should be_truthy;
                });
                in_time(flowDelegate) should have_received(@selector(presentationFlowViewControllerDidFinish:)).with(controller);
            });

            context(@"when the capture session has been stopped and the view disappears", ^{
                it(@"should not attempt to stop the capture session again", PENDING);
            });
        });
    });

    context(@"while recording is in progress", ^{
        beforeEach(^{
            beginRecordingPresentation();
        });

        describe(@"video preview is hidden", ^{
            beforeEach(^{
                [controller preparationViewControllerWillHideVideoPreview:nil];
            });

            it(@"should record a start time on the presentation", ^{
                recorder should have_received(@selector(recordVideoPreviewEndTime:));
            });
        });

        describe(@"instruction video playback starts", ^{
            beforeEach(^{
                spy_on(presentation);
                [controller witnessInstructionsViewControllerStartedPlayback:nil];
            });

            it(@"should record a start time on the presentation", ^{
                recorder should have_received(@selector(recordInstructionsPlaybackStartTime:));
            });
        });

        describe(@"instruction video playback stops", ^{
            beforeEach(^{
                spy_on(presentation);
                [controller witnessInstructionsViewControllerStoppedPlayback:nil];
            });

            it(@"should record a start time on the presentation", ^{
                recorder should have_received(@selector(recordInstructionsPlaybackEndTime:));
            });
        });

        describe(@"when the presentation is finished", ^{
            beforeEach(^{
                [controller presentationCompleteViewControllerDidFinish:nil];
            });

            itShouldBehaveLike(@"ending the presentation");
        });
    });

    describe(@"exiting the presentation before its completion", ^{
        context(@"two-finger swiping upward before recording has started", ^{
            beforeEach(^{
                [controller.twoFingerUpwardSwipeRecognizer recognize];
            });

            it(@"should not respond to the two-finger swipe", ^{
                [UIAlertView currentAlertView] should be_nil;
            });
        });

        context(@"two-finger swiping upward after recording has started", ^{
            __block UIAlertView *alert;

            beforeEach(^{
                beginRecordingPresentation();
                [controller.twoFingerUpwardSwipeRecognizer recognize];
                alert = [UIAlertView currentAlertView];
            });

            it(@"should show an alert view with a password field asking for confirmation", ^{
                alert should_not be_nil;
                alert.alertViewStyle should equal(UIAlertViewStyleSecureTextInput);
                alert.title should equal(@"Enter Officer Password to End the Presentation");
                [alert buttonTitleAtIndex:0] should equal(@"Cancel");
                [alert buttonTitleAtIndex:1] should equal(@"Exit");
            });

            describe(@"when the user cancels exiting", ^{
                beforeEach(^{
                    [alert dismissWithCancelButton];
                });

                it(@"should not notify its delegate of completion", ^{
                    flowDelegate should_not have_received(@selector(presentationFlowViewControllerDidFinish:)).with(controller);
                });

                it(@"should not stop the recording", ^{
                    recorder should_not have_received(@selector(stopRecording));
                });
            });

            describe(@"when the user tries to exit without the password", ^{
                beforeEach(^{
                    [alert dismissWithOkButton];
                });

                it(@"should show an alert view indicating the password was wrong", ^{
                    alert = [UIAlertView currentAlertView];
                    alert.title should equal(@"Incorrect Password");
                });
            });

            describe(@"when the user exits with the right password", ^{
                beforeEach(^{
                    [alert textFieldAtIndex:0].text = @"officer";
                    [alert dismissWithOkButton];
                });

                itShouldBehaveLike(@"ending the presentation");
            });
        });
    });
});

SPEC_END
