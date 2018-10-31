#import "PersonSearchService.h"
#import "PersonsLoader.h"

@interface PersonSearchService ()
@property (nonatomic, strong) PersonsLoader *loader;
@property (nonatomic, strong) NSArray *persons;
@end

@implementation PersonSearchService

- (instancetype)initWithPersonsLoader:(PersonsLoader *)loader {
    if (self = [super init]) {
        self.loader = loader;
    }
    return self;
}

- (KSPromise *)personResultsForFirstName:(NSString *)firstName lastName:(NSString *)lastName suspectID:(NSString *)suspectID {
    KSDeferred *deferred = [KSDeferred defer];

    NSPredicate *firstNamePredicate = [NSPredicate predicateWithFormat:@"firstName BEGINSWITH[cd] %@ OR %@.length == 0", firstName, firstName];
    NSPredicate *lastNamePredicate = [NSPredicate predicateWithFormat:@"lastName BEGINSWITH[cd] %@ OR %@.length == 0", lastName, lastName];
    NSPredicate *suspectIDPredicate = [NSPredicate predicateWithFormat:@"systemID == %@ OR %@.length == 0", suspectID, suspectID];

    NSPredicate *predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[firstNamePredicate, lastNamePredicate, suspectIDPredicate]];
    NSArray *results = [self.persons filteredArrayUsingPredicate:predicate];

    [deferred resolveWithValue:results];
    return deferred.promise;
}

#pragma mark - Accessors

- (NSArray *)persons {
    if (!_persons) {
        _persons = [self.loader loadPersons];
    }
    return _persons;
}

@end
