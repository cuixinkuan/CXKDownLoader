//
//  CXKHTTPDownloader.h
//  CXKDownLoader
//
//  Created by admin on 15/12/2.
//  Copyright © 2015年 CXK. All rights reserved.
//

#import <Foundation/Foundation.h>

@class CXKHTTPDownloader;

@protocol CXKHTTPDownloaderDelegate <NSObject>

@optional

- (void)CXKHTTPDownloader:(CXKHTTPDownloader *)downloader downloaderProgress:(double)progress;
- (void)CXKHTTPDownloader:(CXKHTTPDownloader *)downloader didFinishWithData:(NSData *)data;
- (void)CXKHTTPDownloader:(CXKHTTPDownloader *)downloader didFailWithError:(NSError *)error;

@end

@interface CXKHTTPDownloader : NSOperation

- (id)initWithRequestURL:(NSURL *)URL delegate:(id<CXKHTTPDownloaderDelegate>)delegate;

- (id)initWithRequestURL:(NSURL *)URL
                progress:(void(^)(float percent))progress
              completion:(void(^)(id response,NSError * error))completion;




































@end
