#import "PerpetratorDescription.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(PerpetratorDescriptionSpec)

describe(@"PerpetratorDescription", ^{
    __block PerpetratorDescription *description;

    beforeEach(^{
        description = [[PerpetratorDescription alloc] init];
    });

    it(@"should begin with an empty additional notes", ^{
        description.additionalNotes should equal(@"");
    });

    describe(@"testing equality", ^{
        __block PerpetratorDescription *otherDescription;

        beforeEach(^{
            description.additionalNotes = @"has a badass tattoo";
            otherDescription = [[PerpetratorDescription alloc] init];
            otherDescription.additionalNotes = description.additionalNotes;
        });

        context(@"with another equal perpetrator description", ^{
            it(@"should return YES", ^{
                [description isEqual:otherDescription] should be_truthy;
            });

            it(@"should have the same hash", ^{
                description.hash should equal(otherDescription.hash);
            });

        });

        context(@"with a different additional description", ^{
            beforeEach(^{
                otherDescription.additionalNotes = @"has no tattoo, badass or otherwise";
            });

            it(@"should return NO", ^{
                [description isEqual:otherDescription] should_not be_truthy;
            });

            it(@"should have a different hash", ^{
                description.hash should_not equal(otherDescription.hash);
            });
        });
    });

    describe(@"copying", ^{
        __block PerpetratorDescription *copiedDescription;
        beforeEach(^{
            description.additionalNotes = @"has a badass tattoo";
            copiedDescription = [description copy];
        });

        it(@"should make an equal copy", ^{
            copiedDescription should_not be_same_instance_as(description);
            copiedDescription should equal(description);
        });
    });

    describe(@"persisting the description", ^{
        __block PerpetratorDescription *unarchivedDescription;
        __block NSData *archiveData;

        context(@"on a lineup with data", ^{
            beforeEach(^{
                description.additionalNotes = @"has a badass tattoo";
                archiveData = [NSKeyedArchiver archivedDataWithRootObject:description];
            });

            it(@"should unarchive the lineup correctly", ^{
                unarchivedDescription = [NSKeyedUnarchiver unarchiveObjectWithData:archiveData];
                unarchivedDescription.additionalNotes should equal(@"has a badass tattoo");
            });
        });

        context(@"on a lineup with no data", ^{
            beforeEach(^{
                archiveData = [NSKeyedArchiver archivedDataWithRootObject:description];
            });

            it(@"should unarchive the lineup correctly", ^{
                unarchivedDescription = [NSKeyedUnarchiver unarchiveObjectWithData:archiveData];
                unarchivedDescription.additionalNotes should equal(@"");
            });
        });
    });
    
});

SPEC_END
