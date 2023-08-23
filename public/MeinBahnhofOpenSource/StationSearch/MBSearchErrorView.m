// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBSearchErrorView.h"
#import "MBUIHelper.h"
@interface MBSearchErrorView()

@property(nonatomic,strong) UIImageView* warnIcon;
@property(nonatomic,strong) UILabel* headerLabel;
@property(nonatomic,strong) UILabel* bodyLabel;
@property(nonatomic,strong) UIButton* actionButton;
@property(nonatomic,assign) MBErrorActionType actionType;

@end

@implementation MBSearchErrorView

#define BODY_PRETEXT @"Hinweis: "

-(instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if(self){
        self.backgroundColor = [UIColor whiteColor];
        self.warnIcon = [[UIImageView alloc] initWithImage:[UIImage db_imageNamed:@"app_warndreieck_dunkelgrau"]];
        self.headerLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.bodyLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.headerLabel.textColor = [UIColor blackColor];
        self.bodyLabel.textColor = self.headerLabel.textColor;
        self.bodyLabel.numberOfLines = 0;
        self.headerLabel.numberOfLines = 0;
        self.headerLabel.textAlignment = NSTextAlignmentCenter;
        [self.headerLabel setFont:[UIFont fontWithName:@"HelveticaNeue" size:15.0]];
        [self.bodyLabel setFont:[UIFont fontWithName:@"HelveticaNeue" size:15.0]];

        UIButton* actionButton = [[UIButton alloc] initWithFrame:CGRectZero];
        self.actionButton = actionButton;
        [actionButton setTitle:@"action" forState:UIControlStateNormal];
        [actionButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [actionButton setBackgroundColor:[UIColor db_mainColor]];
        [actionButton.titleLabel setFont:[UIFont db_BoldEighteen]];
        [actionButton addTarget:self action:@selector(actionTapped:) forControlEvents:UIControlEventTouchUpInside];
        [actionButton configureDefaultShadow];
        [self addSubview:actionButton];
        
        [self addSubview:self.warnIcon];
        [self addSubview:self.headerLabel];
        [self addSubview:self.bodyLabel];
    }
    return self;
}

-(void)layoutSubviews{
    [super layoutSubviews];
    if(self.warnIcon.hidden){
        [self.bodyLabel setGravityTop:20];
    } else {
        [self.warnIcon centerViewHorizontalInSuperView];
        [self.warnIcon setGravityTop:20];
        [self.headerLabel setBelow:self.warnIcon withPadding:10];
        CGSize size = [self.headerLabel sizeThatFits:CGSizeMake(self.sizeWidth-2*20, 1000)];
        [self.headerLabel setSize:size];
        [self.headerLabel centerViewHorizontalInSuperView];
        [self.bodyLabel setBelow:self.headerLabel withPadding:20];
    }
    CGSize size = [self.bodyLabel sizeThatFits:CGSizeMake(self.sizeWidth-2*20, 1000)];
    [self.bodyLabel setSize:size];
    [self.bodyLabel setGravityLeft:20];
    int y = CGRectGetMaxY(self.bodyLabel.frame);
    if(!self.actionButton.hidden){
        y += 20;
        self.actionButton.frame = CGRectMake(16, y, self.sizeWidth-2*16, 60);
        self.actionButton.layer.cornerRadius = self.actionButton.sizeHeight/2;
        y += 60;
    }
    [self setSize:CGSizeMake(self.sizeWidth, y+20)];
}

-(void)setHeaderText:(NSString *)headerText bodyText:(NSString *)bodyText actionText:(NSString*)actionText actionType:(MBErrorActionType)actionType{
    self.actionType = actionType;
    self.headerLabel.text = headerText;
    self.warnIcon.hidden = headerText.length == 0;
    self.headerLabel.hidden = self.warnIcon.hidden;
    if(bodyText.length > 0){
        NSMutableAttributedString* attributedText = [[NSMutableAttributedString alloc] initWithString:[BODY_PRETEXT stringByAppendingString:bodyText] attributes:@{}];
        [attributedText setAttributes:@{NSFontAttributeName:[UIFont fontWithName:@"HelveticaNeue-Bold" size:15.0]} range:NSMakeRange(0, BODY_PRETEXT.length)];
        self.bodyLabel.attributedText = attributedText;
    } else {
        self.bodyLabel.text = @"";
    }
    if(actionText){
        [self.actionButton setTitle:actionText forState:UIControlStateNormal];
        self.actionButton.hidden = NO;
    } else {
        self.actionButton.hidden = YES;
    }
    [self setNeedsLayout];
}

-(void)setHeaderText:(NSString *)headerText bodyText:(NSString *)bodyText {
    [self setHeaderText:headerText bodyText:bodyText actionText:nil actionType:MBERrorActionTypeUndefined];
}

-(void)actionTapped:(UIButton*)btn{
    [self.delegate searchErrorDidPressActionButton:self withAction:self.actionType];
}

@end
