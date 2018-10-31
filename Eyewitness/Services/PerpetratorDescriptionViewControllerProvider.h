#import <Foundation/Foundation.h>

@class PerpetratorDescriptionViewController, PerpetratorDescription;

@interface PerpetratorDescriptionViewControllerProvider : NSObject

- (PerpetratorDescriptionViewController *)perpetratorDescriptionViewControllerWithCaseID:(NSString *)caseID perpetratorDescription:(PerpetratorDescription *)perpetratorDescription;

@end
