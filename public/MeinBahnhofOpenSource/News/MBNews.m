// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBNews.h"
#import "NSDictionary+MBDictionary.h"

@interface MBNews()
@property(nonatomic,strong) NSDate* endTimestamp;
@property(nonatomic,strong) NSDate* startTimestamp;
@property(nonatomic,strong) NSDate* createdAtTimestamp;
@property(nonatomic,strong) NSDate* updatedAtTimestamp;
@property(nonatomic) NSInteger groupId;

@property(nonatomic,strong) NSString* title;
@property(nonatomic,strong) NSString* subtitle;
@property(nonatomic,strong) NSString* content;
@property(nonatomic,strong) NSString* link;
@property(nonatomic,strong) NSString* imageBase64;


@end


@implementation MBNews

static NSDateFormatter* newsDateFormatter = nil;
static NSArray<NSNumber*>* groupSortOrder = nil;

-(NSDateFormatter*)sharedFormatter{
    if(!newsDateFormatter){
        newsDateFormatter = [[NSDateFormatter alloc] init];
        newsDateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss.SSS'Z'";
        newsDateFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"DE"];
        newsDateFormatter.timeZone = [NSTimeZone timeZoneWithName:@"Europe/Berlin"];

    }
    return newsDateFormatter;
}

- (BOOL)validWithData:(NSDictionary *)json{
    if([json isKindOfClass:[NSDictionary class]] && [self sharedFormatter]){
        //is it published?
        if(![json db_boolForKey:@"published"]){
            if(DEBUG_LOAD_UNPUBLISHED_NEWS){
                //ignore
            } else {
                return NO;
            }
        }
        
        //is it outdated?
        NSString* end = [json db_stringForKey:@"endTimestamp"];
        if(!end){
            return NO;
        }
        self.endTimestamp = [newsDateFormatter dateFromString:end];
        if([self.endTimestamp timeIntervalSinceNow] < 0){
            return NO;
        }
        
        //is it one of our known groups?
        NSDictionary* group = [json db_dictForKey:@"group"];
        if(!group){
            return NO;
        }
        NSInteger groupId = [[group db_numberForKey:@"id"] integerValue];
        if(groupId == MBNewsTypeOffer
           || groupId == MBNewsTypeDisruption
           || groupId == MBNewsTypeMajorDisruption
           || groupId == MBNewsTypePoll
           || groupId == MBNewsTypeProductsServices){
            self.groupId = groupId;
        } else {
            return NO;
        }

        NSDictionary* optionalData = [json db_dictForKey:@"optionalData"];
        self.link = [optionalData db_stringForKey:@"link"];
        if(self.hasLink && !self.isLinkValid){
            self.link = [@"http://" stringByAppendingString:self.link];
            NSURL* url = [NSURL URLWithString:self.link];
            if(!url){
                return NO;
            }
        }

        //parse the rest of the fields that we use
        self.startTimestamp = [newsDateFormatter dateFromString:[json db_stringForKey:@"startTimestamp"]];
        self.updatedAtTimestamp = [newsDateFormatter dateFromString:[json db_stringForKey:@"updatedAt"]];
        self.createdAtTimestamp = [newsDateFormatter dateFromString:[json db_stringForKey:@"createdAt"]];
        self.title = [json db_stringForKey:@"title"];
        self.subtitle = [json db_stringForKey:@"subtitle"];
        self.content = [json db_stringForKey:@"content"];
        
        NSString* imgString = [json db_stringForKey:@"image"];
        if(imgString){
            NSString* jpgPrefix = @"data:image/jpeg;base64,";
            NSString* pngPrefix = @"data:image/png;base64,";
            if([imgString hasPrefix:jpgPrefix]){
                imgString = [imgString substringFromIndex:jpgPrefix.length];
            } else if([imgString hasPrefix:pngPrefix]){
                imgString = [imgString substringFromIndex:pngPrefix.length];
            }
            self.imageBase64 = imgString;
        }
        
        NSLog(@"created news object %@",self);
        return YES;
    }
    return NO;
}

-(UIImage *)image{
    if(!self.imageBase64){
        return nil;
    }
    //lazy loading of image data
    NSData* decodedData = [[NSData alloc] initWithBase64EncodedString:self.imageBase64 options:0];
    if(decodedData){
        return [UIImage imageWithData:decodedData];
    }
    return nil;
}

