#import <UIKit/UIKit.h>
#import "SuspectPortrayalsView.h"
#import "SuspectPhotoDetailViewControllerDelegate.h"

@class Person;

@interface SuspectPortrayalsViewController : UIViewController <SuspectPhotoDetailViewControllerDelegate>

@property (nonatomic, retain) SuspectPortrayalsView *view;
@property (nonatomic, strong, readonly) Person *person;

- (void)configureWithPerson:(Person *)person;

@end
