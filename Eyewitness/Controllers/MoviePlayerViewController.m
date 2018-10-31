#import "MoviePlayerViewController.h"

@implementation MoviePlayerViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];

    [[NSNotificationCenter defaultCenter] removeObserver:self name:MPMoviePlayerPlaybackDidFinishNotification object:self.moviePlayer];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackDidFinish:) name:MPMoviePlayerPlaybackDidFinishNotification object:self.moviePlayer];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playbackStateChanged:) name:MPMoviePlayerPlaybackStateDidChangeNotification object:self.moviePlayer];
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationPortrait;//MOK
}

- (void)playbackDidFinish:(NSNotification *)note {
    MPMovieFinishReason reason = [note.userInfo[MPMoviePlayerPlaybackDidFinishReasonUserInfoKey] integerValue];

    if (reason == MPMovieFinishReasonUserExited) {
        [self.presentingViewController dismissMoviePlayerViewControllerAnimated];
    }
}

- (void)playbackStateChanged:(NSNotification *)note {
    if (self.moviePlayer.playbackState == MPMoviePlaybackStateStopped) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.moviePlayer stop];
            [self.moviePlayer play];
            [self.moviePlayer pause];
        });
    }
}
//MOK
- (BOOL) shouldAutorotate
{
    return NO;
}

@end
