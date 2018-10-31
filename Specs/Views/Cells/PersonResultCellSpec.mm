#import "PersonResultCell.h"
#import "SuspectCardView.h"
#import "Person.h"
#import "FaceLoader.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(PersonResultCellSpec)

describe(@"PersonResultCell", ^{
    __block PersonResultCell *cell;
    __block SuspectCardView *suspectCardView;

    beforeEach(^{
        cell = [[PersonResultCell alloc] init];
        suspectCardView = cell.suspectCardView;
        spy_on(suspectCardView);
    });

    describe(@"configureWithPerson:faceLoader:", ^{
        __block Person *person;
        __block FaceLoader *faceLoader;

        beforeEach(^{
            faceLoader = nice_fake_for([FaceLoader class]);
            person = [[Person alloc] initWithFirstName:@"Leon" lastName:@"Lewis" dateOfBirth:[NSDate dateWithTimeIntervalSince1970:1397059265] systemID:@"12345" portrayals:@[]];
            [cell configureWithPerson:person faceLoader:faceLoader];
        });

        it(@"should delegate to the portrayal view", ^{
            suspectCardView should have_received(@selector(configureWithPerson:faceLoader:)).with(person, faceLoader);
        });
    });
});

SPEC_END
