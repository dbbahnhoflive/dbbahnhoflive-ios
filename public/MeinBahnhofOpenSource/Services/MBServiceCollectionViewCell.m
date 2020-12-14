// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBServiceCollectionViewCell.h"

@interface MBServiceCollectionViewCell()
@property (nonatomic, strong) UIView* line;
@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UILabel *bubble;
@property (nonatomic, strong) UIView *labelEmbeddedView;
@property (nonatomic, strong) UIView* errorView;
@property (nonatomic, strong) UILabel* errorLabel;
@property (nonatomic, strong) UIImageView* errorImageView;

@property (nonatomic) BOOL hasRegisteredObserver;

@end

@implementation MBServiceCollectionViewCell

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];

    self.backgroundColor = [UIColor whiteColor];
    self.imageAsBackground = NO;
    // image on top
    self.imageView = [[UIImageView alloc] initWithFrame:CGRectZero];
    
    self.imageView.contentMode = UIViewContentModeCenter;
    self.imageView.clipsToBounds = YES;

    [self.contentView addSubview:self.imageView];
        
    self.errorView = [[UIView alloc] initWithFrame:CGRectZero];
    self.errorView.backgroundColor = [UIColor whiteColor];
    [self.contentView addSubview:self.errorView];
    self.errorImageView = [[UIImageView alloc] initWithImage:[UIImage db_imageNamed:@"app_error"]];
    self.errorImageView.contentMode = UIViewContentModeCenter;
    [self.errorView addSubview:self.errorImageView];
    self.errorLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.errorLabel.text = @"Daten nicht verfügbar";
    self.errorLabel.font = [UIFont db_RegularFourteen];
    self.errorLabel.numberOfLines = 0;
    self.errorLabel.textColor = [UIColor redColor];
    self.errorLabel.textAlignment = NSTextAlignmentCenter;
    [self.errorView addSubview:self.errorLabel];
    self.errorView.hidden = YES;
    
    self.line = [[UIView alloc] initWithFrame:CGRectMake(0, self.sizeHeight-44, self.sizeWidth, 1)];
    self.line.backgroundColor = [UIColor dbColorWithRGB:0xE4E4E4];
    [self.contentView addSubview:self.line];

    // title below
    // within a white view
    
    self.labelEmbeddedView = [[UIView alloc] initWithFrame:CGRectZero];
    self.labelEmbeddedView.backgroundColor = [UIColor clearColor];
    
    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.titleLabel.font = [UIFont db_RegularFourteen];
    self.titleLabel.textColor = [UIColor db_333333];
    self.titleLabel.numberOfLines = 0;
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    
    [self.labelEmbeddedView addSubview:self.titleLabel];
    [self.contentView addSubview:self.labelEmbeddedView];
    
    // red or green bubble with number inside
    self.bubble = [[UILabel alloc] initWithFrame:CGRectZero];
    self.bubble.font = UIFont.db_BoldTwentyFive;
    self.bubble.backgroundColor = [UIColor clearColor];
    self.bubble.textAlignment = NSTextAlignmentCenter;
    self.bubble.textColor = UIColor.whiteColor;
    self.bubble.hidden = YES;
    
    [self.contentView addSubview:self.bubble];
    
    self.layer.shadowColor = [[UIColor db_dadada] CGColor];
    self.layer.shadowOffset = CGSizeMake(3.0, 3.0);
    self.layer.shadowRadius = 3.0;
    self.layer.shadowOpacity = 1.0;
    
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];

    CGFloat labelHeight = 44.0;
    
    CGRect imageRect = CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height-labelHeight);
    self.imageView.frame = imageRect;
    
    if(_kachel.showOnlyImage){
        self.imageView.frame = CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height);
        self.imageView.contentMode = UIViewContentModeScaleAspectFit;
        return;
    }
    
    CGRect labelRect = CGRectMake(0, 12.0, self.bounds.size.width, 20.0);
    if (nil != _kachel.title) {
        CGSize titleSize = [self.titleLabel sizeThatFits:CGSizeMake(self.bounds.size.width, 50)];
        if(titleSize.height < 44){
            titleSize.height = 44;//min height
        }
        labelRect.size = titleSize;
    }
    self.titleLabel.frame = labelRect;
    CGRect labelEmbeddedRect = CGRectMake(0, self.frame.size.height-labelHeight, self.bounds.size.width, labelHeight);
    self.labelEmbeddedView.frame = labelEmbeddedRect;
    [self.titleLabel centerViewInSuperView];

    if(self.labelEmbeddedView.frame.origin.y < self.sizeHeight-44){
        [self.line setY:self.labelEmbeddedView.frame.origin.y];
    } else {
        [self.line setY:self.sizeHeight-44];
    }
    [self.line setX:0];
    [self.line setWidth:self.sizeWidth];
    
    CGFloat bubbleWidth = 50.0;
    CGRect bubbleRect = CGRectMake((self.frame.size.width-bubbleWidth) / 2.0, (self.frame.size.height-bubbleWidth-labelHeight)/2.0, bubbleWidth, bubbleWidth);
    self.bubble.frame = bubbleRect;
