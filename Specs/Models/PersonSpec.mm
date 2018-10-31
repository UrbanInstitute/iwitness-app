#import "Person.h"
#import "Portrayal.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(PersonSpec)

describe(@"Person", ^{
    __block Person *person;
    NSArray *portrayalsForPerson = @[
            [[Portrayal alloc] initWithPhotoURL:[NSURL URLWithString:@"some/url"] date:[NSDate dateWithTimeIntervalSince1970:12345]],
            [[Portrayal alloc] initWithPhotoURL:[NSURL URLWithString:@"other/url"] date:[NSDate dateWithTimeIntervalSince1970:23456]]
    ];

    beforeEach(^{
        person = [[Person alloc] initWithFirstName:@"First"
                                          lastName:@"Last"
                                       dateOfBirth:[NSDate dateWithTimeIntervalSince1970:320630400]
                                          systemID:@"0001"
                                        portrayals:portrayalsForPerson];
    });

    describe(@"full name", ^{
        context(@"when both first and last names are present", ^{
            it(@"should concatenate the two", ^{
                person.fullName should equal(@"First Last");
            });
        });

        context(@"when only a first name is present", ^{
            beforeEach(^{
                person = [[Person alloc] initWithFirstName:@"First" lastName:nil dateOfBirth:nil systemID:nil portrayals:nil];
            });

            it(@"should return the first name", ^{
                person.fullName should equal(@"First");
            });
        });

        context(@"when only a last name is present", ^{
            beforeEach(^{
                person = [[Person alloc] initWithFirstName:nil lastName:@"Last" dateOfBirth:nil systemID:nil portrayals:nil];
            });

            it(@"should return the first name", ^{
                person.fullName should equal(@"Last");
            });
        });
    });

    describe(@"selected portrayal", ^{
        context(@"when no portrayal is selected", ^{
            beforeEach(^{
                person.selectedPortrayal = nil;
            });

            it(@"it should default to the first portrayal", ^{
                person.selectedPortrayal should be_same_instance_as(person.portrayals.firstObject);
            });
        });

        context(@"when explicitly set", ^{
            beforeEach(^{
                person.selectedPortrayal should_not equal(person.portrayals.lastObject);
                person.selectedPortrayal = person.portrayals.lastObject;
            });

            it(@"it override the default", ^{
                person.selectedPortrayal should be_same_instance_as(person.portrayals.lastObject);
            });
        });
    });

    describe(@"value equality", ^{
        __block Person *equalPerson;
        __block Person *unequalFirstNamePerson;
        __block Person *unequalLastNamePerson;
        __block Person *unequalDOBPerson;
        __block Person *unequalSystemIDPerson;
        __block Person *unequalSelectedPortrayalPerson;

        beforeEach(^{
            equalPerson = [[Person alloc] initWithFirstName:@"First" lastName:@"Last" dateOfBirth:[NSDate dateWithTimeIntervalSince1970:320630400] systemID:@"0001" portrayals:portrayalsForPerson];
            unequalFirstNamePerson = [[Person alloc] initWithFirstName:@"Albert" lastName:@"Last" dateOfBirth:[NSDate dateWithTimeIntervalSince1970:320630400] systemID:@"0001" portrayals:portrayalsForPerson];
            unequalLastNamePerson = [[Person alloc] initWithFirstName:@"First" lastName:@"Einstein" dateOfBirth:[NSDate dateWithTimeIntervalSince1970:320630400] systemID:@"0001" portrayals:portrayalsForPerson];
            unequalDOBPerson = [[Person alloc] initWithFirstName:@"First" lastName:@"Last" dateOfBirth:[NSDate dateWithTimeIntervalSince1970:-320630400] systemID:@"0001" portrayals:portrayalsForPerson];
            unequalSystemIDPerson = [[Person alloc] initWithFirstName:@"First" lastName:@"Last" dateOfBirth:[NSDate dateWithTimeIntervalSince1970:320630400] systemID:@"0002" portrayals:portrayalsForPerson];

            unequalSelectedPortrayalPerson = [[Person alloc] initWithFirstName:@"First"
                                                               lastName:@"Last"
                                                            dateOfBirth:[NSDate dateWithTimeIntervalSince1970:320630400] systemID:@"0001"
                                                             portrayals:portrayalsForPerson];
            unequalSelectedPortrayalPerson.selectedPortrayal = portrayalsForPerson.lastObject;
        });

        it(@"should report equality", ^{
            [person isEqual:equalPerson] should be_truthy;
            [person hash] should equal([equalPerson hash]);

            [person isEqual:unequalFirstNamePerson] should_not be_truthy;
            [person hash] should_not equal([unequalFirstNamePerson hash]);

            [person isEqual:unequalLastNamePerson] should_not be_truthy;
            [person hash] should_not equal([unequalLastNamePerson hash]);

            [person isEqual:unequalDOBPerson] should_not be_truthy;
            [person hash] should_not equal([unequalDOBPerson hash]);

            [person isEqual:unequalSystemIDPerson] should_not be_truthy;
            [person hash] should_not equal([unequalSystemIDPerson hash]);

            [person isEqual:unequalSelectedPortrayalPerson] should_not be_truthy;
            [person hash] should_not equal([unequalSelectedPortrayalPerson hash]);
        });
    });

    describe(@"copying", ^{
        __block Person *copiedPerson;
        beforeEach(^{
            copiedPerson = [person copy];
        });

        it(@"should make an equal copy", ^{
            copiedPerson should_not be_same_instance_as(person);
            copiedPerson should equal(person);
        });
    });

    describe(@"persisting the person", ^{
        __block Person *unarchivedPerson;
        __block NSData *archiveData;

        context(@"on a lineup with data", ^{
            beforeEach(^{
                person.selectedPortrayal = person.portrayals.lastObject;
                archiveData = [NSKeyedArchiver archivedDataWithRootObject:person];
            });

            it(@"should unarchive the lineup correctly", ^{
                unarchivedPerson = [NSKeyedUnarchiver unarchiveObjectWithData:archiveData];
                unarchivedPerson.firstName should equal(@"First");
                unarchivedPerson.lastName should equal(@"Last");
                unarchivedPerson.dateOfBirth should equal([NSDate dateWithTimeIntervalSince1970:320630400]);
                unarchivedPerson.systemID should equal(@"0001");
                unarchivedPerson.selectedPortrayal should equal(person.portrayals.lastObject);
            });
        });

        context(@"on a lineup with no data", ^{
            beforeEach(^{
                person = [[Person alloc] init];
                archiveData = [NSKeyedArchiver archivedDataWithRootObject:person];
            });

            it(@"should unarchive the lineup correctly", ^{
                unarchivedPerson = [NSKeyedUnarchiver unarchiveObjectWithData:archiveData];
                unarchivedPerson.firstName should be_nil;
                unarchivedPerson.lastName should be_nil;
                unarchivedPerson.dateOfBirth should be_nil;
                unarchivedPerson.systemID should be_nil;
                unarchivedPerson.selectedPortrayal should be_nil;
            });
        });
    });
});

SPEC_END
