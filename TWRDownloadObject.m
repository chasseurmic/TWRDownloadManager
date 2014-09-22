//
//  TWRDownloadObject.m
//  DownloadManager
//
//  Created by Michelangelo Chasseur on 26/07/14.
//  Copyright (c) 2014 Touchware. All rights reserved.
//

#import "TWRDownloadObject.h"

@implementation TWRDownloadObject

- (instancetype)initWithDownloadTask:(NSURLSessionDownloadTask *)downloadTask
                       progressBlock:(TWRDownloadProgressBlock)progressBlock
                       remainingTime:(TWRDownloadRemainingTimeBlock)remainingTimeBlock
                     completionBlock:(TWRDownloadCompletionBlock)completionBlock {
    self = [super init];
    if (self) {
        self.downloadTask = downloadTask;
        self.progressBlock = progressBlock;
        self.remainingTimeBlock = remainingTimeBlock;
        self.completionBlock = completionBlock;
    }
    return self;
}

@end
