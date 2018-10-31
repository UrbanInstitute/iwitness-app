#import "VideoStitcherProvider.h"
#import "VideoStitcher.h"

@implementation VideoStitcherProvider

- (VideoStitcher *)videoStitcher {
    return [[VideoStitcher alloc] initWithApplication:[UIApplication sharedApplication]];
}

@end
