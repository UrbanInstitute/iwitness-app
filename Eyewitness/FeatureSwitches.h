#import <Foundation/Foundation.h>

@interface FeatureSwitches : NSObject

+ (BOOL)perpetratorDescriptionEnabled;
+ (BOOL)choosePhotosFromDBEnabled;
+ (BOOL)audioOnlyLineupsEnabled;
+ (BOOL)notSureResponseEnabled;
+ (BOOL)allowSkippingInstructionalVideoEnabled;

@end
