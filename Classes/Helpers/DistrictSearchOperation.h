//
//  DistrictSearchOperation.h
//  Created by Gregory Combs on 9/1/10.
//
//  StatesLege by Sunlight Foundation, based on work at https://github.com/sunlightlabs/StatesLege
//
//  This work is licensed under the Creative Commons Attribution-NonCommercial 3.0 Unported License. 
//  To view a copy of this license, visit http://creativecommons.org/licenses/by-nc/3.0/
//  or send a letter to Creative Commons, 444 Castro Street, Suite 900, Mountain View, California, 94041, USA.
//
//

#import <MapKit/MapKit.h>
#import <RestKit/RestKit.h>

typedef enum {
    DistrictSearchOperationFailOptionLog,
    DistrictSearchOperationShowAlert,
    DistrictSearchOperationFailOptionCount
} DistrictSearchOperationFailOption;

typedef void(^DistrictSearchSuccessWithResultsBlock)(NSArray *results);
typedef void(^DistrictSearchFailureWithMessageAndFailOptionBlock)(NSString *message, DistrictSearchOperationFailOption failOption);

@interface DistrictSearchOperation : NSObject <RKRequestDelegate> {
}

- (void)searchForCoordinate:(CLLocationCoordinate2D)coordinate
               successBlock:(DistrictSearchSuccessWithResultsBlock)successBlock
               failureBlock:(DistrictSearchFailureWithMessageAndFailOptionBlock)failureBlock;

+ (DistrictSearchOperation *)searchOperationForCoordinate:(CLLocationCoordinate2D)coordinate
               successBlock:(DistrictSearchSuccessWithResultsBlock)successBlock
               failureBlock:(DistrictSearchFailureWithMessageAndFailOptionBlock)failureBlock;

@end
