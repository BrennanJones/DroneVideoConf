//
//  DVCTabBarController.m
//  DVC-MobileClient-iOS
//


#import "DVCTabBarController.h"


@interface DVCTabBarController ()

@end


@implementation DVCTabBarController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.viewControllers makeObjectsPerformSelector:@selector(view)];
}

- (void)didReceiveMemoryWarning
{
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
