#import <RestKit/RestKit.h>
#import <RestKit/CoreData/CoreData.h>
#import "_SLFEvent.h"

@class SLFState;
@interface SLFEvent : _SLFEvent {}
@property (nonatomic,readonly) SLFState *state;
@property (nonatomic,readonly) NSString *dateStartForDisplay;
+ (RKManagedObjectMapping *)mappingWithStateMapping:(RKManagedObjectMapping *)stateMapping;
+ (NSArray *)sortDescriptors;
@end
