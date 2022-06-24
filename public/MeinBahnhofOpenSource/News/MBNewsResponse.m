// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBNewsResponse.h"

@interface MBNewsResponse()

@property(nonatomic,strong) NSArray<MBNews*>* newsList;

@end

@implementation MBNewsResponse

- (instancetype)initWithResponse:(NSDictionary *)json{
    self = [super init];
    if(self){
        if([json isKindOfClass:[NSDictionary class]]){
            NSArray* news = json[@"news"];
            if([news isKindOfClass:NSArray.class]){
                NSMutableArray* res = [NSMutableArray arrayWithCapacity:news.count];
                for(NSDictionary* dict in news){
                    MBNews* newsItem = [MBNews new];
                    if([newsItem validWithData:dict]){
                        [res addObject:newsItem];
                    }
                }
                self.newsList = res;
            }
        }
    }
    return self;
}

-(NSArray<MBNews *> *)currentNewsItems{
    return [self validSortedItemsWithTypes:@[
        [NSNumber numberWithUnsignedInteger:MBNewsTypeOffer],
        [NSNumber numberWithUnsignedInteger:MBNewsTypeDisruption],
        [NSNumber numberWithUnsignedInteger:MBNewsTypeMajorDisruption],
        [NSNumber numberWithUnsignedInteger:MBNewsTypePoll],
        [NSNumber numberWithUnsignedInteger:MBNewsTypeProductsServices],
    ]];
}
-(NSArray<MBNews *> *)currentOfferItems{
    return [self validSortedItemsWithTypes:@[ [NSNumber numberWithUnsignedInteger:MBNewsTypeOffer] ]];
}
-(NSArray<MBNews*>*)validSortedItemsWithTypes:(NSArray<NSNumber*>*)newsTypes{
    NSMutableArray* res = [NSMutableArray arrayWithCapacity:self.newsList.count];
    for(MBNews* news in self.newsList){ //debug: in [MBNews debugData]
        if(news.hasValidTime && [newsTypes containsObject:[NSNumber numberWithUnsignedInteger:news.newsType]]){
            [res addObject:news];
        }
    }
    [res sortUsingComparator:^NSComparisonResult(MBNews* obj1, MBNews* obj2) {
        return [obj1 compare:obj2];
    }];
    return res;
}

-(BOOL)isValid{
    return self.newsList != nil;
}



@end
