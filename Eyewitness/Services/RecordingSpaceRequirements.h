#import <Foundation/Foundation.h>

@interface RecordingSpaceRequirements : NSObject

@property (nonatomic, readonly) NSUInteger cameraBytesPerMinute;
@property (nonatomic, readonly) NSUInteger screenBytesPerMinute;
@property (nonatomic, readonly) NSUInteger stitchedBytesPerMinute;

+ (instancetype)requirementsForStandardScreenCapture;
+ (instancetype)requirementsForRetinaScreenCapture;

@end
