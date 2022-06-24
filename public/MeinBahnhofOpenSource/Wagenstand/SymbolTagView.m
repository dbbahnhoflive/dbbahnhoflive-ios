// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "SymbolTagView.h"
#import "MBUIHelper.h"

@interface SymbolTagView()

@property (nonatomic, strong) UILabel *symbolLabel;
@property (nonatomic, strong) UILabel *symbolDescriptionLabel;

@property(nonatomic,strong) NSMutableArray* iconImageViews;

@end

@implementation SymbolTagView

@synthesize symbolLabel = _symbolLabel;
@synthesize symbolDescription = _symbolDescription;

- (instancetype) initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.symbolLabel = [[UILabel alloc] init];
        self.symbolLabel.font = [UIFont fontWithName:@"DBTTPictos" size:20];
        self.symbolLabel.textColor = [UIColor db_878c96];
        
        self.symbolDescriptionLabel = [[UILabel alloc] init];
        self.symbolDescriptionLabel.font = [UIFont db_RegularTwelve];
        self.symbolDescriptionLabel.textColor = [UIColor blackColor];
        self.symbolDescriptionLabel.numberOfLines = 0;
        self.symbolDescriptionLabel.size = CGSizeMake(self.sizeWidth-50, 20);
                
        [self addSubview:self.symbolLabel];
        [self addSubview:self.symbolDescriptionLabel];
    }
    return self;
}

-(void)setSymbolIcons:(NSArray *)symbolIcons{
    if(!self.iconImageViews){
        self.iconImageViews = [NSMutableArray arrayWithCapacity:3];
    }
    [self.iconImageViews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    for(NSString* name in symbolIcons){
        UIImage* img = [UIImage db_imageNamed:name];
        if(img){
            UIImageView* iv = [[UIImageView alloc] initWithImage:img];
            [self.iconImageViews addObject:iv];
            [self addSubview:iv];
        }
    }
}

- (void) setSymbolCode:(NSString *)symbolCode
{
    _symbolCode = symbolCode;
    self.symbolLabel.text = symbolCode;
}

- (void) setSymbolDescription:(NSString *)symbolDescription
{
    _symbolDescription = symbolDescription;
    self.symbolDescriptionLabel.text = symbolDescription;
    if([symbolDescription hasPrefix:@"Achtung"]){//hacky solution for bold text
        NSMutableAttributedString* str = [[NSMutableAttributedString alloc] initWithString:symbolDescription];
        [str setAttributes:@{NSFontAttributeName:[UIFont db_BoldTwelve]} range:NSMakeRange(0, @"Achtung".length)];
        self.symbolDescriptionLabel.attributedText = str;
    }
}

- (void) layoutSubviews
{
    [super layoutSubviews];

    [self updateLayoutForWidth:self.sizeWidth];
}
#define spacingBetweenTextAndIcon 6
-(void)updateLayoutForWidth:(CGFloat)width{
    CGSize size = [self.symbolDescriptionLabel sizeThatFits:CGSizeMake(width, 500)];
    self.symbolDescriptionLabel.size = size;
    [self.symbolDescriptionLabel setX:0];
    [self.symbolDescriptionLabel setY:0];
    
    self.symbolLabel.size = CGSizeMake(20,20);
    CGFloat x = 0;
    for(UIView* v in self.iconImageViews){
        [v setX:x];
        [v setY:CGRectGetMaxY(self.symbolDescriptionLabel.frame)+spacingBetweenTextAndIcon];
        x += v.frame.size.width+8;
    }
    [self.symbolLabel setX:0];
    [self.symbolLabel setY:CGRectGetMaxY(self.symbolDescriptionLabel.frame)+spacingBetweenTextAndIcon];
}

-(BOOL)hasIcon{
    return self.symbolLabel.text.length > 0 || self.iconImageViews.count > 0;
}

-(void)resizeForWidth:(CGFloat)width{
    [self updateLayoutForWidth:width];
    CGFloat maxY = CGRectGetMaxY(self.symbolDescriptionLabel.frame);
    if([self hasIcon]){
        maxY += spacingBetweenTextAndIcon + 20;
    }
    [self setSize:CGSizeMake(width, maxY)];
}

@end
