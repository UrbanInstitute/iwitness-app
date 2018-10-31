#import "AudioPlayerService.h"
#import "AudioPlayerProvider.h"

@interface AudioPlayerService ()<AVAudioPlayerDelegate>
@property (nonatomic, strong) AudioPlayerProvider *audioPlayerProvider;
@property (nonatomic, strong) AVAudioPlayer *audioPlayer;
@property (nonatomic, strong) KSDeferred *soundPlaybackDeferred;
@end

@implementation AudioPlayerService

+ (AudioPlayerService *)service {
    AudioPlayerProvider *audioPlayerProvider = [[AudioPlayerProvider alloc] init];
    return [[AudioPlayerService alloc] initWithAudioPlayerProvider:audioPlayerProvider];
}

- (instancetype)init {
    @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"Must initialize an audio player service with an audio player provider" userInfo:nil];
}

- (instancetype)initWithAudioPlayerProvider:(AudioPlayerProvider *)audioPlayerProvider {
    if (self = [super init]) {
        self.audioPlayerProvider = audioPlayerProvider;
    }
    return self;
}

- (KSPromise *)playSoundNamed:(NSString *)soundName {
    NSURL *soundURL = [WitnessLocalization URLForAudioPromptWithName:soundName];
    self.audioPlayer = [self.audioPlayerProvider audioPlayerWithSoundURL:soundURL];
    self.audioPlayer.delegate = self;
    [self.audioPlayer play];
    self.soundPlaybackDeferred = [KSDeferred defer];
    return self.soundPlaybackDeferred.promise;
}

- (void)stopPlaying {
    [self.audioPlayer stop];
}

#pragma mark - <AVAudioPlayerDelegate>

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    [self.soundPlaybackDeferred resolveWithValue:nil];
}

@end
