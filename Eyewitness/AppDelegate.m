#import "AppDelegate.h"
#import "EyewitnessTheme.h"
#import "NSFileManager+CommonDirectories.h"
#import "StitchingRestarter.h"
#import "LineupStore.h"
#import "PresentationStore.h"
#import "RecordingTimeAvailableCalculatorProvider.h"
#import "LineupsViewController.h"
#import "PresentationsViewController.h"
#import "StitchingQueue.h"
#import "ScreenCaptureService.h"
#import "PasswordValidator.h"
#import "PresentationFlowViewControllerProvider.h"
#import "PresentationRecorderProvider.h"
#import "CaptureSessionProvider.h"
#import "FaceLocatorProvider.h"
#import "PhotoAssetImporter.h"
#import "PhotoAssetMetadataManager.h"
#import "LineupViewControllerConfigurer.h"
#import "VideoStitcherProvider.h"
//#import <Crashlytics/Crashlytics.h>
//MOK REMOVED
//#if FB_TWEAK_ENABLED || DEBUG
//#import "FBTweakShakeWindow.h"
//#if DEBUG
//#import "FBTweakStore.h"
//#import "FBTweakCategory.h"
//#import "FBTweakCollection.h"
//#import "FBTweak.h"
//#endif
//#endif

@interface AppDelegate ()

@property (nonatomic, strong) PresentationStore *presentationStore;
@property (nonatomic, strong) StitchingQueue *stitchingQueue;
@property (nonatomic, strong) StitchingRestarter *stitchingRestarter;

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
#ifndef FRANKIFIED
#if TARGET_IPHONE_SIMULATOR
    if (!NSClassFromString(@"CDRSpec")) {
        NSArray *URLStrings = @[
                                @"http://cdn.memegenerator.net/instances/500x/9118489.jpg",
                                @"http://thercs.net/starr/cats/leeroy%20jenkins%20cat.jpg",
                                @"http://i0.kym-cdn.com/photos/images/original/000/100/128/happycat.gif?1318992465",
                                @"http://4.bp.blogspot.com/_6xoH967aC00/TLsx5lqoGFI/AAAAAAAAaxk/sa7x2ZuYGzU/s400/cat084.jpg",
                                @"http://www.ukmandown.co.uk/e107_files/public/1362228264_939_FT85242_caturday-oreally.jpg"
                                ];
        for (NSString *imageURLString in URLStrings) {
            UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:imageURLString]]];
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, NULL);
        }
    }
#endif
#endif

//#if !(DEBUG || TARGET_IPHONE_SIMULATOR)
//MOK Removed
//    [Crashlytics startWithAPIKey:@"1312c7dbfeb503615880586bffd4f1efae586dc6"];
//#endif

    [self configureAppearance];

//#if FB_TWEAK_ENABLED || DEBUG
//#if DEBUG
/*
 for(FBTweakCollection *collection in [[FBTweakStore sharedInstance] tweakCategoryWithName:@"Feature Switches"].tweakCollections) {
        for(FBTweak *tweak in collection.tweaks) {
            tweak.currentValue = @(YES);
        }
    }
 */
//#endif
//    self.window = [[FBTweakShakeWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
//#else
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
//#endif

    UIViewController *initialViewController = [[UIStoryboard storyboardWithName:@"AdminFlow" bundle:nil] instantiateInitialViewController];
    self.window.tintColor = [EyewitnessTheme primaryColor];
    self.window.rootViewController = initialViewController;
    self.window.backgroundColor = [UIColor whiteColor];

    self.presentationStore = [[PresentationStore alloc] initWithStoreURL:[PresentationStore defaultStoreURL] fileManager:[[NSFileManager alloc] init]];
    self.stitchingQueue = [[StitchingQueue alloc] initWithVideoStitcherProvider:[[VideoStitcherProvider alloc] init]];

    self.stitchingRestarter = [[StitchingRestarter alloc] initWithPresentationStore:self.presentationStore stitchingQueue:self.stitchingQueue];
    return YES;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [self configureInitialViewControllers];

    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];

    [self.stitchingRestarter restartIncompleteStitches];

    [self.window makeKeyAndVisible];

    [self resetKioskMode];

    return YES;
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    [self.stitchingRestarter restartIncompleteStitches];
}

