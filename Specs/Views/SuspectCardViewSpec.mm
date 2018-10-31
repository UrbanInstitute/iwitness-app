#import "UIImageView+FocusOnRect.h"
#import "SuspectCardView.h"
#import "FaceLoader.h"
#import "Portrayal.h"
#import "Person.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(SuspectCardViewSpec)

describe(@"SuspectCardView", ^{
    __block SuspectCardView *view;

    beforeEach(^{
        view = [[SuspectCardView alloc] init];
    });

    describe(@"configureWithPerson:faceLoader:", ^{
        NSURL *originalPhotoURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"nathan" withExtension:@"jpg" subdirectory:@"SampleLineup"];

        beforeEach(^{
            view.imageView.image = [UIImage imageWithData:[NSData dataWithContentsOfURL:originalPhotoURL]];
        });

        context(@"configuring with a person with attributes", ^{
            NSURL *photoURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"cathy" withExtension:@"jpg" subdirectory:@"SampleLineup"];
            Portrayal *portrayal = [[Portrayal alloc] initWithPhotoURL:photoURL date:[NSDate date]];
            __block LoadFaceCompletionBlock loadFaceCompletionBlock;
            __block FaceLoader *faceLoader;

            beforeEach(^{
                loadFaceCompletionBlock = nil;
                faceLoader = nice_fake_for([FaceLoader class]);
                faceLoader stub_method(@selector(loadFaceWithURL:completion:)).and_do_block(^(NSURL *faceURL, LoadFaceCompletionBlock completionBlock){
                    loadFaceCompletionBlock = [completionBlock copy];
                });

                Person *person = [[Person alloc] initWithFirstName:@"Leon" lastName:@"Lewis" dateOfBirth:[NSDate dateWithTimeIntervalSince1970:1397059265] systemID:@"12345" portrayals:@[portrayal]];
                spy_on(view.imageView);
                [view configureWithPerson:person faceLoader:faceLoader];
            });

            it(@"should set the name label", ^{
                view.nameLabel.text should equal(@"Leon Lewis");
            });

            it(@"should set the system id label", ^{
                view.systemIDLabel.text should equal(@"#12345");
            });

            it(@"should set the date of birth label", ^{
                view.dateOfBirthLabel.text should equal(@"4/9/2014");
            });

            it(@"should clear the image that was previously there", ^{
                view.imageView.image should be_nil;
            });

            it(@"should ask the face loader to load the face", ^{
                faceLoader should have_received(@selector(loadFaceWithURL:completion:)).with(photoURL, Arguments::anything);
            });

            describe(@"when the face is loaded", ^{
                __block UIImage *image;
                beforeEach(^{
                    image = [UIImage imageWithData:[NSData dataWithContentsOfURL:photoURL]];
                    if (loadFaceCompletionBlock) {
                        loadFaceCompletionBlock(image, CGRectMake(1, 2, 3, 4), nil);
                    }
                });

                it(@"should display the portrayal photo in the image view", ^{
                    view.imageView.image should be_same_instance_as(image);
                });

                it(@"should center the image view on the face rect", ^{
                    view.imageView should have_received(@selector(focusOnImageRect:)).with(CGRectMake(1, 2, 3, 4));
                });
            });
        });

        context(@"configuring with a person without attributes", ^{
            beforeEach(^{
                Person *person = [[Person alloc] init];
                [view configureWithPerson:person faceLoader:nil];
            });

            it(@"should set the name label", ^{
                view.nameLabel.text should equal(@"");
            });

            it(@"should set the system id label", ^{
                view.systemIDLabel.text should equal(@"");
            });

            it(@"should set the date of birth label", ^{
                view.dateOfBirthLabel.text should equal(@"");
            });

            it(@"should not request to load the image asynchronously", ^{
                [NSURLConnection connections] should be_empty;
            });

            it(@"should clear the image", ^{
                view.imageView.image should be_nil;
            });
        });
    });
});

SPEC_END
