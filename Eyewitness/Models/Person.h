#import <Foundation/Foundation.h>

@class Portrayal;

@interface Person : NSObject <NSCoding, NSCopying>

@property (nonatomic, strong, readonly) NSDate *dateOfBirth;
@property (nonatomic, copy, readonly) NSString *systemID;
@property (nonatomic, copy) NSString *firstName;
@property (nonatomic, copy) NSString *lastName;
@property (nonatomic, copy) NSArray *portrayals;
@property (nonatomic, strong) Portrayal *selectedPortrayal;

- (instancetype)initWithFirstName:(NSString *)firstName
                         lastName:(NSString *)lastName
                      dateOfBirth:(NSDate *)dateOfBirth
                         systemID:(NSString *)systemID
                        portrayals:(NSArray *)portrayals;

- (NSString *)fullName;
@end
