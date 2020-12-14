// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBOverlayViewController.h"

@interface MBOverlayViewController ()

@property(nonatomic,strong) UIButton* closeBtn;

@end

@implementation MBOverlayViewController


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor clearColor];
    
    UIView* background = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    background.backgroundColor = [UIColor colorWithWhite:0 alpha:0.7];
    UITapGestureRecognizer* tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGesture:)];
    [background addGestureRecognizer:tap];
    [self.view addSubview:background];
    
    _contentView = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height-50-[self expectedContentHeight], self.view.frame.size.width, [self expectedContentHeight]+50)];
    _contentView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:_contentView];
    
    _headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, _contentView.frame.size.width, 50)];
    _headerView.backgroundColor = [UIColor db_HeaderColor];
    [_contentView addSubview:_headerView];
    
    _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 0, _contentView.frame.size.width, 50)];
    _titleLabel.font = [UIFont db_BoldSeventeen];
    _titleLabel.textColor = [UIColor db_333333];
    _titleLabel.accessibilityTraits = UIAccessibilityTraitHeader;
    [_headerView addSubview:_titleLabel];
    
    _closeBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 50, 50)];
    _closeBtn.accessibilityLabel = @"Schließen";
    [_closeBtn setImage:[UIImage db_imageNamed:@"app_schliessen"] forState:UIControlStateNormal];
    [_closeBtn addTarget:self action:@selector(hideOverlay) forControlEvents:UIControlEventTouchUpInside];
    [_headerView addSubview:_closeBtn];
    
}

- (BOOL)accessibilityViewIsModal {
    return YES;
}

-(NSInteger)expectedContentHeight{
    return self.view.frame.size.height-2*40;
}

-(void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    
    _contentView.frame = CGRectMake(0, self.view.frame.size.height-50-[self expectedContentHeight], self.view.frame.size.width, [self expectedContentHeight]+50);
    self.headerView.frame = CGRectMake(0, 0, _contentView.frame.size.width, 50);
    self.titleLabel.frame = CGRectMake(15, 0, _contentView.frame.size.width, 50);
    [_closeBtn setGravityRight:0];
}

-(void)hideOverlay{
    //some overlays are presented as child viewcontroller, some are presented inside a navigation controller
    if(self.overlayIsPresentedAsChildViewController){
        [self willMoveToParentViewController:nil];
        [self.view removeFromSuperview];
        [self removeFromParentViewController];
    } else {
        [self.navigationController dismissViewControllerAnimated:NO completion:nil];
    }
}

-(void)tapGesture:(UITapGestureRecognizer*)sender{
    if (sender.state == UIGestureRecognizerStateEnded)
    {
        [self hideOverlay];
    }
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
