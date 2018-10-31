#import "Presentation.h"
#import "Lineup.h"
#import "PresentationStore.h"
#import "NSMutableArray+Randomization.h"
#import "NSURL+RelativeSandboxPaths.h"
#import "NSFileManager+CommonDirectories.h"
#import "StitchingQueue.h"
#import "Person.h"
#import "Portrayal.h"
#import "LineupReviewWriter.h"

static NSString *const kMovieFileExtension = @"mov";

static NSString *const kPDFFileExtension = @"pdf";

@interface Presentation () <NSCoding>
@property (nonatomic, copy, readwrite) NSString *UUID;
@property (nonatomic, strong, readwrite) NSDate *date;

@property (nonatomic, copy) NSArray *allPhotoURLs;
@property (nonatomic, assign, readwrite) NSInteger currentPhotoIndex;
@property (nonatomic, strong, readwrite) Lineup *lineup;
@end

@implementation Presentation

- (instancetype)initWithLineup:(Lineup *)lineup randomSeed:(unsigned int)seed {
    if (self = [super init]) {
        self.lineup = lineup;
        self.date = [NSDate date];

        NSMutableArray *randomizedPhotoURLs = [[lineup.fillerPhotosFileURLs randomizedArrayWithRandomSeed:seed] mutableCopy];

        if (lineup.suspect.selectedPortrayal.photoURL) {
            [randomizedPhotoURLs insertObject:lineup.suspect.selectedPortrayal.photoURL atRandomIndexInRange:NSMakeRange(1, randomizedPhotoURLs.count - 1) randomSeed:(unsigned) random()];
        }

        self.allPhotoURLs = randomizedPhotoURLs;
        self.UUID = [[NSUUID UUID] UUIDString];
    }
    return self;
}

- (NSURL *)temporaryWorkingDirectory {
    return [[[NSFileManager defaultManager] URLForApplicationSupportDirectory] URLByAppendingPathComponent:self.UUID];
}

- (NSURL *)temporaryCameraRecordingURL {
    NSURL *workingDirectory = [self temporaryWorkingDirectory];
    [[NSFileManager defaultManager] ensureDirectoryExistsAtURL:workingDirectory];
    return [workingDirectory URLByAppendingPathComponent:@"camera.mov"];
}

- (NSURL *)temporaryScreenCaptureURL {
    NSURL *workingDirectory = [self temporaryWorkingDirectory];
    [[NSFileManager defaultManager] ensureDirectoryExistsAtURL:workingDirectory];
    return [workingDirectory URLByAppendingPathComponent:@"screen.mov"];
}

- (NSURL *)temporaryStitchingURL {
    NSURL *workingDirectory = [self temporaryWorkingDirectory];
    [[NSFileManager defaultManager] ensureDirectoryExistsAtURL:workingDirectory];
    return [workingDirectory URLByAppendingPathComponent:@"stitched.mov"];
}

- (NSURL *)temporaryLineupReviewURL {
    NSURL *workingDirectory = [self temporaryWorkingDirectory];
    [[NSFileManager defaultManager] ensureDirectoryExistsAtURL:workingDirectory];
    return [workingDirectory URLByAppendingPathComponent:@"review.pdf"];
}

- (NSURL *)currentPhotoURL {
    return self.allPhotoURLs[self.currentPhotoIndex];
}

- (BOOL)advanceToNextPhoto {
    if (self.currentPhotoIndex < self.allPhotoURLs.count - 1) {
        ++ self.currentPhotoIndex;
        return YES;
    }
    return NO;
}

- (void)rollBackToFirstPhoto {
    self.currentPhotoIndex = 0;
}

- (void)finalizeWithStitchingQueue:(StitchingQueue *)stitchingQueue videoPreviewTimeRange:(CMTimeRange)videoPreviewTimeRange {
    self.videoPreviewTimeRange = videoPreviewTimeRange;
    [self.store updatePresentation:self];
    [stitchingQueue enqueueStitcherForPresentation:self];
}

- (void)finalizeWithoutCameraCapture {
    [self attachLineupReviewAndVideoFromURL:self.temporaryScreenCaptureURL];
}

- (void)finalizeWithoutScreenCapture {
    [self attachLineupReviewAndVideoFromURL:self.temporaryCameraRecordingURL];
}

- (void)attachStitchedVideo {
    [self attachLineupReviewAndVideoFromURL:self.temporaryStitchingURL];
}

- (void)deleteVideoFilesWithFileManager:(NSFileManager *)fileManager {
    [fileManager removeItemAtURL:self.videoURL error:NULL];
    [fileManager removeItemAtURL:self.temporaryWorkingDirectory error:NULL];
}

#pragma mark - Overrides

- (BOOL)isEqual:(Presentation *)other {
    if (![other isKindOfClass:[Presentation class]]) { return NO; }
    if (![self.lineup isEqual:other.lineup] && self.lineup != other.lineup) { return NO; }
    if (![self.date isEqualToDate:other.date] && self.date != other.date) { return NO; }
    if (![self.videoURL isEqual:other.videoURL] && self.videoURL != other.videoURL) { return NO; }
    if (!CMTimeRangeEqual(self.videoPreviewTimeRange, other.videoPreviewTimeRange)) { return NO; }
    if (![self.UUID isEqual:other.UUID] && self.UUID != other.UUID) { return NO; }
    return YES;
}

