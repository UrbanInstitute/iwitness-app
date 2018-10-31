#import "MoviePlayerViewController.h"
#import "CedarAsync.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(MoviePlayerViewControllerSpec)

describe(@"MoviePlayerViewController", ^{
    __block MoviePlayerViewController *controller;
    __block UIViewController *presentingViewController;

    beforeEach(^{
        controller = [[MoviePlayerViewController alloc] init];
        controller.view should_not be_nil;

        presentingViewController = [[UIViewController alloc] init];
        spy_on(presentingViewController);
        presentingViewController stub_method(@selector(dismissMoviePlayerViewControllerAnimated));
        [presentingViewController presentViewController:controller animated:NO completion:NULL];
    });

    it(@"should only support landscape orientation", ^{
        [controller supportedInterfaceOrientations] should equal(UIInterfaceOrientationMaskLandscape);
    });

    describe(@"when the view appears", ^{
        beforeEach(^{
            [controller viewWillAppear:NO];
            [controller viewDidAppear:NO];
        });

        describe(@"when playback finishes normally", ^{
            beforeEach(^{
                [[NSNotificationCenter defaultCenter] postNotificationName:MPMoviePlayerPlaybackDidFinishNotification object:controller.moviePlayer userInfo:@{ MPMoviePlayerPlaybackDidFinishReasonUserInfoKey: @(MPMovieFinishReasonPlaybackEnded) }];
            });

            it(@"should not dismiss itself", ^{
                presentingViewController should_not have_received(@selector(dismissMoviePlayerViewControllerAnimated));
            });
        });

        describe(@"when the user taps the Done button", ^{
            beforeEach(^{
                [[NSNotificationCenter defaultCenter] postNotificationName:MPMoviePlayerPlaybackDidFinishNotification object:controller.moviePlayer userInfo:@{ MPMoviePlayerPlaybackDidFinishReasonUserInfoKey: @(MPMovieFinishReasonUserExited) }];
            });

            it(@"should dismiss itself", ^{
                presentingViewController should have_received(@selector(dismissMoviePlayerViewControllerAnimated));
            });
        });

        describe(@"when the user taps the Fast Forward button", ^{
            beforeEach(^{
                spy_on(controller.moviePlayer);

                controller.moviePlayer stub_method(@selector(playbackState)).and_return(MPMoviePlaybackStateStopped);
                [[NSNotificationCenter defaultCenter] postNotificationName:MPMoviePlayerPlaybackStateDidChangeNotification object:controller.moviePlayer userInfo:{}];
            });

            it(@"should prepare to play the video again from the beginning", ^{
                with_timeout(1, ^{
                    in_time(controller.moviePlayer) should have_received(@selector(stop));
                    in_time(controller.moviePlayer) should have_received(@selector(play));
                    in_time(controller.moviePlayer) should have_received(@selector(pause));
                });
            });
        });
    });

});

SPEC_END
