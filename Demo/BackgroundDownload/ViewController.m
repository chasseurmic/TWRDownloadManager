//
//  ViewController.m
//  BackgroundDownload
//
//  Created by Michelangelo Chasseur on 13/09/14.
//  Copyright (c) 2014 Touchware. All rights reserved.
//

#define FILE_URL @"http://ovh.net/files/10Mio.dat"

#import "ViewController.h"
#import "TWRDownloadManager.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UILabel *mainLabel;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (weak, nonatomic) IBOutlet UIButton *startButton;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIButton *deleteButton;
@property (assign, nonatomic) CGFloat progress;

- (IBAction)startDownload:(id)sender;
- (IBAction)cancelDownload:(id)sender;
- (IBAction)deleteFiles:(id)sender;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.progressView.progress = 0.0f;
    self.mainLabel.text = @"TWRDownloadManager Demo";
    if ([[TWRDownloadManager sharedManager] fileExistsForUrl:FILE_URL]) {
        self.deleteButton.enabled = YES;
        self.cancelButton.enabled = NO;
        self.startButton.enabled = NO;
    } else {
        self.deleteButton.enabled = NO;
        self.cancelButton.enabled = NO;
        self.startButton.enabled = YES;
    }
}

- (IBAction)startDownload:(id)sender {
    // Just a demo example file...
    [[TWRDownloadManager sharedManager] downloadFileForURL:FILE_URL progressBlock:^(CGFloat progress) {
//        NSLog(@"%.2f", progress);
        self.progress = progress;
        self.progressView.progress = progress;
    } remainingTime:^(NSUInteger seconds) {
        NSLog(@"ETA: %lu sec.", (unsigned long)seconds);
        self.mainLabel.text = [NSString stringWithFormat:@"Progress: %.0f%% - ETA: %lu sec.", self.progress, seconds];
    } completionBlock:^(BOOL completed) {
        NSLog(@"Download completed!");
        self.deleteButton.enabled = YES;
        self.cancelButton.enabled = NO;
        self.startButton.enabled = NO;
    } enableBackgroundMode:YES];
    
    self.cancelButton.enabled = YES;
    self.startButton.enabled = NO;
}

- (IBAction)cancelDownload:(id)sender {
    [[TWRDownloadManager sharedManager] cancelAllDownloads];
    [self nilProgress];
    self.startButton.enabled = YES;
    self.cancelButton.enabled = NO;
    self.deleteButton.enabled = NO;
}

- (IBAction)deleteFiles:(id)sender {
    [[TWRDownloadManager sharedManager] deleteFileForUrl:FILE_URL];
    [self nilProgress];
    self.deleteButton.enabled = NO;
    self.startButton.enabled = YES;
    self.cancelButton.enabled = NO;
}

- (void)nilProgress {
    self.progressView.progress = 0.0f;
    self.progress = 0.0f;
    self.mainLabel.text = @"TWRDownloadManager Demo";
}

@end
