#import <Foundation/Foundation.h>

@interface AudioPlayerProvider : NSObject

- (AVAudioPlayer *)audioPlayerWithSoundURL:(NSURL *)soundURL;

@end
