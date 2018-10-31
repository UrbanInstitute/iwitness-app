#import <Foundation/Foundation.h>

@class PersonsLoader;

@interface PersonSearchService : NSObject

- (instancetype)initWithPersonsLoader:(PersonsLoader *)loader;

- (KSPromise *)personResultsForFirstName:(NSString *)firstName lastName:(NSString *)lastName suspectID:(NSString *)suspectID;

@end
