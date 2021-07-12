// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//

#import "RIMapBackgroundTileLayer.h"

@interface RIMapBackgroundTileLayer()
@end

@implementation RIMapBackgroundTileLayer


- (UIImage *)tileForX:(NSUInteger)x y:(NSUInteger)y zoom:(NSUInteger)zoom {

    return nil;//kGMSTileLayerNoTile;
    
}

@end
