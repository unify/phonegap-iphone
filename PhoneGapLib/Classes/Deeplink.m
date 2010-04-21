//
//  Deeplink.m
//  PhoneGapLib
//
//  Created by Sebastian Fastner on 21.04.10.
//  Copyright 2010 Deutsche Telekom AG, Germany. All rights reserved.
//

#import "Deeplink.h"
#import <UIKit/UIKit.h>

@implementation Deeplink

- (id) initWithWebView:(UIWebView *)theWebView
{
	self = (Deeplink*)[super initWithWebView:theWebView];
	
	return self;
}

- (void) open:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options
{
	NSString* url = [arguments objectAtIndex:0];
	
	BOOL successfulOpenURL = [[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
	
	NSString* sucUrl;
	if (successfulOpenURL) {
		sucUrl = @"true";
	} else {
		sucUrl = @"false";
	}
	
	NSString* jsString = [NSString stringWithFormat:@"navigator.deeplink.callback(\"%@\",%@);",url,sucUrl];
	
	[webView stringByEvaluatingJavaScriptFromString:jsString];
	
}

@end
