#import <Foundation/Foundation.h>

@class SuspectPhotoDetailViewController;
@class Portrayal;

@protocol SuspectPhotoDetailViewControllerDelegate <NSObject>
- (void)suspectPhotoDetailViewControllerDidCancel:(SuspectPhotoDetailViewController *)controller;
- (void)suspectPhotoDetailViewController:(SuspectPhotoDetailViewController *)controller didSelectPortrayal:(Portrayal *)portrayal;
@end