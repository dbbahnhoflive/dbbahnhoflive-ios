// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <UIKit/UIKit.h>

@interface SymbolTagView : UIView

@property (nonatomic, strong) NSString *symbolCode;//old api
@property (nonatomic, strong) NSArray *symbolIcons;//new api
@property (nonatomic, strong) NSString *symbolDescription;

-(void)resizeForWidth:(CGFloat)width;

@end
