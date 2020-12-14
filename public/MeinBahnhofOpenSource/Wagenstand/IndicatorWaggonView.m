// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "IndicatorWaggonView.h"
#import "Waggon.h"

@interface IndicatorWaggonView()

@property (nonatomic, strong) UIImageView *waggonBackgroundView;
@property (nonatomic, strong) UIImageView *waggonIconView;

@property (nonatomic, strong) UIImageView *secondWaggonPart; // optional

@property (nonatomic, strong) UIView *highlightIndicator;

@end

@implementation IndicatorWaggonView

- (instancetype) initWithFrame:(CGRect)frame andWaggon:(Waggon*)waggon
{
    if (self = [super initWithFrame:frame]) {
        
        if (waggon.isTrainHead) {
            if(waggon.isTrainHeadWithDirection){
                
                UIImageView* wg = [[UIImageView alloc] initWithImage:[UIImage db_imageNamed:@"app_fahrtrichtung_links"]];
                CGRect f = wg.frame;
                f.origin.y = -5;
                f.origin.x = 1;
                wg.frame = f;
                self.waggonBackgroundView = wg;
            } else {
                self.waggonBackgroundView = [self buildWaggonHead:@"SmallTrainFront"];
            }
        } else if (waggon.isTrainBack) {
            if(waggon.isTrainBackWithDirection){
                UIImageView* wg = [[UIImageView alloc] initWithImage:[UIImage db_imageNamed:@"app_fahrtrichtung_rechts"]];
                CGRect f = wg.frame;
                f.origin.y = -5;
                f.origin.x = -1;
                wg.frame = f;
                self.waggonBackgroundView = wg;
            } else {
                self.waggonBackgroundView = [self buildWaggonHead:@"SmallTrainBack"];
            }
        } else if (waggon.isTrainBothWays) {
            UIImageView* wg = [[UIImageView alloc] initWithImage:[UIImage db_imageNamed:@"app_regionalzug"]];
            CGRect f = wg.frame;
            f.origin.y = -13;
            f.origin.x = -2;
            wg.frame = f;
            self.waggonBackgroundView = wg;
            if(waggon.isTrainBothWithLeft){
                wg.image = [UIImage db_imageNamed:@"app_regionalzug_fahrtrichtung_links"];
            } else if(waggon.isTrainBothWithRight) {
                wg.image = [UIImage db_imageNamed:@"app_regionalzug_fahrtrichtung_rechts"];
            }
        } else if (waggon.isRestaurant && !waggon.waggonHasMultipleClasses) {
            
            self.waggonBackgroundView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.sizeWidth, 15)];
            self.waggonBackgroundView.backgroundColor = [UIColor db_restaurant];
            self.waggonBackgroundView.layer.cornerRadius = 1.5;
            
            UIImageView *restaurantIcon = [[UIImageView alloc] initWithFrame:CGRectMake(0,0,7,9)];
            restaurantIcon.image = [UIImage db_imageNamed:@"SmallRestaurantIcon"];
            [self.waggonBackgroundView addSubview:restaurantIcon];
            
            [restaurantIcon centerViewInSuperView];
        
        } else {
            
            // normal waggon
            self.waggonBackgroundView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.sizeWidth, 15)];
            self.waggonBackgroundView.backgroundColor = [waggon colorForType];
            self.waggonBackgroundView.layer.cornerRadius = 1.5;
            
            if (waggon.waggonHasMultipleClasses) {
                
                UIView *secondWaggonPart = [[UIView alloc] initWithFrame:CGRectMake(0,
                                                                                    0,
                                                                                    self.waggonBackgroundView.sizeWidth/2,
                                                                                    self.waggonBackgroundView.sizeHeight)];
                secondWaggonPart.backgroundColor = [waggon secondaryColor];
                [self.waggonBackgroundView addSubview:secondWaggonPart];
                [secondWaggonPart setGravityRight:0];
                
                [self setMaskTo:secondWaggonPart byRoundingCorners:UIRectCornerBottomRight| UIRectCornerTopRight];

            } else {
            
                UILabel *waggonClassLabel = [[UILabel alloc] init];
                waggonClassLabel.font = [UIFont db_HelveticaTwelve];
                waggonClassLabel.textColor = [UIColor whiteColor];
                waggonClassLabel.isAccessibilityElement = NO;
                [self.waggonBackgroundView addSubview:waggonClassLabel];
                
                waggonClassLabel.text = waggon.classOfWaggon;
                [waggonClassLabel sizeToFit];
                [waggonClassLabel centerViewInSuperView];
            }
        }
    }
    
    self.highlightIndicator = [[UIView alloc] initWithFrame:CGRectMake(0,0,self.sizeWidth, 2)];
    self.highlightIndicator.backgroundColor = [UIColor db_646973];
    self.highlightIndicator.alpha = 0;
    self.highlightIndicator.layer.cornerRadius = 1.5f;
    
    [self addSubview:self.waggonBackgroundView];
    [self addSubview:self.highlightIndicator];
    if(waggon.isTrainHeadWithDirection || waggon.isTrainBackWithDirection){
        [self.highlightIndicator setBelow:self.waggonBackgroundView withPadding:-2];
    } else if(waggon.isTrainBothWays){
        [self.highlightIndicator setGravityTop:17];
    } else {
        [self.highlightIndicator setBelow:self.waggonBackgroundView withPadding:2];
    }
    return self;
}

- (void) setHighlighted:(BOOL)highlighted
{
    _highlighted = highlighted;
    self.highlightIndicator.alpha = _highlighted ? 1 : 0;
}

- (UIImageView*) buildWaggonHead:(NSString*)iconResource
{
    UIImageView *backgroundView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.sizeWidth, 15)];
    backgroundView.image = [UIImage db_imageNamed:iconResource];
    return backgroundView;
}

-(void) setMaskTo:(UIView*)view byRoundingCorners:(UIRectCorner)corners
{
    UIBezierPath* rounded = [UIBezierPath bezierPathWithRoundedRect:view.bounds byRoundingCorners:corners cornerRadii:CGSizeMake(1.5, 1.5)];
    
    CAShapeLayer* shape = [[CAShapeLayer alloc] init];
    [shape setPath:rounded.CGPath];
    
    view.layer.mask = shape;
}


@end
