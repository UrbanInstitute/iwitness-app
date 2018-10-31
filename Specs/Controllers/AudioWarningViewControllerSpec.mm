#import "AudioWarningViewController.h"
#import "PreparationViewController.h"
#import "CedarAsync.h"
#import "LineupsViewController.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(AudioWarningViewControllerSpec)

describe(@"AudioWarningViewController", ^{
    __block AudioWarningViewController *controller;
    __block LineupsViewController *lineupsViewController;
    __block UINavigationController *navController;
    __block AVAudioSession *audioSession;
    __block float currentOutputVolume;

    beforeEach(^{
        currentOutputVolume = -1.f;
        audioSession = nice_fake_for([AVAudioSession class]);

        audioSession stub_method(@selector(outputVolume)).and_do_block(^float{
            return currentOutputVolume;
        });

        controller = [[UIStoryboard storyboardWithName:@"PresentationFlow" bundle:nil] instantiateViewControllerWithIdentifier:@"AudioWarningViewController"];
    });

    void(^displayControllerInHierarchy)() = ^{
        lineupsViewController = [[UIStoryboard storyboardWithName:@"AdminFlow" bundle:nil] instantiateViewControllerWithIdentifier:@"LineupsViewController"];

        navController = [[UINavigationController alloc] initWithRootViewController:lineupsViewController];

        [UIApplication showViewController:navController];
        spy_on(lineupsViewController);
        [navController pushViewController:controller animated:NO];
    };

    context(@"when the audio session cannot be activated", ^{
        beforeEach(^{
            audioSession stub_method(@selector(setActive:withOptions:error:)).with(YES, 0, Arguments::anything).and_return(NO);
            [controller configureWithAudioSession:audioSession];
            displayControllerInHierarchy();
            in_time(navController.view) should contain(controller.view).nested();
        });

        it(@"should show an alert", ^{
            [UIAlertView currentAlertView] should_not be_nil;
        });

        describe(@"when the alert is dismissed", ^{
            beforeEach(^{
                [[UIAlertView currentAlertView] dismissWithCancelButton];
            });

            it(@"should immediately push the preparation view controller", ^{
                navController.topViewController should be_instance_of([PreparationViewController class]);
            });
        });
    });

    context(@"when the audio session can be activated", ^{
        beforeEach(^{
            audioSession stub_method(@selector(setActive:withOptions:error:)).with(YES, 0, Arguments::anything).and_return(YES);
            [controller configureWithAudioSession:audioSession];
        });

        context(@"when audio levels are acceptable", ^{
            beforeEach(^{
                currentOutputVolume = 0.5f;
                displayControllerInHierarchy();
            });

            it(@"should immediately push the preparation view controller", ^{
                in_time(navController.topViewController) should be_instance_of([PreparationViewController class]);
            });
        });

        context(@"when audio levels are not acceptable", ^{
            beforeEach(^{
                currentOutputVolume = 0.4f;
                displayControllerInHierarchy();
                in_time(navController.view) should contain(controller.view).nested();
            });

            sharedExamplesFor(@"tapping the cancel button", ^(NSDictionary *dictionary) {
                beforeEach(^{
                    [controller.cancelButton tap];
                });

                it(@"should perform an unwind segue signifying presentation cancelation", ^{
                    navController.topViewController should be_same_instance_as(lineupsViewController);
                    lineupsViewController should have_received(@selector(presentationCanceled:));
                });
            });

            itShouldBehaveLike(@"tapping the cancel button");

            it(@"should not have pushed another view controller", ^{
                navController.topViewController should be_same_instance_as(controller);
            });

            it(@"should disable the next button", ^{
                controller.continueButton.enabled should be_falsy;
            });

            describe(@"when the audio levels become acceptable", ^{
                beforeEach(^{
                    [audioSession willChangeValueForKey:@"outputVolume"];
                    currentOutputVolume = 0.6f;
                    [audioSession didChangeValueForKey:@"outputVolume"];
                });

                itShouldBehaveLike(@"tapping the cancel button");

                it(@"should enable the next button", ^{
                    controller.continueButton.enabled should be_truthy;
                });

                describe(@"when the next button is tapped", ^{
                    beforeEach(^{
                        [controller.continueButton tap];
                    });

                    it(@"should present the preparation view controller", ^{
                        navController.topViewController should be_instance_of([PreparationViewController class]);
                    });
                });

                describe(@"when the audio levels become unacceptable", ^{
                    beforeEach(^{
                        [audioSession willChangeValueForKey:@"outputVolume"];
                        currentOutputVolume = 0.4f;
                        [audioSession didChangeValueForKey:@"outputVolume"];
                    });

                    itShouldBehaveLike(@"tapping the cancel button");

                    it(@"should disable the next button", ^{
                        controller.continueButton.enabled should be_falsy;
                    });
                });
            });
        });
    });
});

SPEC_END
