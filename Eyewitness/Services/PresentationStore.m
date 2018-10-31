#import "PresentationStore.h"
#import "Presentation.h"
#import "NSFileManager+CommonDirectories.h"

@interface PresentationStore ()
@property (nonatomic, strong) NSURL *storeURL;
@property (nonatomic, strong) NSFileManager *fileManager;
@property (nonatomic, strong) NSMutableArray *presentations;
@end

@implementation PresentationStore

+ (NSURL *)defaultStoreURL {
    return [[[NSFileManager defaultManager] URLForApplicationSupportDirectory] URLByAppendingPathComponent:@"presentations.store"];
}

- (id)init {
    return [self initWithStoreURL:nil fileManager:nil];
}

- (instancetype)initWithStoreURL:(NSURL *)storeURL fileManager:(NSFileManager *)fileManager {
    if (![storeURL isFileURL]) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"PresentationStore must be created with a store URL" userInfo:nil];
    }

    if (self = [super init]) {
        self.storeURL = storeURL;
        self.fileManager = fileManager;
        [self reload];
    }
    return self;
}

- (void)reload {
    NSDictionary *dataDictionary = [NSKeyedUnarchiver unarchiveObjectWithFile:[self.storeURL path]];
    self.presentations = [dataDictionary[@"presentations"] mutableCopy];
    [self.presentations makeObjectsPerformSelector:@selector(setStore:) withObject:self];
    if (!self.presentations) {
        self.presentations = [NSMutableArray new];
    }
}

- (NSArray *)allPresentations {
    return [self.presentations copy];
}

- (Presentation *)createPresentationWithLineup:(Lineup *)lineup {
    if (!lineup) {
        @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"Cannot create a nil presentation" userInfo:nil];
    }
    Presentation *presentation = [[Presentation alloc] initWithLineup:lineup
                                                           randomSeed:(unsigned int)time(NULL)];
    presentation.store = self;
    [self.presentations addObject:presentation];
    [self savePresentations];
    return presentation;
}

- (Presentation *)presentationWithDate:(NSDate *)date {
    return [[self.presentations filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"date == %@", date]] firstObject];
}

- (void)deletePresentation:(Presentation *)presentation {
    [presentation deleteVideoFilesWithFileManager:self.fileManager];

    [self.presentations removeObject:presentation];
    [self savePresentations];
}


#pragma mark - Private

- (void)savePresentations {
    [NSKeyedArchiver archiveRootObject:@{@"presentations": self.presentations} toFile:[self.storeURL path]];
}

- (void)updatePresentation:(Presentation *)presentation {
    Presentation *localPresentation = [self presentationWithDate:presentation.date];

    if (localPresentation != presentation) {
        [self.presentations replaceObjectAtIndex:[self.presentations indexOfObject:localPresentation] withObject:presentation];
    }

    [self savePresentations];
}

@end
