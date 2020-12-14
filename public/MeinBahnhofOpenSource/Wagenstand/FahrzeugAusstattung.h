// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import <Foundation/Foundation.h>

@interface FahrzeugAusstattung : NSObject

//new api
@property(nonatomic,strong) NSString* anzahl;
@property(nonatomic,strong) NSString* ausstattungsart;
@property(nonatomic,strong) NSString* bezeichnung;
@property(nonatomic,strong) NSString* status;


//old api
@property(nonatomic,strong) NSString* symbol;

-(NSString*)displayText;
-(NSArray*)iconNames;
-(BOOL)displayEntry;
-(BOOL)isOldAPI;

@end
