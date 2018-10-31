#import "WitnessInstructionsViewController.h"
#import "ScreenCaptureService.h"
#import "PlayerView.h"
#import "SubtitlesView.h"
#import "PixelBufferView.h"
#import "FBTweakInline.h"
#import "FeatureSwitches.h"

@interface WitnessInstructionsViewController () <AVPlayerItemLegibleOutputPushDelegate>
@property (weak, nonatomic, readwrite) IBOutlet UIButton *replayInstructionsButton;
@property (weak, nonatomic, readwrite) IBOutlet UIButton *confirmInstructionsButton;
@property (weak, nonatomic, readwrite) IBOutlet PixelBufferView *moviePixelBufferView;
@property (weak, nonatomic, readwrite) IBOutlet PlayerView *playerView;
@property (strong, nonatomic) AVPlayer *avPlayer;
@property (weak, nonatomic, readwrite) IBOutlet UILabel *confirmationPromptLabel;
@property (weak, nonatomic, readwrite) IBOutlet SubtitlesView *subtitlesView;
@property (strong, nonatomic) ScreenCaptureService *screenCaptureService;
@property (nonatomic, weak) id<WitnessInstructionsViewControllerDelegate> delegate;

@property (strong, nonatomic) CADisplayLink *displayLink;
@property (strong, nonatomic) AVPlayerItemVideoOutput *videoOutput;
@end

@implementation WitnessInstructionsViewController

- (void)dealloc {
    [self.avPlayer removeObserver:self forKeyPath:@"rate" context:NULL];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    if ([FeatureSwitches allowSkippingInstructionalVideoEnabled]) {
        UIButton *demoSkipButton = [UIButton buttonWithType:UIButtonTypeSystem];
        demoSkipButton.translatesAutoresizingMaskIntoConstraints = NO;
        [demoSkipButton setTitle:@"Demo Only - Skip" forState:UIControlStateNormal];
        [demoSkipButton sizeToFit];
        [demoSkipButton addTarget:self action:@selector(demoSkipButtonTapped) forControlEvents:UIControlEventTouchUpInside];
        [self.view addSubview:demoSkipButton];
        [self.view addConstraint:[NSLayoutConstraint constraintWithItem:demoSkipButton
                                                              attribute:NSLayoutAttributeBottom
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self.bottomLayoutGuide
                                                              attribute:NSLayoutAttributeBottom
                                                             multiplier:1
                                                               constant:-10]];
        [self.view addConstraint:[NSLayoutConstraint constraintWithItem:demoSkipButton
                                                              attribute:NSLayoutAttributeRight
                                                              relatedBy:NSLayoutRelationEqual
                                                                 toItem:self.view
                                                              attribute:NSLayoutAttributeRight
                                                             multiplier:1
                                                               constant:-10]];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self localizeStrings];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    [self.screenCaptureService captureFrame];

    [self.avPlayer play];
    [self.delegate witnessInstructionsViewControllerStartedPlayback:self];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.avPlayer pause];
    [self.displayLink invalidate];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:AVPlayerItemDidPlayToEndTimeNotification
                                                  object:self.avPlayer];
}

- (void)configureWithDelegate:(id <WitnessInstructionsViewControllerDelegate>)delegate
         screenCaptureService:(ScreenCaptureService *)screenCaptureService
                     avPlayer:(AVPlayer *)avPlayer {
    self.delegate = delegate;
    self.avPlayer = avPlayer;
    self.avPlayer.closedCaptionDisplayEnabled = YES;
    self.avPlayer.actionAtItemEnd = AVPlayerActionAtItemEndPause;
    [self.avPlayer addObserver:self forKeyPath:@"rate" options:NSKeyValueObservingOptionOld context:NULL];

    [self selectPlayerMediaOptions];
    [self addPlayerSubtitlesOutput];

    self.playerView.player = self.avPlayer;

    self.videoOutput = [[AVPlayerItemVideoOutput alloc] initWithPixelBufferAttributes:@{ (id)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA) }];
    [self.avPlayer.currentItem addOutput:self.videoOutput];

    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(showFrame)];
    [self.displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];

    self.screenCaptureService = screenCaptureService;
}

