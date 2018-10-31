#import "Lineup.h"
#import "Person.h"
#import "Portrayal.h"
#import "PerpetratorDescription.h"
#import "NSFileManager+CommonDirectories.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(LineupSpec)

describe(@"Lineup", ^{
    NSURL *sandboxURL = [[NSFileManager defaultManager] URLForApplicationSandbox];
    NSURL *suspectPhotoURL = [sandboxURL URLByAppendingPathComponent:@"path/to/einstein.jpg"];
    NSURL *fillerPhotoURL = [sandboxURL URLByAppendingPathComponent:@"path/to/filler.jpg"];
    __block Lineup *lineup;
    __block Person *suspect;

    beforeEach(^{
        lineup = [[Lineup alloc] init];
        suspect = lineup.suspect;
        lineup.audioOnly = YES;
        lineup.fromDB = NO;
        lineup.caseID = @"12345";
        lineup.suspect.firstName = @"Albert";
        lineup.suspect.lastName = @"Einstein";
        lineup.suspect.portrayals = @[[[Portrayal alloc] initWithPhotoURL:suspectPhotoURL date:[NSDate dateWithTimeIntervalSince1970:912345]]];
        lineup.fillerPhotosFileURLs = @[fillerPhotoURL];
        lineup.perpetratorDescription.additionalNotes = @"Has a big hairy mole";
    });

    it(@"should blow up if created with a nil creation date", ^{
        ^{ (void) [[Lineup alloc] initWithCreationDate:nil suspect:nil ]; } should raise_exception;
    });

    it(@"should have a creation date", ^{
        lineup.creationDate should_not be_nil;
    });

    it(@"should have a perpetrator description", ^{
        lineup.perpetratorDescription should be_instance_of([PerpetratorDescription class]);
    });

    describe(@"reverting", ^{
        __block Lineup *lineupToRevertTo;

        beforeEach(^{
            PerpetratorDescription *perpetratorDescription = [[PerpetratorDescription alloc] init];
            perpetratorDescription.additionalNotes = @"had super cool eyes";

            NSDate *creationDate = [NSDate dateWithTimeIntervalSince1970:99954321];
            NSDate *dateOfBirth = [NSDate dateWithTimeIntervalSince1970:9912345];
            NSURL *photoURL = [NSURL URLWithString:@"file:///a/coo/url"];
            NSDate *portrayalDate = [NSDate dateWithTimeIntervalSince1970:99234325];
            Person *person = [[Person alloc] initWithFirstName:@"Shaq"
                                                      lastName:@"O'Neil"
                                                   dateOfBirth:dateOfBirth
                                                      systemID:@"54342314"
                                                    portrayals:@[[[Portrayal alloc] initWithPhotoURL:photoURL date:portrayalDate]]];

            lineupToRevertTo = [[Lineup alloc] initWithCreationDate:creationDate suspect:person];
            lineupToRevertTo.perpetratorDescription = perpetratorDescription;
            lineupToRevertTo.fromDB = YES;
            lineupToRevertTo.audioOnly = NO;

            [lineup updateToMatchLineup:lineupToRevertTo];
        });

        it(@"should update itself to match the lineup requested", ^{
            lineup should equal(lineupToRevertTo);
        });
    });

    describe(@"equality", ^{
        __block Lineup *otherLineup;

        void(^makeLineupIdenticalToLineupWithCreationDate)(NSDate *) = ^(NSDate *date) {
            otherLineup = [[Lineup alloc] initWithCreationDate:date suspect:[[Person alloc] init]];
            otherLineup.perpetratorDescription.additionalNotes = @"Has a big hairy mole";
            otherLineup.audioOnly = YES;
            otherLineup.fromDB = NO;
            otherLineup.caseID = @"12345";
            otherLineup.suspect.firstName = @"Albert";
            otherLineup.suspect.lastName = @"Einstein";
            otherLineup.suspect.portrayals = @[[[Portrayal alloc] initWithPhotoURL:suspectPhotoURL date:[NSDate dateWithTimeIntervalSince1970:912345]]];
            otherLineup.fillerPhotosFileURLs = @[fillerPhotoURL];
        };

        beforeEach(^{
            makeLineupIdenticalToLineupWithCreationDate(lineup.creationDate);
        });

        it(@"should equal an identical lineup", ^{
            [lineup isEqual:otherLineup] should be_truthy;
        });

        it(@"should have the same hash as an identical lineup", ^{
            [lineup hash] should equal([otherLineup hash]);
        });

        context(@"for a lineup with a different caseID", ^{
            beforeEach(^{
                otherLineup.caseID = @"23456";
            });

            it(@"should not be equal", ^{
                [lineup isEqual:otherLineup] should be_falsy;
            });

            it(@"should not have the same hash", ^{
                lineup.hash should_not equal(otherLineup.hash);
            });
        });

        context(@"for a lineup with a different suspect", ^{
            beforeEach(^{
                otherLineup.suspect.firstName = @"Leonardo";
            });

            it(@"should not be equal", ^{
                [lineup isEqual:otherLineup] should be_falsy;
            });

            it(@"should not have the same hash", ^{
                lineup.hash should_not equal(otherLineup.hash);
            });
        });

        context(@"for a lineup with a different date", ^{
            beforeEach(^{
                makeLineupIdenticalToLineupWithCreationDate([NSDate dateWithTimeIntervalSince1970:0]);
            });

            it(@"should not be equal", ^{
                [lineup isEqual:otherLineup] should be_falsy;
            });

            it(@"should not have the same hash", ^{
                lineup.hash should_not equal(otherLineup.hash);
            });
        });

        context(@"for a lineup with a different perpetrator description", ^{
            beforeEach(^{
                otherLineup.perpetratorDescription.additionalNotes = @"Has weird looking freckles";
            });

            it(@"should not be equal", ^{
                [lineup isEqual:otherLineup] should be_falsy;
            });

            it(@"should not have the same hash", ^{
                lineup.hash should_not equal(otherLineup.hash);
            });
        });

        context(@"for a lineup with a different filler photo urls", ^{
            beforeEach(^{
                otherLineup.fillerPhotosFileURLs = @[];
            });

            it(@"should not be equal", ^{
                [lineup isEqual:otherLineup] should be_falsy;
            });

            it(@"should not have the same hash", ^{
                lineup.hash should_not equal(otherLineup.hash);
            });
        });

        context(@"for a lineup with a different 'audio only' setting", ^{
            beforeEach(^{
                otherLineup.audioOnly = !lineup.audioOnly;
            });

            it(@"should not be equal", ^{
                [lineup isEqual:otherLineup] should be_falsy;
            });

            it(@"should not have the same hash", ^{
                lineup.hash should_not equal(otherLineup.hash);
            });
        });
    });

    describe(@"copying", ^{
        __block Lineup *copiedLineup;
        beforeEach(^{
            copiedLineup = [lineup copy];
        });

        it(@"should make an equal copy", ^{
            copiedLineup should_not be_same_instance_as(lineup);
            copiedLineup should equal(lineup);
        });

        it(@"should put the same UUID on the copy", ^{
            copiedLineup.UUID should equal(lineup.UUID);
        });
    });

    describe(@"validation", ^{
        NSURL *suspectPhotoURL = [NSURL fileURLWithPath:@"path/to/suspect/photo.jpg"];
        NSURL *filler1PhotoURL = [NSURL fileURLWithPath:@"path/to/filler1/photo.jpg"];
        NSURL *filler2PhotoURL = [NSURL fileURLWithPath:@"path/to/filler2/photo.jpg"];
        NSURL *filler3PhotoURL = [NSURL fileURLWithPath:@"path/to/filler3/photo.jpg"];
        NSURL *filler4PhotoURL = [NSURL fileURLWithPath:@"path/to/filler4/photo.jpg"];
        NSURL *filler5PhotoURL = [NSURL fileURLWithPath:@"path/to/filler5/photo.jpg"];

        beforeEach(^{
            Lineup.minimumNumberOfFillerPhotos should equal(5);
        });

        context(@"lineup has enough photos", ^{
            beforeEach(^{
                lineup.suspect.portrayals = @[[[Portrayal alloc] initWithPhotoURL:suspectPhotoURL date:[NSDate date]]];
                lineup.fillerPhotosFileURLs = @[ filler1PhotoURL, filler2PhotoURL, filler3PhotoURL, filler4PhotoURL, filler5PhotoURL ];
            });

            it(@"should report itself as valid", ^{
                lineup.valid should be_truthy;
            });
        });

        context(@"lineup has insufficient photos", ^{
            context(@"no suspect photo", ^{
                beforeEach(^{
                    lineup.suspect.portrayals = nil;
                    lineup.fillerPhotosFileURLs = @[ filler1PhotoURL, filler2PhotoURL, filler3PhotoURL, filler4PhotoURL, filler5PhotoURL ];
                });

                it(@"should report itself as invalid", ^{
                    lineup.valid should be_falsy;
                });
            });

            context(@"insufficient number of filler photos", ^{
                beforeEach(^{
                    lineup.suspect.portrayals = @[[[Portrayal alloc] initWithPhotoURL:suspectPhotoURL date:[NSDate date]]];
                    lineup.fillerPhotosFileURLs = @[ filler1PhotoURL ];
                });

                it(@"should report itself as invalid", ^{
                    lineup.valid should be_falsy;
                });
            });
        });
    });

    describe(@"persisting the lineup", ^{
        __block Lineup *unarchivedLineup;
        __block NSData *archiveData;

        context(@"on a lineup with data", ^{
            beforeEach(^{
                lineup.fromDB = lineup.audioOnly = YES;
                archiveData = [NSKeyedArchiver archivedDataWithRootObject:lineup];
            });

            it(@"should unarchive the lineup correctly", ^{
                unarchivedLineup = [NSKeyedUnarchiver unarchiveObjectWithData:archiveData];
                unarchivedLineup.UUID should equal(lineup.UUID);
                unarchivedLineup.caseID should equal(@"12345");
                unarchivedLineup.creationDate should equal(lineup.creationDate);
                unarchivedLineup.suspect should equal(suspect);
                unarchivedLineup.fillerPhotosFileURLs should equal(@[fillerPhotoURL]);
                unarchivedLineup.fromDB should be_truthy;
                unarchivedLineup.perpetratorDescription should equal(lineup.perpetratorDescription);
                unarchivedLineup.audioOnly should equal(lineup.audioOnly);
            });
        });

        context(@"on a lineup with no data", ^{
            beforeEach(^{
                lineup = [[Lineup alloc] initWithCreationDate:[NSDate dateWithTimeIntervalSinceReferenceDate:0] suspect:nil];
                archiveData = [NSKeyedArchiver archivedDataWithRootObject:lineup];
            });

            it(@"should unarchive the lineup correctly", ^{
                unarchivedLineup = [NSKeyedUnarchiver unarchiveObjectWithData:archiveData];
                unarchivedLineup.UUID should equal(lineup.UUID);
                unarchivedLineup.caseID should be_nil;
                unarchivedLineup.suspect.firstName should be_nil;
                unarchivedLineup.suspect.lastName should be_nil;
                unarchivedLineup.creationDate should equal([NSDate dateWithTimeIntervalSinceReferenceDate:0]);
                unarchivedLineup.suspect.portrayals should be_nil;
                unarchivedLineup.fillerPhotosFileURLs should be_nil;
                unarchivedLineup.perpetratorDescription should equal(lineup.perpetratorDescription);
                unarchivedLineup.audioOnly should be_falsy;
            });
        });
    });

    describe(@"persisting photos' relative paths", ^{
        __block NSKeyedArchiver *archiver;

        beforeEach(^{
            NSURL *documentsDir = [[NSFileManager defaultManager] URLForDocumentDirectory];
            lineup = [[Lineup alloc] init];
            lineup.suspect.portrayals = @[[[Portrayal alloc] initWithPhotoURL:[documentsDir URLByAppendingPathComponent:@"suspect.jpg"] date:[NSDate date]]];
            lineup.fillerPhotosFileURLs = @[[documentsDir URLByAppendingPathComponent:@"filler.jpg"]];

            archiver = nice_fake_for([NSKeyedArchiver class]);
            [lineup encodeWithCoder:archiver];
        });

        it(@"should store the path of photos relative to the application sandbox's root", ^{
            archiver should have_received(@selector(encodeObject:forKey:)).with(@[@"Documents/filler.jpg"], @"fillerPhotosFileURLs");
        });
    });
});

SPEC_END
