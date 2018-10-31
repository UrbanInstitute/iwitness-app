#import "RecordingTimeAvailableCalculatorProvider.h"
#import "RecordingTimeAvailableCalculator.h"
#import "ScreenCaptureService.h"
#import "RecordingSpaceRequirements.h"

@interface RecordingTimeAvailableCalculatorProvider ()
@property (nonatomic, strong) ScreenCaptureService *screenCaptureService;
@end

@implementation RecordingTimeAvailableCalculatorProvider

- (instancetype)initWithScreenCaptureService:(ScreenCaptureService *)screenCaptureService {
    if (self = [super init]) {
        self.screenCaptureService = screenCaptureService;
    }
    return self;
}

- (RecordingTimeAvailableCalculator *)recordingTimeAvailableCalculator {
    RecordingSpaceRequirements *spaceRequirements;
    if ([self.screenCaptureService frameScale] == 2.0f) {
        spaceRequirements = [RecordingSpaceRequirements requirementsForRetinaScreenCapture];
    }
    else {
        spaceRequirements = [RecordingSpaceRequirements requirementsForStandardScreenCapture];
    }

    return [[RecordingTimeAvailableCalculator alloc] initWithFileManager:[NSFileManager defaultManager]
                                              recordingSpaceRequirements:spaceRequirements];
}

@end
