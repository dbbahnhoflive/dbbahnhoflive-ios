// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//

#import "MBStatusImageView.h"
#import "UIImage+MBImage.h"

@implementation MBStatusImageView

-(instancetype)init{
    self = [super init];
    if(self){
        [self setStatusUnknown];
    }
    return self;
}

-(void)setStatusUnknown{
    [self setImageWithName:@"app_unbekannt"];
}
-(void)setStatusActive{
    [self setImageWithName:@"app_check"];
}
-(void)setStatusInactive{
    [self setImageWithName:@"app_kreuz"];
}
-(void)setImageWithName:(NSString*)text{
    self.image = [UIImage db_imageNamed:text];
    [self sizeToFit];
}

@end
