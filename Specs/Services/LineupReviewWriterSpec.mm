#import "LineupReviewWriter.h"
#import "Presentation.h"
#import "Lineup.h"
#import "PersonFactory.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(LineupReviewWriterSpec)

describe(@"LineupReviewWriter", ^{
    __block LineupReviewWriter *writer;
    __block Presentation *presentation;

    beforeEach(^{
        NSBundle *bundle = [NSBundle bundleForClass:[self class]];
        Lineup *lineup = [[Lineup alloc] initWithCreationDate:[NSDate dateWithTimeIntervalSince1970:99976876] suspect:[PersonFactory leon]];
        lineup.caseID = @"94582345";
        lineup.fillerPhotosFileURLs = [@[@"abraham", @"alex", @"anand", @"ash", @"austin", @"berger", @"Brian", @"cathy", @"nathan", @"ocean", @"samcoward", @"ward"] collect:^NSURL*(NSString* filename) {
            return [bundle URLForResource:filename withExtension:@"jpg" subdirectory:@"SampleLineup"];
        }];
        presentation = [[Presentation alloc] initWithLineup:lineup randomSeed:1234];
        writer = [[LineupReviewWriter alloc] init];
    });

    it(@"should write a PDF matching a fixture for the setup above", ^{
        [writer writeLineupReviewForPresentation:presentation];
        NSData *actualData = [NSData dataWithContentsOfURL:presentation.temporaryLineupReviewURL];
        NSData *halfOfActualData = [actualData subdataWithRange:NSMakeRange(0, actualData.length / 2)];
        NSData *expectedData = [NSData dataWithContentsOfURL:[[NSBundle bundleForClass:[self class]] URLForResource:@"lineupReviewFixture" withExtension:@"pdf"]];
        NSData *halfOfExpectedData = [expectedData subdataWithRange:NSMakeRange(0, expectedData.length / 2)];
        [halfOfActualData isEqualToData:halfOfExpectedData] should be_truthy;
    });
});

SPEC_END
