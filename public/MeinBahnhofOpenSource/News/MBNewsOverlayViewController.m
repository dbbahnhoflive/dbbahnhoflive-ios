// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBNewsOverlayViewController.h"
#import "MBUrlOpening.h"
#import "MBUIHelper.h"
#import "MBTrackingManager.h"

@interface MBNewsOverlayViewController ()
@property(nonatomic,strong) UIScrollView* contentScrollView;

@property(nonatomic,strong) UILabel* newsHeadlineLabel;
@property(nonatomic,strong) UILabel* newsSubtitleLabel;
@property(nonatomic,strong) UILabel* newsContentLabel;

@end

@implementation MBNewsOverlayViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.title = @"Ersatzverkehr beachten";
    self.titleLabel.text = self.title;

    self.contentScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, self.headerView.sizeHeight, self.contentView.sizeWidth, self.contentView.sizeHeight-self.headerView.sizeHeight)];
    [self.contentView addSubview:self.contentScrollView];
    
    NSInteger y = 16;
    
    self.newsHeadlineLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    [self.contentScrollView addSubview:self.newsHeadlineLabel];
    self.newsHeadlineLabel.numberOfLines = 0;
    self.newsHeadlineLabel.font = [UIFont db_BoldFourteen];
    self.newsHeadlineLabel.textColor = [UIColor db_333333];

    self.newsSubtitleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    [self.contentScrollView addSubview:self.newsSubtitleLabel];
    self.newsSubtitleLabel.numberOfLines = 0;
    self.newsSubtitleLabel.font = [UIFont db_RegularFourteen];
    self.newsSubtitleLabel.textColor = [UIColor db_333333];
    
    self.newsContentLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    [self.contentScrollView addSubview:self.newsContentLabel];
    self.newsContentLabel.numberOfLines = 0;
    self.newsContentLabel.font = [UIFont db_RegularFourteen];
    self.newsContentLabel.textColor = [UIColor db_333333];
    
    //setup labels
    self.newsHeadlineLabel.text = self.news.title;
    self.newsSubtitleLabel.text = self.news.subtitle;
    self.newsContentLabel.text = self.news.content;
    
    NSInteger contentWidth = self.view.frame.size.width-2*15;
    self.newsHeadlineLabel.frame = CGRectMake(15, 0, contentWidth, CGFLOAT_MAX);
    CGSize size = [self.newsHeadlineLabel sizeThatFits:CGSizeMake(self.newsHeadlineLabel.sizeWidth, CGFLOAT_MAX)];
    [self.newsHeadlineLabel setSize:CGSizeMake(ceilf(size.width), ceilf(size.height))];
    [self.newsHeadlineLabel setY:y];//there is a bug in the set frame method when using CGFLOAT_MAX for height the y value is ignored
    
    y = CGRectGetMaxY(self.newsHeadlineLabel.frame)+5;
    
    if(self.newsSubtitleLabel.text.length > 0){
        self.newsSubtitleLabel.frame = CGRectMake(15, 0, contentWidth, CGFLOAT_MAX);
        size = [self.newsSubtitleLabel sizeThatFits:CGSizeMake(self.newsSubtitleLabel.sizeWidth, CGFLOAT_MAX)];
        [self.newsSubtitleLabel setSize:CGSizeMake(ceilf(size.width),ceilf(size.height))];
        [self.newsSubtitleLabel setY:y];
        y = CGRectGetMaxY(self.newsSubtitleLabel.frame)+20;
    }
    
    self.newsContentLabel.frame = CGRectMake(15, 0, contentWidth, CGFLOAT_MAX);
    size = [self.newsContentLabel sizeThatFits:CGSizeMake(self.newsContentLabel.sizeWidth, CGFLOAT_MAX)];
    [self.newsContentLabel setSize:CGSizeMake(ceilf(size.width),ceilf(size.height))];
    [self.newsContentLabel setY:y];
    y = CGRectGetMaxY(self.newsContentLabel.frame)+20;
    
    //display of optional image
    UIImage* image = self.news.image;
    if(image){
        UIImageView* imgView = [[UIImageView alloc] initWithImage:image];
        [self.contentScrollView addSubview:imgView];
        
        if(imgView.frame.size.width > contentWidth){
            [imgView setSize:CGSizeMake(contentWidth, (imgView.image.size.height/imgView.image.size.width)*contentWidth)];
        }
        [imgView centerViewHorizontalInSuperView];
        [imgView setGravityTop:y];
        y = CGRectGetMaxY(imgView.frame)+20;
    }
    
    if(self.news.hasLink){
        UIButton* button = [[UIButton alloc] init];
        [self.contentScrollView addSubview:button];
        if(self.news.newsType == MBNewsTypePoll){
            [button setTitle:@"Zur Umfrage" forState:UIControlStateNormal];
        } else {
            [button setTitle:@"Mehr Informationen" forState:UIControlStateNormal];
        }
        [button addTarget:self action:@selector(didTapOnButton:) forControlEvents:UIControlEventTouchUpInside];
        button.backgroundColor = [UIColor db_GrayButton];
        [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [button.titleLabel setFont:[UIFont db_BoldEighteen]];
        button.width = self.contentScrollView.frame.size.width-16*2;
        button.height = 60;
        [button setGravityTop:y];
        [button centerViewHorizontalInSuperView];
        button.layer.cornerRadius = button.frame.size.height / 2.0;
        [button configureDefaultShadow];
        y = CGRectGetMaxY(button.frame)+20;
    }
    
    self.contentScrollView.contentSize = CGSizeMake(self.contentScrollView.frame.size.width, y);

}

-(void)didTapOnButton:(id)sender{
    [MBTrackingManager trackActionsWithStationInfo:@[@"h1",@"tap",@"newsbox",@"link"]];
    [MBTrackingManager trackActionsWithStationInfo:@[@"h1",@"tap",@"newstype",[NSString stringWithFormat:@"%lu",(unsigned long)self.news.newsType], @"link"]];

    [MBUrlOpening openURL:[NSURL URLWithString:self.news.link]];
}

-(void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    //resize view for content
    int totalHeight = MIN(self.view.sizeHeight-40, self.contentScrollView.contentSize.height+self.headerView.sizeHeight);
    [self.contentView setHeight:totalHeight];
    [self.contentView setGravityBottom:0];
    self.contentScrollView.frame = CGRectMake(0, self.headerView.sizeHeight, self.contentView.sizeWidth, self.contentView.sizeHeight-self.headerView.sizeHeight);
}


@end
