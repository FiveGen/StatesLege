#import <RestKit/RestKit.h>
#import <RestKit/CoreData/CoreData.h>
#import "_SLFCommittee.h"

@class SLFState;
@class SLFChamber;
@interface SLFCommittee : _SLFCommittee {}
@property (nonatomic,readonly) SLFState *state;
@property (nonatomic, readonly) SLFChamber *chamberObj;
@property (nonatomic, readonly) NSString *chamberShortName;
- (NSArray *) sortedMembers;
@end