- (void)showFrame {
    CMTime time = self.avPlayer.currentItem.currentTime;
    if ([self.videoOutput hasNewPixelBufferForItemTime:time]) {
        CVPixelBufferRef pixelBuffer = [self.videoOutput copyPixelBufferForItemTime:time itemTimeForDisplay:nil];
        if (!pixelBuffer) { return; }

        self.moviePixelBufferView.pixelBuffer = pixelBuffer;
        CVPixelBufferRelease(pixelBuffer);
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == self.avPlayer && [keyPath isEqualToString:@"rate"]) {
        float oldRate = [change[NSKeyValueChangeOldKey] floatValue];
        if (self.avPlayer.rate == 0 && oldRate > 0) {
            self.replayInstructionsButton.enabled = YES;
            self.confirmInstructionsButton.enabled = YES;
            [self.delegate witnessInstructionsViewControllerStoppedPlayback:self];
            [self.avPlayer prerollAtRate:1 completionHandler:NULL];
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - <AVPlayerItemLegibleOutputPushDelegate>

- (void)legibleOutput:(AVPlayerItemLegibleOutput *)output didOutputAttributedStrings:(NSArray *)attributedStrings nativeSampleBuffers:(NSArray *)nativeSamples forItemTime:(CMTime)itemTime {
    NSArray *strings = [attributedStrings valueForKey:@"string"];
    self.subtitlesView.text = [strings componentsJoinedByString:@"\n"];
}

#pragma mark - private

- (IBAction)replayInstructionsTapped:(id)sender {
    [self.avPlayer pause];
    [self.avPlayer seekToTime:kCMTimeZero];
    [self.avPlayer play];
    [self.delegate witnessInstructionsViewControllerStartedPlayback:self];
}

- (void)demoSkipButtonTapped {
    [self performSegueWithIdentifier:@"CompleteInstructions" sender:nil];
}

- (void)localizeStrings {
    self.confirmationPromptLabel.text = WitnessLocalizedString(@"Do you understand these instructions?", nil);
    [self.confirmInstructionsButton setTitle:WitnessLocalizedString(@"I UNDERSTAND", nil) forState:UIControlStateNormal];
    [self.replayInstructionsButton setTitle:WitnessLocalizedString(@"REPLAY", nil) forState:UIControlStateNormal];
}

- (void)selectPlayerMediaOptions {
    [self selectAudioTrack];
    [self selectSubtitleTrack];
}

- (void)selectSubtitleTrack {
    AVMediaSelectionGroup *subtitleSelectionGroup = [self.avPlayer.currentItem.asset mediaSelectionGroupForMediaCharacteristic:AVMediaCharacteristicLegible];
    NSArray *subtitleFilteredOptions = [AVMediaSelectionGroup mediaSelectionOptionsFromArray:[subtitleSelectionGroup options]
                                      filteredAndSortedAccordingToPreferredLanguages:@[[WitnessLocalization witnessLanguageCode]]];

    if ([subtitleFilteredOptions count] > 1) {
        subtitleFilteredOptions = [AVMediaSelectionGroup mediaSelectionOptionsFromArray:subtitleFilteredOptions withoutMediaCharacteristics:@[AVMediaCharacteristicContainsOnlyForcedSubtitles]];
    }

    [self.avPlayer.currentItem selectMediaOption:subtitleFilteredOptions.firstObject inMediaSelectionGroup:subtitleSelectionGroup];
}

- (void)selectAudioTrack {
    AVMediaSelectionGroup *audioSelectionGroup = [self.avPlayer.currentItem.asset mediaSelectionGroupForMediaCharacteristic:AVMediaCharacteristicAudible];
    NSArray *audioFilteredOptions = [AVMediaSelectionGroup mediaSelectionOptionsFromArray:[audioSelectionGroup options]
                                      filteredAndSortedAccordingToPreferredLanguages:@[[WitnessLocalization witnessLanguageCode]]];

    [self.avPlayer.currentItem selectMediaOption:audioFilteredOptions.firstObject inMediaSelectionGroup:audioSelectionGroup];
}

- (void)addPlayerSubtitlesOutput {
    AVPlayerItemLegibleOutput *subtitlesOutput = [[AVPlayerItemLegibleOutput alloc] init];
    subtitlesOutput.suppressesPlayerRendering = YES;
    [subtitlesOutput setDelegate:self queue:dispatch_get_main_queue()];
    [self.avPlayer.currentItem addOutput:subtitlesOutput];
}

@end