-(BOOL)isLinkValid{
    return [self.link hasPrefix:@"http"];
}

- (BOOL)hasLink{
    return self.link.length > 0;
}

-(BOOL)hasValidTime{
    //return YES;
    return [self.endTimestamp timeIntervalSinceNow] > 0 && [self.startTimestamp timeIntervalSinceNow] < 0;
}
-(NSDate*)sortDate{
    if(self.updatedAtTimestamp){
        return self.updatedAtTimestamp;
    }
    return self.createdAtTimestamp;
}

-(NSComparisonResult)compare:(MBNews *)news{
    NSComparisonResult res = [self compareGroup:news];
    if(res == NSOrderedSame){
        //next level: sort by date, descending (newer dates first!)
        NSComparisonResult res = [self.sortDate compare:news.sortDate];
        if(res == NSOrderedAscending){
            return NSOrderedDescending;
        } else if(res == NSOrderedDescending){
            return NSOrderedAscending;
        }
        return res;
    }
    return res;
}

-(NSString *)description{
    return [NSString stringWithFormat:@"<MBNews %ld,%@,%@>",(long)self.groupId,self.sortDate,self.title];
}

-(MBNewsType)newsType{
    if(self.groupId == MBNewsTypeOffer){
        return MBNewsTypeOffer;
    } else if(self.groupId == MBNewsTypeDisruption){
        return MBNewsTypeDisruption;
    } else if(self.groupId == MBNewsTypeMajorDisruption){
        return MBNewsTypeMajorDisruption;
    } else if(self.groupId == MBNewsTypePoll){
        return MBNewsTypePoll;
    } else if(self.groupId == MBNewsTypeProductsServices){
        return MBNewsTypeProductsServices;
    } else {
        return MBNewsTypeUndefined;
    }
}

-(NSComparisonResult)compareGroup:(MBNews *)news{
    if(self.groupId == news.groupId){
        return NSOrderedSame;
    } else {
        if(!groupSortOrder){
            groupSortOrder = @[ @(MBNewsTypeMajorDisruption), @(MBNewsTypeDisruption), @(MBNewsTypePoll), @(MBNewsTypeOffer), @(MBNewsTypeProductsServices) ];
        }
        NSInteger selfSortIndex = [groupSortOrder indexOfObject:@(self.newsType)];
        NSInteger otherSortIndex = [groupSortOrder indexOfObject:@(news.newsType)];
        if(selfSortIndex < otherSortIndex){
            return NSOrderedAscending;
        } else {
            return NSOrderedDescending;
        }
    }
}

+(NSArray *)staticInfoData{
    NSMutableArray* res = [NSMutableArray arrayWithCapacity:10];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss Z"];

    MBNews* n = nil;
    n = [MBNews new];
    n.startTimestamp = [dateFormatter dateFromString: @"2023-05-01 23:59:59 GMT+02:00"];
    n.endTimestamp = [dateFormatter dateFromString: @"2023-05-26 20:59:59 GMT+02:00"];
    n.headerOverwrite = @"Ankündigung Ersatzverkehr";
    n.title = @"26.05. – 11.09.2023";
    n.content = @"Ersatzverkehr auf der Strecke Würzburg – Nürnberg aufgrund von Baumaßnahmen.";
    n.groupId = MBNewsTypeMajorDisruption;
    NSLog(@"static news %@ .. %@",n.startTimestamp,n.endTimestamp);
    if([n hasValidTime]){
        [res addObject:n];
    }
    n = [MBNews new];
    n.startTimestamp = [dateFormatter dateFromString: @"2023-05-26 21:00:00 GMT+02:00"];
    n.endTimestamp = [dateFormatter dateFromString: @"2023-09-11 23:59:59 GMT+02:00"];
    n.headerOverwrite = @"Ersatzverkehr beachten";
    n.title = @"26.05. – 11.09.2023";
    n.content = @"Ersatzverkehr auf der Strecke Würzburg – Nürnberg aufgrund von Baumaßnahmen.";
    n.groupId = MBNewsTypeMajorDisruption;
    NSLog(@"static news %@ .. %@",n.startTimestamp,n.endTimestamp);
    if([n hasValidTime]){
        [res addObject:n];
    }
    return res;
}

