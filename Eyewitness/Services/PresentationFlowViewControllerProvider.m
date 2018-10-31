#import "PresentationFlowViewControllerProvider.h"
#import "PresentationFlowViewController.h"
#import "CaptureSessionProvider.h"
#import "PresentationRecorderProvider.h"
#import "AudioLevelMeter.h"
#import "KioskModeService.h"
#import "VideoPreviewView.h"

@interface PresentationFlowViewControllerProvider ()
@property (nonatomic, strong) PresentationRecorderProvider *presentationRecorderProvider;
@property (nonatomic, strong) CaptureSessionProvider *captureSessionProvider;
@property (nonatomic, strong) PasswordValidator *passwordValidator;
@end

@implementation PresentationFlowViewControllerProvider

- (instancetype)initWithPresentationRecorderProvider:(PresentationRecorderProvider *)presentationRecorderProvider
                              captureSessionProvider:(CaptureSessionProvider *)captureSessionProvider
                                   passwordValidator:(PasswordValidator *)passwordValidator {
    if (self = [super init]) {
        self.presentationRecorderProvider = presentationRecorderProvider;
        self.captureSessionProvider = captureSessionProvider;
        self.passwordValidator = passwordValidator;
    }
    return self;
}

- (PresentationFlowViewController *)presentationFlowViewControllerWithPresentation:(Presentation *)presentation flowDelegate:(id<PresentationFlowViewControllerDelegate>)delegate {
    AVCaptureSession *captureSession = [self.captureSessionProvider captureSession];
    VideoPreviewView *videoPreviewView =  [[VideoPreviewView alloc] initWithCaptureSession:captureSession];
    PresentationRecorder *recorder = [self.presentationRecorderProvider presentationRecorderForPresentation:presentation captureSession:captureSession];
    PresentationFlowViewController *controller = [[UIStoryboard storyboardWithName:@"PresentationFlow" bundle:nil] instantiateInitialViewController];
    AudioLevelMeter *audioLevelMeter = [[AudioLevelMeter alloc] initWithCaptureSession:captureSession];
    KioskModeService *kioskModeService = [[KioskModeService alloc] init];

    [controller configureWithPresentation:presentation
                     presentationRecorder:recorder
                        passwordValidator:self.passwordValidator
                         videoPreviewView:videoPreviewView
                           captureSession:captureSession
                          audioLevelMeter:audioLevelMeter
                         kioskModeService:kioskModeService
                             audioSession:[AVAudioSession sharedInstance]
                             flowDelegate:delegate];
    return controller;
}

@end
