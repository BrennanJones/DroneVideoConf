//
//  Utility.m
//  DVC-InvestigatorClient-iOS
//

#import "Utility.h"

#import <UIKit/UIKit.h>

@implementation Utility

+ (void)showAlertWithTitle:(NSString *)title withMessage:(NSString *)message
{
    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:title
                                                        message:message
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
    [alertView show];
}

@end
