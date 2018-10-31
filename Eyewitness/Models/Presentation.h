@class Lineup;
@class PresentationStore;
@class StitchingQueue;

@interface Presentation : NSObject <NSCopying, NSCoding>

@property (nonatomic, copy, readonly) NSString *UUID;
@property (nonatomic, weak) PresentationStore *store;

@property (nonatomic, strong, readonly) Lineup *lineup;
@property (nonatomic, strong, readonly) NSDate *date;
@property (nonatomic, strong, readwrite) NSURL *videoURL;

@property (nonatomic) CMTimeRange videoPreviewTimeRange;

@property (nonatomic, readonly) NSURL *temporaryWorkingDirectory;
@property (nonatomic, readonly) NSURL *temporaryCameraRecordingURL;
@property (nonatomic, readonly) NSURL *temporaryScreenCaptureURL;
@property (nonatomic, readonly) NSURL *temporaryStitchingURL;
@property (nonatomic, readonly) NSURL *temporaryLineupReviewURL;

@property (nonatomic, assign, readonly) NSInteger currentPhotoIndex;

- (instancetype)initWithLineup:(Lineup *)lineup randomSeed:(unsigned int)seed;

- (NSURL *)currentPhotoURL;
- (BOOL)advanceToNextPhoto;
- (void)rollBackToFirstPhoto;

- (void)finalizeWithStitchingQueue:(StitchingQueue *)stitchingQueue videoPreviewTimeRange:(CMTimeRange)videoPreviewTimeRange;

- (void)finalizeWithoutCameraCapture;
- (void)finalizeWithoutScreenCapture;
- (void)attachStitchedVideo;

- (void)deleteVideoFilesWithFileManager:(NSFileManager *)fileManager;
@end
