#import "PlayerView.h"

@implementation PlayerView

+ (Class)layerClass {
    return [AVPlayerLayer class];
}

- (void)setPlayer:(AVPlayer *)player {
    ((AVPlayerLayer *)self.layer).player = player;
}
- (AVPlayer *)player {
    return ((AVPlayerLayer *)self.layer).player;
}

@end
