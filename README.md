TWRDownloadManager
=================

## TWRDownloadManager

A modern download manager for iOS (Objective C) based on NSURLSession to deal with asynchronous downloading, management and persistence of multiple files.

TWRDownloadManager is a singleton instance and can thus be called in your code safely from wherever you need to. The idea of writing yet another download manager library stemmed from the fact that at the time of the writing (and yet still) there were no available open source projects based on the new `NSURLSession` APIs made available by Apple in iOS 7.

TWRDownloadManager leverages the power of `NSURLSession` and `NSURLSessionDownloadTask` to make downloading of files and keeping track of their progress a breeze.

- - - 

**09.22.2014 - UPDATE!!!**

**v1.0.0** of `TWRDownloadManager` now supports background modes. The  API has changed so it’s not backwards compatible, hence its bump to v1.0.0. See the documentation below for further information.

A demo project has also been added to showcase the use of the download manager in its simplest form.

**v1.1.0** of `TWRDownloadManager` adds the ability to pass a block when creating the download to keep track of an estimated remaining download time. The algorithm can definitely be improved but it works. 

Updated demo project.


## Installing the library

To use the library, just add the dependency to your `Podfile`:

```ruby
platform :ios
pod 'TWRDownloadManager'
```

Run `pod install` to install the dependencies.

Next, import the header file wherever you want to use the manager:

```objc
#import <TWRDownloadManager/TWRDownloadManager.h>
```

Since TWRDownloadManager is a singleton you could import it in the `.pch` file of your project so that it can be accessed and used wherever you need it without worrying about importing it in each of your classes.

## Usage

`TWRDownloadManager` provides facilities for the following task:

- downloading files;
- persisting downloaded files and saving them to disk;
- keeping track of download progress via block syntax;
- being notified of the download completion via block syntax;
- deleting downloaded files;
- checking for file existence.

All the following instance methods can be called directly on `
[TWRDownloadManager sharedManager]`.

### Downloading files

```objc 
- (void)downloadFileForURL:(NSString *)url
                  withName:(NSString *)fileName
          inDirectoryNamed:(NSString *)directory
             progressBlock:(void(^)(CGFloat progress))progressBlock
           completionBlock:(void(^)(BOOL completed))completionBlock
      enableBackgroundMode:(BOOL)backgroundMode;

- (void)downloadFileForURL:(NSString *)url
          inDirectoryNamed:(NSString *)directory
             progressBlock:(void(^)(CGFloat progress))progressBlock
           completionBlock:(void(^)(BOOL completed))completionBlock
      enableBackgroundMode:(BOOL)backgroundMode;

- (void)downloadFileForURL:(NSString *)url
             progressBlock:(void(^)(CGFloat progress))progressBlock
           completionBlock:(void(^)(BOOL completed))completionBlock
      enableBackgroundMode:(BOOL)backgroundMode;
```

The easiest way to get started is by simply passing to the last of the aforementioned methods the URL string of the file that needs to be downloaded. You will get a chance to pass in two blocks that will help you keep track of the download progress (a float from 0 to 1) and of the completion of the task.

All the files, once downloaded will be moved from the `/tmp` directory of the device to the Caches directory. This is done for two reasons:
 
- the `/tmp` directory can be cleaned once in a while to make sure that any partial, cancelled or failed downloads get properly disposed of and do not occupy space both on the device and in iTunes backups;
- the Caches directory is not synced by default with the user's iCloud documents. This is in compliance with Apple's rules about content that – not being user-specific – can be re-downloaded from the internet and should not be synced with iCloud.

If a directory name is provided, a new sub-directory will be created in the Cached directory.

Once the file is finished downloading, if a name was provided by the user, it will be used to store the file in its final destination. If no name was provided the manager will use by default the last path component of the URL string (e.g. for `http://www.example.com/files/my_file.zip`, the final file name would be `my_file.zip`).

### Checking for current downloads 

To check if a file is being downloaded, you can use one of the following methods:

```objc
- (BOOL)isFileDownloadingForUrl:(NSString *)url withProgressBlock:(void(^)(CGFloat progress))block;
- (BOOL)isFileDownloadingForUrl:(NSString *)url withProgressBlock:(void(^)(CGFloat progress))block completionBlock:(void(^)(BOOL completed))completionBlock;
```

As with the previous download methods, you get a chance to be called back for progress and completion.

