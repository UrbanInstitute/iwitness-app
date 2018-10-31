#import "PerpetratorAttributesTableViewController.h"
#import "EyewitnessTheme.h"
#import "PerpetratorDescription.h"
#import "AdditionalNotesViewController.h"

@interface PerpetratorAttributesTableViewController ()
@property (weak, nonatomic, readwrite) IBOutlet UIButton *additionalDescriptionTapToEditButton;
@property(nonatomic, copy) NSString *caseID;
@property(nonatomic, strong) PerpetratorDescription *perpetratorDescription;
@end

@implementation PerpetratorAttributesTableViewController

- (void)configureWithCaseID:(NSString *)caseID perpetratorDescription:(PerpetratorDescription *)perpetratorDescription {
    self.caseID = caseID;
    self.perpetratorDescription = perpetratorDescription;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    [super prepareForSegue:segue sender:sender];
    if ([segue.destinationViewController isKindOfClass:[AdditionalNotesViewController class]]) {
        [(AdditionalNotesViewController *)segue.destinationViewController configureWithCaseID:self.caseID perpetratorDescription:self.perpetratorDescription];
    }
}

@end
