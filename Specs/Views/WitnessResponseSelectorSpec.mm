#import "WitnessResponseSelector.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

@protocol WitnessResponseSelectorActionReceiver
- (void)receiveAction:(id)sender;
@end

SPEC_BEGIN(WitnessResponseSelectorSpec)

describe(@"WitnessResponseSelector", ^{
    __block WitnessResponseSelector *responseSelector;
    __block id<WitnessResponseSelectorActionReceiver> actionReceiver;

    beforeEach(^{
        actionReceiver = nice_fake_for(@protocol(WitnessResponseSelectorActionReceiver));
        responseSelector = [[WitnessResponseSelector alloc] init];
        [responseSelector addTarget:actionReceiver action:@selector(receiveAction:) forControlEvents:UIControlEventValueChanged];
    });

    describe(@"button labels", ^{
        it(@"should have correct titles on the buttons", ^{
            responseSelector.yesButton.titleLabel.text should equal(@"YES");
            responseSelector.noButton.titleLabel.text should equal(@"NO");
            responseSelector.notSureButton.titleLabel.text should equal(@"NOT SURE");
        });

        it(@"should have the correct titles on buttons when localized", ^{
            [WitnessLocalization setWitnessLanguageCode:@"es"];
            responseSelector = [[WitnessResponseSelector alloc] init];


            responseSelector.yesButton.titleLabel.text should equal(@"SÍ");
            responseSelector.noButton.titleLabel.text should equal(@"NO");
            responseSelector.notSureButton.titleLabel.text should equal(@"NO ESTOY SEGURO");
        });
    });

    sharedExamplesFor(@"handling a response selection", ^(NSDictionary *sharedContext) {
        __block WitnessResponse expectedSelectedResponse;
        __block UIButton *tappedButton;
        beforeEach(^{
            tappedButton = sharedContext[@"tappedButton"];
            expectedSelectedResponse = (WitnessResponse)[sharedContext[@"expectedSelectedResponse"] integerValue];
        });

        it(@"should select only the tapped button", ^{
            tappedButton.selected should be_truthy;
            if (tappedButton != responseSelector.yesButton) {
                responseSelector.yesButton.selected should be_falsy;
            }
            if (tappedButton != responseSelector.noButton) {
                responseSelector.noButton.selected should be_falsy;
            }
            if (responseSelector.notSureButton && tappedButton != responseSelector.notSureButton) {
                responseSelector.notSureButton.selected should be_falsy;
            }
        });

        it(@"should change the selected response", ^{
            responseSelector.selectedResponse should equal(expectedSelectedResponse);
        });

        it(@"should trigger the value changed action event", ^{
            actionReceiver should have_received(@selector(receiveAction:)).with(responseSelector);
        });

        describe(@"tapping the same button again", ^{
            beforeEach(^{
                [(id<CedarDouble>)actionReceiver reset_sent_messages];
                [tappedButton tap];
            });

            it(@"should not trigger the value changed action event", ^{
                actionReceiver should_not have_received(@selector(receiveAction:)).with(responseSelector);
            });
        });

        describe(@"resetting the control", ^{
            beforeEach(^{
                [(id<CedarDouble>)actionReceiver reset_sent_messages];
                [responseSelector reset];
            });

            it(@"should deselect all buttons", ^{
                responseSelector.noButton.selected should be_falsy;
                responseSelector.yesButton.selected should be_falsy;
                responseSelector.notSureButton.selected should be_falsy;
            });

            it(@"should reset the selected response", ^{
                responseSelector.selectedResponse should equal(WitnessResponseNone);
            });

            it(@"should not trigger the value changed action event", ^{
                actionReceiver should_not have_received(@selector(receiveAction:)).with(responseSelector);
            });
        });
    });

    context(@"when configured to allow responding 'Not Sure' (default)", ^{
        beforeEach(^{
            responseSelector.allowNotSureResponse should be_truthy;
        });

        context(@"when disabled", ^{
            beforeEach(^{
                responseSelector.enabled = NO;
            });

            it(@"should have all its buttons disabled", ^{
                responseSelector.yesButton.enabled should be_falsy;
                responseSelector.noButton.enabled should be_falsy;
                responseSelector.notSureButton.enabled should be_falsy;
            });
        });

        context(@"when enabled", ^{
            beforeEach(^{
                responseSelector.enabled should be_truthy;
            });

            it(@"should have all its buttons enabled", ^{
                responseSelector.yesButton.enabled should be_truthy;
                responseSelector.noButton.enabled should be_truthy;
                responseSelector.notSureButton.enabled should be_truthy;
            });

            it(@"should not have any response selected", ^{
                responseSelector.selectedResponse should equal(WitnessResponseNone);
            });

            it(@"should not have any of the button selected", ^{
                responseSelector.yesButton.selected should be_falsy;
                responseSelector.noButton.selected should be_falsy;
                responseSelector.notSureButton.selected should be_falsy;
            });

            describe(@"tapping the YES button", ^{
                beforeEach(^{
                    SpecHelper.specHelper.sharedExampleContext[@"tappedButton"] = responseSelector.yesButton;
                    SpecHelper.specHelper.sharedExampleContext[@"expectedSelectedResponse"] = @(WitnessResponseYes);
                    [SpecHelper.specHelper.sharedExampleContext[@"tappedButton"] tap];
                });

                itShouldBehaveLike(@"handling a response selection");

                describe(@"tapping the NO button", ^{
                    beforeEach(^{
                        SpecHelper.specHelper.sharedExampleContext[@"tappedButton"] = responseSelector.noButton;
                        SpecHelper.specHelper.sharedExampleContext[@"expectedSelectedResponse"] = @(WitnessResponseNo);
                        [SpecHelper.specHelper.sharedExampleContext[@"tappedButton"] tap];
                    });

                    itShouldBehaveLike(@"handling a response selection");

                    describe(@"tapping the NOT SURE button", ^{
                        beforeEach(^{
                            SpecHelper.specHelper.sharedExampleContext[@"tappedButton"] = responseSelector.notSureButton;
                            SpecHelper.specHelper.sharedExampleContext[@"expectedSelectedResponse"] = @(WitnessResponseNotSure);
                            [SpecHelper.specHelper.sharedExampleContext[@"tappedButton"] tap];
                        });

                        itShouldBehaveLike(@"handling a response selection");
                    });

                    describe(@"tapping the YES button", ^{
                        beforeEach(^{
                            SpecHelper.specHelper.sharedExampleContext[@"tappedButton"] = responseSelector.yesButton;
                            SpecHelper.specHelper.sharedExampleContext[@"expectedSelectedResponse"] = @(WitnessResponseYes);
                            [SpecHelper.specHelper.sharedExampleContext[@"tappedButton"] tap];
                        });

                        itShouldBehaveLike(@"handling a response selection");
                    });
                });

                describe(@"tapping the NOT SURE button", ^{
                    beforeEach(^{
                        SpecHelper.specHelper.sharedExampleContext[@"tappedButton"] = responseSelector.notSureButton;
                        SpecHelper.specHelper.sharedExampleContext[@"expectedSelectedResponse"] = @(WitnessResponseNotSure);
                        [SpecHelper.specHelper.sharedExampleContext[@"tappedButton"] tap];
                    });

                    itShouldBehaveLike(@"handling a response selection");

                    describe(@"tapping the NO button", ^{
                        beforeEach(^{
                            SpecHelper.specHelper.sharedExampleContext[@"tappedButton"] = responseSelector.noButton;
                            SpecHelper.specHelper.sharedExampleContext[@"expectedSelectedResponse"] = @(WitnessResponseNo);
                            [SpecHelper.specHelper.sharedExampleContext[@"tappedButton"] tap];
                        });

                        itShouldBehaveLike(@"handling a response selection");
                    });

                    describe(@"tapping the YES button", ^{
                        beforeEach(^{
                            SpecHelper.specHelper.sharedExampleContext[@"tappedButton"] = responseSelector.yesButton;
                            SpecHelper.specHelper.sharedExampleContext[@"expectedSelectedResponse"] = @(WitnessResponseYes);
                            [SpecHelper.specHelper.sharedExampleContext[@"tappedButton"] tap];
                        });

                        itShouldBehaveLike(@"handling a response selection");
                    });
                });
            });
        });

    });

    context(@"when configured to not allow responding 'Not Sure'", ^{
        beforeEach(^{
            responseSelector.allowNotSureResponse = NO;
        });

        it(@"should not display the 'Not Sure' button", ^{
            responseSelector.subviews should_not contain(responseSelector.notSureButton).nested();
        });

        describe(@"when reconfigured to allow responding 'Not Sure'", ^{
            beforeEach(^{
                responseSelector.allowNotSureResponse = YES;
            });

            it(@"should display the 'Not Sure' button", ^{
                responseSelector.subviews should contain(responseSelector.notSureButton).nested();
            });
        });

        context(@"when disabled", ^{
            beforeEach(^{
                responseSelector.enabled = NO;
            });

            it(@"should have all its buttons disabled", ^{
                responseSelector.yesButton.enabled should be_falsy;
                responseSelector.noButton.enabled should be_falsy;
            });
        });

        context(@"when enabled", ^{
            beforeEach(^{
                responseSelector.enabled should be_truthy;
            });

            it(@"should have all its buttons enabled", ^{
                responseSelector.yesButton.enabled should be_truthy;
                responseSelector.noButton.enabled should be_truthy;
            });

            it(@"should not have any response selected", ^{
                responseSelector.selectedResponse should equal(WitnessResponseNone);
            });

            it(@"should not have any of the button selected", ^{
                responseSelector.yesButton.selected should be_falsy;
                responseSelector.noButton.selected should be_falsy;
            });

            describe(@"tapping the YES button", ^{
                beforeEach(^{
                    SpecHelper.specHelper.sharedExampleContext[@"tappedButton"] = responseSelector.yesButton;
                    SpecHelper.specHelper.sharedExampleContext[@"expectedSelectedResponse"] = @(WitnessResponseYes);
                    [SpecHelper.specHelper.sharedExampleContext[@"tappedButton"] tap];
                });

                itShouldBehaveLike(@"handling a response selection");

                describe(@"tapping the NO button", ^{
                    beforeEach(^{
                        SpecHelper.specHelper.sharedExampleContext[@"tappedButton"] = responseSelector.noButton;
                        SpecHelper.specHelper.sharedExampleContext[@"expectedSelectedResponse"] = @(WitnessResponseNo);
                        [SpecHelper.specHelper.sharedExampleContext[@"tappedButton"] tap];
                    });

                    itShouldBehaveLike(@"handling a response selection");

                    describe(@"tapping the YES button", ^{
                        beforeEach(^{
                            SpecHelper.specHelper.sharedExampleContext[@"tappedButton"] = responseSelector.yesButton;
                            SpecHelper.specHelper.sharedExampleContext[@"expectedSelectedResponse"] = @(WitnessResponseYes);
                            [SpecHelper.specHelper.sharedExampleContext[@"tappedButton"] tap];
                        });

                        itShouldBehaveLike(@"handling a response selection");
                    });
                });
            });
        });
    });
});

SPEC_END
