#import "PersonsLoader.h"
#import "PersonsParser.h"
#import "Person.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(PersonsLoaderSpec)

describe(@"PersonsLoader", ^{
    __block PersonsLoader *loader;
    NSURL *fileURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"persons_fixture" withExtension:@"json"];
    __block PersonsParser *parser;
    NSArray *persons = @[[[Person alloc] initWithFirstName:@"First" lastName:@"Last" dateOfBirth:nil systemID:nil portrayals:nil]];

    beforeEach(^{
        parser = fake_for([PersonsParser class]);
        parser stub_method(@selector(parsePersonsFromDictionary:)).and_return(persons);

        loader = [[PersonsLoader alloc] initWithFileURL:fileURL parser:parser];
    });

    describe(@"loading persons", ^{
        __block NSArray *loadedPersons;

        beforeEach(^{
            loadedPersons = [loader loadPersons];
        });

        it(@"should load the contents of the file for parsing", ^{
            parser should have_received(@selector(parsePersonsFromDictionary:)).with(@{ @"persons": @[ @{ @"firstName": @"First", @"lastName": @"Last" } ] });
        });

        it(@"should return an array of persons from the provided file", ^{
            loadedPersons should equal(persons);
        });
    });
});

SPEC_END
