//
//  TWRDownloadObject.h
//  DownloadManager
//
//  Created by Michelangelo Chasseur on 26/07/14.
//  Copyright (c) 2014 Touchware. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^TWRDownloadProgressBlock)(CGFloat progress);
typedef void(^TWRDownloadCompletionBlock)(BOOL completed);

@interface TWRDownloadObject : NSObject

@property (copy, nonatomic) TWRDownloadProgressBlock progressBlock;
@property (copy, nonatomic) TWRDownloadCompletionBlock completionBlock;
@property (strong, nonatomic) NSURLSessionDownloadTask *downloadTask;
@property (copy, nonatomic) NSString *fileName;
@property (copy, nonatomic) NSString *directoryName;

- (instancetype)initWithDownloadTask:(NSURLSessionDownloadTask *)downloadTask
                       progressBlock:(TWRDownloadProgressBlock)progressBlock
                     completionBlock:(TWRDownloadCompletionBlock)completionBlock;

@end
