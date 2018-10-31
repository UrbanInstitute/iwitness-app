#import "RecordingTimeAvailableCalculator.h"
#import "NSFileManager+FreeDiskSpace.h"
#import "RecordingSpaceRequirements.h"

@interface RecordingTimeAvailableCalculator ()
@property (nonatomic, strong) NSFileManager *fileManager;
@property (nonatomic, strong, readwrite) RecordingSpaceRequirements *recordingSpaceRequirements;
@end

@implementation RecordingTimeAvailableCalculator

- (instancetype)initWithFileManager:(NSFileManager *)fileManager recordingSpaceRequirements:(RecordingSpaceRequirements *)recordingSpaceRequirements {
    if (self = [super init]) {
        self.fileManager = fileManager;
        self.recordingSpaceRequirements = recordingSpaceRequirements;
    }
    return self;
}

- (NSUInteger)calculateAvailableMinutesOfRecordingTime {
    unsigned long long freeDiskSpaceBytes = 0;
    [self.fileManager getFreeDiskSpaceBytes:&freeDiskSpaceBytes totalDiskSpaceBytes:NULL];

    if (self.recordingSpaceRequirements) {
        return (NSUInteger)(freeDiskSpaceBytes/(self.recordingSpaceRequirements.cameraBytesPerMinute+
                                                self.recordingSpaceRequirements.screenBytesPerMinute+
                                                self.recordingSpaceRequirements.stitchedBytesPerMinute));
    } else {
        return 0;
    }
}

- (RecordingTimeAvailableStatus)recordingTimeAvailableStatus {
    if ([self calculateAvailableMinutesOfRecordingTime] < 60) {
        return RecordingTimeAvailableStatusWarning;
    } else {
        return RecordingTimeAvailableStatusNormal;
    }
}

#pragma mark - Accessors

- (NSFileManager *)fileManager {
    if (!_fileManager) {
        _fileManager = [NSFileManager defaultManager];
    }
    return _fileManager;
}

@end
