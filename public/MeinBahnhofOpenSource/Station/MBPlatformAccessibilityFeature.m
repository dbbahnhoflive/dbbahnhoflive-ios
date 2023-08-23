// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBPlatformAccessibilityFeature.h"
#import <UIKit/UIKit.h>

@implementation MBPlatformAccessibilityFeature

+(MBPlatformAccessibilityFeature *)featureForType:(MBPlatformAccessibilityFeatureType)feature{
    MBPlatformAccessibilityFeature* res = [MBPlatformAccessibilityFeature new];
    res.feature = feature;
    return res;
}


+(NSArray<NSNumber*>*)featureOrder{
    NSMutableArray* res = [NSMutableArray arrayWithCapacity:12];
    [res addObject:@(MBPlatformAccessibilityFeatureType_stepFreeAccess)];
    [res addObject:@(MBPlatformAccessibilityFeatureType_standardPlatformHeight)];
    [res addObject:@(MBPlatformAccessibilityFeatureType_passengerInformationDisplay)];
    [res addObject:@(MBPlatformAccessibilityFeatureType_audibleSignalsAvailable)];
    [res addObject:@(MBPlatformAccessibilityFeatureType_tactilePlatformAccess)];
    [res addObject:@(MBPlatformAccessibilityFeatureType_tactileGuidingStrips)];
    [res addObject:@(MBPlatformAccessibilityFeatureType_tactileHandrailLabel)];
    [res addObject:@(MBPlatformAccessibilityFeatureType_stairsMarking)];
    [res addObject:@(MBPlatformAccessibilityFeatureType_platformSign)];
    [res addObject:@(MBPlatformAccessibilityFeatureType_boardingAid)];
    [res addObject:@(MBPlatformAccessibilityFeatureType_automaticDoor)];
    return res;
}

