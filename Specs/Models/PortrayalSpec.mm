#import "Portrayal.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(PortrayalSpec)

describe(@"Portrayal", ^{
    __block Portrayal *portrayal;

    beforeEach(^{
        portrayal = [[Portrayal alloc] initWithPhotoURL:[NSURL URLWithString:@"some/url"] date:[NSDate dateWithTimeIntervalSince1970:123]];
    });

    describe(@"value equality", ^{
        __block Portrayal *equalPortrayal;
        __block Portrayal *unequalURLPortrayal;
        __block Portrayal *unequalDatePortrayal;

        beforeEach(^{
            equalPortrayal = [[Portrayal alloc] initWithPhotoURL:[NSURL URLWithString:@"some/url"]
                                                            date:[NSDate dateWithTimeIntervalSince1970:123]];
            unequalDatePortrayal =[[Portrayal alloc] initWithPhotoURL:[NSURL URLWithString:@"some/url"]
                                                                 date:[NSDate dateWithTimeIntervalSince1970:124]];
            unequalURLPortrayal =[[Portrayal alloc] initWithPhotoURL:[NSURL URLWithString:@"other/url"]
                                                                date:[NSDate dateWithTimeIntervalSince1970:123]];
        });

        it(@"should report equality", ^{
            [portrayal isEqual:equalPortrayal] should be_truthy;
            [portrayal hash] should equal([equalPortrayal hash]);

            [portrayal isEqual:unequalDatePortrayal] should_not be_truthy;
            [portrayal hash] should_not equal([unequalDatePortrayal hash]);

            [portrayal isEqual:unequalURLPortrayal] should_not be_truthy;
            [portrayal hash] should_not equal([unequalURLPortrayal hash]);
        });
    });

    describe(@"copying", ^{
        __block Portrayal *copiedPortrayal;
        beforeEach(^{
            copiedPortrayal = [portrayal copy];
        });

        it(@"should make an equal copy", ^{
            copiedPortrayal should_not be_same_instance_as(portrayal);
            copiedPortrayal should equal(portrayal);
        });
    });

    describe(@"persisting the portrayal", ^{
        __block Portrayal *unarchivedPortrayal;
        __block NSData *archiveData;

        context(@"on a lineup with data", ^{
            beforeEach(^{
                archiveData = [NSKeyedArchiver archivedDataWithRootObject:portrayal];
            });

            it(@"should unarchive the lineup correctly", ^{
                unarchivedPortrayal = [NSKeyedUnarchiver unarchiveObjectWithData:archiveData];
                unarchivedPortrayal.photoURL should equal([NSURL URLWithString:@"some/url"]);
                unarchivedPortrayal.date should equal([NSDate dateWithTimeIntervalSince1970:123]);
            });
        });

        context(@"on a lineup with no data", ^{
            beforeEach(^{
                portrayal = [[Portrayal alloc] init];
                archiveData = [NSKeyedArchiver archivedDataWithRootObject:portrayal];
            });

            it(@"should unarchive the lineup correctly", ^{
                unarchivedPortrayal = [NSKeyedUnarchiver unarchiveObjectWithData:archiveData];
                unarchivedPortrayal.photoURL should be_nil;
                unarchivedPortrayal.date should be_nil;
            });
        });
    });

    describe(@"retrieving the photo URL data from the network", ^{
        __block KSPromise *getPhotoURLDataPromise;

        beforeEach(^{
            getPhotoURLDataPromise = [portrayal getPhotoURLData];
        });

        it(@"should make a network request to load the portrayal's photo data", ^{
            [NSURLConnection.connections.lastObject request].URL should equal(portrayal.photoURL);
        });

        describe(@"when a network error is encountered", ^{
            NSError *error = [NSError errorWithDomain:@"Kitten peed on server"
                                                 code:1234
                                             userInfo:@{}];
            beforeEach(^{
                [NSURLConnection.connections.lastObject failWithError:error];
            });

            it(@"should reject the promise with the error", ^{
                getPhotoURLDataPromise.rejected should be_truthy;
                getPhotoURLDataPromise.error should be_same_instance_as(error);
            });
        });

        describe(@"when a server error is encountered", ^{
            beforeEach(^{
                [NSURLConnection.connections.lastObject receiveResponse:[[PSHKFakeHTTPURLResponse alloc] initWithStatusCode:500 andHeaders:@{} andBody:@"This is fail"]];
            });

            it(@"should reject the promise", ^{
                getPhotoURLDataPromise.rejected should be_truthy;
            });
        });

        describe(@"when the image data is downloaded successfully", ^{
            NSData *someData = [@"fake-dummy-placeholder-for-image-data" dataUsingEncoding:NSUTF8StringEncoding];

            beforeEach(^{
                [NSURLConnection.connections.lastObject receiveResponse:[[PSHKFakeHTTPURLResponse alloc] initWithStatusCode:200 andHeaders:@{} andBodyData:someData]];
            });

            it(@"should resolve the promise with the image data", ^{
                getPhotoURLDataPromise.fulfilled should be_truthy;
                getPhotoURLDataPromise.value should equal(someData);
            });

            describe(@"on a subsequent request for the photoURL", ^{
                beforeEach(^{
                    getPhotoURLDataPromise = [portrayal getPhotoURLData];
                });

                it(@"should not make a new network request", ^{
                    NSURLConnection.connections should be_empty;
                });

                it(@"should resolve the promise with the image data", ^{
                    getPhotoURLDataPromise.fulfilled should be_truthy;
                    getPhotoURLDataPromise.value should equal(someData);
                });
            });
        });
    });
});

SPEC_END
