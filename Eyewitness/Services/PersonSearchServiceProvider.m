#import "PersonSearchServiceProvider.h"
#import "PersonSearchService.h"
#import "PersonsParser.h"
#import "PersonsLoader.h"

@implementation PersonSearchServiceProvider

- (PersonSearchService *)personSearchService {
    NSURL *personsDataURL = [[NSBundle mainBundle] URLForResource:@"photo_records_subset" withExtension:@"json" subdirectory:@"PhotoRecords"];
    PersonsParser *personsParser = [[PersonsParser alloc] init];
    PersonsLoader *personsLoader = [[PersonsLoader alloc] initWithFileURL:personsDataURL parser:personsParser];
    return [[PersonSearchService alloc] initWithPersonsLoader:personsLoader];
}
@end
