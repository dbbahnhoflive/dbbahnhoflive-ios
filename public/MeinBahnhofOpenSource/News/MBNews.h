// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "MBStation.h"

NS_ASSUME_NONNULL_BEGIN

#define NEW_APP_ICON @"news_malfunction"

#define NEW_APP_HEADER @"DB Bahnhof live wird eingestellt"
#define NEW_APP_TITLE @"Stichtag: 31.12.2024"
#define NEW_APP_TEXT @"Bahnhof.de übernimmt die Funktion von DB Bahnhof live."
#define NEW_APP_DESCRIPTION @"<p><b>Stichtag: 31.12.2024</b></p><p><b>Bahnhof.de übernimmt die Funktion von DB Bahnhof live</b></p><p>Bahnhof.de als Ihre praktische Begleitung für die Reise und den Aufenthalt am Bahnhof.</p><p>Die App DB Bahnhof live wird zum Ende des Jahres eingestellt. In Zukunft erwarten Sie die Informationen zu den Bahnhöfen, deren Ausstattung und Serviceangebote, die Echtzeitdaten zu den haltenden Zügen sowie vieles mehr auf bahnhof.de. Die Webseite übernimmt die Funktion der App.</p><p>Weiterführende Informationen zu der Abschaltung der App DB Bahnhof live sowie der Alternative bahnhof.de finden Sie unter <dbactionbutton href=\"https://www.bahnhof.de/entdecken/db-bahnhof-live\" type=\"extern\">bahnhof.de/entdecken/db-bahnhof-live</dbactionbutton></p><p>Wir danken Ihnen herzlich für die Nutzung der DB Bahnhof live App und wünschen Ihnen auch in Zukunft einen angenehmen Aufenthalt an den Bahnhöfen sowie eine gute Reise.</p>"

#define NEW_APP_TITLE_DISABLED @"DB Bahnhof live wird nicht mehr unterstützt"
#define NEW_APP_TEXT_DISABLED @"Für Informationen zu den Bahnhöfen nutzen Sie bitte die Webseite bahnhof.de."
#define NEW_APP_DESCRIPTION_DISABLED @""


#define NEW_APP_LINK @"https://www.bahnhof.de/entdecken/db-bahnhof-live"
#define NEW_APP_LINK_BUTTON @"bahnhof.de"

typedef NS_ENUM(NSUInteger, MBNewsType) {
    MBNewsTypeUndefined = 0,
    MBNewsTypeOffer = 1,//coupon
    MBNewsTypeDisruption = 2,
    MBNewsTypePoll = 3,
    MBNewsTypeProductsServices = 4,
    MBNewsTypeMajorDisruption = 5,
};

#define DEBUG_LOAD_UNPUBLISHED_NEWS NO

@interface MBNews : NSObject

@property(nonatomic,strong) NSString* headerOverwrite;

-(BOOL)validWithData:(NSDictionary*)json;

-(nullable UIImage*)image;
-(MBNewsType)newsType;
-(NSString*)title;
-(NSString* _Nullable)subtitle;
-(NSString*)content;
-(NSString*)link;
-(BOOL)hasLink;
-(BOOL)hasValidTime;
-(NSComparisonResult)compare:(MBNews *)news;

+(NSArray*)debugData;
+(NSArray*)staticInfoData:(MBStation*)station;

@end

NS_ASSUME_NONNULL_END
