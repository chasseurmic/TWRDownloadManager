//
//  TWRDownloadManager.m
//  DownloadManager
//
//  Created by Michelangelo Chasseur on 25/07/14.
//  Copyright (c) 2014 Touchware. All rights reserved.
//

#import "TWRDownloadManager.h"
#import "TWRDownloadObject.h"

@interface TWRDownloadManager () <NSURLSessionDelegate, NSURLSessionDownloadDelegate>

@property (strong, nonatomic) NSURLSession *session;
@property (strong, nonatomic) NSURLSession *backgroundSession;
@property (strong, nonatomic) NSMutableDictionary *downloads;

@end

@implementation TWRDownloadManager

+ (instancetype)sharedManager {
    static TWRDownloadManager *_sharedManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedManager = [[TWRDownloadManager alloc] init];
    });
    
    return _sharedManager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        // Default session
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        self.session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];
        
        // Background session
        NSURLSessionConfiguration *backgroundConfiguration = [NSURLSessionConfiguration backgroundSessionConfiguration:@"re.touchwa.downloadmanager"];
        
        if (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_7_1) {
            backgroundConfiguration = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:@"re.touchwa.downloadmanager"];
        }
        
        self.backgroundSession = [NSURLSession sessionWithConfiguration:backgroundConfiguration delegate:self delegateQueue:nil];
        
        self.downloads = [NSMutableDictionary new];
    }
    return self;
}

#pragma mark - Downloading... 

- (void)downloadFileForURL:(NSString *)urlString
                  withName:(NSString *)fileName
          inDirectoryNamed:(NSString *)directory
             progressBlock:(void(^)(CGFloat progress))progressBlock
             remainingTime:(void(^)(NSUInteger seconds))remainingTimeBlock
           completionBlock:(void(^)(BOOL completed))completionBlock
      enableBackgroundMode:(BOOL)backgroundMode {
    NSURL *url = [NSURL URLWithString:urlString];
    if (!fileName) {
        fileName = [urlString lastPathComponent];
    }
    
    if (![self fileDownloadCompletedForUrl:urlString]) {
        NSLog(@"File is downloading!");
    } else if (![self fileExistsWithName:fileName inDirectory:directory]) {
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        NSURLSessionDownloadTask *downloadTask;
        if (backgroundMode) {
            downloadTask = [self.backgroundSession downloadTaskWithRequest:request];
        } else {
            downloadTask = [self.session downloadTaskWithRequest:request];
        }
        TWRDownloadObject *downloadObject = [[TWRDownloadObject alloc] initWithDownloadTask:downloadTask progressBlock:progressBlock remainingTime:remainingTimeBlock completionBlock:completionBlock];
        downloadObject.startDate = [NSDate date];
        downloadObject.fileName = fileName;
        downloadObject.directoryName = directory;
        [self.downloads addEntriesFromDictionary:@{urlString:downloadObject}];
        [downloadTask resume];
    } else {
        NSLog(@"File already exists!");
    }
}

- (void)downloadFileForURL:(NSString *)url
          inDirectoryNamed:(NSString *)directory
             progressBlock:(void(^)(CGFloat progress))progressBlock
             remainingTime:(void(^)(NSUInteger seconds))remainingTimeBlock
           completionBlock:(void(^)(BOOL completed))completionBlock
      enableBackgroundMode:(BOOL)backgroundMode {
    [self downloadFileForURL:url
                    withName:[url lastPathComponent]
            inDirectoryNamed:directory
               progressBlock:progressBlock
               remainingTime:remainingTimeBlock
             completionBlock:completionBlock
        enableBackgroundMode:backgroundMode];
}

- (void)downloadFileForURL:(NSString *)url
             progressBlock:(void(^)(CGFloat progress))progressBlock
             remainingTime:(void(^)(NSUInteger seconds))remainingTimeBlock
           completionBlock:(void(^)(BOOL completed))completionBlock
      enableBackgroundMode:(BOOL)backgroundMode {
    [self downloadFileForURL:url
                    withName:[url lastPathComponent]
            inDirectoryNamed:nil
               progressBlock:progressBlock
               remainingTime:remainingTimeBlock
             completionBlock:completionBlock
        enableBackgroundMode:backgroundMode];
}

- (void)downloadFileForURL:(NSString *)urlString
                  withName:(NSString *)fileName
          inDirectoryNamed:(NSString *)directory
             progressBlock:(void(^)(CGFloat progress))progressBlock
           completionBlock:(void(^)(BOOL completed))completionBlock
      enableBackgroundMode:(BOOL)backgroundMode {
    [self downloadFileForURL:urlString
                   withName:fileName
           inDirectoryNamed:directory
              progressBlock:progressBlock
              remainingTime:nil
            completionBlock:completionBlock
        enableBackgroundMode:backgroundMode];
}

