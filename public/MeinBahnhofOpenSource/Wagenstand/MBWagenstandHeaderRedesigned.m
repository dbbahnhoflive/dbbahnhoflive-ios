// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBWagenstandHeaderRedesigned.h"
#import "Wagenstand.h"
#import "Train.h"
#import "MBUIHelper.h"

@interface MBWagenstandHeaderRedesigned()

@property(nonatomic,strong) UILabel* trainTypeNumberLabel;
@property(nonatomic,strong) UILabel* destinationTrackLabel;

@end

@implementation MBWagenstandHeaderRedesigned

-(instancetype)initWithWagenstand:(Wagenstand*)wagenstand train:(Train*)train andFrame:(CGRect)frame{
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor clearColor];
        
        self.trainTypeNumberLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.trainTypeNumberLabel.textColor = [UIColor db_333333];
        self.trainTypeNumberLabel.font =  [UIFont db_RegularSeventeen];
        [self addSubview:self.trainTypeNumberLabel];
        
        self.destinationTrackLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.destinationTrackLabel.numberOfLines = 0;
//        self.destinationTrackLabel.textColor = [UIColor db_333333];//configured later in attributed string
//        self.destinationTrackLabel.font =  [UIFont db_BoldSeventeen];
        [self addSubview:self.destinationTrackLabel];
        
        [self updateValuesWithWagenstand:wagenstand train:train];
    }
    return self;
}

-(void)updateValuesWithWagenstand:(Wagenstand*)wagenstand train:(Train*)train{
    self.trainTypeNumberLabel.text = [NSString stringWithFormat:@"%@ %@",train.type,train.number];
    self.trainTypeNumberLabel.accessibilityLabel = [self.trainTypeNumberLabel.text stringByReplacingOccurrencesOfString:@"ICE" withString:@"I C E"];
    NSString* destination = train.destinationStation;
    NSString* track = @"";
    if(train.sections.count > 0){
        track = [NSString stringWithFormat:@" (%@)",[train sectionRangeAsString]];
    }
    self.destinationTrackLabel.text = [destination stringByAppendingString:track];
    
    self.destinationTrackLabel.textColor = [UIColor db_333333];
    self.destinationTrackLabel.font =  [UIFont db_BoldSeventeen];

    
    NSMutableAttributedString * attrText = [[NSMutableAttributedString alloc] initWithString:self.destinationTrackLabel.text attributes:@{NSFontAttributeName:[UIFont db_BoldSeventeen], NSForegroundColorAttributeName:[UIColor db_333333]}];
    [attrText setAttributes:@{NSFontAttributeName:[UIFont db_RegularSeventeen], NSForegroundColorAttributeName:[UIColor db_787d87]} range:NSMakeRange(destination.length, attrText.length-destination.length)];
    self.destinationTrackLabel.attributedText = attrText;
}

-(void)resizeForWidth:(CGFloat)width{
    CGRect f = self.frame;
    f.size.width = width;
    self.frame = f;
    [self updateLayout];
}

-(void)updateLayout{
    [self.trainTypeNumberLabel sizeToFit];
    [self.trainTypeNumberLabel setGravityLeft:15];
    //some trains have a very long number (e.g. in München "BOB 86963/12355"... so we may need more space)
    NSInteger spaceLeft = MAX(105, CGRectGetMaxX(self.trainTypeNumberLabel.frame)+10);
    [self.destinationTrackLabel setGravityLeft:spaceLeft];
    NSInteger maxWidth = self.sizeWidth - spaceLeft -15;
    CGSize size = [self.destinationTrackLabel sizeThatFits:CGSizeMake(maxWidth, 300)];
    self.destinationTrackLabel.size = CGSizeMake(ceil(size.width), ceil(size.height));
    
    CGRect f = self.frame;
    f.size.height = (int) MAX(CGRectGetMaxY(self.trainTypeNumberLabel.frame), CGRectGetMaxY(self.destinationTrackLabel.frame))+1;
    self.frame = f;

}

-(void)layoutSubviews{
    [super layoutSubviews];
    [self updateLayout];
}

@end
