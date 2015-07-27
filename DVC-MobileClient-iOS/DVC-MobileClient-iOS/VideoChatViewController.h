//
//  VideoChatViewController.h
//  DVC-MobileClient-iOS
//


#import <UIKit/UIKit.h>

#import "DeviceController.h"
#import "MainViewController.h"


@interface VideoChatViewController : UIViewController <UITextFieldDelegate, ServerConnectionDelegate>

@property(weak, nonatomic) IBOutlet UIView* blackView;

- (IBAction)swapCameras:(id)sender;
- (IBAction)repositionViews:(id)sender;

- (void)applicationWillResignActive:(UIApplication*)application;

@end
