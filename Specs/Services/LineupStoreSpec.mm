#import "LineupStore.h"
#import "Lineup.h"
#import "Person.h"
#import "Portrayal.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(LineupStoreSpec)

describe(@"LineupStore", ^{
    __block LineupStore *store;

    beforeEach(^{
        NSURL *storeURL = [NSURL URLWithString:@"file:///tmp/test_store"];
        [[NSFileManager defaultManager] removeItemAtURL:storeURL error:NULL];

        store = [[LineupStore alloc] initWithStoreURL:storeURL];
    });

    sharedExamplesFor(@"restoring persisted lineups", ^(NSDictionary *) {
        __block LineupStore *loadedStore;
        beforeEach(^{
            loadedStore = [[LineupStore alloc] initWithStoreURL:store.storeURL];
        });

        it(@"should contain the same lineups as the store with the same storeURL", ^{
            [loadedStore allLineups] should equal([store allLineups]);
        });
    });

    it(@"should begin with no lineups", ^{
        [store allLineups].count should equal(0);
    });

    describe(@"retrieving all lineups", ^{
        __block Lineup *lineup;

        beforeEach(^{
            lineup = [[Lineup alloc] init];
            lineup.caseID = @"123";
            [store updateLineup:lineup];
        });

        it(@"should return all stored lineups", ^{
            store.allLineups should equal(@[lineup]);
        });

        it(@"returns independent copies of lineups", ^{
            store.allLineups.firstObject should equal(store.allLineups.firstObject);
            store.allLineups.firstObject should_not be_same_instance_as(store.allLineups.firstObject);
        });
    });

    describe(@"retrieving a lineup", ^{
        __block Lineup *lineup;

        beforeEach(^{
            lineup = [[Lineup alloc] init];
            lineup.caseID = @"123";
            [store updateLineup:lineup];
        });

        it(@"should return a copy of the lineup", ^{
            Lineup *retrievedLineup = [store lineupWithUUID:lineup.UUID];
            retrievedLineup should equal(lineup);
            retrievedLineup should_not be_same_instance_as(lineup);
        });
    });

    describe(@"modifying the lineup store", ^{
        __block Lineup *lineup;

        beforeEach(^{
            lineup = [[Lineup alloc] init];
            lineup.caseID = @"123";
        });

        context(@"adding a lineup for the first time", ^{
            beforeEach(^{
                [[NSFileManager defaultManager] fileExistsAtPath:[store.storeURL path]] should be_falsy;
                [store updateLineup:lineup];
            });

            it(@"should have created a store with the lineup", ^{
                [[NSFileManager defaultManager] fileExistsAtPath:[store.storeURL path]] should be_truthy;
            });
        });

        context(@"adding a new lineup", ^{
            beforeEach(^{
                [store updateLineup:lineup];
            });

            it(@"should have stored the lineup ", ^{
                store.allLineups should equal(@[lineup]);
            });

            it(@"the stored lineup should be an independent copy", ^{
                lineup.caseID = @"999";
                store.allLineups.firstObject should_not equal(lineup);
            });

            itShouldBehaveLike(@"restoring persisted lineups");
        });

        context(@"updating an existing lineup", ^{
            __block Lineup *updatedLineup;

            beforeEach(^{
                [store updateLineup:lineup];
                updatedLineup = [lineup copy];
                updatedLineup.caseID = @"456";
                [store updateLineup:updatedLineup];
            });

            it(@"should have updated the stored lineup ", ^{
                store.allLineups should equal(@[updatedLineup]);
            });

            it(@"the stored lineup should be an independent copy", ^{
                updatedLineup.caseID = @"999";
                store.allLineups.firstObject should_not equal(updatedLineup);
            });

            itShouldBehaveLike(@"restoring persisted lineups");
        });

    });

    describe(@"deleting a lineup", ^{
        __block Lineup *lineup;
        __block NSURL *suspectPhotoURL;
        __block NSURL *fillerPhotoURL;

        beforeEach(^{
            spy_on([NSFileManager defaultManager]);
            suspectPhotoURL = [NSURL URLWithString:@"/suspect/photo/url"];
            fillerPhotoURL = [NSURL URLWithString:@"/filler/photo/url"];

            lineup = [[Lineup alloc] init];
            [store updateLineup:lineup];

            lineup.suspect.portrayals = @[[[Portrayal alloc] initWithPhotoURL:suspectPhotoURL date:[NSDate date]]];
            lineup.fillerPhotosFileURLs = @[fillerPhotoURL];
        });

        subjectAction(^{
            [store deleteLineup:lineup];
        });

        it(@"should remove the lineup from the lineup collection", ^{
            store.allLineups should be_empty;
        });

        it(@"should delete the filler assets", ^{
            [NSFileManager defaultManager] should have_received(@selector(removeItemAtURL:error:)).with(fillerPhotoURL, Arguments::anything);
        });

        context(@"the lineup came from the database", ^{
            beforeEach(^{
                lineup.fromDB = YES;
            });

            it(@"should not delete the selected suspect photo", ^{
                [NSFileManager defaultManager] should_not have_received(@selector(removeItemAtURL:error:)).with(suspectPhotoURL, Arguments::anything);
            });
        });

        context(@"the lineup did not come from the database", ^{
            beforeEach(^{
                lineup.fromDB = NO;
            });

            it(@"should delete the selected suspect photo", ^{
                [NSFileManager defaultManager] should have_received(@selector(removeItemAtURL:error:)).with(suspectPhotoURL, Arguments::anything);
            });
        });

        itShouldBehaveLike(@"restoring persisted lineups");
    });
});

SPEC_END
