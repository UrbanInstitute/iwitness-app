#import <Foundation/Foundation.h>

#ifdef __cplusplus
extern "C" {
#endif
    NSString *WitnessLocalizedString(NSString *key, NSString *comment);
#ifdef __cplusplus
}
#endif

@interface WitnessLocalization : NSObject

+ (void)setWitnessLanguageCode:(NSString *)languageCode;
+ (NSString *)witnessLanguageCode;
+ (NSURL *)URLForAudioPromptWithName:(NSString *)audioPromptName;

+ (NSURL *)URLForInstructionalVideo;

+ (void)reset;

@end
