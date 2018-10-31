#import <Foundation/Foundation.h>

@class OfficerIdentificationViewController;

@protocol OfficerIdentificationViewControllerDelegate <NSObject>
- (void)officerIdentificationViewControllerDidContinue:(OfficerIdentificationViewController *)controller;
- (void)officerIdentificationViewControllerDidAppear:(OfficerIdentificationViewController *)controller;
@end
