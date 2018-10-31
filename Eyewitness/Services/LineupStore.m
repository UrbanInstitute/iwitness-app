#import "LineupStore.h"
#import "Lineup.h"
#import "NSFileManager+CommonDirectories.h"
#import "Person.h"
#import "Portrayal.h"

@interface LineupStore ()
@property (nonatomic, strong) NSMutableArray *lineups;
@property (nonatomic, strong, readwrite) NSURL *storeURL;
@end

@implementation LineupStore

+ (NSURL *)defaultStoreURL {
    return [[[NSFileManager defaultManager] URLForApplicationSupportDirectory] URLByAppendingPathComponent:@"lineups.store"];
}

- (id)init {
    return [self initWithStoreURL:nil];
}

- (instancetype)initWithStoreURL:(NSURL *)storeURL {
    if (self = [super init]) {
        self.storeURL = storeURL;
        [self loadLineups];
    }
    return self;
}

- (void)updateLineup:(Lineup *)lineup {
    NSUInteger existingLineupIndex = [self indexOfLineupWithUUID:lineup.UUID];
    Lineup *lineupCopy = [lineup copy];

    if (existingLineupIndex == NSNotFound) {
        [self.lineups addObject:lineupCopy];
    } else {
        [self.lineups replaceObjectAtIndex:existingLineupIndex withObject:lineupCopy];
    }

    [self saveLineups];
}

- (void)deleteLineup:(Lineup *)lineup {
    NSUInteger existingLineupIndex = [self indexOfLineupWithUUID:lineup.UUID];

    if (existingLineupIndex == NSNotFound) {
        return;
    }

    [self.lineups removeObjectAtIndex:existingLineupIndex];
    if (!lineup.isFromDB && lineup.suspect.selectedPortrayal.photoURL)
    {
        NSURL * susPhotoUrl = (NSURL *)lineup.suspect.selectedPortrayal.photoURL;
        [[NSFileManager defaultManager] removeItemAtURL:susPhotoUrl error:nil];
        //MOK[[NSFileManager defaultManager] removeItemAtURL:lineup.suspect.selectedPortrayal.photoURL error:nil];
    }

    for (NSURL *fillerPhotoURL in lineup.fillerPhotosFileURLs) {
        [[NSFileManager defaultManager] removeItemAtURL:fillerPhotoURL error:nil];
    }

    [self saveLineups];
}

- (NSArray *)allLineups {
    return [[NSArray alloc] initWithArray:self.lineups copyItems:YES];
}

- (Lineup *)lineupWithUUID:(NSString *)UUID {
    NSUInteger existingLineupIndex = [self indexOfLineupWithUUID:UUID];
    if(existingLineupIndex != NSNotFound) {
        return [self.lineups[existingLineupIndex] copy];
    }
    return nil;
}

#pragma mark - Persistence

- (void)saveLineups {
    NSDictionary *archiveDict = @{ @"lineups": self.lineups };
    [NSKeyedArchiver archiveRootObject:archiveDict toFile:[self.storeURL path]];
}

- (void)loadLineups {
    NSDictionary *archiveDict = [NSKeyedUnarchiver unarchiveObjectWithFile:[self.storeURL path]];
    self.lineups = [NSMutableArray arrayWithArray:[archiveDict objectForKey:@"lineups"]];
}

#pragma mark - private

- (NSUInteger)indexOfLineupWithUUID:(NSString *)UUID {
    return [self.lineups indexOfObjectPassingTest:^BOOL(Lineup *existingLineup, NSUInteger idx, BOOL *stop) {
        return [UUID isEqualToString:existingLineup.UUID];
    }];
}
@end
