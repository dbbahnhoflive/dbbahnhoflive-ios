// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: -
//

#import "MBFilterButton.h"

@implementation MBFilterButton

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setImage:[UIImage db_imageNamed:@"app_filter"] forState:UIControlStateNormal];
        self.backgroundColor = [UIColor whiteColor];
        self.imageView.contentMode = UIViewContentModeCenter;

        CGSize buttonSize = [UIImage db_imageNamed:@"app_filter"].size;
        buttonSize.height = 42.0;
        buttonSize.width = 42.0;
        self.frame = CGRectMake(0,0, buttonSize.width, buttonSize.height);
        self.layer.cornerRadius = buttonSize.height / 2.0;
        self.layer.shadowColor = [[UIColor db_dadada] CGColor];
        self.layer.shadowRadius = 2.0;
        self.imageEdgeInsets = UIEdgeInsetsMake(2.0, 0.0, 0.0, 0.0);
        CGRect backRect = self.bounds;
        backRect.size.height += 4.0;
        backRect.size.width += 4.0;
        backRect.origin.y += 2.0;
        backRect.origin.x -= 2.0;

        self.layer.shadowPath = [[UIBezierPath bezierPathWithRoundedRect:backRect cornerRadius:backRect.size.height / 2.0] CGPath];
        self.layer.shadowOpacity = 1.0;
    }
    return self;
}

-(void)setStateActive:(BOOL)active{
    if(active){
        [self setImage:[UIImage db_imageNamed:@"app_filter_aktiv"] forState:UIControlStateNormal];
    } else {
        [self setImage:[UIImage db_imageNamed:@"app_filter"] forState:UIControlStateNormal];

    }
}

@end
