#import <Foundation/Foundation.h>

@class PersonsParser;

@interface PersonsLoader : NSObject

- (instancetype)initWithFileURL:(NSURL *)fileURL parser:(PersonsParser *)parser;
- (NSArray *)loadPersons;

@end