To retrieve a list of current files being downloaded, you can use the following:

```objc 
- (NSArray *)currentDownloads;
```

This method returns an array of `NSString` objects with the URLs of the current downloads being performed.

### Canceling downloads

The downloads, which are uniquely referenced by the download manager by the provided URL, can either be canceled singularly or all together with a single call via one of the two following methods:

```objc
- (void)cancelAllDownloads;
- (void)cancelDownloadForUrl:(NSString *)urlString;
```

### File management

TWRDownloadManager also provides some facilities to deal with downloaded files. 

You can check for existence...

```objc
- (BOOL)fileExistsForUrl:(NSString *)urlString;
- (BOOL)fileExistsForUrl:(NSString *)urlString inDirectory:(NSString *)directoryName;
- (BOOL)fileExistsWithName:(NSString *)fileName;
- (BOOL)fileExistsWithName:(NSString *)fileName inDirectory:(NSString *)directoryName;
```

...and retrieve the file location with the following ones:

```objc
- (NSString *)localPathForFile:(NSString *)fileIdentifier;
- (NSString *)localPathForFile:(NSString *)fileIdentifier inDirectory:(NSString *)directoryName;
```

### Deleting files

Downloaded files can be deleted via the following methods:

```objc
- (BOOL)deleteFileForUrl:(NSString *)urlString;
- (BOOL)deleteFileForUrl:(NSString *)urlString inDirectory:(NSString *)directoryName;
- (BOOL)deleteFileWithName:(NSString *)fileName;
- (BOOL)deleteFileWithName:(NSString *)fileName inDirectory:(NSString *)directoryName;
```

### Background Mode

To enable background downloads in iOS 7+, you should conform to the following steps:

- enable background modes in your project. Select the project in the Project Navigator in Xcode, select your target, then select the `Capabilities` tab and finally enable Background Modes:

![Enable Background modes](http://cocoahunter-blog.s3.amazonaws.com/TWRDownloadManager/bg_modes.png)

- add the following method to your AppDelegate

```objc
- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)())completionHandler{
    [TWRDownloadManager sharedManager].backgroundTransferCompletionHandler = completionHandler;   
}
```

- register for local notifications in your `application:didFinishLaunchingWithOptions:` so that you can display a message to the user when the download completes:

```objc 
if ([UIApplication instancesRespondToSelector:@selector(registerUserNotificationSettings:)]) {
        [application registerUserNotificationSettings:[UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert | UIUserNotificationTypeBadge | UIUserNotificationTypeSound categories:nil]];
}
```
## Using TWRDownloadManager with custom UITableViewCell

`TWRDownloadManager`, being able to keep track of multiple downloads at once, could be used to show a list of current downloads inside a table view. 

These are just a couple of suggestions on how it could be achieved by using `TWRDownloadManager`.

In your `UITableViewCell` subclass, import `<TWRDownloadManager/TWRDownloadObject.h>`. 

Define your progress and completion blocks as two properties:

```objc
@property (strong, nonatomic) TWRDownloadProgressBlock progressBlock;
@property (strong, nonatomic) TWRDownloadCompletionBlock completionBlock;
```

In your implementation (.m) file, define their block getters:

```objc

- (TWRDownloadProgressBlock)progressBlock {
    __weak typeof(self)weakSelf = self;
    return ^void(CGFloat progress){
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            __strong __typeof(weakSelf)strongSelf = weakSelf;
						// do something with the progress on the cell!
        });
    };
}

- (TWRDownloadCompletionBlock)completionBlock {
    __weak typeof(self)weakSelf = self;
    return ^void(BOOL completed){
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            __strong __typeof(weakSelf)strongSelf = weakSelf;
						// do something 
        });
    };
}
```

Finally, don't forget to nil out the blocks before the cell can be reused:

```objc
-(void)prepareForReuse {
    self.progressBlock = nil;
}
```

Now in your code, whenever you set up a new cell you can get the cell's own progress and completion block and pass them to the download manager. Voilà!

## Requirements

`TWRDownloadManager` requires iOS 7.x or greater.


## License

Usage is provided under the [MIT License](http://opensource.org/licenses/mit-license.php).  See LICENSE for the full details.

## Contributions

All contributions are welcome. Please fork the project to add functionalities and open a pull request to have them merged into the master branch in the next releases.
