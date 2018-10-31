#import "Lineup.h"
#import "NSURL+RelativeSandboxPaths.h"
#import "Person.h"
#import "PerpetratorDescription.h"
#import "Portrayal.h"

@interface Lineup ()
@property (nonatomic, copy, readwrite) NSString *UUID;
@property (nonatomic, strong, readwrite) NSDate *creationDate;
@end

static const NSUInteger kMinimumNumberOfFillerPhotos = 5;
static const NSUInteger kMaximumNumberOfFillerPhotos = 12;

@implementation Lineup

#pragma mark - <NSCoding>

- (id)init {
    return [self initWithCreationDate:[NSDate date] suspect:[[Person alloc] init] ];
}

- (instancetype)initWithCreationDate:(NSDate *)creationDate suspect:(Person *)suspect {
    if (!creationDate) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"initWithCreationDate: must be given a date" userInfo:nil];
    }

    if (self = [super init]) {
        self.UUID = [[NSUUID UUID] UUIDString];
        self.creationDate = creationDate;
        self.suspect = suspect;
        self.perpetratorDescription = [[PerpetratorDescription alloc] init];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
    if (self = [super init]) {
        self.UUID = [decoder decodeObjectForKey:@"UUID"];
        self.caseID = [decoder decodeObjectForKey:@"caseID"];
        self.creationDate = [decoder decodeObjectForKey:@"creationDate"];
        self.fillerPhotosFileURLs = [self fileURLsForRelativePaths:[decoder decodeObjectForKey:@"fillerPhotosFileURLs"]];
        self.suspect = [decoder decodeObjectForKey:@"suspect"];
        if(self.suspect)
        {
            NSArray * susPhotoId = [decoder decodeObjectForKey:@"susPhotoId"];
            if(susPhotoId) //MOK hack fix for non relative path
            {
                [self.suspect.selectedPortrayal setSusPhotoId:[self fileURLsForRelativePaths:susPhotoId][0]];
            }
        }
        self.fromDB = [decoder decodeBoolForKey:@"fromDB"];
        self.audioOnly = [decoder decodeBoolForKey:@"audioOnly"];
        self.perpetratorDescription = [decoder decodeObjectForKey:@"perpetratorDescription"];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.UUID forKey:@"UUID"];
    if (self.caseID) { [coder encodeObject:self.caseID forKey:@"caseID"]; }
    if (self.creationDate) { [coder encodeObject:self.creationDate forKey:@"creationDate"]; }
    if (self.fillerPhotosFileURLs) { [coder encodeObject:[self relativePathsForFileURLs:self.fillerPhotosFileURLs] forKey:@"fillerPhotosFileURLs"]; }
    if (self.suspect)
    {

        if(self.suspect.selectedPortrayal)
        {
            NSArray * susPhotoId = [self relativePathsForFileURLs:@[self.suspect.selectedPortrayal.photoURL]];
            [coder encodeObject:susPhotoId forKey:@"susPhotoId"];
        }
        [coder encodeObject:self.suspect forKey:@"suspect"];
    };
    [coder encodeBool:self.fromDB forKey:@"fromDB"];
    [coder encodeBool:self.audioOnly forKey:@"audioOnly"];
    [coder encodeObject:self.perpetratorDescription forKey:@"perpetratorDescription"];
}

+ (NSUInteger)minimumNumberOfFillerPhotos {
    return kMinimumNumberOfFillerPhotos;
}

+ (NSUInteger)maximumNumberOfFillerPhotos {
    return kMaximumNumberOfFillerPhotos;
}

- (BOOL)isValid {
    if (self.suspect.selectedPortrayal.photoURL && self.fillerPhotosFileURLs.count >= kMinimumNumberOfFillerPhotos) {
        return YES;
    }
    return NO;
}

- (BOOL)isEqual:(Lineup *)other {
    if (![other isKindOfClass:[Lineup class]]) { return NO; }

    if (self.audioOnly != other.audioOnly) { return NO; }

    if (![(self.caseID ?: @"") isEqual:(other.caseID ?: @"")]) { return NO; }

    if (![self.suspect isEqual:other.suspect] && (self.suspect != other.suspect)) { return NO; }

    if (![self.creationDate isEqual:other.creationDate] && (self.creationDate != other.creationDate)) { return NO; }

    if (![self.perpetratorDescription isEqual:other.perpetratorDescription] && (self.perpetratorDescription != other.perpetratorDescription)) { return NO; }

    if (![self.fillerPhotosFileURLs isEqual:other.fillerPhotosFileURLs] && (self.fillerPhotosFileURLs != other.fillerPhotosFileURLs)) { return NO; }

    return YES;
}

- (NSUInteger)hash {
    NSUInteger prime = 31;
    NSUInteger result = 1;

    result += prime * [self.caseID hash];
    result += prime * [self.suspect hash];
    result += prime * [self.creationDate hash];
    result += prime * [self.perpetratorDescription hash];
    result += self.audioOnly;

    for(NSURL *url in self.fillerPhotosFileURLs) {
        result += prime * [url hash];
    }

    return result;
}

- (id)copyWithZone:(NSZone *)zone {
    Lineup *copy = [[Lineup allocWithZone:zone] initWithCreationDate:self.creationDate
                                                             suspect:[self.suspect copyWithZone:zone]];
    copy.UUID = self.UUID;
    copy.caseID = self.caseID;
    copy.fillerPhotosFileURLs = self.fillerPhotosFileURLs;
    copy.fromDB = self.fromDB;
    copy.audioOnly = self.audioOnly;
    copy.perpetratorDescription = [self.perpetratorDescription copyWithZone:zone];
    return copy;
}

- (NSString *)description {
    return [[super description] stringByAppendingFormat:@" caseID: %@\n"
                                                         "suspectName: %@\n"
                                                         "creationDate: %@\n"
                                                         "suspectPhotoFileURL: %@\n"
                                                         "fillerPhotosFileURLs: %@\n"
                                                         "valid: %d\n"
                                                         "fromDB: %d\n"
                                                         "audioOnly: %d\n"
                                                         "perpetratorDescription: %@",
                    self.caseID,
                    self.suspect.fullName,
                    self.creationDate,
                    self.suspect.selectedPortrayal.photoURL,
                    self.fillerPhotosFileURLs,
                    self.valid,
                    self.fromDB,
                    self.audioOnly,
                    self.perpetratorDescription
    ];
}

#pragma mark - private

- (NSArray *)relativePathsForFileURLs:(NSArray *)fileURLs {
    NSMutableArray *relativePaths = [[NSMutableArray alloc] init];
    for (NSURL *fileURL in fileURLs) {
        [relativePaths addObject:[fileURL pathRelativeToApplicationSandbox]];
    }
    return [relativePaths copy];
}

- (NSArray *)fileURLsForRelativePaths:(NSArray *)relativePaths {
    if (relativePaths) {
        NSMutableArray *fileURLs = [[NSMutableArray alloc] init];
        for (NSString *relativePath in relativePaths) {
            [fileURLs addObject:[NSURL fileURLFromPathRelativeToApplicationSandbox:relativePath]];
        }
        return [fileURLs copy];
    }
    return nil;
}

- (void)updateToMatchLineup:(Lineup *)lineup {
    self.perpetratorDescription = [lineup.perpetratorDescription copy];
    self.suspect = [lineup.suspect copy];
    self.fromDB = lineup.fromDB;
    self.fillerPhotosFileURLs = lineup.fillerPhotosFileURLs;
    self.caseID = lineup.caseID;
    self.creationDate = lineup.creationDate;
    self.audioOnly = lineup.audioOnly;
}
@end
