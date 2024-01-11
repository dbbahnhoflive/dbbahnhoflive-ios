// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "FahrzeugAusstattung.h"
#import "Waggon.h"

#define STATUS_DEFEKT @"DEFEKT"
#define STATUS_OFFEN @"OFFEN"
#define STATUS_GESCHLOSSEN @"GESCHLOSSEN"
#define STATUS_VERFUEGBAR @"VERFUEGBAR"
#define STATUS_NICHTVERFUEGBAR @"NICHTVERFUEGBAR"
#define STATUS_RESERVIERT @"RESERVIERT"
#define STATUS_NICHTBEDIENT @"NICHTBEDIENT"
#define STATUS_UNDEFINIERT @"UNDEFINIERT"

#define ART_ABTEILBUSINESS @"ABTEILBUSINESS"
#define ART_ABTEILFAHRRAD @"ABTEILFAHRRAD"
#define ART_ABTEILFAHRRADRESPFLICHT @"ABTEILFAHRRADRESPFLICHT"
#define ART_ABTEILKLEINKIND @"ABTEILKLEINKIND"
#define ART_ABTEILROLLSTUHL @"ABTEILROLLSTUHL"
#define ART_KLIMA @"KLIMA"
#define ART_PLAETZE1 @"PLAETZE1"
#define ART_PLAETZE2 @"PLAETZE2"
#define ART_PLAETZECC @"PLAETZECC"
#define ART_PLAETZEFAHRRAD @"PLAETZEFAHRRAD"
#define ART_PLAETZEFAHRRADRESPFLICHT @"PLAETZEFAHRRADRESPFLICHT"
#define ART_PLAETZEROLLSTUHL @"PLAETZEROLLSTUHL"
#define ART_PLAETZESTEH @"PLAETZESTEH"
#define ART_PLAETZEWL @"PLAETZEWL"
#define ART_PLAETZEWR @"PLAETZEWR"
#define ART_ROLLSTUHLTOILETTE @"ROLLSTUHLTOILETTE"
#define ART_RUHE @"RUHE"
#define ART_TOILETTE @"TOILETTE"
#define ART_WLAN @"WLAN"
#define ART_HANDYBEREICH @"HANDYBEREICH"
#define ART_BISTRO @"BISTRO"
#define ART_PLAETZEBAHNCOMFORT @"PLAETZEBAHNCOMFORT"
#define ART_FAMILIE @"FAMILIE"
#define ART_PLAETZESCHWERBEH @"PLAETZESCHWERBEH"

@implementation FahrzeugAusstattung

