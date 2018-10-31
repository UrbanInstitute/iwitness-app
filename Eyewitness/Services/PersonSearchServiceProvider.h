#import <Foundation/Foundation.h>

@class PersonSearchService;

@interface PersonSearchServiceProvider : NSObject

- (PersonSearchService *)personSearchService;
@end
