#import "WitnessLocalization.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(WitnessLocalizationSpec)

describe(@"WitnessLocalization", ^{
    context(@"when the witness language is reset", ^{
        beforeEach(^{
            [WitnessLocalization setWitnessLanguageCode:@"en"];
            [WitnessLocalization reset];
        });

        it(@"should clear the setting", ^{
            [WitnessLocalization witnessLanguageCode] should equal(@"en");
        });
    });

    context(@"when the witness language is Spanish", ^{
        beforeEach(^{
            [WitnessLocalization setWitnessLanguageCode:@"es"];
        });

        it(@"WitnessLocalizedString should return strings localized in Spanish", ^{
            WitnessLocalizedString(@"START", nil) should equal(@"INICIA");
        });

        it(@"should set the witness language", ^{
            [WitnessLocalization witnessLanguageCode] should equal(@"es");
        });

        it(@"WitnessLocalizedAudioPrompt should return the URL for the Spanish-language audio prompt", ^{
            NSURL *spanishAudioPromptURL = [[NSBundle mainBundle] URLForResource:@"witness_preparation" withExtension:@"m4a" subdirectory:nil localization:@"es"];
            [WitnessLocalization URLForAudioPromptWithName:@"witness_preparation"] should equal(spanishAudioPromptURL);
        });
    });

    context(@"when the witness language is English", ^{
        beforeEach(^{
            [WitnessLocalization setWitnessLanguageCode:@"en"];
        });

        it(@"WitnessLocalizedString should return strings localized in English", ^{
            WitnessLocalizedString(@"START", nil) should equal(@"START");
        });

        it(@"should set the witness language", ^{
            [WitnessLocalization witnessLanguageCode] should equal(@"en");
        });

        it(@"WitnessLocalizedAudioPrompt should return the URL for the Spanish-language audio prompt", ^{
            NSURL *spanishAudioPromptURL = [[NSBundle mainBundle] URLForResource:@"witness_preparation" withExtension:@"m4a" subdirectory:nil localization:@"en"];
            [WitnessLocalization URLForAudioPromptWithName:@"witness_preparation"] should equal(spanishAudioPromptURL);
        });
    });
});

SPEC_END
