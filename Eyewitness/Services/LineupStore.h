@class Lineup;

@interface LineupStore : NSObject

@property (nonatomic, strong, readonly) NSURL *storeURL;

+ (NSURL *)defaultStoreURL;

- (instancetype)initWithStoreURL:(NSURL *)storeURL;

- (void)updateLineup:(Lineup *)lineup;
- (void)deleteLineup:(Lineup *)lineup;

- (NSArray *)allLineups;
- (Lineup *)lineupWithUUID:(NSString *)UUID;

@end
