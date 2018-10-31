#import "PerpetratorDescription.h"

@implementation PerpetratorDescription

- (instancetype)init {
    self = [super init];
    if (self) {
        self.additionalNotes = @"";
    }
    return self;
}

- (BOOL)isEqual:(PerpetratorDescription *)other {
    if (self == other) { return YES; }

    if (![self.additionalNotes isEqualToString:other.additionalNotes] && (self.additionalNotes != other.additionalNotes)) { return NO; }

    return YES;
}

- (NSUInteger)hash {
    return self.additionalNotes.hash;
}

#pragma mark - <NSCoding>

- (instancetype)initWithCoder:(NSCoder *)decoder {
    if (self = [super init]) {
        self.additionalNotes = [decoder decodeObjectForKey:@"additionalNotes"];
    }

    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:self.additionalNotes forKey:@"additionalNotes"];
}

#pragma mark - <NSCopying>

- (instancetype)copyWithZone:(NSZone *)zone {
    PerpetratorDescription *description = [[PerpetratorDescription allocWithZone:zone] init];
    description.additionalNotes = self.additionalNotes;
    return description;
}


@end
