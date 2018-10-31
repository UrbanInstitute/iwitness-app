#import "LineupPhotosDataSource.h"
#import "LineupPhotoCell.h"
#import "AddPhotoCell.h"
#import "UIImageView+FocusOnRect.h"
#import "PhotoAssetMetadataManager.h"
#import "LineupPhotoCellDelegate.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

@interface LineupPhotosDataSource (Specs)
@property (nonatomic, weak) UICollectionView *collectionView;
@end

SPEC_BEGIN(LineupPhotosDataSourceSpec)

describe(@"LineupPhotosDataSource", ^{
    __block LineupPhotosDataSource *dataSource;
    __block PhotoAssetMetadataManager *metadataManager;
    __block id<LineupPhotoCellDelegate> photoCellDelegate;
    __block UICollectionView *collectionView;
    __block LineupPhotoCell *photoCell;
    __block NSURL *imageURL, *imageURL2;

    beforeEach(^{
        dataSource = [[LineupPhotosDataSource alloc] init];

        collectionView = nice_fake_for([UICollectionView class]);
        collectionView stub_method(@selector(dequeueReusableCellWithReuseIdentifier:forIndexPath:)).with(@"LineupPhotoCell", Arguments::any([NSIndexPath class])).and_do_block(^UICollectionViewCell *(NSString *reuseIdentifier, NSIndexPath *indexPath){
            photoCell = [[LineupPhotoCell alloc] init];
            spy_on(photoCell);
            UIImageView *imageView = [[UIImageView alloc] init];
            spy_on(imageView);
            photoCell stub_method(@selector(imageView)).and_return(imageView);
            return photoCell;
        });

        collectionView stub_method(@selector(dequeueReusableCellWithReuseIdentifier:forIndexPath:)).with(@"AddPhotoCell", Arguments::any([NSIndexPath class])).and_return([[AddPhotoCell alloc] init]);

        collectionView stub_method(@selector(performBatchUpdates:completion:)).and_do_block(^(void(^batchUpdates)(), void(^completion)(BOOL)){
            batchUpdates();
        });

        dataSource.collectionView = collectionView;

        photoCellDelegate = fake_for(@protocol(LineupPhotoCellDelegate));
        metadataManager = nice_fake_for([PhotoAssetMetadataManager class]);
        [dataSource configureWithLineupPhotoCellDelegate:photoCellDelegate metadataManager:metadataManager];

        imageURL = [[NSBundle bundleForClass:[self class]] URLForResource:@"cathy" withExtension:@"jpg" subdirectory:@"SampleLineup"];
        imageURL2 = [[NSBundle bundleForClass:[self class]] URLForResource:@"nathan" withExtension:@"jpg" subdirectory:@"SampleLineup"];

        dataSource.photoURLs = @[ imageURL, imageURL2 ];
    });

    describe(@"configuring a photo cell", ^{
        __block LineupPhotoCell *cell;

        beforeEach(^{
            metadataManager stub_method(@selector(largestFaceRectForPhotoURL:)).and_return(CGRectMake(1, 2, 3, 4));
            cell = (LineupPhotoCell *)[dataSource collectionView:collectionView
                                          cellForItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
            cell should be_instance_of([LineupPhotoCell class]);
        });

        it(@"should set the correct image on the cell", ^{
            UIImage *image = [UIImage imageWithContentsOfFile:[imageURL path]];
            [cell.imageView.image isEqualToByBytes:image] should be_truthy;
        });

        it(@"should pass the photo cell delegate down to the cell", ^{
            cell should have_received(@selector(configureWithDelegate:)).with(photoCellDelegate);
        });

        it(@"should center on the largest face", ^{
            cell.imageView should have_received(@selector(focusOnImageRect:)).with(CGRectMake(1, 2, 3, 4));
        });
    });

    context(@"maximum photo limit not reached", ^{
        beforeEach(^{
            dataSource.maximumNumberOfPhotos = 6;
        });

        sharedExamplesFor(@"setting editing on cells when editing changes", ^(NSDictionary *sharedContext) {
            __block LineupPhotoCell *photoCell1, *photoCell2;

            beforeEach(^{
                photoCell1 = nice_fake_for([LineupPhotoCell class]);
                photoCell2 = nice_fake_for([LineupPhotoCell class]);
                UICollectionViewCell *someOtherCell = nice_fake_for([UICollectionViewCell class]);
                collectionView stub_method(@selector(visibleCells)).and_return(@[ photoCell1, photoCell2, someOtherCell ]);
            });

            describe(@"when editing stops", ^{
                beforeEach(^{
                    dataSource.editing = YES;
                    [(id<CedarDouble>)photoCell1 reset_sent_messages];
                    [(id<CedarDouble>)photoCell2 reset_sent_messages];
                    dataSource.editing = NO;
                });

                it(@"should update the editing status of visible cells", ^{
                    photoCell1 should have_received(@selector(setEditing:)).with(NO);
                    photoCell2 should have_received(@selector(setEditing:)).with(NO);
                });
            });

            describe(@"when editing starts", ^{
                beforeEach(^{
                    dataSource.editing = NO;
                    [(id<CedarDouble>)photoCell1 reset_sent_messages];
                    [(id<CedarDouble>)photoCell2 reset_sent_messages];
                    dataSource.editing = YES;
                });

                it(@"should update the editing status of visible cells", ^{
                    photoCell1 should have_received(@selector(setEditing:)).with(YES);
                    photoCell2 should have_received(@selector(setEditing:)).with(YES);
                });
            });
        });

        context(@"the collection view is showing the 'add photo' cell", ^{
            beforeEach(^{
                collectionView stub_method(@selector(numberOfItemsInSection:)).with(0).and_return((NSInteger)dataSource.photoURLs.count + 1);
            });

            itShouldBehaveLike(@"setting editing on cells when editing changes");

            it(@"should notify the collection view that the add photo cell was removed when editing stops", ^{
                dataSource.editing = YES;
                dataSource.editing = NO;
                collectionView should have_received(@selector(deleteItemsAtIndexPaths:)).with(@[ [NSIndexPath indexPathForItem:2 inSection:0] ]);
            });

            it(@"should not notify the collection that the add photo cell was added when editing starts", ^{
                dataSource.editing = NO;
                dataSource.editing = YES;
                collectionView should_not have_received(@selector(insertItemsAtIndexPaths:));
            });
        });

        context(@"the collection view is not showing the 'add photo' cell", ^{
            beforeEach(^{
                collectionView stub_method(@selector(numberOfItemsInSection:)).with(0).and_return((NSInteger)dataSource.photoURLs.count);
            });

            itShouldBehaveLike(@"setting editing on cells when editing changes");

            it(@"should not notify the collection view that the add photo cell was removed when editing stops", ^{
                dataSource.editing = YES;
                dataSource.editing = NO;
                collectionView should_not have_received(@selector(deleteItemsAtIndexPaths:));
            });

            it(@"should notify the collection that the add photo cell was added when editing starts", ^{
                dataSource.editing = NO;
                dataSource.editing = YES;
                collectionView should have_received(@selector(insertItemsAtIndexPaths:)).with(@[ [NSIndexPath indexPathForItem:2 inSection:0] ]);
            });
        });

        describe(@"when editing", ^{
            beforeEach(^{
                dataSource.editing = YES;
            });

            it(@"should provide one item per asset plus 1 more for the 'Add Photo' item", ^{
                [dataSource collectionView:collectionView numberOfItemsInSection:0] should equal(3);
            });

            it(@"should provide editable lineup photo cells for photo items", ^{
                UICollectionViewCell *cell = [dataSource collectionView:collectionView
                                                 cellForItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];

                cell should be_instance_of([LineupPhotoCell class]);
                [(LineupPhotoCell *)cell isEditing] should be_truthy;
            });

            it(@"should provide an 'Add Photo' cell for the last item", ^{
                UICollectionViewCell *cell = [dataSource collectionView:collectionView
                                                 cellForItemAtIndexPath:[NSIndexPath indexPathForItem:2 inSection:0]];

                cell should be_instance_of([AddPhotoCell class]);
            });

            describe(@"when a photo is removed", ^{
                NSIndexPath *firstItemIndexPath = [NSIndexPath indexPathForItem:0 inSection:0];
                __block LineupPhotoCell *photoCell;

                beforeEach(^{
                    photoCell = (LineupPhotoCell *)[dataSource collectionView:collectionView
                                                       cellForItemAtIndexPath:firstItemIndexPath];
                    [(id<CedarDouble>)collectionView reset_sent_messages];

                    collectionView stub_method(@selector(indexPathForCell:)).with(photoCell).and_return(firstItemIndexPath);

                    [dataSource removePhotoURL:dataSource.photoURLs.firstObject];
                });

                it(@"should inform the collection view of the item's deletion", ^{
                    collectionView should have_received(@selector(deleteItemsAtIndexPaths:)).with(@[ firstItemIndexPath ]);
                });

                it(@"should remove the corresponding photo", ^{
                    [dataSource collectionView:collectionView numberOfItemsInSection:0] should equal(2);
                    [dataSource collectionView:collectionView cellForItemAtIndexPath:firstItemIndexPath] should_not be_same_instance_as(photoCell);
                });
            });
        });

        describe(@"when not editing", ^{
            beforeEach(^{
                dataSource.editing = NO;
            });

            it(@"should provide one item per asset", ^{
                [dataSource collectionView:collectionView numberOfItemsInSection:0] should equal(2);
            });

            it(@"should provide non-editable lineup photo cells for photo items", ^{
                UICollectionViewCell *cell = [dataSource collectionView:collectionView
                                                 cellForItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];

                cell should be_instance_of([LineupPhotoCell class]);
                [(LineupPhotoCell *)cell isEditing] should be_falsy;
            });
        });
    });

    context(@"maximum photo limit reached", ^{
        beforeEach(^{
            dataSource.maximumNumberOfPhotos = 2;
        });

        it(@"should provide one item per asset", ^{
            [dataSource collectionView:collectionView numberOfItemsInSection:0] should equal(2);
        });

        describe(@"when editing stops", ^{
            beforeEach(^{
                dataSource.editing = YES;
                dataSource.editing = NO;
            });

            it(@"should not remove any cells", ^{
                collectionView should_not have_received(@selector(deleteItemsAtIndexPaths:));
            });
        });

        describe(@"when editing", ^{
            beforeEach(^{
                dataSource.editing = YES;
            });

            describe(@"when a photo is removed", ^{
                __block LineupPhotoCell *photoCell;
                NSIndexPath *firstItemIndexPath = [NSIndexPath indexPathForItem:0 inSection:0];
                NSIndexPath *lastItemIndexPath = [NSIndexPath indexPathForItem:1 inSection:0];

                beforeEach(^{

                    photoCell = (LineupPhotoCell *)[dataSource collectionView:collectionView
                                                       cellForItemAtIndexPath:firstItemIndexPath];
                    [(id<CedarDouble>)collectionView reset_sent_messages];

                    collectionView stub_method(@selector(indexPathForCell:)).with(photoCell).and_return(firstItemIndexPath);

                    [dataSource removePhotoURL:dataSource.photoURLs.firstObject];
                });

                it(@"should inform the collection view to delete the corresponding cell and add a cell at the end (for the AddPhotoCell)", ^{
                    collectionView should have_received(@selector(deleteItemsAtIndexPaths:)).with(@[ firstItemIndexPath ]);
                    collectionView should have_received(@selector(insertItemsAtIndexPaths:)).with(@[ lastItemIndexPath ]);
                });

                it(@"should remove the corresponding photo, and add an AddPhotoCell at the end", ^{
                    [dataSource collectionView:collectionView numberOfItemsInSection:0] should equal(2);
                    [dataSource collectionView:collectionView cellForItemAtIndexPath:firstItemIndexPath] should_not be_same_instance_as(photoCell);
                    [dataSource collectionView:collectionView cellForItemAtIndexPath:lastItemIndexPath] should be_instance_of([AddPhotoCell class]);
                });
            });
        });
    });
});

SPEC_END
