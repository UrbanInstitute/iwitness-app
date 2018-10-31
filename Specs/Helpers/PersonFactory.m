#import "PersonFactory.h"
#import "Person.h"
#import "Portrayal.h"

@implementation PersonFactory

+ (Person *)leon {
    NSArray *portrayals = @[
                            [self portrayalWithResourceName:@"463672-0" date:@"2012-08-08"],
                            [self portrayalWithResourceName:@"463672-1" date:@"2007-09-14"]
                            ];

    return [[Person alloc] initWithFirstName:@"Leon"
                                    lastName:@"Lewis"
                                 dateOfBirth:[NSDate dateWithTimeIntervalSince1970:159253200]
                                    systemID:@"463672"
                                  portrayals:portrayals];
}

+ (Person *)larry {
    NSArray *portrayals = @[
            [self portrayalWithResourceName:@"800740-0" date:@"2013-09-16"],
            [self portrayalWithResourceName:@"800740-1" date:@"2008-12-17"]
    ];

    return [[Person alloc] initWithFirstName:@"Larry"
                                    lastName:@"Garcia"
                                 dateOfBirth:[NSDate dateWithTimeIntervalSince1970:472107600]
                                    systemID:@"4636"
                                  portrayals:portrayals];
}

+ (Portrayal *)portrayalWithResourceName:(NSString *)resourceName date:(NSString *)dateString {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"YYYY-MM-dd";
    return [[Portrayal alloc] initWithPhotoURL:[[NSBundle mainBundle] URLForResource:resourceName withExtension:@"jpg" subdirectory:@"PhotoRecords"] date:[dateFormatter dateFromString:dateString]];
}
@end