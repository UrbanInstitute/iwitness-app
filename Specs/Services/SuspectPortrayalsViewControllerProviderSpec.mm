#import "SuspectPortrayalsViewControllerProvider.h"
#import "PersonFactory.h"
#import "Person.h"
#import "SuspectPortrayalsViewController.h"
#import "SuspectCardView.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(SuspectPortrayalsViewControllerProviderSpec)

describe(@"SuspectPortrayalsViewControllerProvider", ^{
    __block SuspectPortrayalsViewControllerProvider *provider;
    __block SuspectPortrayalsViewController *suspectPortrayalsVC;
    __block Person *person;

    beforeEach(^{
        provider = [[SuspectPortrayalsViewControllerProvider alloc] init];
        person = [PersonFactory leon];
        suspectPortrayalsVC = [provider suspectPortrayalsViewControllerWithPerson:person];
        [UIApplication showViewController:suspectPortrayalsVC];
    });

    it(@"should provide a suspect portrayals view controller configured with the person", ^{
        suspectPortrayalsVC.view.suspectCardView.nameLabel.text should equal(person.fullName);
    });
});

SPEC_END
