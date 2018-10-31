#import "WitnessInstructionsViewController.h"
#import "PhotoIDViewController.h"
#import "Presentation.h"
#import <MediaPlayer/MediaPlayer.h>
#import "ScreenCaptureService.h"
#import "PlayerView.h"
#import "WitnessLocalization.h"
#import "SubtitlesView.h"
#import "CADisplayLink+SpecHelpers.h"
#import "PixelBufferView.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(WitnessInstructionsViewControllerSpec)

describe(@"WitnessInstructionsViewController", ^{
    __block WitnessInstructionsViewController *controller;
    __block UINavigationController *navController;

    beforeEach(^{
        controller = [[UIStoryboard storyboardWithName:@"PresentationFlow" bundle:nil] instantiateViewControllerWithIdentifier:@"WitnessInstructionsViewController"];
        navController = [[UINavigationController alloc] initWithRootViewController:controller];

        controller.view should_not be_nil;
        [controller viewWillAppear:NO];

        spy_on(controller.playerView);
        controller.playerView stub_method(@selector(setPlayer:));
    });

    describe(@"when the controller is configured", ^{
        __block AVPlayer *avPlayer;
        __block AVPlayerItem *playerItem;
        __block AVPlayerItemLegibleOutput *playerItemLegibleOutput;
        __block AVPlayerItemVideoOutput *playerItemVideoOutput;
        __block AVURLAsset *asset;
        __block NSURL *instructionsMovieURL;
        __block AVMediaSelectionOption *selectedSubtitleMediaOption;
        __block AVMediaSelectionOption *selectedAudioMediaOption;
        __block id<WitnessInstructionsViewControllerDelegate> delegate;
        __block ScreenCaptureService *screenCaptureService;
        __block float currentPlayerRate;
        __block CVPixelBufferRef moviePixelBuffer;

        beforeEach(^{
            selectedSubtitleMediaOption = nil;
            selectedAudioMediaOption = nil;
            playerItemLegibleOutput = nil;
            playerItemVideoOutput = nil;
            moviePixelBuffer = NULL;

            [WitnessLocalization setWitnessLanguageCode:@"es"];

            instructionsMovieURL = [WitnessLocalization URLForInstructionalVideo];

            asset = [AVURLAsset assetWithURL:instructionsMovieURL];

            playerItem = fake_for([AVPlayerItem class]);
            playerItem stub_method(@selector(selectMediaOption:inMediaSelectionGroup:)).and_do_block(^(AVMediaSelectionOption *selectedMediaOption, AVMediaSelectionGroup *selectionGroup){
                if([selectedMediaOption.mediaType isEqualToString:AVMediaTypeSubtitle]) {
                    selectedSubtitleMediaOption = selectedMediaOption;
                }

                if([selectedMediaOption.mediaType isEqualToString:AVMediaTypeAudio]) {
                    selectedAudioMediaOption = selectedMediaOption;
                }
            });

            playerItem stub_method(@selector(addOutput:)).and_do_block(^(AVPlayerItemOutput *playerItemOutput){
                if ([playerItemOutput isKindOfClass:[AVPlayerItemLegibleOutput class]]) {
                    playerItemLegibleOutput = (AVPlayerItemLegibleOutput *)playerItemOutput;
                } else if([playerItemOutput isKindOfClass:[AVPlayerItemVideoOutput class]]) {
                    playerItemVideoOutput = (AVPlayerItemVideoOutput *)playerItemOutput;
                    spy_on(playerItemVideoOutput);

                    CVPixelBufferCreate(NULL, 1, 1, kCVPixelFormatType_32BGRA, NULL, &moviePixelBuffer);
                    playerItemVideoOutput stub_method(@selector(hasNewPixelBufferForItemTime:)).and_return((YES));
                    playerItemVideoOutput stub_method(@selector(copyPixelBufferForItemTime:itemTimeForDisplay:)).and_return(moviePixelBuffer);
                }
            });

            playerItem stub_method(@selector(asset)).and_return(asset);
            playerItem stub_method(@selector(currentTime));

            avPlayer = nice_fake_for([AVPlayer class]);
            avPlayer stub_method(@selector(currentItem)).and_return(playerItem);

            avPlayer stub_method(@selector(rate)).and_do_block(^float{
                return currentPlayerRate;
            });
            avPlayer stub_method(@selector(play)).and_do_block(^{
                currentPlayerRate = 1;
            });
            avPlayer stub_method(@selector(pause)).and_do_block(^{
                float oldRate = currentPlayerRate;
                currentPlayerRate = 0;
                [controller observeValueForKeyPath:@"rate" ofObject:avPlayer change:@{ NSKeyValueChangeOldKey: @(oldRate) } context:NULL];
            });

            delegate = nice_fake_for(@protocol(WitnessInstructionsViewControllerDelegate));

            screenCaptureService = fake_for([ScreenCaptureService class]);
            screenCaptureService stub_method(@selector(captureFrame));

            [controller configureWithDelegate:delegate screenCaptureService:screenCaptureService avPlayer:avPlayer];
        });

        it(@"should configure its player view for its player", ^{
            controller.playerView should have_received(@selector(setPlayer:)).with(avPlayer);
        });

        it(@"should select the subtitle track with non-forced subtitles", ^{
            [selectedSubtitleMediaOption.propertyList valueForKey:AVMediaCharacteristicContainsOnlyForcedSubtitles] should be_nil;
        });

        it(@"should select the subtitle track for the selected language", ^{
            [NSLocale canonicalLanguageIdentifierFromString:[[selectedSubtitleMediaOption locale] localeIdentifier]] should equal(@"es");
        });

        it(@"should select the audio track for the selected language", ^{
            [NSLocale canonicalLanguageIdentifierFromString:[[selectedAudioMediaOption locale] localeIdentifier]] should equal(@"es");
        });

        describe(@"string localization", ^{
            context(@"English", ^{
                beforeEach(^{
                    [WitnessLocalization setWitnessLanguageCode:@"en"];
                    [controller viewWillAppear:NO];
                });

                it(@"should localize the strings for English", ^{
                    controller.confirmationPromptLabel.text should equal(@"Do you understand these instructions?");
                    controller.confirmInstructionsButton.titleLabel.text should equal(@"I UNDERSTAND");
                    controller.replayInstructionsButton.titleLabel.text should equal(@"REPLAY");
                });
            });

            context(@"Spanish", ^{
                beforeEach(^{
                    [WitnessLocalization setWitnessLanguageCode:@"es"];
                    [controller viewWillAppear:NO];
                });

                it(@"should localize the strings for Spanish", ^{
                    controller.confirmationPromptLabel.text should equal(@"¿Usted entiende estas instrucciones?");
                    controller.confirmInstructionsButton.titleLabel.text should equal(@"YO ENTIENDO");
                    controller.replayInstructionsButton.titleLabel.text should equal(@"REPETIR");
                });
            });
        });

        describe(@"rendering subtitles", ^{
            context(@"when the player item output provides subtitles", ^{
                beforeEach(^{
                    [playerItemLegibleOutput.delegate legibleOutput:playerItemLegibleOutput
                                         didOutputAttributedStrings:@[[[NSAttributedString alloc] initWithString:@"COOL SUBTITLE"], [[NSAttributedString alloc] initWithString:@"AND MORE"]]
                                                nativeSampleBuffers:nil
                                                        forItemTime:kCMTimeZero];
                });

                it(@"should show the subtitles", ^{
                    controller.subtitlesView.text should equal(@"COOL SUBTITLE\nAND MORE");
                });

                context(@"when the player item output provides no subtitles", ^{
                    beforeEach(^{
                        [playerItemLegibleOutput.delegate legibleOutput:playerItemLegibleOutput
                                             didOutputAttributedStrings:@[]
                                                    nativeSampleBuffers:nil
                                                            forItemTime:kCMTimeZero];
                    });

                    it(@"should show clear the subtitles", ^{
                        controller.subtitlesView.text should equal(@"");
                    });
                });
            });
        });

        describe(@"when the view has appeared", ^{
            beforeEach(^{
                [controller viewDidAppear:NO];
            });

            it(@"should ensure that the screen capture service has captured a frame", ^{
                screenCaptureService should have_received(@selector(captureFrame));
            });

            it(@"should notify its delegate that playback started", ^{
                delegate should have_received(@selector(witnessInstructionsViewControllerStartedPlayback:)).with(controller);
            });

            it(@"should start playing an instructional video", ^{
                avPlayer should have_received(@selector(play));
            });

            it(@"should disable the 'Replay' and 'Yes' buttons", ^{
                controller.replayInstructionsButton.enabled should be_falsy;
                controller.confirmInstructionsButton.enabled should be_falsy;
            });

            describe(@"presenting video frames for screen capture", ^{
                it(@"should show a video frame when the display link fires", ^{
                    [CADisplayLink triggerMostRecentDisplayLink];

                    controller.moviePixelBufferView.pixelBuffer should equal(moviePixelBuffer);
                });
            });

            describe(@"presenting video frames for screen capture", ^{
                it(@"should show a video frame when the display link fires", ^{
                    [CADisplayLink triggerMostRecentDisplayLink];

                    controller.moviePixelBufferView.pixelBuffer should equal(moviePixelBuffer);
                });
            });

            describe(@"when the movie finishes playing", ^{
                beforeEach(^{
                    [avPlayer pause];
                });

                it(@"should enable the 'Replay' and 'Yes' buttons", ^{
                    controller.replayInstructionsButton.enabled should be_truthy;
                    controller.confirmInstructionsButton.enabled should be_truthy;
                });

                it(@"should notify its delegate that playback stopped", ^{
                    delegate should have_received(@selector(witnessInstructionsViewControllerStoppedPlayback:)).with(controller);
                });

                describe(@"when the 'Yes' button is tapped to confirm the instructions are understood", ^{
                    beforeEach(^{
                        [controller.confirmInstructionsButton tap];
                    });

                    it(@"should push a Photo ID view controller onto the navigation stack", ^{
                        navController.topViewController should be_instance_of([PhotoIDViewController class]);
                    });
                });

                describe(@"when the 'Replay' button is tapped", ^{
                    beforeEach(^{
                        [(id<CedarDouble>)delegate reset_sent_messages];
                        [controller.replayInstructionsButton tap];
                    });

                    it(@"should replay the instructions", ^{
                        avPlayer should have_received(@selector(pause));
                        avPlayer should have_received(@selector(play));
                    });

                    it(@"should notify its delegate that playback (re)started", ^{
                        delegate should have_received(@selector(witnessInstructionsViewControllerStartedPlayback:)).with(controller);
                    });

                    describe(@"when the view disappears", ^{
                        subjectAction(^{
                            [(id<CedarDouble>)avPlayer reset_sent_messages];
                            [(id<CedarDouble>)delegate reset_sent_messages];

                            [controller viewWillDisappear:NO];
                            [controller viewDidDisappear:NO];
                        });

                        context(@"while the movie is still playing", ^{
                            beforeEach(^{
                                [avPlayer play];
                            });

                            it(@"should stop the movie playback", ^{
                                avPlayer should have_received(@selector(pause));
                            });

                            it(@"should notify its delegate that playback stopped", ^{
                                delegate should have_received(@selector(witnessInstructionsViewControllerStoppedPlayback:)).with(controller);
                            });
                        });

                        context(@"while the movie is not playing", ^{
                            beforeEach(^{
                                [avPlayer pause];
                            });

                            it(@"should not notify its delegate that playback stopped", ^{
                                delegate should_not have_received(@selector(witnessInstructionsViewControllerStoppedPlayback:));
                            });
                        });
                    });
                });
            });
        });
    });
});

SPEC_END
