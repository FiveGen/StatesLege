// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to SLFCommittee.h instead.

#import <CoreData/CoreData.h>

@class CommitteeMember;
@class SLFState;






@class NSArray;




@interface SLFCommitteeID : NSManagedObjectID {}
@end

@interface _SLFCommittee : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (SLFCommitteeID*)objectID;




@property (nonatomic, retain) NSString *chamber;


//- (BOOL)validateChamber:(id*)value_ error:(NSError**)error_;




@property (nonatomic, retain) NSString *committeeID;


//- (BOOL)validateCommitteeID:(id*)value_ error:(NSError**)error_;




@property (nonatomic, retain) NSString *committeeName;


//- (BOOL)validateCommitteeName:(id*)value_ error:(NSError**)error_;




@property (nonatomic, retain) NSDate *dateCreated;


//- (BOOL)validateDateCreated:(id*)value_ error:(NSError**)error_;




@property (nonatomic, retain) NSDate *dateUpdated;


//- (BOOL)validateDateUpdated:(id*)value_ error:(NSError**)error_;




@property (nonatomic, retain) NSSet* members;


- (NSMutableSet*)membersSet;




@property (nonatomic, retain) NSString *parentID;


//- (BOOL)validateParentID:(id*)value_ error:(NSError**)error_;




@property (nonatomic, retain) NSArray *sources;


//- (BOOL)validateSources:(id*)value_ error:(NSError**)error_;




@property (nonatomic, retain) NSString *stateID;


//- (BOOL)validateStateID:(id*)value_ error:(NSError**)error_;




@property (nonatomic, retain) NSString *subcommittee;


//- (BOOL)validateSubcommittee:(id*)value_ error:(NSError**)error_;




@property (nonatomic, retain) NSString *votesmartID;


//- (BOOL)validateVotesmartID:(id*)value_ error:(NSError**)error_;





@property (nonatomic, retain) SLFState* stateObj;

//- (BOOL)validateStateObj:(id*)value_ error:(NSError**)error_;




@end

@interface _SLFCommittee (CoreDataGeneratedAccessors)

- (void)addMembers:(NSSet*)value_;
- (void)removeMembers:(NSSet*)value_;
- (void)addMembersObject:(CommitteeMember*)value_;
- (void)removeMembersObject:(CommitteeMember*)value_;

@end

@interface _SLFCommittee (CoreDataGeneratedPrimitiveAccessors)


- (NSString*)primitiveChamber;
- (void)setPrimitiveChamber:(NSString*)value;




- (NSString*)primitiveCommitteeID;
- (void)setPrimitiveCommitteeID:(NSString*)value;




- (NSString*)primitiveCommitteeName;
- (void)setPrimitiveCommitteeName:(NSString*)value;




- (NSDate*)primitiveDateCreated;
- (void)setPrimitiveDateCreated:(NSDate*)value;




- (NSDate*)primitiveDateUpdated;
- (void)setPrimitiveDateUpdated:(NSDate*)value;




- (NSMutableSet*)primitiveMembers;
- (void)setPrimitiveMembers:(NSMutableSet*)value;




- (NSString*)primitiveParentID;
- (void)setPrimitiveParentID:(NSString*)value;




- (NSArray*)primitiveSources;
- (void)setPrimitiveSources:(NSArray*)value;




- (NSString*)primitiveStateID;
- (void)setPrimitiveStateID:(NSString*)value;




- (NSString*)primitiveSubcommittee;
- (void)setPrimitiveSubcommittee:(NSString*)value;




- (NSString*)primitiveVotesmartID;
- (void)setPrimitiveVotesmartID:(NSString*)value;





- (SLFState*)primitiveStateObj;
- (void)setPrimitiveStateObj:(SLFState*)value;


@end