//    self.bubble.layer.cornerRadius = bubbleRect.size.width / 2.0;
    if (self.imageAsBackground) {
        self.imageView.contentMode = UIViewContentModeScaleAspectFill;
        self.imageView.frame = self.bounds;
        
    } else {
        self.imageView.contentMode = UIViewContentModeCenter;
        CGRect imageRect = CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height-44.0);
        self.imageView.frame = imageRect;
        
    }

    self.errorView.frame = CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height-44);
    self.errorLabel.frame = CGRectMake(10, 0, self.bounds.size.width-2*10, 200);
    self.errorLabel.size = CGSizeMake(self.errorLabel.size.width, [self.errorLabel sizeThatFits:self.errorLabel.size].height);
    self.errorImageView.frame = CGRectMake(0, 0, self.bounds.size.width, self.imageView.image.size.height);
    NSInteger errorContentHeight = self.errorLabel.size.height +20 + self.errorImageView.size.height;
    [self.errorImageView setY:(int)(((self.errorView.frame.size.height)-errorContentHeight)/2.)];
    [self.errorLabel setBelow:self.errorImageView withPadding:20];
    [self bringSubviewToFront:self.line];
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.imageAsBackground = NO;
    self.bubble.hidden = YES;
    self.imageView.image = nil;
    self.imageView.hidden = YES;
    self.line.hidden = YES;
    self.errorView.hidden = YES;
    [self removeObservers];
    self.kachel = nil;
}

- (void) removeObservers
{
    if(self.hasRegisteredObserver){
        @try{
            [self.kachel removeObserver:self forKeyPath:@"bubbleText"];
            [self.kachel removeObserver:self forKeyPath:@"bubbleColor"];
        }@catch(id anException){
            // NSLog(@"No observer was registered - ignore");
        }
        self.hasRegisteredObserver = NO;
    }
}

- (void)setKachel:(MBStationKachel *)kachel {
    _kachel = kachel;
    if (nil != _kachel) {
        BOOL showBubble = _kachel.showBubble;
        NSString* imageName = _kachel.imageName;
        if(_kachel.requestFailed){
            showBubble = NO;
            imageName = nil;
            self.errorView.hidden = NO;
        } else {
            self.errorView.hidden = YES;
        }
        
        if (showBubble) {
            _bubble.text = _kachel.bubbleText;
            _bubble.hidden = NO;
            
            [self removeObservers];
            [_kachel addObserver:self forKeyPath:@"bubbleText" options:NSKeyValueObservingOptionNew context:nil];
            [_kachel addObserver:self forKeyPath:@"bubbleColor" options:NSKeyValueObservingOptionNew context:nil];
            self.hasRegisteredObserver = YES;
        } else {
            _bubble.text = @"";
        }
//        if (nil != kachel.bubbleColor) {
//            _bubble.layer.backgroundColor = kachel.bubbleColor.CGColor;
//        }
        _line.hidden = NO;
        if (nil != imageName) {
            UIImage *image = [UIImage db_imageNamed:imageName];
            _imageView.image = image;
            _imageView.hidden = NO;
            _line.hidden = YES;
        } else {
            if (nil != _icon) {
                _imageView.image = _icon;
                _imageView.hidden = NO;
                _line.hidden = YES;
            }
        }
        if (nil != _kachel.title) {
            _titleLabel.text = _kachel.title;
            if(_kachel.needsLineAboveText){
                _line.hidden = NO;
            }
        }
        
        self.isAccessibilityElement = true;
        self.accessibilityLabel = [NSString stringWithFormat:@"%@, %@.",self.titleLabel.text,self.bubble.text];
        if(kachel.titleForVoiceOver){
            self.accessibilityLabel = kachel.titleForVoiceOver;
        }
        self.accessibilityTraits = UIAccessibilityTraitStaticText|UIAccessibilityTraitButton;
        self.bubble.isAccessibilityElement = NO;
        self.titleLabel.isAccessibilityElement = NO;
        
        [self setNeedsLayout];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"bubbleText"]) {
        NSString *newText = (NSString *)[change objectForKey:NSKeyValueChangeNewKey];
        _bubble.text = newText;
    }
}

- (void)willMoveToSuperview:(UIView *)newSuperview {
    if (nil == newSuperview) {
        [self removeObservers];
    }
}


@end
