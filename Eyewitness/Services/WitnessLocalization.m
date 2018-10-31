#import "WitnessLocalization.h"

static NSString *const kWitnessLanguageDefaultsKey = @"WitnessLanguage";

NSString *WitnessLocalizedString(NSString *key, NSString *comment) {
    NSString *languageCode = [[NSUserDefaults standardUserDefaults] valueForKey:kWitnessLanguageDefaultsKey];
    NSURL *languageBundleURL = [[NSBundle mainBundle] URLForResource:languageCode withExtension:@"lproj"];
    NSBundle *languageBundle = [NSBundle bundleWithURL:languageBundleURL];

    return [languageBundle localizedStringForKey:key value:@"" table:nil];
}

@implementation WitnessLocalization

+ (void)initialize {
    [[NSUserDefaults standardUserDefaults] registerDefaults:@{ kWitnessLanguageDefaultsKey: @"en" }];
}

+ (void)setWitnessLanguageCode:(NSString *)languageCode {
    [[NSUserDefaults standardUserDefaults] setObject:languageCode forKey:kWitnessLanguageDefaultsKey];
}

+ (NSString *)witnessLanguageCode {
    return [[NSUserDefaults standardUserDefaults] objectForKey:kWitnessLanguageDefaultsKey];
}

+ (NSURL *)URLForAudioPromptWithName:(NSString *)audioPromptName {
    return [[NSBundle mainBundle] URLForResource:audioPromptName
                                   withExtension:@"m4a"
                                    subdirectory:nil
                                    localization:[WitnessLocalization witnessLanguageCode]];
}

+ (NSURL *)URLForInstructionalVideo {
    return [[NSBundle mainBundle] URLForResource:@"instructions"
                                   withExtension:@"mp4"
                                    subdirectory:nil
                                    localization:[WitnessLocalization witnessLanguageCode]];
}


+ (void)reset {
    if(![[[NSUserDefaults standardUserDefaults] valueForKey:kWitnessLanguageDefaultsKey] isEqualToString:@"en"]) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:kWitnessLanguageDefaultsKey];
    }
}

@end
