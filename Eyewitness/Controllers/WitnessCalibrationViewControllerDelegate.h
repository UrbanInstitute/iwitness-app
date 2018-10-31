#import <Foundation/Foundation.h>

@class WitnessCalibrationViewController;

@protocol WitnessCalibrationViewControllerDelegate <NSObject>
- (void)witnessCalibrationViewControllerDidContinue:(WitnessCalibrationViewController *)controller;
@end
