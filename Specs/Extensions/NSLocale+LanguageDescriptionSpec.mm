#import "NSLocale+LanguageDescription.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(NSLocale_LanguageDescriptionSpec)

describe(@"NSLocale_LanguageDescription", ^{
    describe(@"+languageDescriptionForCode:", ^{
        it(@"should be just 'English' for the English code (en)", ^{
            [NSLocale languageDescriptionForCode:@"en"] should equal(@"English");
        });

        it(@"should contain the localized and English descriptions", ^{
            [NSLocale languageDescriptionForCode:@"es"] should equal(@"español - Spanish");
            [NSLocale languageDescriptionForCode:@"fr"] should equal(@"français - French");
        });
    });
});

SPEC_END
