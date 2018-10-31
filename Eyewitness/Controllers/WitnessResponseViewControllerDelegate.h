#import <Foundation/Foundation.h>

@class WitnessResponseViewController;

@protocol WitnessResponseViewControllerDelegate <NSObject>
- (void)qualifyUncertaintyViewControllerDidContinue:(WitnessResponseViewController *)controller;
- (void)qualifyIdentificationViewControllerDidContinue:(WitnessResponseViewController *)controller;
- (void)identificationCertaintyViewControllerDidContinue:(WitnessResponseViewController *)controller;
@end
