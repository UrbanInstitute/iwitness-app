#import "Presentation.h"
#import "Lineup.h"
#import "NSFileManager+CommonDirectories.h"
#import "Presentation+SpecHelpers.h"
#import "NSURL+RelativeSandboxPaths.h"
#import "VideoStitcher.h"
#import "PresentationStore.h"
#import "StitchingQueue.h"
#import "Person.h"
#import "Portrayal.h"
#import "PersonFactory.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(PresentationSpec)

describe(@"Presentation", ^{
    __block Presentation *presentation1, *presentation2;
    __block Lineup *lineup;
    __block NSSet *lineupPhotoURLs;
    __block PresentationStore *presentationStore;

    beforeEach(^{
        lineup = nice_fake_for([Lineup class]);
        NSArray *allPhotoURLs = [[[NSBundle bundleForClass:[self class]] URLsForResourcesWithExtension:@"jpg" subdirectory:@"SampleLineup"] collect:^NSURL *(NSURL *url) {
            return [NSURL fileURLFromPathRelativeToApplicationSandbox:[url pathRelativeToApplicationSandbox]];
        }];

        Person *suspect = nice_fake_for([Person class]);
        Portrayal *portrayal = [[Portrayal alloc] initWithPhotoURL:allPhotoURLs.firstObject date:[NSDate date]];
        suspect stub_method(@selector(portrayals)).and_return(@[portrayal]);
        suspect stub_method(@selector(selectedPortrayal)).and_return(portrayal);

        lineup stub_method(@selector(suspect)).and_return(suspect);
        lineup stub_method(@selector(fillerPhotosFileURLs)).and_return([allPhotoURLs subarrayWithRange:NSMakeRange(1, allPhotoURLs.count - 1)]);

        presentation1 = [[Presentation alloc] initFromSampleLineupWithSeed:1234];
        presentation1.videoURL = [NSURL fileURLFromPathRelativeToApplicationSandbox:@"a/relative/url"];
        presentation1.videoPreviewTimeRange = CMTimeRangeMake(CMTimeMakeWithSeconds(1.5, 30), CMTimeMakeWithSeconds(5, 30));
        [presentation1 finalizeWithStitchingQueue:nil videoPreviewTimeRange:kCMTimeRangeInvalid];
        presentation2 = [[Presentation alloc] initFromSampleLineupWithSeed:12345678];

        lineupPhotoURLs = [NSSet setWithArray:allPhotoURLs];

        presentationStore = nice_fake_for([PresentationStore class]);
        presentation1.store = presentationStore;
        presentation2.store = presentationStore;
    });

    it(@"should have a temporary camera recording URL based on the presentation UUID", ^{
        NSURL *expectedURL = [[[[NSFileManager defaultManager] URLForApplicationSupportDirectory] URLByAppendingPathComponent:presentation1.UUID] URLByAppendingPathComponent:@"camera.mov"];
        presentation1.temporaryCameraRecordingURL should equal(expectedURL);
    });

    it(@"should have a temporary screen capture URL based on the presentation UUID", ^{
        NSURL *expectedURL = [[[[NSFileManager defaultManager] URLForApplicationSupportDirectory] URLByAppendingPathComponent:presentation1.UUID] URLByAppendingPathComponent:@"screen.mov"];
        presentation1.temporaryScreenCaptureURL should equal(expectedURL);
    });

    it(@"should have a temporary stitching URL based on the presentation UUID", ^{
        NSURL *expectedURL = [[[[NSFileManager defaultManager] URLForApplicationSupportDirectory] URLByAppendingPathComponent:presentation1.UUID] URLByAppendingPathComponent:@"stitched.mov"];
        presentation1.temporaryStitchingURL should equal(expectedURL);
    });

    describe(@"finalizing a presentation with content to be stitched", ^{
        __block StitchingQueue *stitchingQueue;
        __block VideoStitcher *videoStitcher;
        __block KSDeferred *stitchingDeferred;

        beforeEach(^{
            stitchingDeferred = [KSDeferred defer];
            videoStitcher = nice_fake_for([VideoStitcher class]);
            videoStitcher stub_method(@selector(stitchCameraCaptureAtURL:withScreenCaptureAtURL:outputURL:videoPreviewTimeRange:excludeCameraVideo:)).and_return(stitchingDeferred.promise);

            stitchingQueue = nice_fake_for([StitchingQueue class]);
            stitchingQueue stub_method(@selector(stitcherForPresentation:)).and_return(videoStitcher);

            [presentation1 finalizeWithStitchingQueue:stitchingQueue videoPreviewTimeRange:kCMTimeRangeZero];
        });

        it(@"should enqeue the video stitching for this presentation", ^{
            stitchingQueue should have_received(@selector(enqueueStitcherForPresentation:)).with(presentation1);
        });

        it(@"should store the video playback time range", ^{
            presentation1.videoPreviewTimeRange should equal(kCMTimeRangeZero);
        });

        it(@"should save the updated instructional video playback time ranges", ^{
            presentationStore should have_received(@selector(updatePresentation:)).with(presentation1);
        });
    });

    sharedExamplesFor(@"attaching the expected video to the presentation", ^(NSDictionary *sharedContext) {
        it(@"should remove the working directory", ^{
            [[NSFileManager defaultManager] fileExistsAtPath:[presentation1.temporaryWorkingDirectory path]] should be_falsy;
        });

        it(@"should persist the edited presentation", ^{
            presentationStore should have_received(@selector(updatePresentation:)).with(presentation1);
        });

        it(@"should move the video URL to a path based on the presentation's date with a suffix to make it unique", ^{
            [NSData dataWithContentsOfURL:sharedContext[@"expectedVideoURL"]] should equal([@"DUMMY-VIDEO-DATA" dataUsingEncoding:NSUTF8StringEncoding]);
        });

        it(@"should set the final video URL of the presentation", ^{
            presentation1.videoURL should equal(sharedContext[@"expectedVideoURL"]);
        });

        it(@"should move the lineup review PDF to a path with the same base name as the video", ^{
            [NSData dataWithContentsOfURL:sharedContext[@"expectedLineupReviewURL"]] should equal([@"DUMMY-PDF-LINEUP-REVIEW-DATA" dataUsingEncoding:NSUTF8StringEncoding]);
        });
    });

    sharedExamplesFor(@"generating attachments", ^(NSDictionary *sharedContext) {
        __block NSURL *expectedVideoURL, *expectedLineupReviewURL;
        __block NSString *dateFormattedForFileName;

        beforeEach(^{
            NSDateFormatter *fileNameDateFormatter = [[NSDateFormatter alloc] init];
            [fileNameDateFormatter setDateFormat:@"yyyy-MM-dd-HHmmss"];
            dateFormattedForFileName = [fileNameDateFormatter stringFromDate:presentation1.date];

            expectedVideoURL = [[[NSFileManager defaultManager] URLForDocumentDirectory] URLByAppendingPathComponent:[NSString stringWithFormat:@"%@-%@.mov", dateFormattedForFileName, presentation1.lineup.caseID]];
            expectedLineupReviewURL = [[expectedVideoURL URLByDeletingPathExtension] URLByAppendingPathExtension:@"pdf"];
            [@"DUMMY-PDF-LINEUP-REVIEW-DATA" writeToURL:presentation1.temporaryLineupReviewURL atomically:YES encoding:NSUTF8StringEncoding error:nil];
        });

        afterEach(^{
            [[NSFileManager defaultManager] removeItemAtURL:expectedVideoURL error:nil];
            [[NSFileManager defaultManager] removeItemAtURL:expectedLineupReviewURL error:nil];
        });

        context(@"when the URL for the final attached video is not in use", ^{
            beforeEach(^{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                [presentation1 performSelector:NSSelectorFromString(sharedContext[@"attachmentGenerationMethod"])];
#pragma clang diagnostic pop
                SpecHelper.specHelper.sharedExampleContext[@"expectedVideoURL"] = expectedVideoURL;
                SpecHelper.specHelper.sharedExampleContext[@"expectedLineupReviewURL"] = expectedLineupReviewURL;
            });

            itShouldBehaveLike(@"attaching the expected video to the presentation");
        });

        context(@"when the URL for the final attached video is already in use", ^{
            __block NSURL *newExpectedVideoURL, *newExpectedLineupReviewURL, *existingVideoURL;

            beforeEach(^{
                existingVideoURL = expectedVideoURL;
                newExpectedVideoURL = [[[NSFileManager defaultManager] URLForDocumentDirectory] URLByAppendingPathComponent:[NSString stringWithFormat:@"%@-%@-1.mov", dateFormattedForFileName, presentation1.lineup.caseID]];
                newExpectedLineupReviewURL = [[newExpectedVideoURL URLByDeletingPathExtension] URLByAppendingPathExtension:@"pdf"];
                [[NSFileManager defaultManager] createFileAtPath:[existingVideoURL path]
                                                        contents:[@"foo" dataUsingEncoding:NSUTF8StringEncoding]
                                                      attributes:nil];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                [presentation1 performSelector:NSSelectorFromString(sharedContext[@"attachmentGenerationMethod"])];
#pragma clang diagnostic pop

                SpecHelper.specHelper.sharedExampleContext[@"expectedVideoURL"] = newExpectedVideoURL;
                SpecHelper.specHelper.sharedExampleContext[@"expectedLineupReviewURL"] = newExpectedLineupReviewURL;
            });

            afterEach(^{
                [[NSFileManager defaultManager] removeItemAtURL:newExpectedVideoURL error:nil];
                [[NSFileManager defaultManager] removeItemAtURL:newExpectedLineupReviewURL error:nil];
            });

            itShouldBehaveLike(@"attaching the expected video to the presentation");

            it(@"should not overwrite the original file", ^{
                [NSData dataWithContentsOfURL:expectedVideoURL] should equal([@"foo" dataUsingEncoding:NSUTF8StringEncoding]);
            });
        });

        context(@"when the URL for the final attached video's lineup review PDF is already in use", ^{
            __block NSURL *newExpectedVideoURL, *newExpectedLineupReviewURL, *existingLineupReviewURL;

            beforeEach(^{
                existingLineupReviewURL = expectedLineupReviewURL;
                newExpectedVideoURL = [[[NSFileManager defaultManager] URLForDocumentDirectory] URLByAppendingPathComponent:[NSString stringWithFormat:@"%@-%@-1.mov", dateFormattedForFileName, presentation1.lineup.caseID]];
                newExpectedLineupReviewURL = [[newExpectedVideoURL URLByDeletingPathExtension] URLByAppendingPathExtension:@"pdf"];
                [[NSFileManager defaultManager] createFileAtPath:[existingLineupReviewURL path]
                                                        contents:[@"foo" dataUsingEncoding:NSUTF8StringEncoding]
                                                      attributes:nil];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                [presentation1 performSelector:NSSelectorFromString(sharedContext[@"attachmentGenerationMethod"])];
#pragma clang diagnostic pop

                SpecHelper.specHelper.sharedExampleContext[@"expectedVideoURL"] = newExpectedVideoURL;
                SpecHelper.specHelper.sharedExampleContext[@"expectedLineupReviewURL"] = newExpectedLineupReviewURL;
            });

            afterEach(^{
                [[NSFileManager defaultManager] removeItemAtURL:newExpectedVideoURL error:nil];
                [[NSFileManager defaultManager] removeItemAtURL:newExpectedLineupReviewURL error:nil];
            });

            itShouldBehaveLike(@"attaching the expected video to the presentation");

            it(@"should not overwrite the original file", ^{
                [NSData dataWithContentsOfURL:existingLineupReviewURL] should equal([@"foo" dataUsingEncoding:NSUTF8StringEncoding]);
            });
        });
    });

    describe(@"finalizing a presentation without screen capture", ^{
        beforeEach(^{
            [@"DUMMY-VIDEO-DATA" writeToURL:presentation1.temporaryCameraRecordingURL atomically:YES encoding:NSUTF8StringEncoding error:nil];
            SpecHelper.specHelper.sharedExampleContext[@"attachmentGenerationMethod"] = NSStringFromSelector(@selector(finalizeWithoutScreenCapture));
        });

        itShouldBehaveLike(@"generating attachments");
    });

    describe(@"finalizing a presentation without camera capture", ^{
        beforeEach(^{
            [@"DUMMY-VIDEO-DATA" writeToURL:presentation1.temporaryScreenCaptureURL atomically:YES encoding:NSUTF8StringEncoding error:nil];
            SpecHelper.specHelper.sharedExampleContext[@"attachmentGenerationMethod"] = NSStringFromSelector(@selector(finalizeWithoutCameraCapture));
        });

        itShouldBehaveLike(@"generating attachments");
    });

    describe(@"attaching the stitched video", ^{
        beforeEach(^{
            [@"DUMMY-VIDEO-DATA" writeToURL:presentation1.temporaryStitchingURL atomically:YES encoding:NSUTF8StringEncoding error:nil];
            SpecHelper.specHelper.sharedExampleContext[@"attachmentGenerationMethod"] = NSStringFromSelector(@selector(attachStitchedVideo));
        });

        itShouldBehaveLike(@"generating attachments");
    });

    describe(@"creating a presentation from a lineup", ^{
        it(@"should present all photos that were part of the provided lineup", ^{
            NSMutableArray *presentedPhotoURLs = [NSMutableArray arrayWithObject:presentation1.currentPhotoURL];

            while ([presentation1 advanceToNextPhoto]) {
                [presentedPhotoURLs addObject:presentation1.currentPhotoURL];
            }

            NSSet *lineupSet = [NSSet setWithArray:[@[lineup.suspect.selectedPortrayal.photoURL] arrayByAddingObjectsFromArray:lineup.fillerPhotosFileURLs]];
            NSSet *presentedSet = [NSSet setWithArray:presentedPhotoURLs];

            lineupSet should equal(presentedSet);
        });

        it(@"should be assigned a unique identifier", ^{
            presentation1.UUID should_not equal(presentation2.UUID);
        });
    });

    describe(@"advancing to the next photo", ^{
        it(@"should return YES if there are more photos", ^{
            [presentation1 advanceToNextPhoto] should be_truthy;
        });

        it(@"should return NO if the current photo is the last", ^{
            for (NSInteger i = 0; i < [lineupPhotoURLs count] - 1; ++i) {
                [presentation1 advanceToNextPhoto];
            }
            [presentation1 advanceToNextPhoto] should be_falsy;
        });
    });

    describe(@"getting the current photo URL", ^{
        it(@"should return an image from the canned sample images", ^{
            [lineupPhotoURLs containsObject:presentation1.currentPhotoURL];
            [lineupPhotoURLs containsObject:presentation2.currentPhotoURL];
        });

        it(@"should return the same current image for the same random seed", ^{
            [[Presentation alloc] initWithLineup:lineup randomSeed:1234].currentPhotoURL should equal(presentation1.currentPhotoURL);
        });

        it(@"should return a different image for a different random seed", ^{
            presentation1.currentPhotoURL should_not equal(presentation2.currentPhotoURL);
        });

        it(@"should never return the suspect's photo as the first photo in the lineup", ^{
            NSArray *lineupPhotoURLsArray = [lineupPhotoURLs allObjects];
            Lineup *smallLineup = [[Lineup alloc] init];
            Portrayal *portrayal = [[Portrayal alloc] initWithPhotoURL:lineupPhotoURLsArray[0] date:[NSDate date]];
            smallLineup.suspect.portrayals = @[portrayal];
            smallLineup.fillerPhotosFileURLs = @[lineupPhotoURLsArray[1]];

            for (int i=0; i<20; i++) {
                Presentation *presentation = [[Presentation alloc] initWithLineup:smallLineup randomSeed:(unsigned)time(NULL)];
                [presentation currentPhotoURL] should_not equal(smallLineup.suspect.selectedPortrayal.photoURL);
            }
        });

        context(@"when advanced to the next photo", ^{
            __block NSURL *previousPhotoURL;

            beforeEach(^{
                previousPhotoURL = presentation1.currentPhotoURL;
                [presentation1 advanceToNextPhoto];
            });

            it(@"should return a different photo", ^{
                presentation1.currentPhotoURL should_not equal(previousPhotoURL);
            });
        });

        context(@"when an attempt to advance past the next photo has been made", ^{
            beforeEach(^{
                for (NSInteger i = 0; i < [lineupPhotoURLs count] - 1; ++i) {
                    [presentation1 advanceToNextPhoto];
                }
                [presentation1 advanceToNextPhoto] should be_falsy;
            });

            it(@"should not blow up", ^{
                ^{ [presentation1 currentPhotoURL]; } should_not raise_exception;
            });
        });

        sharedExamplesFor(@"advancing through all photos", ^(NSDictionary *context) {
            __block NSMutableSet *photos;

            beforeEach(^{
                photos = [NSMutableSet set];
                [photos addObject:presentation1.currentPhotoURL];

                while ([presentation1 advanceToNextPhoto]) {
                    [photos addObject:presentation1.currentPhotoURL];
                }
            });

            it(@"should return all photos by the end", ^{
                photos should equal(lineupPhotoURLs);
            });
        });

        itShouldBehaveLike(@"advancing through all photos");

        describe(@"rolling back to the first photo", ^{
            beforeEach(^{
                while ([presentation1 advanceToNextPhoto]) { }
                [presentation1 rollBackToFirstPhoto];
            });

            itShouldBehaveLike(@"advancing through all photos");
        });
    });

    describe(@"when the presentation is archived", ^{
        __block NSData *persistedPresentationData;

        beforeEach(^{
            persistedPresentationData = [NSKeyedArchiver archivedDataWithRootObject:presentation1];
        });

        it(@"should unarchive successfully", ^{
            [NSKeyedUnarchiver unarchiveObjectWithData:persistedPresentationData] should equal(presentation1);
        });
    });

    describe(@"presentation equality and hash", ^{
        __block Lineup *theLineup;
        __block Lineup *theOtherLineup;

        __block Presentation *thePresentation;
        __block Presentation *theOtherPresentation;

        beforeEach(^{
            theLineup = [[Lineup alloc] initWithCreationDate:[NSDate dateWithTimeIntervalSince1970:98712345]
                                                     suspect:[PersonFactory leon]];
            theLineup.fillerPhotosFileURLs = [lineupPhotoURLs allObjects];

            theOtherLineup = [[Lineup alloc] initWithCreationDate:[NSDate dateWithTimeIntervalSince1970:12345678]
                                                          suspect:[PersonFactory larry]];
            theOtherLineup.fillerPhotosFileURLs = [lineupPhotoURLs allObjects];

            thePresentation = [[Presentation alloc] initWithLineup:theLineup randomSeed:12345];
            theOtherPresentation = [thePresentation copy];

            spy_on(theOtherPresentation);
        });

        it(@"should be equal for a presentation with the same values", ^{
            [thePresentation isEqual:theOtherPresentation] should be_truthy;
        });

        xit(@"should have the same hash as a presentation with the same values", ^{
            thePresentation.hash should equal(theOtherPresentation.hash);
        });

        sharedExamplesFor(@"the presentations are not equal", ^(NSDictionary *sharedContext) {
            it(@"should not be equal", ^{
                [thePresentation isEqual:theOtherPresentation] should be_falsy;
            });

            //TODO: remove after https://www.pivotaltracker.com/story/show/70969240 is fixed in Cedar
            xit(@"should not have the same hash", ^{
                thePresentation.hash should_not equal(theOtherPresentation.hash);
            });
        });

        context(@"when the lineup is different", ^{
            beforeEach(^{
                theOtherPresentation stub_method(@selector(lineup)).and_return(theOtherLineup);
            });

            itShouldBehaveLike(@"the presentations are not equal");
        });

        context(@"when the date is different", ^{
            beforeEach(^{
                theOtherPresentation stub_method(@selector(date)).and_return([NSDate dateWithTimeInterval:1000 sinceDate:thePresentation.date]);
            });

            itShouldBehaveLike(@"the presentations are not equal");
        });

        context(@"when the video URL is different", ^{
            beforeEach(^{
                theOtherPresentation stub_method(@selector(videoURL)).and_return([NSURL URLWithString:@"file://a/different/URL"]);
            });

            itShouldBehaveLike(@"the presentations are not equal");
        });

        context(@"when the video preview time range is different", ^{
            beforeEach(^{
                theOtherPresentation stub_method(@selector(videoPreviewTimeRange)).and_return(CMTimeRangeMake(CMTimeMakeWithSeconds(1234, 1), CMTimeMakeWithSeconds(1, 1)));
            });

            itShouldBehaveLike(@"the presentations are not equal");
        });

        context(@"when the UUID is different", ^{
            beforeEach(^{
                theOtherPresentation stub_method(@selector(UUID)).and_return(@"1234-ABCD-1234-ABCD-1234-NOT-A-REAL-UUID-JUST-DIFFERENT");
            });

            itShouldBehaveLike(@"the presentations are not equal");
        });
    });

    describe(@"copying a presentation", ^{
        __block Presentation *copiedPresentation;

        beforeEach(^{
            presentation1.videoURL = [NSURL URLWithString:@"/video/url"];
            copiedPresentation = [presentation1 copy];
        });

        it(@"should copy the presentation and its properties", ^{
            copiedPresentation.UUID should equal(presentation1.UUID);
            copiedPresentation.lineup should equal(presentation1.lineup);
            copiedPresentation.date should equal(presentation1.date);
            copiedPresentation.videoURL should equal(presentation1.videoURL);
            copiedPresentation.videoPreviewTimeRange should equal(presentation1.videoPreviewTimeRange);
            [copiedPresentation currentPhotoURL] should equal([presentation1 currentPhotoURL]);
            while ([presentation1 advanceToNextPhoto]) {
                [copiedPresentation advanceToNextPhoto] should be_truthy;
                [copiedPresentation currentPhotoURL] should equal([presentation1 currentPhotoURL]);
            }
            [copiedPresentation advanceToNextPhoto] should_not be_truthy;
        });
    });

    describe(@"persisting videoURL's relative path", ^{
        __block NSKeyedArchiver *archiver;

        beforeEach(^{
            NSURL *documentsDir = [[NSFileManager defaultManager] URLForDocumentDirectory];
            presentation1.videoURL = [documentsDir URLByAppendingPathComponent:@"video.mov"];

            archiver = nice_fake_for([NSKeyedArchiver class]);
            [presentation1 encodeWithCoder:archiver];
        });

        it(@"should store the path of the video url relative to the application sandbox's root", ^{
            archiver should have_received(@selector(encodeObject:forKey:)).with(@"Documents/video.mov", @"videoURL");
        });
    });

    describe(@"deleting video files", ^{
        __block NSFileManager *fileManager;

        beforeEach(^{
            fileManager = fake_for([NSFileManager class]);
            fileManager stub_method(@selector(removeItemAtURL:error:));

            [presentation1 deleteVideoFilesWithFileManager:fileManager];
        });

        it(@"should remove the stitched video from disk", ^{
            fileManager should have_received(@selector(removeItemAtURL:error:)).with(presentation1.videoURL, Arguments::anything);
        });

        it(@"should remove the working directory from disk", ^{
            fileManager should have_received(@selector(removeItemAtURL:error:)).with(presentation1.temporaryWorkingDirectory, Arguments::anything);
        });
    });
});

SPEC_END
