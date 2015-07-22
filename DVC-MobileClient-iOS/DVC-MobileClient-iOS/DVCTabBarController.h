//
//  DVCTabBarController.h
//  DVC-MobileClient-iOS
//


#import <UIKit/UIKit.h>

#import "DeviceController.h"
#import "DVC-Swift.h"


@interface DVCTabBarController : UITabBarController

@property (nonatomic, strong) DeviceController *deviceController;
@property (nonatomic, strong) SocketIOClient *socket;

@end
