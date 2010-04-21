//
//  Deeplink.h
//  PhoneGapLib
//
//  Created by Sebastian Fastner on 21.04.10.
//  Copyright 2010 Deutsche Telekom AG, Germany. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "PhoneGapCommand.h"

@interface Deeplink : PhoneGapCommand {
}

- (void)open:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options;

@end
