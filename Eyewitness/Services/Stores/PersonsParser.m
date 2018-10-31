#import "PersonsParser.h"
#import "NSArray+PivotalCore.h"
#import "Person.h"
#import "Portrayal.h"

@implementation PersonsParser

- (NSArray *)parsePersonsFromDictionary:(NSDictionary *)dictionary {
    NSArray *personDicts = dictionary[@"persons"];
    return [personDicts collect:^id(NSDictionary *personDict) {
        NSString *dobString = personDict[@"dateOfBirth"];
        NSDate *dateOfBirth = [self.dateFormatter dateFromString:dobString];
        NSString *systemID = personDict[@"ID"];
        NSArray *portrayals = [personDict[@"portrayals"] collect:^Portrayal *(NSDictionary *portrayalDict) {
            return [[Portrayal alloc] initWithPhotoURL:[[NSBundle mainBundle] URLForResource:portrayalDict[@"photo"] withExtension:@"jpg" subdirectory:@"PhotoRecords"] date:[self.dateFormatter dateFromString:portrayalDict[@"date"]]];
        }];

        return [[Person alloc] initWithFirstName:personDict[@"firstName"]
                                        lastName:personDict[@"lastName"]
                                     dateOfBirth:dateOfBirth
                                        systemID:systemID
                                       portrayals:portrayals];
    }];
}

- (NSDateFormatter *)dateFormatter {
    static NSDateFormatter *dateFormatter;
    if (!dateFormatter) {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd"];
    }
    return dateFormatter;
}

@end
