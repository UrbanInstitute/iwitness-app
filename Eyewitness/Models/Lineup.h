@class Person, PerpetratorDescription;

@interface Lineup : NSObject <NSCoding, NSCopying>

@property (nonatomic, copy, readonly) NSString *UUID;

@property (nonatomic, copy) NSString *caseID;
@property (nonatomic, strong, readonly) NSDate *creationDate;

@property (nonatomic, copy) NSArray *fillerPhotosFileURLs;

@property (nonatomic, assign, readonly, getter=isValid) BOOL valid;
@property (nonatomic, assign, getter=isFromDB) BOOL fromDB;
@property (nonatomic, assign, getter=isAudioOnly) BOOL audioOnly;

@property (nonatomic, strong) Person *suspect;

@property (nonatomic, strong) PerpetratorDescription *perpetratorDescription;

- (instancetype)initWithCreationDate:(NSDate *)creationDate suspect:(Person *)suspect;

- (void)updateToMatchLineup:(Lineup *)lineup;

+ (NSUInteger)minimumNumberOfFillerPhotos;

+ (NSUInteger)maximumNumberOfFillerPhotos;
@end
