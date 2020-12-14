// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "WaggonCell.h"
#import "FahrzeugAusstattung.h"

@interface WaggonCell()

@property (nonatomic, strong) UIView *waggonTypeColorContainer;

@property (nonatomic, strong) UIView *firstHalfColor;
@property (nonatomic, strong) UIView *secondHalfColor;

@property (nonatomic, strong) UIView *symbolContainer;
@property (nonatomic, strong) UIImageView *waggonNumberContainer;
@property (nonatomic, strong) UILabel *waggonNumberLabel;

@property (nonatomic, strong) UILabel *differentDestinationLabel;

@property (nonatomic, strong) NSMutableArray *symbolTagViews;
@property (nonatomic, strong) UILabel *waggonClassLabel;

@property (nonatomic, strong) UIView* bottomLine;
@property (nonatomic, strong) UIView* rightLine;

@end

@implementation WaggonCell

@synthesize waggon = _waggon;

- (instancetype) initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.waggonTypeColorContainer = [[UIView alloc] init];
        self.waggonNumberContainer = [[UIImageView alloc] initWithImage:[UIImage db_imageNamed:@"WaggonNumberIcon"]];
        
        self.secondHalfColor = [[UIView alloc] init];
        
        self.waggonNumberLabel = [[UILabel alloc] init];
        self.waggonNumberLabel.textColor = [UIColor db_878c96];
        self.waggonNumberLabel.font = [UIFont db_RegularTwenty];
        
        self.waggonClassLabel = [[UILabel alloc] init];
        self.waggonClassLabel.textColor = [UIColor whiteColor];
        self.waggonClassLabel.font = [UIFont db_HelveticaTwentyFour];
        
        self.differentDestinationLabel = [[UILabel alloc] init];
        self.differentDestinationLabel.font = [UIFont db_HelveticaBoldTwelve];
        self.differentDestinationLabel.textColor = [UIColor blackColor];
        self.differentDestinationLabel.adjustsFontSizeToFitWidth = YES;
        
        self.symbolTagViews = [NSMutableArray array];
        self.symbolContainer = [[UIView alloc] init];
        self.symbolContainer.clipsToBounds = NO;
        
        self.bottomLine = [[UIView alloc] init];
        self.bottomLine.backgroundColor = [UIColor colorWithRed:193.0/255.0 green:193.0/255.0 blue:193.0/255.0 alpha:1.0];
        self.rightLine = [[UIView alloc] init];
        self.rightLine.backgroundColor = self.bottomLine.backgroundColor;
        
        [self.waggonTypeColorContainer addSubview:self.secondHalfColor];
        [self.waggonTypeColorContainer addSubview:self.waggonClassLabel];
        [self.waggonNumberContainer addSubview:self.waggonNumberLabel];
        [self.waggonTypeColorContainer addSubview:self.waggonNumberContainer];
        
        [self.contentView addSubview:self.differentDestinationLabel];
        [self.contentView addSubview:self.waggonTypeColorContainer];
        [self.contentView addSubview:self.symbolContainer];
        
        if(ISIPAD){
            [self.contentView addSubview:self.bottomLine];
            [self.contentView addSubview:self.rightLine];
        }
        self.isAccessibilityElement = YES;
    }
    return self;
}

