#import "PreparationViewController.h"
#import "RecordingTimeAvailableCalculator.h"
#import "PreparationViewControllerDelegate.h"
#import "EyewitnessTheme.h"
#import "AnalyticsTracker.h"
#import "OfficerCalibrationViewController.h"
#import "VideoPreviewView.h"
#import "AudioLevelMeter.h"
#import "OfficerIdentificationViewController.h"
#import "WitnessCalibrationViewController.h"
#import "WitnessIdentificationViewController.h"
#import "WitnessInstructionsViewController.h"
#import "CedarAsync.h"
#import "LineupsViewController.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(PreparationViewControllerSpec)

describe(@"PreparationViewControllerSpec", ^{
    __block PreparationViewController *controller;
    __block RecordingTimeAvailableCalculator *recordingTimeAvailableCalculator;
    __block AVAudioSession *audioSession;
    __block id<PreparationViewControllerDelegate> delegate;
    __block VideoPreviewView *videoPreviewView;
    __block AudioLevelMeter *audioLevelMeter;
    __block LineupsViewController *lineupsViewController;
    __block UINavigationController *navController;

    beforeEach(^{
        controller = [[UIStoryboard storyboardWithName:@"PresentationFlow" bundle:nil] instantiateViewControllerWithIdentifier:@"PreparationViewController"];

        recordingTimeAvailableCalculator = nice_fake_for([RecordingTimeAvailableCalculator class]);

        videoPreviewView = [[VideoPreviewView alloc] initWithCaptureSession:nil];

        audioSession = nice_fake_for([AVAudioSession class]);
        spy_on([AnalyticsTracker sharedInstance]);

        audioLevelMeter = nice_fake_for([AudioLevelMeter class]);

        delegate = fake_for(@protocol(PreparationViewControllerDelegate));
        delegate stub_method(@selector(preparationViewControllerDidPresentOfficerIdentification:));
        delegate stub_method(@selector(preparationViewControllerWillHideVideoPreview:));
    });

    void(^displayControllerInHierarchy)() = ^{
        lineupsViewController = [[UIStoryboard storyboardWithName:@"AdminFlow" bundle:nil] instantiateViewControllerWithIdentifier:@"LineupsViewController"];
        navController = [[UINavigationController alloc] initWithRootViewController:lineupsViewController];

        [UIApplication showViewController:navController];
        [navController pushViewController:controller animated:NO];

        in_time(navController.view) should contain(controller.view).nested();

        spy_on(lineupsViewController);
    };

    sharedExamplesFor(@"common behavior of preparation view controller", ^(NSDictionary *sharedContext) {
        describe(@"when the cancel button is tapped", ^{
            beforeEach(^{
                displayControllerInHierarchy();
                [controller.cancelButton tap];
            });

            it(@"should perform an unwind segue signifying presentation cancelation", ^{
                navController.topViewController should be_same_instance_as(lineupsViewController);
                lineupsViewController should have_received(@selector(presentationCanceled:));
            });
        });

        describe(@"preparing for segue", ^{
            describe(@"for the officer calibration view controller", ^{
                __block OfficerCalibrationViewController *officerCalibrationViewController;

                beforeEach(^{
                    officerCalibrationViewController = nice_fake_for([OfficerCalibrationViewController class]);
                    UIStoryboardSegue *segue = [UIStoryboardSegue segueWithIdentifier:@"embedOfficerCalibration"
                                                                               source:controller
                                                                          destination:officerCalibrationViewController
                                                                       performHandler:^{}];
                    [controller prepareForSegue:segue sender:controller];
                });

                it(@"should configure the officer calibration view controller appropriately", ^{
                    officerCalibrationViewController should have_received(@selector(configureWithAudioLevelMeter:audioSession:delegate:)).with(audioLevelMeter, audioSession, controller);
                });

                describe(@"for the officer identification view controller", ^{
                    __block OfficerIdentificationViewController *officerIdentificationViewController;

                    beforeEach(^{
                        officerIdentificationViewController = nice_fake_for([OfficerIdentificationViewController class]);
                        UIStoryboardSegue *segue = [UIStoryboardSegue segueWithIdentifier:@"embedOfficerIdentification"
                                                                                   source:controller
                                                                              destination:officerIdentificationViewController
                                                                           performHandler:^{}];
                        [controller prepareForSegue:segue sender:controller];
                    });

                    it(@"should configure the officer calibration view controller appropriately", ^{
                        officerIdentificationViewController should have_received(@selector(configureWithAudioLevelMeter:delegate:)).with(audioLevelMeter, controller);
                    });
                });

                describe(@"for the witness calibration view controller", ^{
                    __block WitnessCalibrationViewController *witnessCalibrationViewController;

                    beforeEach(^{
                        witnessCalibrationViewController = nice_fake_for([WitnessCalibrationViewController class]);
                        UIStoryboardSegue *segue = [UIStoryboardSegue segueWithIdentifier:@"embedWitnessCalibration"
                                                                                   source:controller
                                                                              destination:witnessCalibrationViewController
                                                                           performHandler:^{}];
                        [controller prepareForSegue:segue sender:controller];
                    });

                    it(@"should configure the witness calibration view controller appropriately", ^{
                        witnessCalibrationViewController should have_received(@selector(configureWithAudioLevelMeter:delegate:)).with(audioLevelMeter, controller);
                    });
                });

                describe(@"for the witness identification view controller", ^{
                    __block WitnessIdentificationViewController *witnessIdentificationViewController;

                    beforeEach(^{
                        witnessIdentificationViewController = nice_fake_for([WitnessIdentificationViewController class]);
                        UIStoryboardSegue *segue = [UIStoryboardSegue segueWithIdentifier:@"embedWitnessIdentification"
                                                                                   source:controller
                                                                              destination:witnessIdentificationViewController
                                                                           performHandler:^{}];
                        [controller prepareForSegue:segue sender:controller];
                    });

                    it(@"should configure the witness calibration view controller appropriately", ^{
                        witnessIdentificationViewController should have_received(@selector(configureWithAudioLevelMeter:delegate:)).with(audioLevelMeter, controller);
                    });
                });
            });
        });

        describe(@"indication of available recording time", ^{
            subjectAction(^{
                displayControllerInHierarchy();
            });

            context(@"recording time available has normal status", ^{
                beforeEach(^{
                    recordingTimeAvailableCalculator stub_method(@selector(calculateAvailableMinutesOfRecordingTime)).and_return((NSUInteger)61);
                    recordingTimeAvailableCalculator stub_method(@selector(recordingTimeAvailableStatus)).and_return(RecordingTimeAvailableStatusNormal);
                });

                it(@"should show the available time with a normal appearance ", ^{
                    controller.availableTimeLabel.textColor should equal([EyewitnessTheme darkerGrayColor]);
                });

                it(@"should show that more than an hour is available", ^{
                    controller.availableTimeLabel.text should equal(@"More than an hour of video left on device");
                });
            });

            context(@"recording time available has warning status", ^{
                beforeEach(^{
                    recordingTimeAvailableCalculator stub_method(@selector(calculateAvailableMinutesOfRecordingTime)).and_return((NSUInteger)59);
                    recordingTimeAvailableCalculator stub_method(@selector(recordingTimeAvailableStatus)).and_return(RecordingTimeAvailableStatusWarning);
                });

                it(@"should show the available time with an alert appearance ", ^{
                    controller.availableTimeLabel.textColor should equal([EyewitnessTheme warnColor]);
                });

                it(@"should show how many minutes are available", ^{
                    controller.availableTimeLabel.text should equal(@"59 minutes of video left on device");
                });
            });
        });

        context(@"when the view has appeared", ^{
            beforeEach(^{
                displayControllerInHierarchy();
            });

            it(@"should intially embed an officer calibration view controller", ^{
                controller.childViewControllers.count should equal(1);
                controller.childViewControllers.lastObject should be_instance_of([OfficerCalibrationViewController class]);
                controller.embedContainerView.subviews should contain([controller.childViewControllers.lastObject view]);
            });

            describe(@"when the officer calibration view controller cancels", ^{
                beforeEach(^{
                    [controller officerCalibrationViewControllerDidCancel:nice_fake_for([OfficerCalibrationViewController class])];
                });

                it(@"should perform an unwind segue signifying presentation cancelation", ^{
                    navController.topViewController should be_same_instance_as(lineupsViewController);
                    lineupsViewController should have_received(@selector(presentationCanceled:));
                });
            });

            describe(@"when the officer calibration view controller continues", ^{
                beforeEach(^{
                    [controller officerCalibrationViewControllerDidContinue:nice_fake_for([OfficerCalibrationViewController class])];
                });

                it(@"should embed an officer identification view controller", ^{
                    controller.childViewControllers.count should equal(1);
                    controller.childViewControllers.lastObject should be_instance_of([OfficerIdentificationViewController class]);
                    controller.embedContainerView.subviews should contain([controller.childViewControllers.lastObject view]);
                });

                it(@"should remove the cancel button from the left bar button items", ^{
                    controller.navigationItem.leftBarButtonItems should be_empty;
                });

                it(@"should hide the available recording time bar", ^{
                    controller.availableTimeLabelContainer.isHidden should be_truthy;
                });
            });

            describe(@"when the officer identification view controller continues", ^{
                beforeEach(^{
                    [controller officerIdentificationViewControllerDidContinue:nice_fake_for([OfficerIdentificationViewController class])];
                });

                it(@"should embed a witness calibration view controller", ^{
                    controller.childViewControllers.count should equal(1);
                    controller.childViewControllers.lastObject should be_instance_of([WitnessCalibrationViewController class]);
                    controller.embedContainerView.subviews should contain([controller.childViewControllers.lastObject view]);
                });
            });

            describe(@"when the officer identification view controller appears", ^{
                beforeEach(^{
                    [controller officerIdentificationViewControllerDidAppear:nice_fake_for([OfficerIdentificationViewController class])];
                });

                it(@"should notify its delegate of presenting the officer identification view controller", ^{
                    delegate should have_received(@selector(preparationViewControllerDidPresentOfficerIdentification:)).with(controller);
                });
            });

            describe(@"when the witness calibration view controller continues", ^{
                beforeEach(^{
                    [controller witnessCalibrationViewControllerDidContinue:nice_fake_for([WitnessCalibrationViewController class])];
                });

                it(@"should embed a witness identification view controller", ^{
                    controller.childViewControllers.count should equal(1);
                    controller.childViewControllers.lastObject should be_instance_of([WitnessIdentificationViewController class]);
                    controller.embedContainerView.subviews should contain([controller.childViewControllers.lastObject view]);
                });
            });

            describe(@"when the witness identification view controller continues", ^{
                __block UINavigationController *navController;

                beforeEach(^{
                    navController = [[UINavigationController alloc] initWithRootViewController:controller];
                    [controller witnessIdentificationViewControllerDidContinue:nice_fake_for([WitnessIdentificationViewController class])];
                });

                it(@"should push the witness instructions view controller onto the navigation stack", ^{
                    navController.topViewController should be_instance_of([WitnessInstructionsViewController class]);
                });
            });
        });

        describe(@"Indication of showing/hiding the video preview", ^{
            context(@"after the view appears", ^{
                subjectAction(^{
                    [controller viewDidAppear:NO];
                });

                context(@"when the delegate responds to the video preview being shown", ^{
                    beforeEach(^{
                        delegate stub_method(@selector(preparationViewControllerDidShowVideoPreview:));
                    });

                    it(@"should tell the delegate that it has shown the video preview", ^{
                        delegate should have_received(@selector(preparationViewControllerDidShowVideoPreview:)).with(controller);
                    });
                });

                context(@"when the delegate does not respond to the video preview being shown", ^{
                    beforeEach(^{
                        [delegate respondsToSelector:@selector(preparationViewControllerDidShowVideoPreview:)] should be_falsy;
                    });
                    it(@"should tell the delegate that it has shown the video preview", ^{
                        delegate should_not have_received(@selector(preparationViewControllerDidShowVideoPreview:)).with(controller);
                    });
                });
            });

            context(@"before the the view disappears", ^{
                beforeEach(^{
                    [controller viewWillDisappear:NO];
                });

                it(@"should tell the delegate that it has shown the video preview", ^{
                    delegate should have_received(@selector(preparationViewControllerWillHideVideoPreview:)).with(controller);
                });
            });
        });
    });

    context(@"when configured with a video preview view", ^{
        beforeEach(^{
            [controller configureWithCaseID:nil
                           videoPreviewView:videoPreviewView
                            audioLevelMeter:audioLevelMeter
                               audioSession:audioSession
                                   delegate:delegate
           recordingTimeAvailableCalculator:recordingTimeAvailableCalculator];
            controller.view should_not be_nil;
        });

        itShouldBehaveLike(@"common behavior of preparation view controller");

        context(@"when the view is about to layout it's subviews", ^{
            beforeEach(^{
                [controller viewWillLayoutSubviews];
            });

            it(@"should visibily place the video preview in the container", ^{
                controller.outerVideoPreviewContainerView.hidden should be_falsy;
                controller.videoPreviewContainerView.hidden should be_falsy;
                videoPreviewView.superview should be_same_instance_as(controller.videoPreviewContainerView);
                controller.videoPreviewContainerView.superview should be_same_instance_as(controller.outerVideoPreviewContainerView);
            });

            context(@"when the view is about to layout it's subviews again", ^{
                beforeEach(^{
                    [controller viewWillLayoutSubviews];
                });

                it(@"should visibily place the video preview in the container", ^{
                    controller.outerVideoPreviewContainerView.hidden should be_falsy;
                    controller.videoPreviewContainerView.hidden should be_falsy;
                    videoPreviewView.superview should be_same_instance_as(controller.videoPreviewContainerView);
                    controller.videoPreviewContainerView.superview should be_same_instance_as(controller.outerVideoPreviewContainerView);
                });
            });
        });
    });

    context(@"when configured without a video preview view", ^{
        beforeEach(^{
            [controller configureWithCaseID:nil
                           videoPreviewView:nil
                            audioLevelMeter:audioLevelMeter
                               audioSession:audioSession
                                   delegate:delegate
           recordingTimeAvailableCalculator:recordingTimeAvailableCalculator];
            controller.view should_not be_nil;
        });

        itShouldBehaveLike(@"common behavior of preparation view controller");

        context(@"when the view is about to layout it's subviews", ^{
            beforeEach(^{
                [controller viewWillLayoutSubviews];
            });

            it(@"should hide the container of the video preview view's container", ^{
                controller.outerVideoPreviewContainerView.hidden should be_truthy;
            });
        });
    });

    describe(@"setting the navigation title", ^{
        context(@"when configured with a caseID", ^{
            beforeEach(^{
                [controller configureWithCaseID:@"784834"
                               videoPreviewView:nil
                                audioLevelMeter:nil
                                   audioSession:nil
                                       delegate:nil
               recordingTimeAvailableCalculator:nil];
                displayControllerInHierarchy();
            });

            it(@"should set the title of the navigation bar item", ^{
                controller.navigationItem.title should equal(@"Present Case ID: 784834");
            });
        });

        context(@"when configured without a caseID", ^{
            beforeEach(^{
                [controller configureWithCaseID:nil
                               videoPreviewView:nil
                                audioLevelMeter:nil
                                   audioSession:nil
                                       delegate:nil
               recordingTimeAvailableCalculator:nil];
                displayControllerInHierarchy();
            });

            it(@"should set the title of the navigation bar item", ^{
                controller.navigationItem.title should equal(@"Present Case ID: <unknown>");
            });
        });

        context(@"when configured with a blank caseID", ^{
            beforeEach(^{
                [controller configureWithCaseID:@""
                               videoPreviewView:nil
                                audioLevelMeter:nil
                                   audioSession:nil
                                       delegate:nil
               recordingTimeAvailableCalculator:nil];
                displayControllerInHierarchy();
            });

            it(@"should set the title of the navigation bar item", ^{
                controller.navigationItem.title should equal(@"Present Case ID: <unknown>");
            });
        });

    });
});

SPEC_END
