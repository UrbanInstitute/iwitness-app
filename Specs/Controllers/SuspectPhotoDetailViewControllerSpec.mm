#import "SuspectPhotoDetailViewController.h"
#import "Portrayal.h"
#import "Person.h"
#import "SuspectPhotoDetailViewControllerDelegate.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(SuspectPhotoDetailViewControllerSpec)

describe(@"SuspectPhotoDetailViewController", ^{
    __block SuspectPhotoDetailViewController *controller;
    __block id<SuspectPhotoDetailViewControllerDelegate> delegate;
    __block Person *person;
    __block KSDeferred *getImageDataDeferred;
    __block Portrayal *portrayal2 = [[Portrayal alloc]
                                     initWithPhotoURL:[[NSBundle bundleForClass:[self class]] URLForResource:@"cathy" withExtension:@"jpg" subdirectory:@"SampleLineup"]
                                     date:[NSDate dateWithTimeIntervalSince1970:1396968887]];

    void(^configureAndPresentController)() = ^{
        [controller configureWithDelegate:delegate person:person portrayal:portrayal2];
        [UIApplication showViewController:controller];
    };

    beforeEach(^{
        controller = [[UIStoryboard storyboardWithName:@"PhotoDBFlow" bundle:nil] instantiateViewControllerWithIdentifier:@"SuspectPhotoDetailViewController"];
        Portrayal *portrayal1 = [[Portrayal alloc] initWithPhotoURL:[NSURL URLWithString:@"http://example.com/myphotoURL1.jpg"]
                                                               date:[NSDate date]];
        person = [[Person alloc] initWithFirstName:@"Sterling"
                                          lastName:@"Archer"
                                       dateOfBirth:[NSDate date]
                                          systemID:@"12345"
                                        portrayals:@[portrayal1, portrayal2]];
        delegate = nice_fake_for(@protocol(SuspectPhotoDetailViewControllerDelegate));

        spy_on(portrayal2);
        getImageDataDeferred = [KSDeferred defer];
        portrayal2 stub_method(@selector(getPhotoURLData)).and_return(getImageDataDeferred.promise);
        configureAndPresentController();
    });

    it(@"should have asked the portrayal to retrieve its image data", ^{
        portrayal2 should have_received(@selector(getPhotoURLData));
    });

    it(@"should display a caption describing the portrayal photo", ^{
        controller.captionLabel.text should equal(@"Sterling Archer. Photo taken 4/8/2014");
    });

    it(@"should disable the select suspect photo button", ^{
        controller.selectSuspectPhotoButton.enabled should be_falsy;
    });

    describe(@"when retrieving the portrayal image data fails", ^{
        beforeEach(^{
            [getImageDataDeferred rejectWithError:nil];
        });
        
        it(@"should alert the user", ^{
            [UIAlertView currentAlertView] should_not be_nil;
        });

        describe(@"when the alert is dismissed", ^{
            beforeEach(^{
                [[UIAlertView currentAlertView] dismissWithCancelButton];
            });

            it(@"should inform the delegate", ^{
                delegate should have_received(@selector(suspectPhotoDetailViewControllerDidCancel:)).with(controller);
            });
        });
    });

    describe(@"when retrieving the portrayal image data succeeds", ^{
        beforeEach(^{
            [getImageDataDeferred resolveWithValue:[NSData dataWithContentsOfURL:portrayal2.photoURL]];
        });

        it(@"should display the portrayal photo in the image view", ^{
            [controller.portrayalImageView.image isEqualToByBytes:[UIImage imageWithData:[NSData dataWithContentsOfURL:portrayal2.photoURL]]] should be_truthy;
        });

        it(@"should enable the select suspect photo button", ^{
            controller.selectSuspectPhotoButton.enabled should be_truthy;
        });

        describe(@"when the 'Select suspect photo' button is tapped", ^{
            beforeEach(^{
                [controller.selectSuspectPhotoButton tap];
            });

            it(@"should inform the delegate", ^{
                delegate should have_received(@selector(suspectPhotoDetailViewController:didSelectPortrayal:)).with(controller, portrayal2);
            });
        });
    });

    describe(@"when the cancel button is tapped", ^{
        beforeEach(^{
            [controller.cancelButton tap];
        });

        it(@"should inform the delegate", ^{
            delegate should have_received(@selector(suspectPhotoDetailViewControllerDidCancel:)).with(controller);
        });
    });
});

SPEC_END
