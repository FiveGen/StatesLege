//
//  MKiCloudSync.h
//  iCloud1
//
//  Created by Mugunth Kumar on 20/11/11.
//  Copyright (c) 2011 Steinlogic. All rights reserved.

//  As a side note on using this code, you might consider giving some credit to me by
//	1) linking my website from your app's website 
//	2) or crediting me inside the app's credits page 
//	3) or a tweet mentioning @mugunthkumar
//	4) A paypal donation to mugunth.kumar@gmail.com
//
//  A note on redistribution
//	if you are re-publishing after editing, please retain the above copyright notices

extern NSString * const kMKiCloudSyncNotification;

@interface MKiCloudSync : NSObject
+(void) start;
@end
