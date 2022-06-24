// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: -
//

#import "MBPlatformAccessibilityInfoOverlayViewController.h"
#import "MBPlatformAccessibility.h"
#import "MBUIHelper.h"

@interface MBPlatformAccessibilityInfoOverlayViewController ()
@property(nonatomic,strong) UIScrollView* contentScrollView;

@end

@implementation MBPlatformAccessibilityInfoOverlayViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.title = @"Merkmale der Barrierefreiheit";
    self.titleLabel.text = self.title;

    self.contentScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, self.headerView.sizeHeight, self.contentView.sizeWidth, self.contentView.sizeHeight-self.headerView.sizeHeight)];
    [self.contentView addSubview:self.contentScrollView];
    
    NSInteger y = 16;
    
    NSMutableArray* texts = [NSMutableArray arrayWithCapacity:12*2];
    for(NSNumber* featureType in [MBPlatformAccessibilityFeature featureOrder]){
        MBPlatformAccessibilityFeature* feature = [MBPlatformAccessibilityFeature featureForType:featureType.integerValue];
        [texts addObject:feature.displayText];
        [texts addObject:feature.descriptionText];
    }
    
    NSInteger space = 15;
    for(NSInteger i=0; i<texts.count; ){
        NSString* header = texts[i++];
        NSString* body = texts[i++];
        UILabel* headerLabel = [UILabel new];
        headerLabel.text = header;
        headerLabel.font = [UIFont db_BoldFourteen];
        headerLabel.textColor = UIColor.blackColor;
        headerLabel.numberOfLines = 0;
        CGSize size = [headerLabel sizeThatFits:CGSizeMake(self.view.frame.size.width-2*space, 5000)];
        [headerLabel setSize:size];
        [self.contentScrollView addSubview:headerLabel];
        [headerLabel setY:y];
        [headerLabel setX:space];
        y += headerLabel.sizeHeight + 5;
        
        UILabel* bodyLabel = [UILabel new];
        bodyLabel.numberOfLines = 0;
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        paragraphStyle.lineSpacing = 6;
        bodyLabel.attributedText = [[NSAttributedString alloc] initWithString:body attributes:@{
            NSParagraphStyleAttributeName:paragraphStyle,
            NSForegroundColorAttributeName:UIColor.blackColor,
            NSFontAttributeName:[UIFont db_RegularFourteen]
        }];
        
        size = [bodyLabel sizeThatFits:CGSizeMake(self.view.frame.size.width-2*space, 5000)];
        [bodyLabel setSize:size];
        [self.contentScrollView addSubview:bodyLabel];
        [bodyLabel setY:y];
        [bodyLabel setX:space];
        y += bodyLabel.sizeHeight + 25;

    }
    
    self.contentScrollView.contentSize = CGSizeMake(self.contentScrollView.frame.size.width, y);

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
