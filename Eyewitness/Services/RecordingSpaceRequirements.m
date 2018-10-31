#import "RecordingSpaceRequirements.h"

@implementation RecordingSpaceRequirements

- (instancetype)initWithCameraBytesPerMinute:(NSUInteger)cameraBytesPerMinute
                        screenBytesPerMinute:(NSUInteger)screenBytesPerMinute
                      stitchedBytesPerMinute:(NSUInteger)stitchedBytesPerMinute {
    if (self = [super init]) {
        _cameraBytesPerMinute = cameraBytesPerMinute;
        _screenBytesPerMinute = screenBytesPerMinute;
        _stitchedBytesPerMinute = stitchedBytesPerMinute;
    }
    return self;
}

- (BOOL)isEqual:(RecordingSpaceRequirements *)other {
    return ([other isKindOfClass:[self class]] &&
            self.cameraBytesPerMinute==other.cameraBytesPerMinute &&
            self.screenBytesPerMinute==other.screenBytesPerMinute &&
            self.stitchedBytesPerMinute==other.stitchedBytesPerMinute);
}

- (NSUInteger)hash {
    NSUInteger prime = 31;
    NSUInteger result = 1;
    result  = prime * result + self.cameraBytesPerMinute;
    result  = prime * result + self.screenBytesPerMinute;
    result  = prime * result + self.stitchedBytesPerMinute;
    return result;
}

+ (instancetype)requirementsForStandardScreenCapture {
    return [[RecordingSpaceRequirements alloc] initWithCameraBytesPerMinute:6*1024*1024
                                                       screenBytesPerMinute:1.5*1024*1024
                                                     stitchedBytesPerMinute:20*1024*1024];
}

+ (instancetype)requirementsForRetinaScreenCapture {
    return [[RecordingSpaceRequirements alloc] initWithCameraBytesPerMinute:6*1024*1024
                                                       screenBytesPerMinute:3*1024*1024
                                                     stitchedBytesPerMinute:20*1024*1024];
}

@end
