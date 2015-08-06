//
//  DVCTabBarController.h
//  DVC-InvestigatorClient-iOS
//


#import <UIKit/UIKit.h>

#import "DVCInvestigator-Swift.h"


@interface DVCTabBarController : UITabBarController

@property (nonatomic, strong) SocketIOClient *socket;

@end