+(NSArray*)debugData{
    NSMutableArray* res = [NSMutableArray arrayWithCapacity:10];
    NSDate* date = [NSDate date];
    MBNews* n = nil;
    
    n = [MBNews new];
    n.startTimestamp = date;
    n.endTimestamp = [date dateByAddingTimeInterval:10*10*60];
    n.title = @"10s, type off";
    n.subtitle = @"subtitle!";
    n.content = @"Lorem ipsum dolor sit amet Lorem ipsum dolor sit amet Lorem ipsum dolor sit amet.";
    n.updatedAtTimestamp = [date dateByAddingTimeInterval:-10];
    n.imageBase64 = [UIImagePNGRepresentation([UIImage imageNamed:@"FloatingMap"]) base64EncodedStringWithOptions:0];
    n.groupId = MBNewsTypeOffer;
    n.link = @"https://www.bahn.de";
    [res addObject:n];
    
    n = [MBNews new];
    n.startTimestamp = date;
    n.endTimestamp = [date dateByAddingTimeInterval:10*10*60];
    n.title = @"10s, type disr";
    n.subtitle = @"subtitle long Lorem ipsum dolor sit amet Lorem ipsum Lorem ipsum dolor sit amet Lorem ipsum!";
    n.content = @"Lorem ipsum dolor sit amet Lorem ipsum dolor sit amet Lorem ipsum dolor sit amet.";
    n.updatedAtTimestamp = [date dateByAddingTimeInterval:-10];
    n.groupId = MBNewsTypeDisruption;
    n.link = @"https://www.bahn.de";
    [res addObject:n];

    n = [MBNews new];
    n.startTimestamp = date;
    n.endTimestamp = [date dateByAddingTimeInterval:10*10*60];
    n.title = @"10s, type poll";
    n.updatedAtTimestamp = [date dateByAddingTimeInterval:-10];
    n.groupId = MBNewsTypePoll;
    n.link = @"https://www.bahn.de";
    [res addObject:n];
    
    n = [MBNews new];
    n.startTimestamp = date;
    n.endTimestamp = [date dateByAddingTimeInterval:10*10*60];
    n.title = @"5s, type off";
    n.updatedAtTimestamp = [date dateByAddingTimeInterval:-5];
    n.groupId = MBNewsTypeOffer;
    [res addObject:n];
    
    n = [MBNews new];
    n.startTimestamp = date;
    n.endTimestamp = [date dateByAddingTimeInterval:10*10*60];
    n.title = @"15s, type off";
    n.updatedAtTimestamp = [date dateByAddingTimeInterval:-15];
    n.groupId = MBNewsTypeOffer;
    [res addObject:n];
        
    n = [MBNews new];
    n.startTimestamp = date;
    n.endTimestamp = [date dateByAddingTimeInterval:10*10*60];
    n.title = @"5s, type disr";
    n.updatedAtTimestamp = [date dateByAddingTimeInterval:-5];
    n.groupId = MBNewsTypeDisruption;
    [res addObject:n];
    
    n = [MBNews new];
    n.startTimestamp = date;
    n.endTimestamp = [date dateByAddingTimeInterval:10*10*60];
    n.title = @"15s, type disr";
    n.updatedAtTimestamp = [date dateByAddingTimeInterval:-15];
    n.groupId = MBNewsTypeDisruption;
    [res addObject:n];

    n = [MBNews new];
    n.startTimestamp = date;
    n.endTimestamp = [date dateByAddingTimeInterval:10*10*60];
    n.title = @"5s, type poll";
    n.updatedAtTimestamp = [date dateByAddingTimeInterval:-5];
    n.groupId = MBNewsTypePoll;
    [res addObject:n];

    n = [MBNews new];
    n.startTimestamp = date;
    n.endTimestamp = [date dateByAddingTimeInterval:10*10*60];
    n.title = @"15s, type poll";
    n.updatedAtTimestamp = [date dateByAddingTimeInterval:-15];
    n.groupId = MBNewsTypePoll;
    [res addObject:n];

    n = [MBNews new];
    n.startTimestamp = date;
    n.endTimestamp = [date dateByAddingTimeInterval:10*10*60];
    n.title = @"15s, type product";
    n.updatedAtTimestamp = [date dateByAddingTimeInterval:-15];
    n.groupId = MBNewsTypeProductsServices;
    [res addObject:n];

    return res;
}

@end
