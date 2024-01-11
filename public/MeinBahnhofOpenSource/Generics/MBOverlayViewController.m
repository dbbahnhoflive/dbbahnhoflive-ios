// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBOverlayViewController.h"
#import "MBUIHelper.h"

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
    
    if(self.usesContentScrollView){
        _contentScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, self.headerView.sizeHeight, self.contentView.sizeWidth, self.contentView.sizeHeight-self.headerView.sizeHeight)];
        [self.contentView addSubview:self.contentScrollView];        
    }
    
    self.titleLabel.text = self.title;

}

-(void)setTitle:(NSString *)title{
    [super setTitle:title];
    self.titleLabel.text = title;
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
    [_closeBtn setGravityRight:0];
    self.titleLabel.frame = CGRectMake(15, 0, _contentView.frame.size.width-_closeBtn.size.width-15, 50);
    
    if(self.usesContentScrollView){
        int totalHeight = MIN(self.view.sizeHeight-50, self.contentScrollView.contentSize.height+self.headerView.sizeHeight);
        [self.contentView setHeight:totalHeight];
        [self.contentView setGravityBottom:0];
        self.contentScrollView.frame = CGRectMake(0, self.headerView.sizeHeight, self.contentView.sizeWidth, self.contentView.sizeHeight-self.headerView.sizeHeight);
    }
}

-(void)updateContentScrollViewContentHeight:(NSInteger)y{
    self.contentScrollView.contentSize = CGSizeMake(self.contentScrollView.frame.size.width, y);
}


-(void)hideOverlay{
    [self hideOverlayWithCompletion:nil];
}

-(void)hideOverlayWithCompletion:(void(^)(void))actionBlock{
    //some overlays are presented as child viewcontroller, some are presented inside a navigation controller
    if(self.overlayIsPresentedAsChildViewController){
        [self willMoveToParentViewController:nil];
        [self.view removeFromSuperview];
        [self removeFromParentViewController];
        if(actionBlock){
            actionBlock();
        }
    } else {
        [self.navigationController dismissViewControllerAnimated:NO completion:^{
            if(actionBlock){
                actionBlock();
            }
        }];
    }
}

-(void)tapGesture:(UITapGestureRecognizer*)sender{
    if (sender.state == UIGestureRecognizerStateEnded)
    {
        [self hideOverlay];
    }
}


-(BOOL)accessibilityPerformEscape{
    [self hideOverlay];
    UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil);
    return YES;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(BOOL)usesContentScrollView{
    return true;
}

@end