-(NSString*)serverKey{
    switch (self.feature) {
        case MBPlatformAccessibilityFeatureType_automaticDoor:
            return @"automaticDoor";
        case MBPlatformAccessibilityFeatureType_boardingAid:
            return @"boardingAid";
        case MBPlatformAccessibilityFeatureType_platformSign:
            return @"platformSign";
        case MBPlatformAccessibilityFeatureType_stairsMarking:
            return @"stairsMarking";
        case MBPlatformAccessibilityFeatureType_tactileHandrailLabel:
            return @"tactileHandrailLabel";
        case MBPlatformAccessibilityFeatureType_tactileGuidingStrips:
            return @"tactileGuidingStrips";
        case MBPlatformAccessibilityFeatureType_tactilePlatformAccess:
            return @"tactilePlatformAccess";
        case MBPlatformAccessibilityFeatureType_audibleSignalsAvailable:
            return @"audibleSignalsAvailable";
        case MBPlatformAccessibilityFeatureType_passengerInformationDisplay:
            return @"passengerInformationDisplay";
        case MBPlatformAccessibilityFeatureType_standardPlatformHeight:
            return @"standardPlatformHeight";
        case MBPlatformAccessibilityFeatureType_stepFreeAccess:
            return @"stepFreeAccess";
    }
    return @"";
}
-(NSString*)displayText{
    switch (self.feature) {
        case MBPlatformAccessibilityFeatureType_automaticDoor:
            return @"Automatiktüren";
        case MBPlatformAccessibilityFeatureType_boardingAid:
            return @"Einstieghilfe";
        case MBPlatformAccessibilityFeatureType_platformSign:
            return @"Kontrastreiche Wegeleitung";
        case MBPlatformAccessibilityFeatureType_stairsMarking:
            return @"Treppenstufenmarkierung";
        case MBPlatformAccessibilityFeatureType_tactileHandrailLabel:
            return @"Handlaufschilder";
        case MBPlatformAccessibilityFeatureType_tactileGuidingStrips:
            return @"Taktiles Leitsystem auf dem Bahnsteig";
        case MBPlatformAccessibilityFeatureType_tactilePlatformAccess:
            return @"Taktiler Weg zum Bahnsteig";
        case MBPlatformAccessibilityFeatureType_audibleSignalsAvailable:
            return @"Lautsprecheranlage";
        case MBPlatformAccessibilityFeatureType_passengerInformationDisplay:
            return @"Zuganzeiger";
        case MBPlatformAccessibilityFeatureType_standardPlatformHeight:
            if(UIAccessibilityIsVoiceOverRunning()){
                return @"Moderne Bahnsteighöhe. 55 cm oder höher";
            } else {
                return @"Bahnsteighöhe >= 55 cm";
            }
        case MBPlatformAccessibilityFeatureType_stepFreeAccess:
            return @"Stufenfreier Zugang";
    }
    return @"";
}
-(NSString*)descriptionText{
    switch (self.feature) {
        case MBPlatformAccessibilityFeatureType_automaticDoor:
            return @"An diesem Bahnhof ist der Zugang zum Empfangsgebäude mit Automatiktüren ausgestattet.";
        case MBPlatformAccessibilityFeatureType_boardingAid:
            return @"Der Einstieg vom Bahnsteig in den Zug ist direkt (niveaugleich) oder über mobile Einstiegshilfen wie Hublifte oder mobile Rampen möglich. Unsere DB Service-Mitarbeiter und Mitarbeiterinnen sind speziell geschult, um mobilitätseingeschränkte Reisende beim Ein- und Aussteigen zu unterstützen.";
        case MBPlatformAccessibilityFeatureType_platformSign:
            return @"Ein kontrastreiches und damit gut lesbares, modernes Wegeleitsystem ist vorhanden.\n(Gut erkennbare, kontrastreiche Schilder erleichtern die Orientierung. Dazu gehören blaue Schilder mit weißer oder gelber Schrift.)";
        case MBPlatformAccessibilityFeatureType_stairsMarking:
            return @"Die Kanten der Treppenstufen, mindestens der ersten und der letzten Stufe, sind kontrastreich markiert.";
        case MBPlatformAccessibilityFeatureType_tactileHandrailLabel:
            return @"Die Handläufe an den Treppen und Rampen zum Bahnsteig verfügen über ein Handlaufschild mit Kurzinformationen (z.B. zu Gleisen) in ertastbarer Schrift.";
        case MBPlatformAccessibilityFeatureType_tactileGuidingStrips:
            return @"Auf diesem Bahnsteig ist ein taktiles Blindenleitsystem vorhanden. Solche Leitsysteme bestehen aus ertastbaren Bodenelementen. Diese Bodenelemente helfen blinden und sehbeeinträchtigten Menschen, sich mit ihrem Tastsinn zu orientieren und weisen z.B. auf Einstiegsbereiche und Bahnsteigkanten hin.";
        case MBPlatformAccessibilityFeatureType_tactilePlatformAccess:
            return @"Vom Bahnhofseingang bis zum Bahnsteig ist ein tastbarer Weg für blinde und sehbehinderte Menschen vorhanden. Er besteht zum Beispiel aus ertastbaren Bodenelementen (Blindenleitsysteme), Handläufen und weiteren baulichen Elementen (z.B. Wände, Bordsteine).";
        case MBPlatformAccessibilityFeatureType_audibleSignalsAvailable:
            return @"Der Bahnsteig ist mit Lautsprechern für Durchsagen und akustische Hinweise ausgestattet.";
        case MBPlatformAccessibilityFeatureType_passengerInformationDisplay:
            return @"Der Bahnsteig ist mit Anzeigetafeln, sogenannten Zugzielanzeigern oder Dynamischen Schriftanzeigern, ausgestattet. Dort erhalten Sie die wichtigsten Informationen über Abfahrten oder Verspätungen.";
        case MBPlatformAccessibilityFeatureType_standardPlatformHeight:
            return @"Der Bahnsteig ist mindestens 55 cm hoch.";
        case MBPlatformAccessibilityFeatureType_stepFreeAccess:
            return @"Der Bahnsteig ist über Aufzüge, Rampen, Gehwege oder weitere ebenerdige Zugänge (stufenfrei, höhengleich) erreichbar.";
    }
    return @"";
}

@end
