/*
 * PhoneGap is available under *either* the terms of the modified BSD license *or* the
 * MIT License (2008). See http://opensource.org/licenses/alphabetical for full text.
 * 
 * Copyright (c) 2005-2011, Nitobi Software Inc.
 * Copyright (c) 2011, Matt Kane
 * Copyright (c) 2011, IBM Corporation
 */

#import "FileTransfer.h"


@implementation FileTransfer

- (void) upload:(NSMutableArray*)arguments withDict:(NSMutableDictionary*)options {
    NSString* callbackId = [arguments objectAtIndex:0];
    NSString* fileKey = (NSString*)[options objectForKey:@"fileKey"];
    NSString* fileName = (NSString*)[options objectForKey:@"fileName"];
    NSString* mimeType = (NSString*)[options objectForKey:@"mimeType"];
    NSMutableDictionary* params = [NSMutableDictionary dictionaryWithDictionary:(NSDictionary*)[options objectForKey:@"params"]];
    NSString* filePath = (NSString*)[options objectForKey:@"filePath"];
    NSString* server = (NSString*)[options objectForKey:@"server"];
    PluginResult* result = nil;
    FileTransferError errorCode = 0;

    
    NSURL* file;
    
    if ([filePath hasPrefix:@"/"]) {
        file = [NSURL fileURLWithPath:filePath];
    } else {
        file = [NSURL URLWithString:filePath];
    }
    
    NSURL *url = [NSURL URLWithString:server];

    
    if(![file isFileURL]) {
        NSLog(@"File Transfer Error: Invalid file path or URL");
    } else if (!url) {
        NSLog(@"File Transfer Error: Invalid server URL");

        
    }
    if(errorCode > 0) {
        result = [PluginResult resultWithStatus: PGCommandStatus_OK messageAsInt: INVALID_URL_ERR cast: @"navigator.fileTransfer._castTransferError"];
        [self writeJavascript:[result toErrorCallbackString:callbackId]];
        return;
    }
    
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:url];
	[req setHTTPMethod:@"POST"];
	
//    Magic value to set a cookie
	if([params objectForKey:@"__cookie"]) {
		[req setValue:[params objectForKey:@"__cookie"] forHTTPHeaderField:@"Cookie"];
		[params removeObjectForKey:@"__cookie"];
		[req setHTTPShouldHandleCookies:NO];
	}
	
	NSString *boundary = @"*****com.phonegap.formBoundary";
    
	NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@", boundary];
	[req setValue:contentType forHTTPHeaderField:@"Content-type"];
	[req setValue:@"XMLHttpRequest" forHTTPHeaderField:@"X-Requested-With"];
	NSString* userAgent = [[webView request] valueForHTTPHeaderField:@"User-agent"];
	if(userAgent) {
		[req setValue: userAgent forHTTPHeaderField:@"User-agent"];
	}
	
	NSData *imageData = [NSData dataWithContentsOfURL:file];
	
	if(!imageData) {
        result = [PluginResult resultWithStatus: PGCommandStatus_OK messageAsInt: FILE_NOT_FOUND_ERR cast: @"navigator.fileTransfer._castTransferError"];
        NSLog(@"File Transfer Error: Could not open file");
        [self writeJavascript:[result toErrorCallbackString:callbackId]];

		return;
	}
	
	NSMutableData *postBody = [NSMutableData data];
	
	NSEnumerator *enumerator = [params keyEnumerator];
	id key;
	id val;
	while ((key = [enumerator nextObject])) {
		val = [params objectForKey:key];
		if(!val || val == [NSNull null]) {
			continue;	
		}
		[postBody appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
		[postBody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n", key] dataUsingEncoding:NSUTF8StringEncoding]];
		[postBody appendData:[val dataUsingEncoding:NSUTF8StringEncoding]];
		[postBody appendData:[@"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
	}
    
	[postBody appendData:[[NSString stringWithFormat:@"--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n", fileKey, fileName] dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:[[NSString stringWithFormat:@"Content-Type: %@\r\n\r\n", mimeType] dataUsingEncoding:NSUTF8StringEncoding]];
	[postBody appendData:imageData];
	[postBody appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n", boundary] dataUsingEncoding:NSUTF8StringEncoding]];
	[req setHTTPBody:postBody];
	
	FileTransferDelegate* delegate = [[[FileTransferDelegate alloc] init] autorelease];
	delegate.command = self;
    delegate.callbackId = callbackId;
	
	[NSURLConnection connectionWithRequest:req delegate:delegate];
    
}

@end


@implementation FileTransferDelegate

@synthesize callbackId, responseData, command, bytesWritten;


- (void)connectionDidFinishLoading:(NSURLConnection *)connection 
{
    NSString* response = [[NSString alloc] initWithData:self.responseData encoding:NSUTF8StringEncoding];
    // create dictionary to return FileUploadResult object
    NSMutableDictionary* uploadResult = [NSMutableDictionary dictionaryWithCapacity:3];
    [uploadResult setObject: [response stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding] forKey: @"response"];
    [uploadResult setObject:[NSNumber numberWithInt: self.bytesWritten] forKey:@"bytesSent"];
    [uploadResult setObject:[NSNull null] forKey: @"responseCode"];
    PluginResult* result = [PluginResult resultWithStatus: PGCommandStatus_OK messageAsDictionary: uploadResult cast: @"navigator.fileTransfer._castUploadResult"];
    [command writeJavascript:[result toSuccessCallbackString: callbackId]];
    [response release];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error 
{
    PluginResult* result = [PluginResult resultWithStatus: PGCommandStatus_OK messageAsInt: CONNECTION_ERR cast: @"navigator.fileTransfer._castTransferError"];
    NSLog(@"File Transfer Error: %@", [error localizedDescription]);
    [command writeJavascript:[result toErrorCallbackString: callbackId]];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [responseData appendData:data];
}
- (void)connection:(NSURLConnection *)connection didSendBodyData:(NSInteger)bytesWritten totalBytesWritten:(NSInteger)totalBytesWritten totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite
{
    self.bytesWritten = totalBytesWritten;
}
/* TESTING ONLY CODE
// use ONLY for testing with self signed certificates
// uncomment and modify server name in connectiondidReceiveAuthenticationChallenge
- (BOOL)connection:(NSURLConnection *)connection canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace
{
    return [protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust];
}

- (void)connection:(NSURLConnection *) connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge*)challenge
{
	if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust])
	{
        //NSLog(@"challenge host: %@", challenge.protectionSpace.host);
		// we only trust our own domain
		if ([challenge.protectionSpace.host isEqualToString:@"serverName.domain.com"]){
            NSURLCredential* myCredential = [NSURLCredential credentialForTrust: challenge.protectionSpace.serverTrust];
            
            [challenge.sender useCredential:myCredential forAuthenticationChallenge:challenge];
			
		}
	}
    
	[challenge.sender continueWithoutCredentialForAuthenticationChallenge:challenge];
}
// uncomment the above two methods for testing servers with self signed certificates
// END TESTING ONLY CODE
 */
- (id) init
{
    if ((self = [super init])) {
		self.responseData = [NSMutableData data];
    }
    return self;
}

- (void) dealloc
{
    [callbackId release];
	[responseData release];
	[command release];
    [super dealloc];
}


@end;

