#import <Foundation/Foundation.h>

@class OfficerCalibrationViewController;

@protocol OfficerCalibrationViewControllerDelegate <NSObject>
- (void)officerCalibrationViewControllerDidCancel:(OfficerCalibrationViewController *)controller;
- (void)officerCalibrationViewControllerDidContinue:(OfficerCalibrationViewController *)controller;
@end