static NSDictionary* staticConfig = nil;
-(NSDictionary*)config{
    if(!staticConfig){
        staticConfig = @{
                         [ART_ABTEILBUSINESS stringByAppendingString:STATUS_DEFEKT]: @{
                                 @"text": @"Businessabteil defekt",
                                 @"icons": @[@"wagenaustattung_businessabteil-nicht-verfuegbar"]
                                 },
                         [ART_ABTEILBUSINESS stringByAppendingString:STATUS_GESCHLOSSEN]: @{
                                 @"text": @"Businessabteil geschlossen",
                                 @"icons": @[@"wagenaustattung_businessabteil-nicht-verfuegbar"]
                                 },
                         [ART_ABTEILBUSINESS stringByAppendingString:STATUS_VERFUEGBAR]: @{
                                 @"text": @"Businessabteil verfügbar",
                                 @"icons": @[@"wagenaustattung_businessabteil"]
                                 },
                         [ART_ABTEILBUSINESS stringByAppendingString:STATUS_NICHTVERFUEGBAR]: @{
                                 @"text": @"Businessabteil nicht verfügbar",
                                 @"icons": @[@"wagenaustattung_businessabteil-nicht-verfuegbar"]
                                 },
                         [ART_ABTEILBUSINESS stringByAppendingString:STATUS_RESERVIERT]: @{
                                 @"text": @"Businessabteil reserviert",
                                 @"icons": @[@"wagenaustattung_businessabteil-nicht-verfuegbar"]
                                 },

                         [ART_PLAETZEBAHNCOMFORT stringByAppendingString:STATUS_UNDEFINIERT]: @{
                                 @"text": @"BahnComfort Bereich",
                                 @"icons": @[@"wagenaustattung_bahncomfort"]
                                 },
                         [ART_PLAETZEBAHNCOMFORT stringByAppendingString:STATUS_NICHTVERFUEGBAR]: @{
                                 @"text": @"BahnComfort Bereich nicht verfügbar",
                                 @"icons": @[@"wagenaustattung_bahncomfort-nicht-verfuegbar"]
                                 },
                         
                         [ART_FAMILIE stringByAppendingString:STATUS_UNDEFINIERT]: @{
                                 @"text": @"Familienbereich",
                                 @"icons": @[@"wagenaustattung_familienbereich"]
                                 },
                         [ART_FAMILIE stringByAppendingString:STATUS_NICHTVERFUEGBAR]: @{
                                 @"text": @"Familienbereich nicht verfügbar",
                                 @"icons": @[@"wagenaustattung_familienbereich-nicht-verfuegbar"]
                                 },

                         [ART_PLAETZESCHWERBEH stringByAppendingString:STATUS_UNDEFINIERT]: @{
                                 @"text": @"Vorrangplätze für Reisende mit eingeschränkter Mobilität",
                                 @"icons": @[@"wagenaustattung_mobilitaetseingeschraenkt-1", @"wagenaustattung_mobilitaetseingeschraenkt-2"]
                                 },
                          [ART_PLAETZESCHWERBEH stringByAppendingString:STATUS_NICHTVERFUEGBAR]: @{
                                  @"text": @"Vorrangplätze für Reisende mit eingeschränkter Mobilität nicht verfügbar",
                                  @"icons": @[@"wagenaustattung_mobilitaetseingeschraenkt-1-nicht-verfuegbar", @"wagenaustattung_mobilitaetseingeschraenkt-2-nicht-verfuegbar"]
                                  },

                         /*[@"INFO" stringByAppendingString:STATUS_UNDEFINIERT]: @{
                                 @"text": @"Informationen",
                                 @"icons": @[@"wagenaustattung_businessabteil-nicht-verfuegbar"]
                                 },
                          */

                         [ART_ABTEILFAHRRAD stringByAppendingString:STATUS_DEFEKT]: @{
                                 @"text": @"Fahrradabteil defekt",
                                 @"icons": @[@"wagenaustattung_fahrrad-nicht-verfuegbar"]
                                 },
                         [ART_ABTEILFAHRRAD stringByAppendingString:STATUS_VERFUEGBAR]: @{
                                 @"text": @"Fahrradabteil verfügbar",
                                 @"icons": @[@"wagenaustattung_fahrrad"]
                                 },
                         [ART_ABTEILFAHRRAD stringByAppendingString:STATUS_NICHTVERFUEGBAR]: @{
                                 @"text": @"Fahrradabteil nicht verfügbar",
                                 @"icons": @[@"wagenaustattung_fahrrad-nicht-verfuegbar"]
                                 },
                         [ART_ABTEILFAHRRAD stringByAppendingString:STATUS_RESERVIERT]: @{
                                 @"text": @"Fahrradabteil reserviert",
                                 @"icons": @[@"wagenaustattung_fahrrad-nicht-verfuegbar"]
                                 },
                         [ART_ABTEILFAHRRAD stringByAppendingString:STATUS_UNDEFINIERT]: @{
                                 @"text": @"Fahrradabteil",
                                 @"icons": @[@"wagenaustattung_fahrrad"]
                                 },
                         
                         
                         [ART_ABTEILFAHRRADRESPFLICHT stringByAppendingString:STATUS_DEFEKT]: @{
                                 @"text": @"Fahrradabteil defekt",
                                 @"icons": @[@"wagenaustattung_fahrrad-nicht-verfuegbar"]
                                 },
                         [ART_ABTEILFAHRRADRESPFLICHT stringByAppendingString:STATUS_VERFUEGBAR]: @{
                                 @"text": @"Fahrradabteil verfügbar (Reservierung erforderlich)",
                                 @"icons": @[@"wagenaustattung_fahrrad"]
                                 },
                         [ART_ABTEILFAHRRADRESPFLICHT stringByAppendingString:STATUS_NICHTVERFUEGBAR]: @{
                                 @"text": @"Fahrradabteil nicht verfügbar",
                                 @"icons": @[@"wagenaustattung_fahrrad-nicht-verfuegbar"]
                                 },
                         [ART_ABTEILFAHRRADRESPFLICHT stringByAppendingString:STATUS_RESERVIERT]: @{
                                 @"text": @"Fahrradabteil reserviert",
                                 @"icons": @[@"wagenaustattung_fahrrad-nicht-verfuegbar"]
                                 },
                         [ART_ABTEILFAHRRADRESPFLICHT stringByAppendingString:STATUS_UNDEFINIERT]: @{
                                 @"text": @"Fahrradabteil (Reservierung erforderlich)",
                                 @"icons": @[@"wagenaustattung_fahrrad"]
                                 },
                         
                         
                         [ART_ABTEILKLEINKIND stringByAppendingString:STATUS_DEFEKT]: @{
                                 @"text": @"Kleinkindabteil defekt",
                                 @"icons": @[@"wagenaustattung_kleinkindabteil-nicht-verfuegbar"]
                                 },
                         [ART_ABTEILKLEINKIND stringByAppendingString:STATUS_GESCHLOSSEN]: @{
                                 @"text": @"Kleinkindabteil geschlossen",
                                 @"icons": @[@"wagenaustattung_kleinkindabteil-nicht-verfuegbar"]
                                 },
                         [ART_ABTEILKLEINKIND stringByAppendingString:STATUS_VERFUEGBAR]: @{
                                 @"text": @"Kleinkindabteil verfügbar",
                                 @"icons": @[@"wagenaustattung_kleinkindabteil"]
                                 },
                         [ART_ABTEILKLEINKIND stringByAppendingString:STATUS_NICHTVERFUEGBAR]: @{
                                 @"text": @"Kleinkindabteil nicht verfügbar",
                                 @"icons": @[@"wagenaustattung_kleinkindabteil-nicht-verfuegbar"]
                                 },
                         [ART_ABTEILKLEINKIND stringByAppendingString:STATUS_RESERVIERT]: @{
                                 @"text": @"Kleinkindabteil reserviert",
                                 @"icons": @[@"wagenaustattung_kleinkindabteil-nicht-verfuegbar"]
                                 },
                         [ART_ABTEILKLEINKIND stringByAppendingString:STATUS_UNDEFINIERT]: @{
                                 @"text": @"Kleinkindabteil",
                                 @"icons": @[@"wagenaustattung_kleinkindabteil"]
                                 },
                         
                         
                         [ART_ABTEILROLLSTUHL stringByAppendingString:STATUS_DEFEKT]: @{
                                 @"text": @"Abteil für Rollstuhlfahrer defekt",
                                 @"icons": @[@"wagenaustattung_rollstuhlstellplaetze-nicht-verfuegbar"]
                                 },
                         [ART_ABTEILROLLSTUHL stringByAppendingString:STATUS_GESCHLOSSEN]: @{
                                 @"text": @"Abteil für Rollstuhlfahrer geschlossen",
                                 @"icons": @[@"wagenaustattung_rollstuhlstellplaetze-nicht-verfuegbar"]
                                 },
                         [ART_ABTEILROLLSTUHL stringByAppendingString:STATUS_VERFUEGBAR]: @{
                                 @"text": @"Abteil für Rollstuhlfahrer verfügbar",
                                 @"icons": @[@"wagenaustattung_rollstuhlstellplaetze"]
                                 },
                         [ART_ABTEILROLLSTUHL stringByAppendingString:STATUS_NICHTVERFUEGBAR]: @{
                                 @"text": @"Abteil für Rollstuhlfahrer nicht verfügbar",
                                 @"icons": @[@"wagenaustattung_rollstuhlstellplaetze-nicht-verfuegbar"]
                                 },
                         [ART_ABTEILROLLSTUHL stringByAppendingString:STATUS_RESERVIERT]: @{
                                 @"text": @"Abteil für Rollstuhlfahrer reserviert",
                                 @"icons": @[@"wagenaustattung_rollstuhlstellplaetze-nicht-verfuegbar"]
                                 },
                         [ART_ABTEILROLLSTUHL stringByAppendingString:STATUS_UNDEFINIERT]: @{
                                 @"text": @"Abteil für Rollstuhlfahrer",
                                 @"icons": @[@"wagenaustattung_rollstuhlstellplaetze"]
                                 },
                         
                         
                         [ART_KLIMA stringByAppendingString:STATUS_DEFEKT]: @{
                                 @"text": @"Achtung: In diesem Wagen ist die Klimaanlage nicht funktionfähig. Bitte weichen Sie auf einen anderen Wagen aus.",
                                 @"icons": @[]
                                 },

                         
                         
                         [ART_PLAETZEFAHRRAD stringByAppendingString:STATUS_VERFUEGBAR]: @{
                                 @"text": @"Stellplätze für Fahrräder verfügbar",
                                 @"icons": @[@"wagenaustattung_fahrrad"]
                                 },
                         [ART_PLAETZEFAHRRAD stringByAppendingString:STATUS_NICHTVERFUEGBAR]: @{
                                 @"text": @"Stellplätze für Fahrräder nicht verfügbar",
                                 @"icons": @[@"wagenaustattung_fahrrad-nicht-verfuegbar"]
                                 },
                         [ART_PLAETZEFAHRRAD stringByAppendingString:STATUS_RESERVIERT]: @{
                                 @"text": @"Stellplätze für Fahrräder reserviert",
                                 @"icons": @[@"wagenaustattung_fahrrad-nicht-verfuegbar"]
                                 },
                         [ART_PLAETZEFAHRRAD stringByAppendingString:STATUS_UNDEFINIERT]: @{
                                 @"text": @"Stellplätze für Fahrräder",
                                 @"icons": @[@"wagenaustattung_fahrrad"]
                                 },

                         
                         [ART_PLAETZEFAHRRADRESPFLICHT stringByAppendingString:STATUS_VERFUEGBAR]: @{
                                 @"text": @"Stellplätze für Fahrräder verfügbar (Reservierung erforderlich)",
                                 @"icons": @[@"wagenaustattung_fahrrad"]
                                 },
                         [ART_PLAETZEFAHRRADRESPFLICHT stringByAppendingString:STATUS_NICHTVERFUEGBAR]: @{
                                 @"text": @"Stellplätze für Fahrräder nicht verfügbar",
                                 @"icons": @[@"wagenaustattung_fahrrad-nicht-verfuegbar"]
                                 },
                         [ART_PLAETZEFAHRRADRESPFLICHT stringByAppendingString:STATUS_RESERVIERT]: @{
                                 @"text": @"Stellplätze für Fahrräder reserviert",
                                 @"icons": @[@"wagenaustattung_fahrrad-nicht-verfuegbar"]
                                 },
                         [ART_PLAETZEFAHRRADRESPFLICHT stringByAppendingString:STATUS_UNDEFINIERT]: @{
                                 @"text": @"Stellplätze für Fahrräder (Reservierung erforderlich)",
                                 @"icons": @[@"wagenaustattung_fahrrad"]
                                 },

                         
                         [ART_PLAETZEROLLSTUHL stringByAppendingString:STATUS_VERFUEGBAR]: @{
                                 @"text": @"Plätze für Menschen mit Rollstuhl verfügbar",
                                 @"icons": @[@"wagenaustattung_rollstuhlstellplaetze"]
                                 },
                         [ART_PLAETZEROLLSTUHL stringByAppendingString:STATUS_NICHTVERFUEGBAR]: @{
                                 @"text": @"Plätze für Menschen mit Rollstuhl nicht verfügbar",
                                 @"icons": @[@"wagenaustattung_rollstuhlstellplaetze-nicht-verfuegbar"]
                                 },
                         [ART_PLAETZEROLLSTUHL stringByAppendingString:STATUS_RESERVIERT]: @{
                                 @"text": @"Plätze für Menschen mit Rollstuhl reserviert",
                                 @"icons": @[@"wagenaustattung_rollstuhlstellplaetze-nicht-verfuegbar"]
                                 },
                         [ART_PLAETZEROLLSTUHL stringByAppendingString:STATUS_UNDEFINIERT]: @{
                                 @"text": @"Plätze für Menschen mit Rollstuhl",
                                 @"icons": @[@"wagenaustattung_rollstuhlstellplaetze"]
                                 },

                         
                         [ART_ROLLSTUHLTOILETTE stringByAppendingString:STATUS_DEFEKT]: @{
                                 @"text": @"Toilette für mobilitätseingeschränkte Personen defekt",
                                 @"icons": @[@"wagenaustattung_toilette-nicht-verfuegbar", @"wagenaustattung_rollstuhlstellplaetze-nicht-verfuegbar"]
                                 },
                         [ART_ROLLSTUHLTOILETTE stringByAppendingString:STATUS_GESCHLOSSEN]: @{
                                 @"text": @"Toilette für mobilitätseingeschränkte Personen geschlossen",
                                 @"icons": @[@"wagenaustattung_toilette-nicht-verfuegbar", @"wagenaustattung_rollstuhlstellplaetze-nicht-verfuegbar"]
                                 },
                         [ART_ROLLSTUHLTOILETTE stringByAppendingString:STATUS_VERFUEGBAR]: @{
                                 @"text": @"Toilette für mobilitätseingeschränkte Personen verfügbar",
                                 @"icons": @[@"wagenaustattung_toilette", @"wagenaustattung_rollstuhlstellplaetze"]
                                 },
                         [ART_ROLLSTUHLTOILETTE stringByAppendingString:STATUS_NICHTVERFUEGBAR]: @{
                                 @"text": @"Toilette für mobilitätseingeschränkte Personen nicht verfügbar",
                                 @"icons": @[@"wagenaustattung_toilette-nicht-verfuegbar", @"wagenaustattung_rollstuhlstellplaetze-nicht-verfuegbar"]
                                 },
                         [ART_ROLLSTUHLTOILETTE stringByAppendingString:STATUS_UNDEFINIERT]: @{
                                 @"text": @"Toilette für mobilitätseingeschränkte Personen",
                                 @"icons": @[@"wagenaustattung_toilette", @"wagenaustattung_rollstuhlstellplaetze"]
                                 },
                         
                         
                         [ART_RUHE stringByAppendingString:STATUS_GESCHLOSSEN]: @{
                                 @"text": @"Ruhebereich geschlossen",
                                 @"icons": @[@"wagenaustattung_ruhebereich-nicht-verfuegbar"]
                                 },
                         [ART_RUHE stringByAppendingString:STATUS_VERFUEGBAR]: @{
                                 @"text": @"Ruhebereich verfügbar",
                                 @"icons": @[@"wagenaustattung_ruhebereich"]
                                 },
                         [ART_RUHE stringByAppendingString:STATUS_NICHTVERFUEGBAR]: @{
                                 @"text": @"Ruhebereich nicht verfügbar",
                                 @"icons": @[@"wagenaustattung_ruhebereich-nicht-verfuegbar"]
                                 },
                         [ART_RUHE stringByAppendingString:STATUS_RESERVIERT]: @{
                                 @"text": @"Ruhebereich reserviert",
                                 @"icons": @[@"wagenaustattung_ruhebereich-nicht-verfuegbar"]
                                 },
                         [ART_RUHE stringByAppendingString:STATUS_UNDEFINIERT]: @{
                                 @"text": @"Ruhebereich",
                                 @"icons": @[@"wagenaustattung_ruhebereich"]
                                 },
                         
                         [ART_WLAN stringByAppendingString:STATUS_DEFEKT]: @{
                                 @"text": @"WLAN defekt",
                                 @"icons": @[@"wagenaustattung_wlan-nicht-verfuegbar"]
                                 },
                         [ART_WLAN stringByAppendingString:STATUS_VERFUEGBAR]: @{
                                 @"text": @"WLAN verfügbar",
                                 @"icons": @[@"wagenaustattung_wlan"]
                                 },
                         [ART_WLAN stringByAppendingString:STATUS_NICHTVERFUEGBAR]: @{
                                 @"text": @"WLAN nicht verfügbar",
                                 @"icons": @[@"wagenaustattung_wlan-nicht-verfuegbar"]
                                 },
                         [ART_WLAN stringByAppendingString:STATUS_UNDEFINIERT]: @{
                                 @"text": @"WLAN",
                                 @"icons": @[@"wagenaustattung_wlan"]
                                 },

                         [ART_HANDYBEREICH stringByAppendingString:STATUS_DEFEKT]: @{
                                 @"text": @"Handybereich defekt",
                                 @"icons": @[@"wagenaustattung_handybereich-nicht-verfuegbar"]
                                 },
                         [ART_HANDYBEREICH stringByAppendingString:STATUS_GESCHLOSSEN]: @{
                                 @"text": @"Handybereich geschlossen",
                                 @"icons": @[@"wagenaustattung_handybereich-nicht-verfuegbar"]
                                 },
                         [ART_HANDYBEREICH stringByAppendingString:STATUS_VERFUEGBAR]: @{
                                 @"text": @"Handybereich verfügbar",
                                 @"icons": @[@"wagenaustattung_handybereich"]
                                 },
                         [ART_HANDYBEREICH stringByAppendingString:STATUS_NICHTVERFUEGBAR]: @{
                                 @"text": @"Handybereich nicht verfügbar",
                                 @"icons": @[@"wagenaustattung_handybereich-nicht-verfuegbar"]
                                 },
                         [ART_HANDYBEREICH stringByAppendingString:STATUS_UNDEFINIERT]: @{
                                 @"text": @"Handybereich",
                                 @"icons": @[@"wagenaustattung_handybereich"]
                                 },
                         
                         
                         [ART_BISTRO stringByAppendingString:STATUS_OFFEN]: @{
                                 @"text": @"Bordbistro geöffnet",
                                 @"icons": @[@"wagenaustattung_bistro"]
                                 },
                         [ART_BISTRO stringByAppendingString:STATUS_GESCHLOSSEN]: @{
                                 @"text": @"Bordbistro geschlossen",
                                 @"icons": @[@"wagenaustattung_bistro-nicht-verfuegbar"]
                                 },
                         [ART_BISTRO stringByAppendingString:STATUS_VERFUEGBAR]: @{
                                 @"text": @"Bordbistro verfügbar",
                                 @"icons": @[@"wagenaustattung_bistro"]
                                 },
                         [ART_BISTRO stringByAppendingString:STATUS_NICHTVERFUEGBAR]: @{
                                 @"text": @"Bordbistro nicht verfügbar",
                                 @"icons": @[@"wagenaustattung_bistro-nicht-verfuegbar"]
                                 },
                         [ART_BISTRO stringByAppendingString:STATUS_NICHTBEDIENT]: @{
                                 @"text": @"Bordbistro nicht bedient",
                                 @"icons": @[@"wagenaustattung_bistro-nicht-verfuegbar"]
                                 },
                         [ART_BISTRO stringByAppendingString:STATUS_UNDEFINIERT]: @{
                                 @"text": @"Bordbistro",
                                 @"icons": @[@"wagenaustattung_bistro"]
                                 },

                         };
    }
    return staticConfig;
}
-(NSDictionary*)configForArtAndStatus{
    NSDictionary* dict = [self config][[self.ausstattungsart stringByAppendingString:self.status]];
    if(!dict){
        //NSLog(@"no config for %@ + %@",self.ausstattungsart,self.status);
    }
    return dict;
}

-(NSString *)displayText{
    NSDictionary* c = [self configForArtAndStatus];
    if(c){
        NSString* res = c[@"text"];
        if(res){
            return res;
        }
    }
    if(self.symbol.length > 0){
        NSString* res = [Waggon descriptionForSymbol:self.symbol];
        if(res){
            return res;
        }
    }
    return @"";
}
-(NSArray<NSString*>*)iconNames{
    NSDictionary* c = [self configForArtAndStatus];
    if(c){
        return c[@"icons"];
    }
    return nil;
}

-(BOOL)hasSymbolText{
    return self.symbol.length > 0;
}

-(BOOL)displayEntry{
    return [self configForArtAndStatus] != nil || self.symbol.length > 0;
}


@end
