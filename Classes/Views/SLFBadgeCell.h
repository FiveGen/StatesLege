//
//  SLFBadgeCell.h
//  Created by Gregory Combs on 3/24/11.
//
//  OpenStates (iOS) by Sunlight Foundation Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

#import <UIKit/UIKit.h>

@class BillsSubjectsEntry;
@interface SLFBadgeCell : UITableViewCell
@property (nonatomic,assign) BOOL isClickable;
@property (nonatomic,retain) BillsSubjectsEntry *subjectEntry;
@end