- (void)downloadFileForURL:(NSString *)urlString
          inDirectoryNamed:(NSString *)directory
             progressBlock:(void(^)(CGFloat progress))progressBlock
           completionBlock:(void(^)(BOOL completed))completionBlock
      enableBackgroundMode:(BOOL)backgroundMode {
    // if no file name was provided, use the last path component of the URL as its name
    [self downloadFileForURL:urlString
                    withName:[urlString lastPathComponent]
            inDirectoryNamed:directory
               progressBlock:progressBlock
             completionBlock:completionBlock
        enableBackgroundMode:backgroundMode];
}

- (void)downloadFileForURL:(NSString *)urlString
             progressBlock:(void(^)(CGFloat progress))progressBlock
           completionBlock:(void(^)(BOOL completed))completionBlock
      enableBackgroundMode:(BOOL)backgroundMode {
    [self downloadFileForURL:urlString
            inDirectoryNamed:nil
               progressBlock:progressBlock
             completionBlock:completionBlock
        enableBackgroundMode:backgroundMode];
}

- (void)cancelDownloadForUrl:(NSString *)fileIdentifier {
    TWRDownloadObject *download = [self.downloads objectForKey:fileIdentifier];
    if (download) {
        [download.downloadTask cancel];
        [self.downloads removeObjectForKey:fileIdentifier];
        if (download.completionBlock) {
            download.completionBlock(NO);
        }
    }
    if (self.downloads.count == 0) {
        [self cleanTmpDirectory];
        
    }
}

- (void)cancelAllDownloads {
    [self.downloads enumerateKeysAndObjectsUsingBlock:^(id key, TWRDownloadObject *download, BOOL *stop) {
        if (download.completionBlock) {
            download.completionBlock(NO);
        }
        [download.downloadTask cancel];
        [self.downloads removeObjectForKey:key];
    }];
    [self cleanTmpDirectory];
}

- (NSArray *)currentDownloads {
    NSMutableArray *currentDownloads = [NSMutableArray new];
    [self.downloads enumerateKeysAndObjectsUsingBlock:^(id key, TWRDownloadObject *download, BOOL *stop) {
        [currentDownloads addObject:download.downloadTask.originalRequest.URL.absoluteString];
    }];
    return currentDownloads;
}

#pragma mark - NSURLSession Delegate

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    NSString *fileIdentifier = downloadTask.originalRequest.URL.absoluteString;
    TWRDownloadObject *download = [self.downloads objectForKey:fileIdentifier];
    if (download.progressBlock) {
        CGFloat progress = (CGFloat)totalBytesWritten / (CGFloat)totalBytesExpectedToWrite;
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            download.progressBlock(progress);
        });
    }
    
    CGFloat remainingTime = [self remainingTimeForDownload:download bytesTransferred:totalBytesWritten totalBytesExpectedToWrite:totalBytesExpectedToWrite];
    if (download.remainingTimeBlock) {
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            download.remainingTimeBlock((NSUInteger)remainingTime);
        });
    }
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location {
//    NSLog(@"Download finisehd!");
    
    NSError *error;
    NSURL *destinationLocation;
    
    NSString *fileIdentifier = downloadTask.originalRequest.URL.absoluteString;
    TWRDownloadObject *download = [self.downloads objectForKey:fileIdentifier];
    
    if (download.directoryName) {
        destinationLocation = [[[self cachesDirectoryUrlPath] URLByAppendingPathComponent:download.directoryName] URLByAppendingPathComponent:download.fileName];
    } else {
        destinationLocation = [[self cachesDirectoryUrlPath] URLByAppendingPathComponent:download.fileName];
    }
    
    // Move downloaded item from tmp directory to te caches directory
    // (not synced with user's iCloud documents)
    [[NSFileManager defaultManager] moveItemAtURL:location
                                            toURL:destinationLocation
                                            error:&error];
    if (error) {
        NSLog(@"ERROR: %@", error);
    }
    
    if (download.completionBlock) {
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            download.completionBlock(YES);
        });
    }
    
    // remove object from the download
    [self.downloads removeObjectForKey:fileIdentifier];
}

- (CGFloat)remainingTimeForDownload:(TWRDownloadObject *)download
                   bytesTransferred:(int64_t)bytesTransferred
          totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite {
    NSTimeInterval timeInterval = [[NSDate date] timeIntervalSinceDate:download.startDate];
    CGFloat speed = (CGFloat)bytesTransferred / (CGFloat)timeInterval;
    CGFloat remainingBytes = totalBytesExpectedToWrite - bytesTransferred;
    CGFloat remainingTime =  remainingBytes / speed;
    return remainingTime;
}

#pragma mark - File Management

- (NSURL *)cachesDirectoryUrlPath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cachesDirectory = [paths objectAtIndex:0];
    NSURL *cachesDirectoryUrl = [NSURL fileURLWithPath:cachesDirectory];
    return cachesDirectoryUrl;
}

- (BOOL)fileDownloadCompletedForUrl:(NSString *)fileIdentifier {
    BOOL retValue = YES;
    TWRDownloadObject *download = [self.downloads objectForKey:fileIdentifier];
    if (download) {
        // downloads are removed once they finish
        retValue = NO;
    }
    return retValue;
}

