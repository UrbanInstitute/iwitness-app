#import "PersonsLoader.h"
#import "PersonsParser.h"

@interface PersonsLoader ()
@property (nonatomic, strong) NSURL *fileURL;
@property (nonatomic, strong) PersonsParser *parser;
@end

@implementation PersonsLoader

- (instancetype)initWithFileURL:(NSURL *)fileURL parser:(PersonsParser *)parser {
    if (self = [super init]) {
        self.fileURL = fileURL;
        self.parser = parser;
    }
    return self;
}

- (NSArray *)loadPersons {
    NSData *fileData = [NSData dataWithContentsOfURL:self.fileURL];
    NSDictionary *personsJSON = (NSDictionary *)[NSJSONSerialization JSONObjectWithData:fileData options:0 error:NULL];
    return [self.parser parsePersonsFromDictionary:personsJSON];
}

@end
