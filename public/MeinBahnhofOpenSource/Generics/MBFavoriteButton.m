// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//

#import "MBFavoriteButton.h"
#import "UIView+Frame.h"
#import "UIImage+MBImage.h"

@interface MBFavoriteButton()
@property(nonatomic,strong) UIImageView* favBtnImgView;
@end

@implementation MBFavoriteButton

- (instancetype)init{
    self = [super initWithFrame:CGRectMake(0, 0, 40, 40)];
    if(self){
        self.accessibilityIdentifier = @"FavButton";
        self.favBtnImgView = [[UIImageView alloc] initWithImage:[UIImage db_imageNamed:@"app_favorit_default"]];
        [self addSubview:self.favBtnImgView];
        [self.favBtnImgView centerViewInSuperView];
    }
    return self;
}
-(void)setIsFavorite:(BOOL)isFavorite{
    _isFavorite = isFavorite;
    if(isFavorite){
        self.favBtnImgView.image = [UIImage db_imageNamed:@"app_favorit"];
    } else {
        self.favBtnImgView.image = [UIImage db_imageNamed:@"app_favorit_default"];
    }
}

@end
