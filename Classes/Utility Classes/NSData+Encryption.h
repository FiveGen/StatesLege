//
//  NSData+Encryption.h
//  TexLege
//
//  Created by Gregory Combs on 8/10/10.
//  Copyright 2010 Gregory S. Combs. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface NSData (Encryption) {

}

- (NSData *)AES256EncryptWithKey:(NSString *)key;
- (NSData *)AES256DecryptWithKey:(NSString *)key;
	
@end
