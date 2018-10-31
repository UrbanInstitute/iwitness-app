#import "PersonSearchService.h"
#import "Person.h"
#import "PersonsLoader.h"
#import "Portrayal.h"
#import "PersonFactory.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(PersonSearchServiceSpec)

describe(@"PersonSearchService", ^{
    __block PersonSearchService *service;
    __block PersonsLoader *loader;
    __block KSPromise *promise;
    __block Person *leon, *larry;

    beforeEach(^{
        loader = nice_fake_for([PersonsLoader class]);

        leon = [PersonFactory leon];
        larry = [PersonFactory larry];

        loader stub_method(@selector(loadPersons)).and_return(@[leon, larry]);
        service = [[PersonSearchService alloc] initWithPersonsLoader:loader];
    });

    describe(@"searching for persons", ^{
        context(@"with an exact name search", ^{
            beforeEach(^{
                promise = [service personResultsForFirstName:@"Leon" lastName:@"Lewis" suspectID:@""];
            });

            it(@"should attach a person to the promise", ^{
                promise.fulfilled should be_truthy;
                promise.value should contain(leon);
            });
        });

        context(@"with a case insensitive search", ^{
            beforeEach(^{
                promise = [service personResultsForFirstName:@"leon" lastName:@"lewis" suspectID:@""];
            });

            it(@"should attach a person to the promise", ^{
                promise.fulfilled should be_truthy;
                promise.value should contain(leon);
            });
        });

        context(@"with a partial first name search", ^{
            beforeEach(^{
                promise = [service personResultsForFirstName:@"Leo" lastName:@"" suspectID:@""];
            });

            it(@"should attach a person to the promise", ^{
                promise.fulfilled should be_truthy;
                promise.value should contain(leon);
            });
        });

        context(@"with a partial last name search", ^{
            beforeEach(^{
                promise = [service personResultsForFirstName:@"" lastName:@"Lew" suspectID:@""];
            });

            it(@"should attach a person to the promise", ^{
                promise.fulfilled should be_truthy;
                promise.value should contain(leon);
            });
        });

        context(@"with an unknown name", ^{
            beforeEach(^{
                promise = [service personResultsForFirstName:@"John" lastName:@"Smith" suspectID:@""];
            });

            it(@"should attach an empty array to the promise", ^{
                promise.fulfilled should be_truthy;
                promise.value should be_empty;
            });
        });

        context(@"with one known name and one unknown name", ^{
            beforeEach(^{
                promise = [service personResultsForFirstName:@"Leon" lastName:@"Smith" suspectID:@""];
            });

            it(@"should attach an empty array to the promise", ^{
                promise.fulfilled should be_truthy;
                promise.value should be_empty;
            });
        });

        context(@"with a partial name that does not match the beginning of the string", ^{
            beforeEach(^{
                promise = [service personResultsForFirstName:@"eon" lastName:@"ewis" suspectID:@""];
            });

            it(@"should attach an empty array to the promise", ^{
                promise.fulfilled should be_truthy;
                promise.value should be_empty;
            });
        });

        context(@"with an exact suspect ID", ^{
            beforeEach(^{
                promise = [service personResultsForFirstName:@"" lastName:@"" suspectID:@"4636"];
            });

            it(@"should fulfill the promise only with a person exactly matching the ID", ^{
                promise.fulfilled should be_truthy;
                promise.value should contain(larry);
                promise.value should_not contain(leon);
            });
        });

    });
});

SPEC_END
