#import <Foundation/Foundation.h>

@class RecordingSpaceRequirements;

typedef NS_ENUM(NSInteger, RecordingTimeAvailableStatus) {
    RecordingTimeAvailableStatusNormal,
    RecordingTimeAvailableStatusWarning
};

@interface RecordingTimeAvailableCalculator : NSObject

@property (nonatomic, readonly) RecordingSpaceRequirements *recordingSpaceRequirements;

- (instancetype)initWithFileManager:(NSFileManager *)fileManager recordingSpaceRequirements:(RecordingSpaceRequirements *)recordingSpaceRequirements;

- (NSUInteger)calculateAvailableMinutesOfRecordingTime;
- (RecordingTimeAvailableStatus)recordingTimeAvailableStatus;

@end
