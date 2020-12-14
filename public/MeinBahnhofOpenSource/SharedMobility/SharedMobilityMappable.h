// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//



#import <Mantle/Mantle.h>
#import "MBMarker.h"
//#import <GoogleMaps/GoogleMaps.h>
#import <CoreLocation/CoreLocation.h>

/**
 Call a Bike
 Cambio
 Drivenow
 Flinkster
 Greenwheels
 Multicity
 Nextbike
 Quicar
 Stadtmobil
 NONE
**/

/**
 Jedes Sharable hat folgende Attribute:
 Id: Die eindeutige ID (int)
 external_id: Die externe ID des Anbieters (string)
 latitude: GeoPosition (float)
 Longitude: GeoPosition (float)
 name: Der Name des Sharables (string)
 address: Die Adresse des Sharables (string)
 type_name und type_name_i18n (string) - siehe „AGENTS“
 city: Die Stadt des Sharables (string), wichtig für Tracking
 Data: Die weiteren Daten als JSON-Array
	title: Der lokalisierte Titel, z.B. „Sauberkeit“ oder „Cleanliness“
	key: Der Key des Attributes, wichtig für Filter und mögliche Interaktionspunkte (fuel, mo-del, automatic, clean, clean_inner, clean_outer, bike_numbers[für Nextbike], info_url[für Cam-bio])
	content: Der Inhalt des Attributs, z.B. „Smart CE“ für Model
	type: Der Typ des Attributs, z.B: rating, bool oder list - nicht immer gesetzt!
 Generell sollte für Data-Attribute immer der Title und Content angezeigt werden.
 Der key ist vor allem wichtig für den Filter, um die Attribute mit einem festen Wert finden zu können.
 Der type ist ggf. wichtig, um den content variable anpassen zu können. Für bool ist der content z.B. „true“ oder „false“ und nicht übersetzt! Für cleanliness ist der content „1/3“ oder „4/4“ (je nach Anbieter) und bei „list“ ist es ein kommata-separiertes Array (123, 543, 234)
 Cambio nutzt eine info-URL, um weitere Daten zu der Station anzuzeigen. Diese muss als app-interner Browser geöffnet werden.
**/

@interface MobilityMappable : MTLModel <MTLJSONSerializing>

@property (nonatomic, assign, readonly) NSUInteger shareableId;
@property (nonatomic, copy, readonly) NSString *externalId;
@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, copy, readonly) NSString *address;
@property (nonatomic, copy, readonly) NSString *typeName;
@property (nonatomic, copy, readonly) NSString *translatedTypeName;
@property (nonatomic, copy, readonly) NSString *city;
@property (nonatomic, copy, readonly) NSArray *data; // Array of Dictionaries
@property (nonatomic, copy, readonly) NSString *latitude;
@property (nonatomic, copy, readonly) NSString *longitude;

@property (nonatomic, strong) NSString *model;
@property (nonatomic, strong) NSString *fuelStatus;
@property (nonatomic, strong) NSString *gearBox;
@property (nonatomic, assign) BOOL isBikeOffer;

- (UIImage *) pinForProvider;
- (NSURL *) urlScheme;
- (NSString*) appStoreUrlForProvider;
- (MBMarker*)marker;

- (NSString*) sanitizedProvider;

@end
