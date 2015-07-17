//
//  DVCTabBarController.h
//  DVC-MobileClient-iOS
//

#import <UIKit/UIKit.h>

#import "DeviceController.h"


@interface DVCTabBarController : UITabBarController

@property (nonatomic, strong) DeviceController *deviceController;

@end
