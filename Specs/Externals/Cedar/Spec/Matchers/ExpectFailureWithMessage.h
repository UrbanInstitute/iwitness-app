#import <Foundation/Foundation.h>
#import "CDRExampleBase.h"

void expectFailureWithMessage(NSString *message, CDRSpecBlock block);
void expectExceptionWithReason(NSString *reason, CDRSpecBlock block);
