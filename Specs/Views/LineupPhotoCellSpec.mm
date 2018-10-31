#import "LineupPhotoCell.h"
#import "LineupPhotoCellDelegate.h"

using namespace Cedar::Matchers;
using namespace Cedar::Doubles;

SPEC_BEGIN(LineupPhotoCellSpec)

describe(@"LineupPhotoCell", ^{
    __block LineupPhotoCell *cell;
    __block id<LineupPhotoCellDelegate> delegate;

    beforeEach(^{
        cell = [[LineupPhotoCell alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
        delegate = nice_fake_for(@protocol(LineupPhotoCellDelegate));

        [cell configureWithDelegate:delegate];
    });

    describe(@"when loaded with its view hierarchy", ^{
        beforeEach(^{
            UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
            UIButton *deleteButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 20, 20)];

            [cell.contentView addSubview:imageView];
            [cell.contentView addSubview:deleteButton];

            [deleteButton addTarget:cell
                             action:NSSelectorFromString(@"deleteTapped:")
                   forControlEvents:UIControlEventTouchUpInside];
            [cell setValue:imageView forKey:@"imageView"];
            [cell setValue:deleteButton forKey:@"deleteButton"];

            [cell awakeFromNib];
        });

        it(@"should not be initially editable", ^{
            cell.isEditing should be_falsy;
        });

        it(@"should have the delete button hidden by default", ^{
            cell.deleteButton.alpha should equal(0);
        });

        context(@"the cell is editable", ^{
            beforeEach(^{
                [cell setEditing:YES];
            });

            it(@"should allow the user to delete the cell", ^{
                cell.deleteButton.hidden should be_falsy;
            });

            describe(@"when the delete button is tapped", ^{
                beforeEach(^{
                    [cell.deleteButton tap];
                });

                it(@"should notify the delegate for deletion", ^{
                    delegate should have_received(@selector(lineupPhotoCellDidDelete:)).with(cell);
                });
            });
        });

        describe(@"when the cell isn't editable", ^{
            beforeEach(^{
                [cell setEditing:NO];
            });

            it(@"should not allow the user to delete the cell", ^{
                cell.deleteButton.alpha should equal(0);
            });
        });
    });
});

SPEC_END
