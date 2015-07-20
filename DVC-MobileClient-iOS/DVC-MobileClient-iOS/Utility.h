//
//  Utility.h
//  DVC-MobileClient-iOS
//

#import <Foundation/Foundation.h>

@interface Utility : NSObject

+ (void)showAlertWithTitle:(NSString *)title withMessage:(NSString *)message;

double radiansToDegrees(double radians);
double degreesToRadians(double degrees);

@end
