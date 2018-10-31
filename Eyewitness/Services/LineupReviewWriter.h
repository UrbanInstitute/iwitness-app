#import <Foundation/Foundation.h>

@class Presentation;

@interface LineupReviewWriter : NSObject
- (void)writeLineupReviewForPresentation:(Presentation *)presentation;
@end