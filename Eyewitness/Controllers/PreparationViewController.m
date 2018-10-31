#import "PreparationViewController.h"
#import "RecordingTimeAvailableCalculator.h"
#import "RecordingTimeAvailableFormatter.h"
#import "EyewitnessTheme.h"
#import "PreparationViewControllerDelegate.h"
#import "OfficerIdentificationViewController.h"
#import "AudioLevelMeter.h"
#import "OfficerCalibrationViewController.h"
#import "VideoPreviewView.h"
#import "WitnessCalibrationViewController.h"
#import "WitnessIdentificationViewController.h"

@interface PreparationViewController ()
@property (nonatomic, weak, readwrite) IBOutlet UIView *embedContainerView;
@property (nonatomic, weak, readwrite) IBOutlet UIView *outerVideoPreviewContainerView;
@property (nonatomic, weak, readwrite) IBOutlet UIView *videoPreviewContainerView;
@property (nonatomic, weak, readwrite) IBOutlet UIView *availableTimeLabelContainer;
@property (nonatomic, weak, readwrite) IBOutlet UILabel *availableTimeLabel;
@property (nonatomic, weak, readwrite) IBOutlet UIBarButtonItem *cancelButton;
@property (nonatomic, strong) RecordingTimeAvailableCalculator *recordingTimeAvailableCalculator;
@property (nonatomic, strong) AVAudioSession *audioSession;
@property (nonatomic, weak) id<PreparationViewControllerDelegate> delegate;
@property (nonatomic, strong) VideoPreviewView *videoPreviewView;
@property (nonatomic, strong) AudioLevelMeter *audioLevelMeter;
@property(nonatomic, copy) NSString *caseID;
@end

@implementation PreparationViewController

- (void)configureWithCaseID:(NSString *)caseID
           videoPreviewView:(VideoPreviewView *)videoPreviewView
            audioLevelMeter:(AudioLevelMeter *)audioLevelMeter
               audioSession:(AVAudioSession *)audioSession
                   delegate:(id <PreparationViewControllerDelegate>)delegate
        recordingTimeAvailableCalculator:(RecordingTimeAvailableCalculator *)recordingTimeAvailableCalculator {
    self.caseID = caseID;
    self.videoPreviewView = videoPreviewView;
    self.audioLevelMeter = audioLevelMeter;
    self.audioSession = audioSession;
    self.delegate = delegate;
    self.recordingTimeAvailableCalculator = recordingTimeAvailableCalculator;
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    if (self.videoPreviewView) {
        if (self.videoPreviewView.superview != self.videoPreviewContainerView) {
            [self.videoPreviewContainerView addSubview:self.videoPreviewView];
            NSDictionary *bindings = @{@"videoPreviewView" : self.videoPreviewView};
            [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[videoPreviewView]|"
                                                                              options:NSLayoutFormatAlignAllTop
                                                                              metrics:nil
                                                                                views:bindings]];
            [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[videoPreviewView]|"
                                                                              options:NSLayoutFormatAlignAllLeft
                                                                              metrics:nil
                                                                                views:bindings]];
        }
    } else {
        self.outerVideoPreviewContainerView.hidden = YES;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self performSegueWithIdentifier:@"embedOfficerCalibration" sender:self];
    [self configureAvailableTimeLabel];
    self.navigationItem.title = [@"Present Case ID: " stringByAppendingString:(self.caseID && ![self.caseID isBlank]) ? self.caseID : @"<unknown>"];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if ([self.delegate respondsToSelector:@selector(preparationViewControllerDidShowVideoPreview:)]) {
        [self.delegate preparationViewControllerDidShowVideoPreview:self];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.delegate preparationViewControllerWillHideVideoPreview:self];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.destinationViewController isKindOfClass:[OfficerCalibrationViewController class]]) {
        OfficerCalibrationViewController *controller = segue.destinationViewController;
        [controller configureWithAudioLevelMeter:self.audioLevelMeter
                                    audioSession:self.audioSession
                                        delegate:self];
    } else if ([segue.destinationViewController isKindOfClass:[OfficerIdentificationViewController class]]) {
            OfficerIdentificationViewController *controller = segue.destinationViewController;
            [controller configureWithAudioLevelMeter:self.audioLevelMeter delegate:self];
    } else if ([segue.destinationViewController isKindOfClass:[WitnessCalibrationViewController class]]) {
        WitnessCalibrationViewController *controller = segue.destinationViewController;
        [controller configureWithAudioLevelMeter:self.audioLevelMeter delegate:self];
    } else if ([segue.destinationViewController isKindOfClass:[WitnessIdentificationViewController class]]) {
        WitnessIdentificationViewController *controller = segue.destinationViewController;
        [controller configureWithAudioLevelMeter:self.audioLevelMeter delegate:self];
    } else {
        [super prepareForSegue:segue sender:sender];
    }
}

#pragma mark - <OfficerCalibrationViewControllerDelegate>

- (void)officerCalibrationViewControllerDidCancel:(OfficerCalibrationViewController *)controller {
    [self performSegueWithIdentifier:@"unwindPresentationCanceled" sender:self]; //TODO: kill this interface?
}

- (void)officerCalibrationViewControllerDidContinue:(OfficerCalibrationViewController *)controller {
    self.navigationItem.leftBarButtonItems = @[];
    self.availableTimeLabelContainer.hidden = YES;
    [self performSegueWithIdentifier:@"embedOfficerIdentification" sender:self];
}

#pragma mark - <OfficerIdentificationViewControllerDelegate>

- (void)officerIdentificationViewControllerDidContinue:(OfficerIdentificationViewController *)controller {
    [self performSegueWithIdentifier:@"embedWitnessCalibration" sender:self];
}

- (void)officerIdentificationViewControllerDidAppear:(OfficerIdentificationViewController *)controller {
    [self.delegate preparationViewControllerDidPresentOfficerIdentification:self];
}

#pragma mark - <WitnessCalibrationViewControllerDelegate>

- (void)witnessCalibrationViewControllerDidContinue:(WitnessCalibrationViewController *)controller {
    [self performSegueWithIdentifier:@"embedWitnessIdentification" sender:self];
}

#pragma mark - <WitnessIdentificationViewControllerDelegate>

- (void)witnessIdentificationViewControllerDidContinue:(WitnessIdentificationViewController *)controller {
    [self performSegueWithIdentifier:@"pushWitnessInstructions" sender:self];
}

#pragma mark - private

- (void)configureAvailableTimeLabel {
    NSUInteger minutesAvailable = [self.recordingTimeAvailableCalculator calculateAvailableMinutesOfRecordingTime];
    RecordingTimeAvailableFormatter *formatter = [[RecordingTimeAvailableFormatter alloc] init];
    formatter.fullMode = YES;
    NSString *timeString = [formatter stringFromTimeAvailable:minutesAvailable*60];

    self.availableTimeLabel.text = [NSString stringWithFormat:@"%@ of video left on device", timeString];

    if ([self.recordingTimeAvailableCalculator recordingTimeAvailableStatus] == RecordingTimeAvailableStatusWarning) {
        self.availableTimeLabel.textColor = [EyewitnessTheme warnColor];
    } else {
        self.availableTimeLabel.textColor = [EyewitnessTheme darkerGrayColor];
    }
}

@end
