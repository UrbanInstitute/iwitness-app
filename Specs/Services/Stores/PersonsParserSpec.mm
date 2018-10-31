#import "PersonsParser.h"
#import "Person.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(PersonsParserSpec)

describe(@"PersonsParser", ^{
    __block PersonsParser *parser;
    __block NSDictionary *dict;

    beforeEach(^{
        dict = @{ @"persons": @[@{@"ID": @"0001",
                                  @"firstName": @"Alex",
                                  @"lastName": @"Basson",
                                  @"dateOfBirth": @"1975-01-21",
                                  },
                                @{@"ID": @"0002",
                                  @"firstName": @"Brian",
                                  @"lastName": @"Croom",
                                  @"dateOfBirth": @"1980-02-29",
                                  }] };
        parser = [[PersonsParser alloc] init];
    });

    describe(@"parsing a dictionary into persons", ^{
        __block Person *alex;
        __block Person *brian;

        beforeEach(^{
            alex = [[Person alloc] initWithFirstName:@"Alex"
                                            lastName:@"Basson"
                                         dateOfBirth:[NSDate dateWithTimeIntervalSince1970:159512400]
                                            systemID:@"0001"
                                          portrayals:nil];
            brian = [[Person alloc] initWithFirstName:@"Brian"
                                             lastName:@"Croom"
                                          dateOfBirth:[NSDate dateWithTimeIntervalSince1970:320648400]
                                             systemID:@"0002"
                                           portrayals:nil];
        });

        it(@"should return an array of persons", ^{
            [parser parsePersonsFromDictionary:dict] should equal(@[alex, brian]);
        });
    });
});

SPEC_END
