@class Lineup;
@class Presentation;

@interface PresentationStore : NSObject

+ (NSURL *)defaultStoreURL;

- (instancetype)initWithStoreURL:(NSURL *)storeURL fileManager:(NSFileManager *)fileManager;

- (void) reload;
- (NSArray *)allPresentations;
- (Presentation *)createPresentationWithLineup:(Lineup *)lineup;
- (Presentation *)presentationWithDate:(NSDate *)date;
- (void)deletePresentation:(Presentation *)presentation;
- (void)updatePresentation:(Presentation *)presentation;

@end
