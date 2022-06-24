// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBStationChatbotTeaserCollectionViewCell.h"
#import "MBUIHelper.h"

@interface MBStationChatbotTeaserCollectionViewCell()
@property(nonatomic,strong) UILabel* mainLabel;
@property(nonatomic,strong) UILabel* subLabel;
@property(nonatomic,strong) UIImageView* chatbotImage;

@end

@implementation MBStationChatbotTeaserCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if(self){
        self.backgroundColor = [UIColor whiteColor];
        
        self.mainLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.mainLabel.text = @"Sie haben Fragen?";
        self.mainLabel.numberOfLines = 0;
        self.mainLabel.textColor = [UIColor db_333333];
        self.mainLabel.font = [UIFont dbHeadBlackWithSize:17];
        [self.contentView addSubview:self.mainLabel];
        
        self.subLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.subLabel.text = @"Ich helfe Ihnen gerne weiter.";
        self.subLabel.numberOfLines = 0;
        self.subLabel.textColor = [UIColor db_333333];
        self.subLabel.font = [UIFont dbHeadLightWithSize:17];
        [self.contentView addSubview:self.subLabel];
        
        //need more line spacing in the labels:
        NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:self.mainLabel.text];
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        paragraphStyle.lineSpacing = 8;
        [attributedString addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, self.mainLabel.text.length)];
        self.mainLabel.attributedText = attributedString;
        //and for sublabel too
        attributedString = [[NSMutableAttributedString alloc] initWithString:self.subLabel.text];
        paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        paragraphStyle.lineSpacing = 8;
        [attributedString addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, self.subLabel.text.length)];
        self.subLabel.attributedText = attributedString;

        
        self.chatbotImage = [[UIImageView alloc] initWithImage:[UIImage db_imageNamed:@"chatbot_h1"]];
        [self.contentView addSubview:self.chatbotImage];
        self.chatbotImage.isAccessibilityElement = NO;

        self.mainLabel.isAccessibilityElement = NO;
        self.subLabel.isAccessibilityElement = NO;
        self.isAccessibilityElement = YES;
        self.accessibilityTraits = UIAccessibilityTraitButton|UIAccessibilityTraitStaticText;
        self.accessibilityLabel = [NSString stringWithFormat:@"Chatbot. %@ %@",self.mainLabel.text,self.subLabel.text];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];

    NSLog(@"initial asset size %@",NSStringFromCGRect(self.chatbotImage.frame));
    //code needs to be optimized when we show another tile next to the chatbot, currently not used
    /*if(_reducedSize){
        //size according to width
        NSInteger imgW = (110./237.)*self.frame.size.width;
        self.chatbotImage.frame = CGRectMake(0, 0, imgW, imgW);
        NSInteger spaceImageRight = (7./237.)*self.frame.size.width;
        [self.chatbotImage setGravityRight:spaceImageRight];
        [self.chatbotImage setGravityBottom:0];
        NSInteger x = (19./237.)*self.frame.size.width;
        NSInteger spaceRight = self.frame.size.width-(self.chatbotImage.frame.origin.x-x);
        NSInteger w = self.frame.size.width-spaceImageRight-spaceRight;
        CGSize size = [self.mainLabel sizeThatFits:CGSizeMake(w, 200)];
        self.mainLabel.frame = CGRectMake(x, 23, size.width,size.height);
        size = [self.subLabel sizeThatFits:CGSizeMake(w, 200)];
        self.subLabel.frame = CGRectMake(x, CGRectGetMaxY(self.mainLabel.frame)+18, size.width,size.height);
        return;
    }*/
    self.chatbotImage.frame = CGRectMake(0, 0, self.chatbotImage.image.size.width*0.8, self.chatbotImage.image.size.height*0.8 );
    [self.chatbotImage setGravityRight:24];
    [self.chatbotImage centerViewVerticalInSuperView];
    NSInteger spaceRight = self.frame.size.width-(self.chatbotImage.frame.origin.x-22);
    NSInteger w = self.frame.size.width-24-spaceRight;
    
    CGSize size = [self.mainLabel sizeThatFits:CGSizeMake(w, 200)];
    self.mainLabel.frame = CGRectMake(24, 44, size.width,size.height);
    size = [self.subLabel sizeThatFits:CGSizeMake(w, 200)];
    self.subLabel.frame = CGRectMake(24, CGRectGetMaxY(self.mainLabel.frame)+18, size.width,size.height);
    if(CGRectGetMaxY(self.subLabel.frame) > self.size.height-20){
        //reduced size (e.g. iPhone5...), must move text up
        [self.mainLabel setGravityTop:20];
        [self.subLabel setGravityTop:CGRectGetMaxY(self.mainLabel.frame)+15];
    }
}
@end