- (NSUInteger)hash {
    NSUInteger prime = 31;
    NSUInteger result = 1;

    result += prime * [self.UUID hash];
    result += prime * [self.lineup hash];
    result += prime * [self.date hash];
    result += prime * [self.videoURL hash];

    return result;
}

- (id)copyWithZone:(NSZone *)zone {
    Presentation *copy = [[Presentation allocWithZone:zone] init];

    if (copy) {
        copy.currentPhotoIndex = self.currentPhotoIndex;

        copy.lineup = [self.lineup copyWithZone:zone];
        copy.date = [self.date copyWithZone:zone];
        copy.videoURL = [self.videoURL copyWithZone:zone];
        copy.videoPreviewTimeRange = self.videoPreviewTimeRange;

        copy.allPhotoURLs = [self.allPhotoURLs copyWithZone:zone];
        copy.UUID = [self.UUID copyWithZone:zone];
    }

    return copy;
}

#pragma mark - <NSCoding>

- (void)encodeWithCoder:(NSCoder *)coder {
    if (self.lineup) { [coder encodeObject:self.lineup forKey:@"lineup"]; }
    if (self.date) { [coder encodeObject:self.date forKey:@"date"]; }
    if (self.allPhotoURLs) { [coder encodeObject:self.allPhotoURLs forKey:@"allPhotoURLs"]; }
    if (self.videoURL) { [coder encodeObject:[self.videoURL pathRelativeToApplicationSandbox] forKey:@"videoURL"]; }
    [coder encodeCMTimeRange:self.videoPreviewTimeRange forKey:@"videoPreviewTimeRange"];
    if (self.UUID) { [coder encodeObject:self.UUID forKey:@"UUID"]; }
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
    if (self = [super init]) {
        self.lineup = [decoder decodeObjectForKey:@"lineup"];
        self.date = [decoder decodeObjectForKey:@"date"];
        self.allPhotoURLs = [decoder decodeObjectForKey:@"allPhotoURLs"];
        self.videoURL = [NSURL fileURLFromPathRelativeToApplicationSandbox:[decoder decodeObjectForKey:@"videoURL"]];
        self.videoPreviewTimeRange = [decoder decodeCMTimeRangeForKey:@"videoPreviewTimeRange"];
        self.UUID = [decoder decodeObjectForKey:@"UUID"];
    }
    return self;
}

#pragma mark - Private

- (void)attachLineupReviewAndVideoFromURL:(NSURL *)finalVideoURL {
    NSURL *baseURL = [self getNextAvailableAttachmentsBaseURL];
    NSURL *pdfURL = [baseURL URLByAppendingPathExtension:kPDFFileExtension];
    self.videoURL = [baseURL URLByAppendingPathExtension:kMovieFileExtension];

    [[NSFileManager defaultManager] moveItemAtURL:finalVideoURL toURL:self.videoURL error:NULL];
    [[NSFileManager defaultManager] moveItemAtURL:self.temporaryLineupReviewURL toURL:pdfURL error:NULL];
    [[NSFileManager defaultManager] removeItemAtURL:self.temporaryWorkingDirectory error:NULL];

    [self.store updatePresentation:self];
}

- (NSURL *)getNextAvailableAttachmentsBaseURL {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *baseURL = [[fileManager URLForDocumentDirectory] URLByAppendingPathComponent:[self baseFileNameForAttachments]];
    NSURL *videoURL = [baseURL URLByAppendingPathExtension:kMovieFileExtension];
    NSURL *pdfURL = [baseURL URLByAppendingPathExtension:kPDFFileExtension];

    NSInteger count = 0;
    while ([fileManager fileExistsAtPath:[videoURL path]] || [fileManager fileExistsAtPath:[pdfURL path]]) {
        NSString *fileName = [NSString stringWithFormat:@"%@-%ld", [self baseFileNameForAttachments], (long)++count];
        baseURL = [[fileManager URLForDocumentDirectory] URLByAppendingPathComponent:fileName];
        videoURL = [baseURL URLByAppendingPathExtension:kMovieFileExtension];
        pdfURL = [baseURL URLByAppendingPathExtension:kPDFFileExtension];
    }

    return baseURL;
}

- (NSString *)baseFileNameForAttachments {
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd-HHmmss"];

    NSString *sanitizedCaseID = [self.lineup.caseID stringByReplacingOccurrencesOfString:@"[^A-Za-z0-9_]"
                                                                              withString:@""
                                                                                 options:NSRegularExpressionSearch
                                                                                   range:NSMakeRange(0, self.lineup.caseID.length)];
    return [NSString stringWithFormat:@"%@-%@", [dateFormatter stringFromDate:self.date], sanitizedCaseID];
}
@end
