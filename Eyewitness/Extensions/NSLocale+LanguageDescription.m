#import "NSLocale+LanguageDescription.h"

@implementation NSLocale (LanguageDescription)

+ (NSString *)languageDescriptionForCode:(NSString *)languageCode {
    NSLocale *englishLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en"];
    NSString *englishDescription = [englishLocale displayNameForKey:NSLocaleIdentifier value:languageCode];

    if ([languageCode isEqualToString:@"en"]) {
        return englishDescription;
    } else {
        NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:languageCode];
        NSString *localizedDescription = [locale displayNameForKey:NSLocaleIdentifier value:languageCode];
        return [NSString stringWithFormat:@"%@ - %@", localizedDescription, englishDescription];
    }
}

@end
