#import "StitchingRestarter.h"
#import "PresentationStore.h"
#import "StitchingQueue.h"
#import "Presentation.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(StitchingRestarterSpec)

describe(@"StitchingRestarter", ^{
    __block StitchingRestarter *restarter;
    __block PresentationStore *store;
    __block StitchingQueue *queue;

    __block Presentation *stitchedPresentation;
    __block Presentation *inProgressStitchingPresentation;
    __block Presentation *unstitchedPresentation;    // not stitched

    beforeEach(^{
        stitchedPresentation = nice_fake_for([Presentation class]);
        stitchedPresentation stub_method(@selector(videoURL)).and_return(@"stitched/movie.mov");

        inProgressStitchingPresentation = nice_fake_for([Presentation class]);

        unstitchedPresentation = nice_fake_for([Presentation class]);

        queue = nice_fake_for([StitchingQueue class]);
        queue stub_method(@selector(stitcherForPresentation:)).with(inProgressStitchingPresentation).and_return(fake_for([VideoStitcher class]));

        store = nice_fake_for([PresentationStore class]);
        store stub_method(@selector(allPresentations)).and_return(@[stitchedPresentation, inProgressStitchingPresentation, unstitchedPresentation]);

        restarter = [[StitchingRestarter alloc] initWithPresentationStore:store stitchingQueue:queue];
    });

    describe(@"restarting stitchers", ^{
        beforeEach(^{
            [restarter restartIncompleteStitches];
        });

        it(@"should enqueue presentations that have not been stitched and are not actively being stitched", ^{
            queue should have_received(@selector(enqueueStitcherForPresentation:)).with(unstitchedPresentation);
        });

        it(@"should not enqueue presentations that have stitching in progress", ^{
            queue should_not have_received(@selector(enqueueStitcherForPresentation:)).with(inProgressStitchingPresentation);
        });

        it(@"should not enqueue presentations that have completed stitching", ^{
            queue should_not have_received(@selector(enqueueStitcherForPresentation:)).with(stitchedPresentation);
        });

        context(@"when not initialized with a store and a queue", ^{
            beforeEach(^{
                restarter = [[StitchingRestarter alloc] initWithPresentationStore:nil stitchingQueue:nil];
            });

            it(@"should throw an exception", ^{
                ^{ [restarter restartIncompleteStitches]; } should raise_exception;
            });
        });
    });
});

SPEC_END
