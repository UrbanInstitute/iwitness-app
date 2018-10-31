#import "SuspectSearchViewController.h"
#import "SuspectSearchViewControllerDelegate.h"

@interface SuspectSearchViewController ()

@property (nonatomic, copy) NSString *caseID;
@property (nonatomic, weak) id<SuspectSearchViewControllerDelegate> delegate;
@end

@implementation SuspectSearchViewController
//MOK adds
@dynamic view;
- (void)configureWithCaseID:(NSString *)caseID delegate:(id<SuspectSearchViewControllerDelegate>)delegate {
    self.caseID = caseID;
    self.delegate = delegate;

    if ([self isViewLoaded]) {
        self.view.caseIDLabel.text = self.caseID;
    }
}

- (IBAction)searchTapped {
    [self.view.firstNameTextField resignFirstResponder];
    [self.view.lastNameTextField resignFirstResponder];
    [self.view.suspectIDTextField resignFirstResponder];

    [self.delegate suspectSearchViewController:self
                 didRequestSearchWithFirstName:self.view.firstNameTextField.text
                                      lastName:self.view.lastNameTextField.text
                                     suspectID:self.view.suspectIDTextField.text];

    self.view.searchButton.enabled = NO;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    self.view.searchButton.enabled = YES;
    return YES;
}


@end
