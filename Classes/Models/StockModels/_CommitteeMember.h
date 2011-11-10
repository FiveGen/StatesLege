// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to CommitteeMember.h instead.

#import <CoreData/CoreData.h>


@class SLFCommittee;





@interface CommitteeMemberID : NSManagedObjectID {}
@end

@interface _CommitteeMember : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (CommitteeMemberID*)objectID;




@property (nonatomic, retain) NSString *legID;


//- (BOOL)validateLegID:(id*)value_ error:(NSError**)error_;




@property (nonatomic, retain) NSString *legislatorName;


//- (BOOL)validateLegislatorName:(id*)value_ error:(NSError**)error_;




@property (nonatomic, retain) NSString *role;


//- (BOOL)validateRole:(id*)value_ error:(NSError**)error_;





@property (nonatomic, retain) SLFCommittee* committeeInverse;

//- (BOOL)validateCommitteeInverse:(id*)value_ error:(NSError**)error_;




@end

@interface _CommitteeMember (CoreDataGeneratedAccessors)

@end

@interface _CommitteeMember (CoreDataGeneratedPrimitiveAccessors)


- (NSString*)primitiveLegID;
- (void)setPrimitiveLegID:(NSString*)value;




- (NSString*)primitiveLegislatorName;
- (void)setPrimitiveLegislatorName:(NSString*)value;




- (NSString*)primitiveRole;
- (void)setPrimitiveRole:(NSString*)value;





- (SLFCommittee*)primitiveCommitteeInverse;
- (void)setPrimitiveCommitteeInverse:(SLFCommittee*)value;


@end
