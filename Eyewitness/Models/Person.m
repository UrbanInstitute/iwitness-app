#import "Person.h"
#import "Portrayal.h"

@interface Person ()
@property (nonatomic, strong, readwrite) NSDate *dateOfBirth;
@property (nonatomic, copy, readwrite) NSString *systemID;
@end

@implementation Person
- (instancetype)initWithFirstName:(NSString *)firstName
                         lastName:(NSString *)lastName
                      dateOfBirth:(NSDate *)dateOfBirth
                         systemID:(NSString *)systemID
                        portrayals:(NSArray *)portrayals {
    if (self = [super init]) {
        self.firstName = firstName;
        self.lastName = lastName;
        self.dateOfBirth = dateOfBirth;
        self.systemID = systemID;
        self.portrayals = portrayals;
    }
    return self;
}

- (BOOL)isEqual:(Person *)other {
    if (self == other) { return YES; }
    if (![other isKindOfClass:[Person class]]) { return NO; }
    if (![(self.firstName ?: @"") isEqualToString:(other.firstName ?: @"")]) { return NO; }
    if (![(self.lastName ?: @"") isEqualToString:(other.lastName ?: @"")]) { return NO; }
    if (![self.dateOfBirth isEqualToDate:other.dateOfBirth] && (self.dateOfBirth != other.dateOfBirth)) { return NO; }
    if (![self.systemID isEqualToString:other.systemID] && (self.systemID != other.systemID)) { return NO; }
    if (![self.selectedPortrayal isEqual:other.selectedPortrayal] && (self.selectedPortrayal != other.selectedPortrayal)) { return NO; }

    return YES;
}

- (NSUInteger)hash {
    NSUInteger prime = 31;
    NSUInteger result = 1;

    result += prime * [self.firstName hash];
    result += prime * [self.lastName hash];
    result += prime * [self.dateOfBirth hash];
    result += prime * [self.systemID hash];
    result += prime * [self.selectedPortrayal hash];
    return result;
}

- (id)copyWithZone:(NSZone *)zone {
    Person *copy = [[Person allocWithZone:zone] initWithFirstName:self.firstName lastName:self.lastName dateOfBirth:self.dateOfBirth systemID:self.systemID portrayals:self.portrayals];
    copy.selectedPortrayal = [self.selectedPortrayal copy];
    return copy;
}

- (NSString *)fullName {
    if (self.firstName && self.lastName) {
        return [self.firstName stringByAppendingFormat:@" %@", self.lastName];
    } else {
        return self.firstName ?: self.lastName;
    }
}

- (Portrayal *)selectedPortrayal {
    if (_selectedPortrayal) {
        return _selectedPortrayal;
    }
    return self.portrayals.firstObject;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ %@, DOB: %@, systemID: %@, portrayals: %@, selectedPortrayal: %@", self.firstName, self.lastName, self.dateOfBirth, self.systemID, self.portrayals, self.selectedPortrayal];
}

#pragma mark - <NSCoding>

- (void)encodeWithCoder:(NSCoder *)coder {
    if (self.firstName) {[coder encodeObject:self.firstName forKey:@"firstName"];}
    if (self.lastName) {[coder encodeObject:self.lastName forKey:@"lastName"];}
    if (self.dateOfBirth) {[coder encodeObject:self.dateOfBirth forKey:@"dateOfBirth"];}
    if (self.systemID) {[coder encodeObject:self.systemID forKey:@"systemID"];}
    if (self.selectedPortrayal) {[coder encodeObject:self.selectedPortrayal forKey:@"selectedPortrayal"];}
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
    if (self = [super init]) {
        self.firstName = [decoder decodeObjectForKey:@"firstName"];
        self.lastName = [decoder decodeObjectForKey:@"lastName"];
        self.dateOfBirth = [decoder decodeObjectForKey:@"dateOfBirth"];
        self.systemID = [decoder decodeObjectForKey:@"systemID"];
        self.selectedPortrayal = [decoder decodeObjectForKey:@"selectedPortrayal"];
    }
    return self;
}

@end
