#import "PresentationStore.h"
#import "Presentation.h"
#import "Lineup.h"
#import "NSURL+RelativeSandboxPaths.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

@interface Presentation (Spec)
@property (nonatomic, copy, readwrite) NSString *caseID;
@property (nonatomic, strong, readwrite) NSDate *date;
@end

SPEC_BEGIN(PresentationStoreSpec)

describe(@"PresentationStore", ^{
    __block PresentationStore *store;
    __block NSURL *storeURL;
    __block Lineup *lineup;
    __block NSFileManager *fileManager;

    beforeEach(^{
        storeURL = [NSURL URLWithString:@"file:///tmp/presentation_store"];
        [[NSFileManager defaultManager] removeItemAtURL:storeURL error:NULL];
        fileManager = fake_for([NSFileManager class]);
        fileManager stub_method(@selector(removeItemAtURL:error:));

        store = [[PresentationStore alloc] initWithStoreURL:storeURL fileManager:fileManager];

        lineup = [[Lineup alloc] init];
        lineup.caseID = @"Case#12345!%";
    });

    it(@"should not allow creating a store without a store URL", ^{
        ^{ (void)[[PresentationStore alloc] initWithStoreURL:nil fileManager:nil]; } should raise_exception;
        ^{ (void)[[PresentationStore alloc] init]; } should raise_exception;
    });

    it(@"should begin with no presentations", ^{
        [store allPresentations].count should equal(0);
    });

    describe(@"creating a presentation", ^{
        __block Presentation *newPresentation;

        beforeEach(^{
            newPresentation = [store createPresentationWithLineup:lineup];
        });

        it(@"should provide access to the created presentation", ^{
            [store allPresentations] should contain(newPresentation);
        });

        it(@"should not allow creating a presentation with a nil lineup", ^{
            ^{ [store createPresentationWithLineup:nil]; } should raise_exception;
        });

        it(@"should persist the presentations", ^{
            PresentationStore *loadedStore = [[PresentationStore alloc] initWithStoreURL:storeURL fileManager:fileManager];
            [loadedStore allPresentations] should equal([store allPresentations]);
        });

        it(@"should set itself as the presentation's store", ^{
            newPresentation.store should be_same_instance_as(store);
        });
    });

    describe(@"updating a presentation", ^{
        __block Presentation *originalPresentation, *updatedPresentation;

        beforeEach(^{
            originalPresentation = [store createPresentationWithLineup:lineup];
            updatedPresentation = [originalPresentation copy];
            updatedPresentation.videoURL = [NSURL fileURLFromPathRelativeToApplicationSandbox:@"updated/url/for/video.mov"];

            [store updatePresentation:updatedPresentation];
        });

        it(@"should replace the corresponding presentation in the store", ^{
            Presentation *retrievedPresentation = [store presentationWithDate:originalPresentation.date];
            retrievedPresentation.videoURL should equal(updatedPresentation.videoURL);
            retrievedPresentation.videoURL should_not equal(originalPresentation.videoURL);
        });

        it(@"should persist the updated presentation", ^{
            PresentationStore *loadedStore = [[PresentationStore alloc] initWithStoreURL:storeURL fileManager:fileManager];
            Presentation *retrievedPresentation = [loadedStore presentationWithDate:updatedPresentation.date];
            retrievedPresentation should equal(updatedPresentation);
        });
    });

    describe(@"retrieving a presentation", ^{
        __block Presentation *newPresentation, *retrievedPresentation;

        beforeEach(^{
            newPresentation = [store createPresentationWithLineup:lineup];
            retrievedPresentation = [store presentationWithDate:newPresentation.date];
        });

        it(@"should retrieve the correct presentation", ^{
            retrievedPresentation.date should equal(newPresentation.date);
        });

        it(@"should set itself as the presentation's store", ^{
            retrievedPresentation.store should be_same_instance_as(store);
        });
    });

    describe(@"retrieving all presentations", ^{
        __block Presentation *presentation1, *presentation2;

        beforeEach(^{
            presentation1 = [store createPresentationWithLineup:lineup];
            presentation2 = [store createPresentationWithLineup:lineup];
        });

        it(@"should return all created presentations", ^{
            [store allPresentations] should equal(@[ presentation1, presentation2 ]);
        });

        it(@"should set itself as the presentations' store", ^{
            for (Presentation *presentation in store.allPresentations) {
                presentation.store should be_same_instance_as(store);
            }
        });

        describe(@"from a different store", ^{
            beforeEach(^{
                store = [[PresentationStore alloc] initWithStoreURL:storeURL fileManager:fileManager];
            });

            it(@"should set itself as the presentations' store", ^{
                for (Presentation *presentation in store.allPresentations) {
                    presentation.store should be_same_instance_as(store);
                }
            });
        });
    });

    describe(@"deleting a presentation", ^{
        __block Presentation *newPresentation;

        beforeEach(^{
            newPresentation = [store createPresentationWithLineup:lineup];
            newPresentation.videoURL = [NSURL fileURLWithPath:@"/this/is/a/great/video.mov"];
            spy_on(newPresentation);

            [store deletePresentation:newPresentation];
        });

        it(@"should not have newPresentation", ^{
            [store allPresentations] should_not contain(newPresentation);
        });

        it(@"should delete the presentation's video files", ^{
            newPresentation should have_received(@selector(deleteVideoFilesWithFileManager:)).with(fileManager);
        });
    });

    describe(@"reloading", ^{
        __block PresentationStore *otherStore;
        __block Presentation *presentationFromOtherStore;
        beforeEach(^{
            otherStore = [[PresentationStore alloc] initWithStoreURL:storeURL fileManager:fileManager];
            presentationFromOtherStore = [otherStore createPresentationWithLineup:[[Lineup alloc] init]];

            [store reload];
        });

        it(@"should pick up changes that occur in other store instances with the same store URL", ^{
            [store allPresentations] should contain(presentationFromOtherStore);
        });
    });
});

SPEC_END
