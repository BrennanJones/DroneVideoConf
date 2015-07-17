//
//  DroneVideoViewController.h
//  DVC-MobileClient-iOS
//


#import <UIKit/UIKit.h>

#import "DeviceController.h"
#import "DroneVideoView.h"


@interface DroneVideoViewController : UIViewController <DroneVideoDelegate>

@property (strong, nonatomic) IBOutlet DroneVideoView *droneVideoView;

@end
