#import <RestKit/RestKit.h>
#import <RestKit/CoreData/CoreData.h>
#import "MultiRowAnnotationProtocol.h"
#import "_SLFDistrict.h"

@class SLFChamber;
@class SLFParty;
@interface SLFDistrict : _SLFDistrict <MultiRowAnnotationProtocol> {}
@property (nonatomic,readonly) SLFChamber *chamberObj;
@property (nonatomic,assign) MKCoordinateRegion region;
@property (nonatomic,readonly) CLLocationCoordinate2D coordinate;
@property (nonatomic,readonly) SLFParty *party;
@property (nonatomic,retain) MKPolygon *districtPolygon;
@property (nonatomic,readonly) NSUInteger pinColorIndex;
- (NSArray *)calloutCells;
- (NSString *)title;
- (NSString *)subtitle;
- (UIImage *)image;
- (MKPolygon *)polygonFactory;
+ (RKManagedObjectMapping *)mappingWithStateMapping:(RKManagedObjectMapping *)stateMapping;
+ (NSArray *)sortDescriptors;
+ (NSString *)estimatedBoundaryIDForDistrict:(NSString *)district chamber:(SLFChamber *)chamber;
@end
