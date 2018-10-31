#import <Foundation/Foundation.h>

@class SuspectPortrayalsViewController, Person;

@interface SuspectPortrayalsViewControllerProvider : NSObject

- (SuspectPortrayalsViewController *)suspectPortrayalsViewControllerWithPerson:(Person *)person;
@end
