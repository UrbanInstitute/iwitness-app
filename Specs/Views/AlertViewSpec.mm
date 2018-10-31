#import "AlertView.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(AlertViewSpec)

describe(@"AlertView", ^{
    __block AlertView *alertView;
    __block BOOL cancelled;
    __block BOOL button1Pressed;
    __block BOOL button2Pressed;

    beforeEach(^{
        cancelled = NO;
        button1Pressed = NO;
        button2Pressed = NO;

        alertView = [[AlertView alloc] initWithTitle:@"Title"
                                             message:@"message"
                                   cancelButtonTitle:@"Cancel"
                                   otherButtonTitles:@[@"button1", @"button2"]
                                       cancelHandler:^{
                                           cancelled = YES;
                                       }
                                 confirmationHandler:^(NSInteger otherButtonIndex){
                                     switch (otherButtonIndex) {
                                         case 0: button1Pressed = YES;
                                             break;
                                         case 1: button2Pressed = YES;
                                             break;
                                        default:
                                             break;
                                     }
                                 }];
    });

    it(@"should create the alert view", ^{
        alertView.title should equal(@"Title");
        alertView.message should equal(@"message");
        [alertView buttonTitleAtIndex:alertView.cancelButtonIndex] should equal(@"Cancel");
        [alertView buttonTitleAtIndex:1] should equal(@"button1");
        [alertView buttonTitleAtIndex:2] should equal(@"button2");
        alertView.delegate should be_same_instance_as(alertView);
    });

    sharedExamplesFor(@"releasing the completion handlers", ^(NSDictionary *sharedContext) {
        beforeEach(^{
            cancelled = NO;
            button1Pressed = NO;
        });

        it(@"should release the cancel handler", ^{
            [alertView dismissWithClickedButtonIndex:alertView.cancelButtonIndex animated:NO];
            cancelled should_not be_truthy;
        });

        it(@"should release the confirmationHandler", ^{
            [alertView dismissWithClickedButtonIndex:1 animated:NO];
            button1Pressed should_not be_truthy;
        });
    });

    describe(@"pressing buttons", ^{
        context(@"cancel button", ^{
            beforeEach(^{
                [alertView dismissWithClickedButtonIndex:alertView.cancelButtonIndex animated:NO];
            });

            it(@"should call the cancel handler", ^{
                cancelled should be_truthy;
            });

            itShouldBehaveLike(@"releasing the completion handlers");
        });

        context(@"button1", ^{
            beforeEach(^{
                [alertView dismissWithClickedButtonIndex:1 animated:NO];
            });

            it(@"should call the confirmation handler with button 1", ^{
                button1Pressed should be_truthy;
                button2Pressed should_not be_truthy;
            });

            itShouldBehaveLike(@"releasing the completion handlers");
        });

        context(@"button2", ^{
            beforeEach(^{
                [alertView dismissWithClickedButtonIndex:2 animated:NO];
            });

            it(@"should call the confirmation handler with button 2", ^{
                button2Pressed should be_truthy;
                button1Pressed should_not be_truthy;
            });

            itShouldBehaveLike(@"releasing the completion handlers");
        });
    });
});

SPEC_END
