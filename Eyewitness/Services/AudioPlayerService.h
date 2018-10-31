#import <Foundation/Foundation.h>

@class AudioPlayerProvider;

@interface AudioPlayerService : NSObject

+ (AudioPlayerService *)service;

- (instancetype)initWithAudioPlayerProvider:(AudioPlayerProvider *)audioPlayerProvider;
- (KSPromise *)playSoundNamed:(NSString *)soundName;
- (void)stopPlaying;

@end
