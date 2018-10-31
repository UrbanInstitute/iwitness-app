#import "PhotoIDViewController.h"
#import "Presentation.h"
#import "WitnessConfirmationViewController.h"
#import "QualifyUncertaintyViewController.h"
#import "QualifyIdentificationViewController.h"
#import "IdentificationCertaintyViewController.h"
#import "PresentationCompleteViewController.h"
#import "AudioLevelMeter.h"
#import "PhotoNumberLabel.h"
#import "AudioPlayerService.h"
#import "WitnessResponseSelector.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(PhotoIDViewControllerSpec)

describe(@"PhotoIDViewController", ^{
    __block PhotoIDViewController *controller;
    __block UINavigationController *navController;
    __block NSURL *firstPhotoURL;
    __block NSURL *currentPhotoURL;
    __block NSInteger currentPhotoIndex;
    __block Presentation *presentation;
    __block AudioPlayerService *audioPlayerService;
    __block KSDeferred *recognitionPromptDeferred;
    __block AudioLevelMeter *audioLevelMeter;

    beforeEach(^{
        controller = [[UIStoryboard storyboardWithName:@"PresentationFlow" bundle:nil] instantiateViewControllerWithIdentifier:@"PhotoIDViewController"];

        firstPhotoURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"cathy" withExtension:@"jpg" subdirectory:@"SampleLineup"];
        currentPhotoURL = firstPhotoURL;
        currentPhotoIndex = 0;

        presentation = nice_fake_for([Presentation class]);
        presentation stub_method(@selector(currentPhotoURL)).and_do_block(^NSURL *{
            return currentPhotoURL;
        });

        presentation stub_method(@selector(currentPhotoIndex)).and_do_block(^NSInteger{
           return currentPhotoIndex;
        });

        audioLevelMeter = nice_fake_for([AudioLevelMeter class]);

        audioPlayerService = nice_fake_for([AudioPlayerService class]);
        recognitionPromptDeferred = [KSDeferred defer];
        audioPlayerService stub_method(@selector(playSoundNamed:)).with(@"recognition_prompt").and_return(recognitionPromptDeferred.promise);

        [controller configureWithPresentation:presentation
                              audioLevelMeter:audioLevelMeter
                           audioPlayerService:audioPlayerService];

        navController = [[UINavigationController alloc] initWithRootViewController:controller];

        controller.view should_not be_nil;
    });

    sharedExamplesFor(@"showing a prompt to speak view controller", ^(NSDictionary *dictionary) {
        it(@"should show a prompt to speak view controller", ^{
            controller.childViewControllers.firstObject should be_instance_of([PromptToSpeakViewController class]);
            controller.view should contain([controller.childViewControllers.firstObject view]).nested();
        });
    });

    describe(@"when the view has appeared", ^{
        beforeEach(^{
            [controller viewWillAppear:NO];
            [controller viewDidAppear:NO];
        });

        itShouldBehaveLike(@"showing a prompt to speak view controller");

        it(@"should disable the witness response selector", ^{
            controller.responseSelector.enabled should_not be_truthy;
        });

        it(@"should play the recognition audio prompt", ^{
            audioPlayerService should have_received(@selector(playSoundNamed:)).with(@"recognition_prompt");
        });

        it(@"should use the first photo for the mugshot photo image view", ^{
            [controller.mugshotPhotoImageView.image isEqualToByBytes:[UIImage imageWithContentsOfFile:[firstPhotoURL path]]] should be_truthy;
            controller.photoNumberLabel.text should equal(@"1");
        });

        context(@"the recognition audio prompt has finished playing", ^{
            beforeEach(^{
                [recognitionPromptDeferred resolveWithValue:nil];
            });

            it(@"should enable the witness response selector", ^{
                controller.responseSelector.enabled should be_truthy;
            });
        });
    });

    describe(@"string localization", ^{
        context(@"English", ^{
            beforeEach(^{
                [WitnessLocalization setWitnessLanguageCode:@"en"];
                [controller viewWillAppear:NO];
            });

            it(@"should localize the strings for English", ^{
                controller.recognitionPromptLabel.text should equal(@"Please state whether you recognize this person.");
            });
        });

        context(@"Spanish", ^{
            beforeEach(^{
                [WitnessLocalization setWitnessLanguageCode:@"es"];
                [controller viewWillAppear:NO];
            });

            it(@"should localize the strings for Spanish", ^{
                controller.recognitionPromptLabel.text should equal(@"Sírvase indicar si usted reconoce a esta persona.");
            });
        });
    });

    describe(@"when not configured with a presentation", ^{
        beforeEach(^{
            controller = [[UIStoryboard storyboardWithName:@"PresentationFlow" bundle:nil] instantiateViewControllerWithIdentifier:@"PhotoIDViewController"];
            controller.view should_not be_nil;
            [controller viewWillAppear:NO];
        });

        it(@"should blow up when the view appears", ^{
            ^{ [controller viewDidAppear:NO]; } should raise_exception;
        });
    });

    describe(@"when the 'No' button is tapped to deny knowing the person in the mugshot", ^{
        beforeEach(^{
            [controller.responseSelector.noButton tap];
        });

        it(@"should show Denial Confirmation view controller within the answer details container view", ^{
            controller.childViewControllers.firstObject should be_instance_of([WitnessConfirmationViewController class]);
            controller.embedContainerView.subviews should contain([controller.childViewControllers.firstObject view]);
        });
    });

    describe(@"when the 'Not Sure' button is tapped to indicate uncertainty of knowing person in the mugshot", ^{
        beforeEach(^{
            [controller.responseSelector.notSureButton tap];
        });

        it(@"should show Unsure Confirmation view controller within the answer details container view", ^{
            controller.childViewControllers.firstObject should be_instance_of([QualifyUncertaintyViewController class]);
            controller.embedContainerView.subviews should contain([controller.childViewControllers.firstObject view]);
        });
    });

    describe(@"when the 'Yes' button is tapped to indicate knowing the person in the mugshot", ^{
        beforeEach(^{
            [controller.responseSelector.yesButton tap];
        });

        it(@"should show Qualify Identification view controller within the answer details container view", ^{
            controller.childViewControllers.firstObject should be_instance_of([QualifyIdentificationViewController class]);
            controller.embedContainerView.subviews should contain([controller.childViewControllers.firstObject view]);
        });
    });

    describe(@"IdentificationCertaintyViewControllerDelegate implementation", ^{
        describe(@"when the identification certainty view controller continues", ^{
            beforeEach(^{
                [controller identificationCertaintyViewControllerDidContinue:nil];
            });

            it(@"should show the Witness Confirmation view controller within the answer details container view", ^{
                controller.childViewControllers.firstObject should be_instance_of([WitnessConfirmationViewController class]);
                controller.embedContainerView.subviews should contain([controller.childViewControllers.firstObject view]);
            });
        });
    });

    describe(@"QualifyUncertaintyViewControllerDelegate implementation", ^{
        describe(@"when the qualify uncertainty view controller continues", ^{
            beforeEach(^{
                [controller qualifyUncertaintyViewControllerDidContinue:nil];
            });

            it(@"should show the Witness Confirmation view controller within the answer details container view", ^{
                controller.childViewControllers.firstObject should be_instance_of([WitnessConfirmationViewController class]);
                controller.embedContainerView.subviews should contain([controller.childViewControllers.firstObject view]);
            });
        });
    });

    describe(@"QualifyIdentificationViewControllerDelegate implementation", ^{
        describe(@"when the qualify identification view controller continues", ^{
            beforeEach(^{
                [controller qualifyIdentificationViewControllerDidContinue:nil];
            });

            it(@"should show Identification Certainty view controller within the answer details container view", ^{
                controller.childViewControllers.firstObject should be_instance_of([IdentificationCertaintyViewController class]);
                controller.embedContainerView.subviews should contain([controller.childViewControllers.firstObject view]);
            });
        });
    });

    describe(@"WitnessConfirmationViewControllerDelegate implementation", ^{
        describe(@"when the witness confirmation view controller continues", ^{
            beforeEach(^{
                [controller.responseSelector.noButton tap];
                controller.childViewControllers.count should equal(1);
            });

            context(@"when there is a next photo", ^{
                __block NSURL *nextPhotoURL;

                beforeEach(^{
                    nextPhotoURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"Brian" withExtension:@"jpg" subdirectory:@"SampleLineup"];
                    presentation stub_method(@selector(advanceToNextPhoto)).and_do_block(^BOOL{
                        currentPhotoURL = nextPhotoURL;
                        currentPhotoIndex = 1;
                        return YES;
                    });
                    [controller witnessConfirmationViewControllerDidContinue:nil];
                });

                itShouldBehaveLike(@"showing a prompt to speak view controller");

                it(@"should show the next photo", ^{
                    [controller.mugshotPhotoImageView.image isEqualToByBytes:[UIImage imageWithContentsOfFile:[nextPhotoURL path]]] should be_truthy;
                    controller.photoNumberLabel.text should equal(@"2");
                });

                it(@"should disable the witness response selector", ^{
                    controller.responseSelector.enabled should_not be_truthy;
                });

                it(@"should play the recognition audio prompt", ^{
                    audioPlayerService should have_received(@selector(playSoundNamed:)).with(@"recognition_prompt");
                });

                it(@"should clear the selected response", ^{
                    controller.responseSelector.selectedResponse should equal(WitnessResponseNone);
                });

                context(@"the recognition audio prompt has finished playing", ^{
                    beforeEach(^{
                        recognitionPromptDeferred.promise.fulfilled should_not be_truthy;
                        [recognitionPromptDeferred resolveWithValue:nil];
                    });

                    it(@"should enable the witness response selector", ^{
                        controller.responseSelector.enabled should be_truthy;
                    });
                });
            });

            context(@"when there is no next photo", ^{
                beforeEach(^{
                    presentation stub_method(@selector(advanceToNextPhoto)).and_return(NO);
                    [controller witnessConfirmationViewControllerDidContinue:nil];
                });

                it(@"should show the completion screen", ^{
                    navController.topViewController.view should_not be_nil;
                    navController.topViewController should be_instance_of([PresentationCompleteViewController class]);
                });

                it(@"should clear the mugshot image view", ^{
                    controller.mugshotPhotoImageView.image should be_nil;
                });

                describe(@"when unwinding to Photo ID view controller for replaying presentation", ^{
                    beforeEach(^{
                        [controller unwindToPhotoIDViewController:nil];
                    });

                    it(@"should tell the presentation to rollback to the first photo", ^{
                        presentation should have_received(@selector(rollBackToFirstPhoto));
                    });

                    it(@"should clear the selected response", ^{
                        controller.responseSelector.selectedResponse should equal(WitnessResponseNone);
                    });
                });
            });
        });
    });

    describe(@"when preparing to segue into a prompt to speak view controller", ^{
        __block PromptToSpeakViewController *promptToSpeakViewController;
        beforeEach(^{
            promptToSpeakViewController = nice_fake_for([PromptToSpeakViewController class]);
            UIStoryboardSegue *segue = [[UIStoryboardSegue alloc] initWithIdentifier:@"embedDenialConfirmation"
                                                                              source:controller
                                                                         destination:promptToSpeakViewController];
            [controller prepareForSegue:segue sender:nil];
        });

        it(@"should configure the controller", ^{
            promptToSpeakViewController should have_received(@selector(configureWithAudioLevelMeter:)).with(audioLevelMeter);
        });
    });

    describe(@"when preparing to segue into a confirmation view controller", ^{
        __block WitnessConfirmationViewController *confirmationViewController;

        beforeEach(^{
            confirmationViewController = nice_fake_for([WitnessConfirmationViewController class]);
        });

        context(@"for a denial", ^{
            beforeEach(^{
                UIStoryboardSegue *segue = [[UIStoryboardSegue alloc] initWithIdentifier:@"embedDenialConfirmation"
                                                                                  source:controller
                                                                             destination:confirmationViewController];
                [controller prepareForSegue:segue sender:nil];
            });

            it(@"should configure the confirmation view controller for denial", ^{
                confirmationViewController should have_received(@selector(configureForDenialWithDelegate:audioLevelMeter:audioPlayerService:)).with(controller, audioLevelMeter, Arguments::any([AudioPlayerService class]));
            });
        });

        context(@"for a certainty", ^{
            beforeEach(^{
                UIStoryboardSegue *segue = [[UIStoryboardSegue alloc] initWithIdentifier:@"embedCertaintyConfirmation"
                                                                                  source:controller
                                                                             destination:confirmationViewController];
                [controller prepareForSegue:segue sender:nil];
            });

            it(@"should configure the confirmation view controller for certainty", ^{
                confirmationViewController should have_received(@selector(configureForCertaintyWithDelegate:audioLevelMeter:audioPlayerService:)).with(controller, audioLevelMeter, Arguments::any([AudioPlayerService class]));
            });
        });

        context(@"for an uncertainty", ^{
            beforeEach(^{
                UIStoryboardSegue *segue = [[UIStoryboardSegue alloc] initWithIdentifier:@"embedUncertaintyConfirmation"
                                                                                  source:controller
                                                                             destination:confirmationViewController];
                [controller prepareForSegue:segue sender:nil];
            });

            it(@"should configure the confirmation view controller for uncertainty", ^{
                confirmationViewController should have_received(@selector(configureForUncertaintyWithDelegate:audioLevelMeter:audioPlayerService:)).with(controller, audioLevelMeter, Arguments::any([AudioPlayerService class]));
            });
        });
    });

    describe(@"when preparing to segue into the quality identification view controller", ^{
        __block QualifyIdentificationViewController *qualifyIdentificationViewController;

        beforeEach(^{
            qualifyIdentificationViewController = nice_fake_for([QualifyIdentificationViewController class]);
            UIStoryboardSegue *segue = [[UIStoryboardSegue alloc] initWithIdentifier:@"embedIdentificationQualification"
                                                                              source:controller
                                                                         destination:qualifyIdentificationViewController];
            [controller prepareForSegue:segue sender:nil];
        });

        it(@"should configure the view controller with a delegate, audio level meter and audio player service", ^{
            qualifyIdentificationViewController should have_received(@selector(configureWithDelegate:audioLevelMeter:audioPlayerService:)).with(controller, audioLevelMeter, Arguments::any([AudioPlayerService class]));
        });
    });

    describe(@"when preparing to segue into the identification certainty view controller", ^{
        __block IdentificationCertaintyViewController *identificationCertaintyViewController;

        beforeEach(^{
            identificationCertaintyViewController = nice_fake_for([IdentificationCertaintyViewController class]);
            UIStoryboardSegue *segue = [[UIStoryboardSegue alloc] initWithIdentifier:@"embedIdentificationCertainty"
                                                                              source:controller
                                                                         destination:identificationCertaintyViewController];
            [controller prepareForSegue:segue sender:nil];
        });

        it(@"should configure the view controller with a delegate and audio level meter", ^{
            identificationCertaintyViewController should have_received(@selector(configureWithDelegate:audioLevelMeter:audioPlayerService:)).with(controller, audioLevelMeter, Arguments::any([AudioPlayerService class]));
        });
    });

    describe(@"when preparing to segue into the qualify uncertainty view controller", ^{
        __block QualifyUncertaintyViewController *qualifyUncertaintyViewController;

        beforeEach(^{
            qualifyUncertaintyViewController = nice_fake_for([QualifyUncertaintyViewController class]);
            UIStoryboardSegue *segue = [[UIStoryboardSegue alloc] initWithIdentifier:@"embedQualifyUncertainty"
                                                                              source:controller
                                                                         destination:qualifyUncertaintyViewController];
            [controller prepareForSegue:segue sender:nil];
        });

        it(@"should configure the view controller with a delegate and audio level meter", ^{
            qualifyUncertaintyViewController should have_received(@selector(configureWithDelegate:audioLevelMeter:audioPlayerService:)).with(controller, audioLevelMeter, Arguments::any([AudioPlayerService class]));
        });
    });
});

SPEC_END
