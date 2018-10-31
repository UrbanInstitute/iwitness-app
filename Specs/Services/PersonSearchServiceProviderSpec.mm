#import "PersonSearchServiceProvider.h"
#import "PersonSearchService.h"
#import "CedarAsync.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(PersonSearchServiceProviderSpec)

describe(@"PersonSearchServiceProvider", ^{
    __block PersonSearchServiceProvider *provider;
    __block PersonSearchService *searchService;

    beforeEach(^{
        provider = [[PersonSearchServiceProvider alloc] init];
        searchService = [provider personSearchService];
    });

    it(@"should provide a search service that returns results from the internal person store", ^{
        KSPromise *leonSearchPromise = [searchService personResultsForFirstName:@"Leon" lastName:@"Lewis" suspectID:@""];
        in_time(leonSearchPromise.fulfilled) should be_truthy;
        leonSearchPromise.value should_not be_empty;

        KSPromise *virgilSearchPromise = [searchService personResultsForFirstName:@"Virgil" lastName:@"Edwards" suspectID:@""];
        in_time(virgilSearchPromise.fulfilled) should be_truthy;
        virgilSearchPromise.value should_not be_empty;
    });
});

SPEC_END
