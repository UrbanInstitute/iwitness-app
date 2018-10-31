#import "AudioLevelMeter.h"

@interface AudioLevelMeter ()
@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureAudioDataOutput *audioDataOutput;

@property (nonatomic, readwrite) float averagePowerLevel;
@property (nonatomic, readwrite) float peakHoldLevel;

@property (nonatomic, strong) AVCaptureConnection *audioConnection;
@property (nonatomic, strong) NSArray *audioChannels;
@end

@implementation AudioLevelMeter

- (instancetype)initWithCaptureSession:(AVCaptureSession *)captureSession {
    if (self = [super init]) {
        self.captureSession = captureSession;
        self.audioDataOutput = [[AVCaptureAudioDataOutput alloc] init];
    }
    return self;
}

- (void)dealloc {
    [self stopMetering];
}

- (void)startMetering {
    if ([self isMetering]) { return; }

    if (![self.captureSession.outputs containsObject:self.audioDataOutput]) {
        [self.captureSession addOutput:self.audioDataOutput];
    }

    NSArray *connections = self.audioDataOutput.connections;
    if (connections.count > 0) {
        self.audioConnection = connections.firstObject;
        self.audioConnection.enabled = YES;
        self.audioChannels = self.audioConnection.audioChannels;

        [self pollPowerLevel];
        [self pollPowerLevelSoon];
    }
}

- (void)stopMetering {
    self.audioConnection.enabled = NO;
    self.audioChannels = nil;
}

#pragma mark - private

- (BOOL)isMetering {
    return self.audioConnection.enabled;
}

- (void)pollPowerLevel {
    float averagePowerDecibels = 0.0f;
    float peakHoldDecibels = 0.0f;

    for (AVCaptureAudioChannel *audioChannel in self.audioChannels) {
        averagePowerDecibels += [audioChannel averagePowerLevel];
        peakHoldDecibels += [audioChannel peakHoldLevel];
    }

    averagePowerDecibels /= self.audioChannels.count;
    peakHoldDecibels /= self.audioChannels.count;

    float previousPeak = self.peakHoldLevel;
    self.peakHoldLevel = [self normalizedAveragePower:peakHoldDecibels];

    self.averagePowerLevel = (self.peakHoldLevel > previousPeak) ? self.peakHoldLevel : [self normalizedAveragePower:averagePowerDecibels];
}

- (void)pollPowerLevelSoon {
    __weak id weakSelf = self;
    double delayInSeconds = 0.05;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        if ([self isMetering]) {
            [weakSelf pollPowerLevel];
            [weakSelf pollPowerLevelSoon];
        }
    });
}

- (float)normalizedAveragePower:(float)averagePowerLevel {
    averagePowerLevel = MAX(MIN(averagePowerLevel, 0), -40);
    float k = 40.0f;
    return 0.5 - 0.5 * cosf(M_PI * ((averagePowerLevel + k)/k));
}

@end