#pragma mark - private

- (void)configureInitialViewControllers {
    LineupStore *lineupStore = [[LineupStore alloc] initWithStoreURL:[LineupStore defaultStoreURL]];

    RecordingTimeAvailableCalculatorProvider *calculatorProvider = [[RecordingTimeAvailableCalculatorProvider alloc] initWithScreenCaptureService:[[ScreenCaptureService alloc] init]];
    RecordingTimeAvailableCalculator *timeAvailableCalculator = [calculatorProvider recordingTimeAvailableCalculator];

    NSURL *configurationURL = [[NSBundle mainBundle] URLForResource:@"configuration" withExtension:@"plist"];
    NSDictionary *configuration = [NSDictionary dictionaryWithContentsOfURL:configurationURL];
    NSString *correctPassword = configuration[@"officerPassword"];

    PasswordValidator *passwordValidator = [[PasswordValidator alloc] initWithCorrectPassword:correctPassword];
    PresentationRecorderProvider *recorderProvider = [[PresentationRecorderProvider alloc] initWithStitchingQueue:self.stitchingQueue];
    PresentationFlowViewControllerProvider *presentationFlowViewControllerProvider = [[PresentationFlowViewControllerProvider alloc] initWithPresentationRecorderProvider:recorderProvider
                                                                                                                                                   captureSessionProvider:[[CaptureSessionProvider alloc] init]
                                                                                                                                                        passwordValidator:passwordValidator];

    FaceLocatorProvider *faceLocatorProvider = [[FaceLocatorProvider alloc] init];
    PhotoAssetImporter *photoAssetImporter = [[PhotoAssetImporter alloc] initWithDestinationDirectory:[[NSFileManager defaultManager] URLForLineupPhotos]
                                                                                          faceLocator:[faceLocatorProvider faceLocator]
                                                                                      metadataManager:[[PhotoAssetMetadataManager alloc] init]];

    LineupsViewController *lineupsViewController = (LineupsViewController *)[self.window.rootViewController.childViewControllers[0] topViewController];

    LineupViewControllerConfigurer *lineupViewControllerConfigurer = [[LineupViewControllerConfigurer alloc] initWithLineupStore:lineupStore
                                                                                                              photoAssetImporter:photoAssetImporter
                                                                                                                        delegate:lineupsViewController];

    [lineupsViewController configureWithPresentationFlowViewControllerProvider:presentationFlowViewControllerProvider
                                                                   lineupStore:lineupStore
                                                             presentationStore:self.presentationStore
                                              recordingTimeAvailableCalculator:timeAvailableCalculator
                                                lineupViewControllerConfigurer:lineupViewControllerConfigurer];

    PresentationsViewController *presentationsViewController = (PresentationsViewController *)[self.window.rootViewController.childViewControllers[1] topViewController];
    [presentationsViewController configureWithPresentationStore:self.presentationStore
                               recordingTimeAvailableCalculator:timeAvailableCalculator
                                                 stitchingQueue:self.stitchingQueue];

}

- (void)configureAppearance {
    [[UINavigationBar appearance] setTitleTextAttributes:@{NSFontAttributeName : [EyewitnessTheme toolbarFont],
                                                           NSForegroundColorAttributeName : [EyewitnessTheme darkerGrayColor]}];
    [[UIBarButtonItem appearance] setTitleTextAttributes:@{NSFontAttributeName: [EyewitnessTheme toolbarFont]} forState:UIControlStateNormal];
}

- (void)resetKioskMode {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^(void){
        UIAccessibilityRequestGuidedAccessSession(NO, NULL);
    });
}

@end
