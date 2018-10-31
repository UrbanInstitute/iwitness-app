#import <Foundation/Foundation.h>

@class PreparationViewController;

@protocol PreparationViewControllerDelegate <NSObject>
- (void)preparationViewControllerDidPresentOfficerIdentification:(PreparationViewController *)controller;
- (void)preparationViewControllerWillHideVideoPreview:(PreparationViewController *)controller;
@optional
- (void)preparationViewControllerDidShowVideoPreview:(PreparationViewController *)controller;
@end
