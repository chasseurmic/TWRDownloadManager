//
//  ViewController.m
//  BackgroundDownload
//
//  Created by Michelangelo Chasseur on 13/09/14.
//  Copyright (c) 2014 Touchware. All rights reserved.
//

#import "ViewController.h"
#import <TWRDownloadManager/TWRDownloadManager.h>

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Just a demo example file...
    [[TWRDownloadManager sharedManager] downloadFileForURL:@"http://ovh.net/files/10Mio.dat" progressBlock:^(CGFloat progress) {
        NSLog(@"%.2f", progress);
    } completionBlock:^(BOOL completed) {
        NSLog(@"Download completed!");
    } enableBackgroundMode:YES];
}

@end
