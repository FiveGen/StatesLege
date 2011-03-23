//
//  UtilityMethods.h
//  TexLege
//
//  Created by Gregory Combs on 7/22/09.
//  Copyright 2009 Gregory S. Combs. All rights reserved.
//


#import <Foundation/Foundation.h>
#import "TexLegeReachability.h"

BOOL IsEmpty(id thing);

@class CapitolMap;
@interface UtilityMethods : NSObject {
}

+ (id) texLegeStringWithKeyPath:(NSString *)keyPath;

+ (CGFloat) iOSVersion;
+ (BOOL) iOSVersion4;
	
+ (BOOL) supportsEventKit;

+ (BOOL) supportsMKPolyline;
+ (BOOL) locationServicesEnabled;

+ (BOOL) isLandscapeOrientation;
+ (BOOL) isIPadDevice;

//+ (BOOL) fileExistsAtPath:(NSString *)path;

+ (NSURL *)urlToMainBundle;
+ (NSString *) titleFromURL:(NSURL *)url;
+ (NSDictionary *)parametersOfQuery:(NSString *)queryString;

+ (NSURL *) safeWebUrlFromString:(NSString *)urlString;
+ (CapitolMap *) capitolMapFromOfficeString:(NSString *)office;
+ (CapitolMap *) capitolMapFromChamber:(NSInteger)chamber;
+ (NSURL *) googleMapUrlFromStreetAddress:(NSString *)address;
+ (NSString *)applicationDocumentsDirectory;
+ (NSString *)applicationCachesDirectory;

+ (BOOL) openURLWithTrepidation:(NSURL *)url;
+ (BOOL) openURLWithoutTrepidation:(NSURL *)url;
+ (BOOL) canMakePhoneCalls;
+ (void) alertNotAPhone;
+ (NSString*)ordinalNumberFormat:(NSInteger)num;

@end


@interface NSArray (Find)
- (NSArray *)findAllWhereKeyPath:(NSString *)keyPath equals:(id)value;
- (id)findWhereKeyPath:(NSString *)keyPath equals:(id)value;

@end

@interface NSString (FlattenHtml)
- (NSString *)flattenHTML;
- (NSString *)convertFromUTF8;

@end

@interface NSString  (HasSubstring)
- (BOOL) hasSubstring:(NSString*)substring caseInsensitive:(BOOL)insensitive;
@end




