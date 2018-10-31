#import "EyewitnessTheme.h"

@implementation EyewitnessTheme

+ (UIColor *)primaryColor {
    return [UIColor colorWithRed:0.f/255.f green:36.f/255.f blue:186.f/255.f alpha:1.f];
}

+ (UIColor *)primaryActiveColor {
    return [UIColor colorWithRed:0.f/255.f green:24.f/255.f blue:121.f/255.f alpha:1.f];
}

+ (UIColor *)warnColor {
    return [UIColor colorWithRed:107.f/255.f green:3.f/255.f blue:28.f/255.f alpha:1.f];
}

+ (UIColor *)warnActiveColor {
    return [UIColor colorWithRed:70.f/255.f green:1.f/255.f blue:17.f/255.f alpha:1.f];
}

+ (UIColor *)successColor {
    return [UIColor colorWithRed:40.f/255.f green:102.f/255.f blue:3.f/255.f alpha:1.f];
}

+ (UIColor *)recordColor {
    return [UIColor colorWithRed:238.f/255.f green:51.f/255.f blue:51.f/255.f alpha:1.f];
}

+ (UIColor *)grayColor {
    return [UIColor colorWithRed:230.f/255.f green:230.f/255.f blue:230.f/255.f alpha:1.f];
}

+ (UIColor *)darkerGrayColor {
    return [UIColor colorWithRed:38.f/255.f green:38.f/255.f blue:29.f/255.f alpha:1.f];
}

+ (UIColor *)lightGrayColor {
    return [UIColor colorWithRed:242.f/255.f green:242.f/255.f blue:242.f/255.f alpha:1.f];
}

+ (UIColor *)darkGrayColor {
    return [UIColor colorWithRed:199.f/255.f green:199.f/255.f blue:199.f/255.f alpha:1.f];
}

+ (UIColor *)touchOverlayColor {
    return [UIColor colorWithRed:252.0f/255.0f green:238.0f/255.0f blue:33.0f/255.0f alpha:204.0f/255.0f];
}

+ (UIColor *)yesColor {
    return [UIColor colorWithRed:56.f/255.f green:150.f/255.f blue:57.f/255.f alpha:1.f];
}

+ (UIColor *)noColor {
    return [UIColor colorWithRed:106.f/255.f green:6.f/255.f blue:30.f/255.f alpha:1.f];
}

+ (UIFont *)portrayalCardNameFont {
    return [UIFont fontWithName:@"Avenir-Heavy" size:19.f];
}

+ (UIFont *)tableDetailValueFont {
    return [UIFont fontWithName:@"Avenir-Heavy" size:16.f];
}

+ (UIFont *)tableTextLabelFont {
    return [UIFont fontWithName:@"Avenir-Book" size:36.f];
}

+ (UIFont *)tableDetailLabelFont {
    return [UIFont fontWithName:@"Avenir-Book" size:16.f];
}

+ (UIFont *)sectionHeadingFont {
    return [UIFont fontWithName:@"Avenir-Medium" size:16.f];
}

+ (UIFont *)formLabelFont {
    return [UIFont fontWithName:@"Avenir-Black" size:16.f];
}

+ (UIFont *)formValueFont {
    return [UIFont fontWithName:@"Avenir-Book" size:18.f];
}

+ (UIFont *)witnessPromptFont {
    return [UIFont fontWithName:@"Avenir-Medium" size:32.f];
}

+ (UIFont *)witnessInstructionFont {
    return [UIFont fontWithName:@"Avenir-Black" size:26.f];
}

+ (UIFont *)buttonTextFont {
    return [UIFont fontWithName:@"Avenir-Black" size:17.f];
}

+ (UIFont *)segmentTextFont {
    return [UIFont fontWithName:@"Avenir-Black" size:26.f];
}

+ (UIFont *)messageTextFont {
    return [UIFont fontWithName:@"Avenir-MediumOblique" size:16.f];
}

+ (UIFont *)toolbarFont {
    return [UIFont fontWithName:@"Avenir-Medium" size:18.f];
}

@end
