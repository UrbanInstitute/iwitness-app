#import <Foundation/Foundation.h>

@class WitnessIdentificationViewController;

@protocol WitnessIdentificationViewControllerDelegate <NSObject>
- (void)witnessIdentificationViewControllerDidContinue:(WitnessIdentificationViewController *)controller;
@end