- (BOOL)isFileDownloadingForUrl:(NSString *)fileIdentifier
              withProgressBlock:(void(^)(CGFloat progress))block {
    return [self isFileDownloadingForUrl:fileIdentifier
                       withProgressBlock:block
                         completionBlock:nil];
}

- (BOOL)isFileDownloadingForUrl:(NSString *)fileIdentifier
              withProgressBlock:(void(^)(CGFloat progress))block
                completionBlock:(void(^)(BOOL completed))completionBlock {
    BOOL retValue = NO;
    TWRDownloadObject *download = [self.downloads objectForKey:fileIdentifier];
    if (download) {
        download.progressBlock = block;
        download.completionBlock = completionBlock;
        retValue = YES;
    }
    return retValue;
}

#pragma mark File existance

- (NSString *)localPathForFile:(NSString *)fileIdentifier {
    return [self localPathForFile:fileIdentifier inDirectory:nil];
}

- (NSString *)localPathForFile:(NSString *)fileIdentifier inDirectory:(NSString *)directoryName {
    NSString *fileName = [fileIdentifier lastPathComponent];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cachesDirectory = [paths objectAtIndex:0];
    return [[cachesDirectory stringByAppendingPathComponent:directoryName] stringByAppendingPathComponent:fileName];
}

- (BOOL)fileExistsForUrl:(NSString *)urlString {
    return [self fileExistsForUrl:urlString inDirectory:nil];
}

- (BOOL)fileExistsForUrl:(NSString *)urlString inDirectory:(NSString *)directoryName {
    return [self fileExistsWithName:[urlString lastPathComponent] inDirectory:directoryName];
}

- (BOOL)fileExistsWithName:(NSString *)fileName
               inDirectory:(NSString *)directoryName {
    BOOL exists = NO;
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cachesDirectory = [paths objectAtIndex:0];
    
    // if no directory was provided, we look by default in the base cached dir
    if ([[NSFileManager defaultManager] fileExistsAtPath:[[cachesDirectory stringByAppendingPathComponent:directoryName] stringByAppendingPathComponent:fileName]]) {
        exists = YES;
    }
    
    return exists;
}

- (BOOL)fileExistsWithName:(NSString *)fileName {
    return [self fileExistsWithName:fileName inDirectory:nil];
}

#pragma mark File deletion

- (BOOL)deleteFileForUrl:(NSString *)urlString {
    return [self deleteFileForUrl:urlString inDirectory:nil];
}

- (BOOL)deleteFileForUrl:(NSString *)urlString inDirectory:(NSString *)directoryName {
    return [self deleteFileWithName:[urlString lastPathComponent] inDirectory:directoryName];
}

- (BOOL)deleteFileWithName:(NSString *)fileName {
    return [self deleteFileWithName:fileName inDirectory:nil];
}

- (BOOL)deleteFileWithName:(NSString *)fileName
               inDirectory:(NSString *)directoryName {
    BOOL deleted = NO;
    
    NSError *error;
    NSURL *fileLocation;
    if (directoryName) {
        fileLocation = [[[self cachesDirectoryUrlPath] URLByAppendingPathComponent:directoryName] URLByAppendingPathComponent:fileName];
    } else {
        fileLocation = [[self cachesDirectoryUrlPath] URLByAppendingPathComponent:fileName];
    }
    
    
    // Move downloaded item from tmp directory to te caches directory
    // (not synced with user's iCloud documents)
    [[NSFileManager defaultManager] removeItemAtURL:fileLocation error:&error];
    
    if (error) {
        deleted = NO;
        NSLog(@"Error deleting file: %@", error);
    } else {
        deleted = YES;
    }
    return deleted;
}

#pragma mark - Clean tmp directory

- (void)cleanTmpDirectory {
    NSArray* tmpDirectory = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:NSTemporaryDirectory() error:NULL];
    for (NSString *file in tmpDirectory) {
        [[NSFileManager defaultManager] removeItemAtPath:[NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), file] error:NULL];
    }
}

#pragma mark - Background download

-(void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session {
    // Check if all download tasks have been finished.
    [session getTasksWithCompletionHandler:^(NSArray *dataTasks, NSArray *uploadTasks, NSArray *downloadTasks) {
        if ([downloadTasks count] == 0) {
            if (self.backgroundTransferCompletionHandler != nil) {
                // Copy locally the completion handler.
                void(^completionHandler)() = self.backgroundTransferCompletionHandler;
                
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    // Call the completion handler to tell the system that there are no other background transfers.
                    completionHandler();
                    
                    // Show a local notification when all downloads are over.
                    UILocalNotification *localNotification = [[UILocalNotification alloc] init];
                    localNotification.alertBody = @"All files have been downloaded!";
                    [[UIApplication sharedApplication] presentLocalNotificationNow:localNotification];
                }];
                
                // Make nil the backgroundTransferCompletionHandler.
                self.backgroundTransferCompletionHandler = nil;
            }
        }
    }];
}

@end
