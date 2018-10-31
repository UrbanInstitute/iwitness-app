#import "PresentationCompleteViewController.h"
#import "PresentationCompleteViewControllerDelegate.h"
#import "PasswordValidator.h"
#import "AudioPlayerService.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(PresentationCompleteViewControllerSpec)

describe(@"PresentationCompleteViewController", ^{
    __block PresentationCompleteViewController *controller;
    __block id<PresentationCompleteViewControllerDelegate> delegate;
    __block PasswordValidator *passwordValidator;
    __block AudioPlayerService *audioPlayerService;

    beforeEach(^{
        delegate = nice_fake_for(@protocol(PresentationCompleteViewControllerDelegate));
        audioPlayerService = nice_fake_for([AudioPlayerService class]);

        passwordValidator = nice_fake_for([PasswordValidator class]);
        controller = [[UIStoryboard storyboardWithName:@"PresentationFlow" bundle:nil] instantiateViewControllerWithIdentifier:@"PresentationCompleteViewController"];
        [controller configureWithPasswordValidator:passwordValidator delegate:delegate audioPlayerService:audioPlayerService];
        controller.view should_not be_nil;
        [controller viewWillAppear:NO];
        [controller viewDidAppear:NO];
    });

    it(@"should not show the password incorrect label", ^{
        controller.passwordIncorrectLabel.hidden should be_truthy;
    });

    it(@"should play the audio prompt", ^{
        audioPlayerService should have_received(@selector(playSoundNamed:)).with(@"presentation_complete");
    });

    describe(@"string localization", ^{
        context(@"English", ^{
            beforeEach(^{
                [WitnessLocalization setWitnessLanguageCode:@"en"];
                [controller viewWillAppear:NO];
            });

            it(@"should localize the strings for English", ^{
                controller.presentationCompleteLabel.text should equal(@"Presentation Complete.");
                controller.returnDeviceLabel.text should equal(@"Please return this device to the Officer.");
            });
        });

        context(@"Spanish", ^{
            beforeEach(^{
                [WitnessLocalization setWitnessLanguageCode:@"es"];
                [controller viewWillAppear:NO];
            });

            it(@"should localize the strings for Spanish", ^{
                controller.presentationCompleteLabel.text should equal(@"Presentación Completa.");
                controller.returnDeviceLabel.text should equal(@"Por favor devuelva este dispositivo al Oficial.");
            });
        });
    });

    describe(@"when not configured with a delegate", ^{
        beforeEach(^{
            controller = [[UIStoryboard storyboardWithName:@"PresentationFlow" bundle:nil] instantiateViewControllerWithIdentifier:@"PresentationCompleteViewController"];
            controller.view should_not be_nil;
            [controller viewWillAppear:NO];
        });

        it(@"should throw an exception after the view appears", ^{
            ^{ [controller viewDidAppear:NO]; } should raise_exception;
        });
    });

    context(@"when the officer enters the wrong password", ^{
        sharedExamplesFor(@"indicating that the password is invalid", ^(NSDictionary *) {
            it(@"should show the password incorrect label", ^{
                controller.passwordIncorrectLabel.hidden should be_falsy;
            });

            it(@"should not show the presentation completion options", ^{
                controller.replayButton.hidden should be_truthy;
                controller.finishButton.hidden should be_truthy;
            });
        });

        beforeEach(^{
            passwordValidator stub_method(@selector(isValidPassword:)).and_return(NO);
        });

        describe(@"tapping the 'Proceed' button", ^{
            beforeEach(^{
                [controller.proceedButton tap];
            });

            itShouldBehaveLike(@"indicating that the password is invalid");
        });

        describe(@"tapping the Return key on the keyboard", ^{
            beforeEach(^{
                [controller textFieldShouldReturn:nil];
            });

            itShouldBehaveLike(@"indicating that the password is invalid");
        });
    });

    context(@"when the officer enters the correct password", ^{
        sharedExamplesFor(@"showing the presentation completion options", ^(NSDictionary *) {
            it(@"should show options for replaying or finishing the presentation", ^{
                controller.replayButton.hidden should be_falsy;
                controller.finishButton.hidden should be_falsy;
            });

            it(@"should disable the officer password validation controls", ^{
                controller.officerPasswordTextField.enabled should be_falsy;
                controller.proceedButton.enabled should be_falsy;
            });

            describe(@"tapping the 'Finish' button", ^{
                beforeEach(^{
                    [controller.finishButton tap];
                });

                it(@"should finish the presentation", ^{
                    delegate should have_received(@selector(presentationCompleteViewControllerDidFinish:)).with(controller);
                });
            });

            describe(@"tapping the 'Replay' button", ^{
                beforeEach(^{
                    spy_on(controller);
                    [controller.replayButton tap];
                });

                it(@"should restart the presentation", ^{
                    controller should have_received(@selector(performSegueWithIdentifier:sender:)).with(@"UnwindForReplayPresentation", controller.replayButton);
                });
            });
        });

        beforeEach(^{
            passwordValidator stub_method(@selector(isValidPassword:)).and_return(YES);
        });

        describe(@"tapping the 'Proceed' button", ^{
            beforeEach(^{
                [controller.proceedButton tap];
            });

            itShouldBehaveLike(@"showing the presentation completion options");
        });

        describe(@"tapping the Return key on the keyboard", ^{
            beforeEach(^{
                [controller textFieldShouldReturn:nil];
            });

            itShouldBehaveLike(@"showing the presentation completion options");
        });
    });
});

SPEC_END
