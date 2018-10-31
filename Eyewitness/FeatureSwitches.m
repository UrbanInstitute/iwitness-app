#import "FeatureSwitches.h"
//#import "FBTweakInline.h"

//#define FEATURE_SWITCH_KEY @"Feature Switches";

@implementation FeatureSwitches

+ (BOOL)perpetratorDescriptionEnabled {
    return true;//FBTweakValue(FEATURE_SWITCH_KEY, @"Perpetrator Description", @"Enabled", NO);
}

+ (BOOL)choosePhotosFromDBEnabled {
    return false;//return FBTweakValue(FEATURE_SWITCH_KEY, @"Choose Photos From DB", @"Enabled", NO);
}

+ (BOOL)audioOnlyLineupsEnabled {
    return false;//FBTweakValue(FEATURE_SWITCH_KEY, @"Audio Only Lineups", @"Enabled", NO);
}

+ (BOOL)notSureResponseEnabled {
    return false;//return FBTweakValue(FEATURE_SWITCH_KEY, @"'Not Sure' Response", @"Enabled", NO);
}

+ (BOOL)allowSkippingInstructionalVideoEnabled {
    return true;//FBTweakValue(FEATURE_SWITCH_KEY, @"Allow Skipping Instructional Video", @"Enabled", NO);
}

@end
