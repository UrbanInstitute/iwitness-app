#import "AdditionalNotesViewController.h"
#import "PerpetratorDescription.h"
#import "CedarAsync.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(AdditionalNotesViewControllerSpec)

describe(@"AdditionalNotesViewController", ^{
    __block AdditionalNotesViewController *controller;
    __block PerpetratorDescription *perpetratorDescription;

    void(^configureAndPresentController)() = ^{
        [controller configureWithCaseID:@"98548234" perpetratorDescription:perpetratorDescription];
        [UIApplication showViewController:controller];
    };

    void(^editAdditionalNotes)(NSString *) = ^(NSString *newText) {
        UITextView *textView = controller.additionalNotesTextView;
        if ([textView.delegate textView:textView shouldChangeTextInRange:NSMakeRange(0, textView.text.length) replacementText:newText]) {
            textView.text = newText;
        }
    };

    beforeEach(^{
        perpetratorDescription = [[PerpetratorDescription alloc] init];
        perpetratorDescription.additionalNotes = @"His hair was purple";
        controller = [[UIStoryboard storyboardWithName:@"WitnessDescription" bundle:nil] instantiateViewControllerWithIdentifier:@"AdditionalNotesViewController"];
        configureAndPresentController();
    });

    it(@"should set the content inset of the additional notes textView and its scrollviews to the height of the keyboard", ^{
        in_time(controller.additionalNotesTextView.contentInset.bottom) should be_greater_than(0);
        controller.additionalNotesTextView.scrollIndicatorInsets.bottom should be_greater_than(0);
    });

    it(@"should display the case ID", ^{
        controller.caseIDLabel.text should equal(@"98548234");
    });

    it(@"should focus on the additional notes text view", ^{
        in_time([controller.additionalNotesTextView isFirstResponder]) should be_truthy;
    });

    it(@"should set the additional notes text view from the perpetrator description", ^{
        controller.additionalNotesTextView.text should equal(perpetratorDescription.additionalNotes);
    });

    describe(@"when the additional notes text view is changed", ^{
        beforeEach(^{
            editAdditionalNotes(@"His hair was actually red");
        });

        it(@"should update the model", ^{
            perpetratorDescription.additionalNotes should equal(@"His hair was actually red");
        });
    });

    describe(@"when the keyboard is about hide", ^{
        beforeEach(^{
            in_time(controller.additionalNotesTextView.contentInset.bottom) should be_greater_than(0);
            [[NSNotificationCenter defaultCenter] postNotificationName:UIKeyboardWillHideNotification object:nil userInfo:@{}];
        });

        it(@"should reset the content inset of the additional notes textView and its scrollviews", ^{
            controller.additionalNotesTextView.scrollIndicatorInsets should equal(UIEdgeInsetsZero);
            controller.additionalNotesTextView.contentInset should equal(UIEdgeInsetsZero);
        });
    });
});

SPEC_END
