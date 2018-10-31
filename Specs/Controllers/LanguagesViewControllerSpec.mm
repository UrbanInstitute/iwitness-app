#import "LanguagesViewController.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(LanguagesViewControllerSpec)

describe(@"LanguagesViewController", ^{
    __block LanguagesViewController *controller;
    __block id<LanguagesViewControllerDelegate> delegate;

    beforeEach(^{
        delegate = nice_fake_for(@protocol(LanguagesViewControllerDelegate));
        controller = [[LanguagesViewController alloc] initWithDelegate:delegate];

        controller.view should_not be_nil;
        [controller viewWillAppear:NO];
        [controller viewDidAppear:NO];
    });

    it(@"should list the languages available", ^{
        [controller.tableView valueForKeyPath:@"visibleCells.textLabel.text"] should contain(@"español - Spanish");
        [controller.tableView valueForKeyPath:@"visibleCells.textLabel.text"] should contain(@"English");
    });

    it(@"should report its preferred content size to fit the languages to be displayed", ^{
        NSInteger numLanguages = 2;
        controller.preferredContentSize should equal(CGSizeMake(300, numLanguages*44));
    });

    describe(@"tapping on a language", ^{
        beforeEach(^{
            [controller.tableView.visibleCells[1] tap];
        });

        it(@"should inform its delegate of the selected language", ^{
            delegate should have_received(@selector(languagesViewController:didSelectLanguageWithCode:)).with(controller, @"es");
        });

        it(@"should set the user default", ^{
            [WitnessLocalization witnessLanguageCode] should equal(@"es");
        });
    });
});

SPEC_END
