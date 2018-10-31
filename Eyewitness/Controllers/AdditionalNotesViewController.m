#import "AdditionalNotesViewController.h"
#import "PerpetratorDescription.h"

@interface AdditionalNotesViewController ()<UITextViewDelegate>

@property (weak, nonatomic, readwrite) IBOutlet UILabel *caseIDLabel;
@property (weak, nonatomic, readwrite) IBOutlet UITextView *additionalNotesTextView;
@property(nonatomic, strong) PerpetratorDescription *perpetratorDescription;
@property(nonatomic, copy) NSString *caseID;
@end

@implementation AdditionalNotesViewController

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillAppear:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillDisappear:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    self.caseIDLabel.text = self.caseID;
    self.additionalNotesTextView.text = self.perpetratorDescription.additionalNotes;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.additionalNotesTextView becomeFirstResponder];

}

- (void)configureWithCaseID:(NSString *)caseID perpetratorDescription:(PerpetratorDescription *)perpetratorDescription {
    self.caseID = caseID;
    self.perpetratorDescription = perpetratorDescription;
}

#pragma mark - keyboard notification handling

- (void)keyboardWillAppear:(NSNotification *)notification {
    CGRect finalKeyboardFrame = [notification.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    self.additionalNotesTextView.contentInset = self.additionalNotesTextView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, CGRectGetHeight(finalKeyboardFrame), 0);
}

- (void)keyboardWillDisappear:(NSNotification *)notification {
    self.additionalNotesTextView.contentInset = self.additionalNotesTextView.scrollIndicatorInsets = UIEdgeInsetsZero;
}

#pragma mark - <UITextFieldDelegate>

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    self.perpetratorDescription.additionalNotes = [self.perpetratorDescription.additionalNotes stringByReplacingCharactersInRange:range withString:text];
    return YES;
}

@end
