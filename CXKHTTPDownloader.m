//
//  CXKHTTPDownloader.m
//  CXKDownLoader
//
//  Created by admin on 15/12/2.
//  Copyright © 2015年 CXK. All rights reserved.
//

#import "CXKHTTPDownloader.h"
#define DELEGATE_HAS_METHOD(delegate, method) delegate && [delegate respondsToSelector:@selector(method)]

typedef NS_ENUM(NSInteger,CXKRequestState) {
    CXKRequestStateReady = 0,
    CXKRequestStateExecuting = 1,
    CXKRequestStateFinished = 2,
};

static const NSTimeInterval kRequestTimeout = 20.0f;

@interface CXKHTTPDownloader ()<NSURLConnectionDelegate,NSURLConnectionDataDelegate>

@property (nonatomic,strong)NSMutableData * fileData;
@property (nonatomic,strong)NSMutableURLRequest * request;
@property (nonatomic,strong)NSURLConnection * connection;

@property (nonatomic,assign)float expectedLength;
@property (nonatomic,assign)float receivedLength;
@property (nonatomic,assign)CXKRequestState state;
@property (nonatomic,assign)CFRunLoopRef operationRunLoop;

@property (nonatomic,weak)id <CXKHTTPDownloaderDelegate> delegate;
@property (nonatomic,copy)void (^completion)(id response,NSError * error);
@property (nonatomic,copy)void (^progress)(float persent);

@end

@implementation CXKHTTPDownloader
@synthesize state = _state;

- (void)dealloc {
    [self.connection cancel];
}

#pragma - initialize methods - 

- (id)initWithRequestURL:(NSURL *)URL delegate:(id<CXKHTTPDownloaderDelegate>)delegate {
    return [self initWithRequestURL:URL delegate:delegate progress:nil completion:nil];
}
- (id)initWithRequestURL:(NSURL *)URL progress:(void (^)(float))progress completion:(void (^)(id, NSError *))completion {
    return [self initWithRequestURL:URL delegate:nil progress:progress completion:completion];
}

- (id)initWithRequestURL:(NSURL *)URL delegate:(id<CXKHTTPDownloaderDelegate>)delegate progress:(void(^)(float percent))progress completion:(void(^)(id response,NSError * error))completion;
{
    if (self = [super init]) {
        self.delegate = delegate;
        self.progress = progress;
        self.completion = completion;
        self.request = [NSMutableURLRequest requestWithURL:URL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:kRequestTimeout];
    }
    return self;
}

#pragma msrk - NSOperation Methods -
- (void)start {
    if (self.isCancelled) {
        [self finish];
        return;
    }
    [self willChangeValueForKey:@"isExecuting"];
    self.state = CXKRequestStateExecuting;
    [self didChangeValueForKey:@"isExecuting"];
    
    self.connection = [[NSURLConnection alloc] initWithRequest:self.request delegate:self startImmediately:NO];
    
    NSOperationQueue * currentQueue = [NSOperationQueue currentQueue];
    BOOL backgroundQueue = (currentQueue != nil && currentQueue != [NSOperationQueue mainQueue]);
    NSRunLoop * targetRunLoop = (backgroundQueue)?[NSRunLoop currentRunLoop]:[NSRunLoop mainRunLoop];
    [self.connection scheduleInRunLoop:targetRunLoop forMode:NSRunLoopCommonModes];
    if (backgroundQueue) {
        self.operationRunLoop = CFRunLoopGetCurrent();
        CFRunLoopRun();
    }
    
}


#pragma msrk - request status -

- (void)finish {
    [self.connection cancel];
    self.connection = nil;
    [self willChangeValueForKey:@"isExecuting"];
    [self willChangeValueForKey:@"isFinished"];
    self.state = CXKRequestStateFinished;
    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
}

- (void)cancel {
    if (![self isExecuting]) {
        return;
    }
    [super cancel];
    [self finish];
}

- (BOOL)isConcurrent {
    return YES;
}

- (BOOL)isFinished {
    return self.state == CXKRequestStateFinished;
}

- (BOOL)isExecuting {
    return self.state == CXKRequestStateExecuting;
}

- (CXKRequestState)state {
    @synchronized(self) {
        return _state;
    }
}

- (void)setState:(CXKRequestState)newState {
    @synchronized(self) {
        [self willChangeValueForKey:@"state"];
        _state = newState;
        [self didChangeValueForKey:@"state"];
    }
}


#pragma msrk - NSURLConnectionDelegate -
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    self.expectedLength = response.expectedContentLength;
    self.receivedLength =  0;
    self.fileData = [NSMutableData data];
}
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [self.fileData appendData:data];
    self.receivedLength += data.length;
    float percent = self.receivedLength / self.expectedLength;
    if (self.progress) {
        self.progress(percent);
    }
    if (DELEGATE_HAS_METHOD(self.delegate, CXKHTTPDownloader:downloaderProgress:)) {
        [self.delegate CXKHTTPDownloader:self downloaderProgress:percent];
    }
}
- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    [self downloadFinishedWithResponse:self.fileData error:nil];
}
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [self downloadFinishedWithResponse:nil error:error];
}

#pragma mark - Download Finished - 
- (void)downloadFinishedWithResponse:(id)response error:(NSError *)error {
    if (self.operationRunLoop) {
        CFRunLoopStop(self.operationRunLoop);
    }
    if (self.isCancelled) {
        return;
    }
    if (self.completion ) {
        self.completion(self.fileData,error);
    }
    if (response && DELEGATE_HAS_METHOD(self.delegate, CXKHTTPDownloader:didFinishWithData:)) {
        [self.delegate CXKHTTPDownloader:self didFinishWithData:response];
    }
    else if (!response && DELEGATE_HAS_METHOD(self.delegate, CXKHTTPDownloader:didFailWithError:)) {
        [self.delegate CXKHTTPDownloader:self didFailWithError:error];
    }
    [self finish];
    
}















































@end
