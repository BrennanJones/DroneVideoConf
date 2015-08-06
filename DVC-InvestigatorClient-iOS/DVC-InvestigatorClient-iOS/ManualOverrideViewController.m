//
//  ManualOverrideViewController.m
//  DVC-InvestigatorClient-iOS
//

#import "ManualOverrideViewController.h"

@interface ManualOverrideViewController ()

@end

@implementation ManualOverrideViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    NSLog(@"ManualOverrideViewController: viewWillAppear ... ");
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tabBarController.tabBar setBarStyle:UIBarStyleDefault];
        [self.tabBarController.tabBar setTranslucent:NO];
    });
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
