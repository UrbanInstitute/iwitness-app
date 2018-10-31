#ifdef FRANKIFIED

#import "AppDelegate.h"
#import "HomeViewController.h"
#import "LineupStore.h"
#import "Lineup.h"
#import "Presentation.h"
#import "PresentationStore.h"
#import "Person.h"
#import "Portrayal.h"

@interface Presentation (Frankified)
- (void)setVideoURL:(NSURL *)URL;
@end

@interface PresentationStore (Frankified)
- (void)updatePresentation:(Presentation *)presentation;
@end

@interface AppDelegate (ForFrank)
- (void)configureInitialViewControllers;
@end

@implementation AppDelegate (Frankified)

- (void)addPhotosToPhotoLibrary {
    for (NSURL *photoURL in [self samplePhotoURLs]) {
        UIImage *image = [UIImage imageWithContentsOfFile:[photoURL path]];
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, NULL);
    }
}

- (void) resetViewControllers {
    self.window.hidden = YES;
    [self.window resignKeyWindow];

    HomeViewController *homeViewController = [[UIStoryboard storyboardWithName:@"AdminFlow" bundle:nil] instantiateInitialViewController];
    self.window.rootViewController = homeViewController;
    [self configureInitialViewControllers];

    [self.window makeKeyAndVisible];
}

- (void)createValidLineupAndRestart {
    LineupStore *lineupStore = [[LineupStore alloc] initWithStoreURL:[LineupStore defaultStoreURL]];
    Lineup *sampleLineup = [self sampleLineupWithValidity:YES];
    [lineupStore updateLineup:sampleLineup];

    [self resetViewControllers];
}

- (void)createInvalidLineupAndRestart {
    LineupStore *lineupStore = [[LineupStore alloc] initWithStoreURL:[LineupStore defaultStoreURL]];
    Lineup *sampleLineup = [self sampleLineupWithValidity:NO];
    [lineupStore updateLineup:sampleLineup];

    [self resetViewControllers];
}

- (void)createSamplePresentationAndRestart {
    PresentationStore *presentationStore = [[PresentationStore alloc] initWithStoreURL:[PresentationStore defaultStoreURL] fileManager:[NSFileManager defaultManager]];

    Lineup *sampleLineup = [self sampleLineupWithValidity:YES];
    Presentation *presentation = [presentationStore createPresentationWithLineup:sampleLineup];
    [presentation performSelector:@selector(setDate:) withObject:[NSDate dateWithTimeIntervalSince1970:1389558900]];
    [presentation performSelector:@selector(setVideoURL:) withObject:[[self frankBundle] URLForResource:@"stitched" withExtension:@"mov" subdirectory:@"SamplePresentation"]];
    [presentationStore updatePresentation:presentation];

    [self resetViewControllers];
}

- (Lineup *)sampleLineupWithValidity:(BOOL)valid {
    NSInteger numberOfFillers = valid ? 5 : 4;
    NSArray *photosURL = [self samplePhotoURLs];
    Portrayal *portrayal = [[Portrayal alloc] initWithPhotoURL:photosURL.firstObject date:[NSDate date]];
    Lineup *lineup = [[Lineup alloc] initWithCreationDate:[NSDate date]
                                                  suspect:[[Person alloc]
                                                           initWithFirstName:@"Harreh"
                                                           lastName:@"Pottah"
                                                           dateOfBirth:nil
                                                           systemID:nil
                                                           portrayals:@[portrayal]]];
    lineup.caseID = @"12345-6789";
    lineup.fillerPhotosFileURLs = [photosURL subarrayWithRange:NSMakeRange(1, numberOfFillers)];
    return lineup;
}

- (NSArray *)samplePhotoURLs {
    return [[self frankBundle] URLsForResourcesWithExtension:@"jpg" subdirectory:@"SampleLineup"];
}

- (NSBundle *)frankBundle {
    NSString *staticResourceBundlePath = [[NSBundle mainBundle] pathForResource: @"frank_static_resources.bundle" ofType: nil];
    return [NSBundle bundleWithPath:staticResourceBundlePath];
}

- (UIInterfaceOrientation) interfaceOrientationOfTopViewController {
    UIViewController *topViewController = self.window.rootViewController;
    while (topViewController.presentedViewController) {
        topViewController = topViewController.presentedViewController;
    }

    return topViewController.interfaceOrientation;
}

- (BOOL) isStatusBarHidden {
    return [UIApplication sharedApplication].statusBarHidden;
}

@end
#endif
