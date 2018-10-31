#import "UIImage+SinglePixelImage.h"

@implementation UIImage (SinglePixelImage)

+ (UIImage *)singlePixelImageWithColor:(UIColor *)color {
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(1, 1), NO, 1);

    [color set];
    UIRectFill(CGRectMake(0, 0, 1, 1));

    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return image;
}

@end
