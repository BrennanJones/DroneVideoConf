//
//  Utility.m
//  DVC-MobileClient-iOS
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

double radiansToDegrees(double radians)
{
    return radians * (180.0 / M_PI);
}

double degreesToRadians(double degrees)
{
    return degrees * (M_PI / 180.0);
}

@end
