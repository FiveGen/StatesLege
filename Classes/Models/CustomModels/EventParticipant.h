#import "_EventParticipant.h"

@class RKManagedObjectMapping;
@interface EventParticipant : _EventParticipant {}
+ (RKManagedObjectMapping *)mapping;
+ (NSArray *)sortDescriptors;
@end
