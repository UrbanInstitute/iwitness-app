#import "AudioPlayerProvider.h"

@implementation AudioPlayerProvider

- (AVAudioPlayer *)audioPlayerWithSoundURL:(NSURL *)soundURL {
    return [[AVAudioPlayer alloc] initWithContentsOfURL:soundURL error:nil];
}

@end