- (void)setWaggon:(Waggon *)waggon
{
    _waggon = waggon;
    
    double widthOfLegendPart = [WaggonCell widthOfLegendPartForWidth:self.sizeWidth];
    
    self.waggonTypeColorContainer.backgroundColor = [_waggon colorForType];
    
    self.differentDestinationLabel.text = waggon.differentDestination;
    self.differentDestinationLabel.size = [self.differentDestinationLabel sizeThatFits:CGSizeMake(widthOfLegendPart, CGFLOAT_MAX)];
    
    [self.symbolTagViews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [self.symbolTagViews removeAllObjects];
    
    [self.symbolTagViews addObjectsFromArray:[_waggon setupTagViewsForWidth:widthOfLegendPart]];
    NSMutableString* symbolDescriptions = [[NSMutableString alloc] init];
    
    for(SymbolTagView* tagView in self.symbolTagViews){
        [self.symbolContainer addSubview:tagView];
        if(symbolDescriptions.length > 0){
            [symbolDescriptions appendString:@", "];
        }
        [symbolDescriptions appendString:tagView.symbolDescription];
    }
    
    if (self.waggon.waggonHasMultipleClasses) {
        self.secondHalfColor.backgroundColor = [self.waggon secondaryColor];
        self.waggonClassLabel.text = @"";
    } else {
        self.secondHalfColor.backgroundColor = [UIColor clearColor];
        self.waggonClassLabel.text = [_waggon classOfWaggon];
    }
    
    self.waggonNumberLabel.text = _waggon.number;
    
    NSMutableString* accessibilityText = [[NSMutableString alloc] init];
    if(self.waggonNumberLabel.text.length > 0){
        [accessibilityText appendFormat:@"\"Wagennummer %@\". ",self.waggonNumberLabel.text];
    }
    if(self.waggonClassLabel.text.length > 0){
        [accessibilityText appendFormat:@"\"Klasse %@\". ",self.waggonClassLabel.text];
    }
    NSString* section = [self.waggon.sections lastObject];
    if(section.length > 0){
        [accessibilityText appendFormat:@"\"Abschnitt %@\". ",section];
    }
    if(symbolDescriptions.length > 0){
        [accessibilityText appendString:symbolDescriptions];
    }
    self.accessibilityLabel = accessibilityText;
}

# pragma -
# pragma Layout

+(CGFloat)widthOfLegendPartForWidth:(CGFloat)totalWidth{
    //return self.sizeWidth-(self.waggonTypeColorContainer.originX+self.waggonTypeColorContainer.sizeWidth+20);
    CGFloat res= totalWidth-((ISIPAD ? 120 : 20)+ 85 + 20 + 20);
    if(ISIPAD){
        res -= 120;
    }
    //NSLog(@"widthOfLegendPartForWidth: %f -> %f",totalWidth,res);
    return res;
}

- (void) layoutSubviews
{
    [super layoutSubviews];
    
    self.waggonTypeColorContainer.size = CGSizeMake(85, self.sizeHeight);
    [self.waggonTypeColorContainer setGravityLeft:(ISIPAD ? 120 : 20)];
    
    self.secondHalfColor.size = CGSizeMake(self.waggonTypeColorContainer.sizeWidth, self.waggonTypeColorContainer.sizeHeight/2);
    [self.secondHalfColor setGravityBottom:0];
    
    [self.waggonClassLabel sizeToFit];
    [self.waggonNumberLabel sizeToFit];
    
    [self.waggonClassLabel setGravityBottom:10];
    [self.waggonClassLabel setGravityRight:10];
    
    self.waggonNumberContainer.size = CGSizeMake(self.waggonTypeColorContainer.sizeWidth-20, self.waggonTypeColorContainer.sizeWidth-20);
    [self.waggonNumberContainer centerViewHorizontalInSuperView];
    [self.waggonNumberContainer setGravityTop:10];
    
    [self.waggonNumberLabel centerViewHorizontalInSuperView];
    [self.waggonNumberLabel setGravityTop:10];
    
    if (self.waggon.length == 1) {
        self.waggonClassLabel.hidden = YES;
    } else {
        self.waggonNumberContainer.hidden = NO;
    }
    
    [self.differentDestinationLabel setGravityTop:self.differentDestinationLabel.text.length>0?10:0];
    [self.differentDestinationLabel setRight:self.waggonTypeColorContainer withPadding:20];

    self.waggonClassLabel.hidden = [self.waggon isRestaurant];
    
    double widthOfLegendPart = [WaggonCell widthOfLegendPartForWidth:self.sizeWidth];
    
    [_waggon setupTagViewsForWidth:widthOfLegendPart];
    
    //self.symbolContainer.backgroundColor = [UIColor redColor];
    [self.symbolContainer resizeToFitSubviews];
    [self.symbolContainer setRight:self.waggonTypeColorContainer withPadding:20];
    [self.symbolContainer setBelow:self.differentDestinationLabel withPadding:0];
    
    if(ISIPAD){
        self.bottomLine.size = CGSizeMake(self.size.width-2*(self.waggonTypeColorContainer.frame.origin.x), 0.5);
        [self.bottomLine setGravityBottom:0];
        [self.bottomLine setGravityLeft:self.waggonTypeColorContainer.frame.origin.x];
        
        self.rightLine.size = CGSizeMake(0.5, self.size.height);
        [self.rightLine setGravityRight:self.waggonTypeColorContainer.frame.origin.x];
    }
}



@end
