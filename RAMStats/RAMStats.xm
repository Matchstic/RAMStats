#import <mach/mach.h>
#import <mach/mach_host.h>
#import <UIKit/UIKit.h>
#import <SpringBoard/SpringBoard.h>
#import <SpringBoard/SBAwayController.h>

// Yep, this is pretty much my BatteryStats with a few modifications ;)

#define settingsFile @"/var/mobile/Library/Preferences/RAMStats-prefs.plist"

static NSTimer *timer;

@interface SpringBoard (RAMStats)

-(void)ramChanged;

@end

%hook SpringBoard

// Breakage point with iOS releases, good for iOS 5.0+, not for 4.3.x - 7.0 works!
-(void)_performDeferredLaunchWork {
    %orig;
    
    // Check if prefs exists
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:settingsFile];
    if (!fileExists) {
        NSMutableDictionary *data = [[NSMutableDictionary alloc] init];
        
        [data setObject:[NSNumber numberWithFloat:30] forKey:@"refreshRate"];
        
        [data writeToFile:settingsFile atomically:YES];
        [data release];
    }

    NSDictionary *settings = [[[NSDictionary alloc] initWithContentsOfFile:settingsFile] autorelease];
    double interval = [[settings objectForKey:@"refreshRate"] doubleValue];
    
    // potential breakage point?
    timer = [NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(ramChanged) userInfo:nil repeats:YES];
}

%new 
- (void)ramChanged {
        mach_port_t host_port;
    mach_msg_type_number_t host_size;
    vm_size_t pagesize;

    host_port = mach_host_self();
    host_size = sizeof(vm_statistics_data_t) / sizeof(integer_t);
    host_page_size(host_port, &pagesize);        

    vm_statistics_data_t vm_stat;

    if (host_statistics(host_port, HOST_VM_INFO, (host_info_t)&vm_stat, &host_size) != KERN_SUCCESS)
        NSLog(@"Failed to fetch vm statistics");

    /* Stats in bytes */ 
    natural_t mem_used = (vm_stat.active_count +
                          vm_stat.inactive_count +
                          vm_stat.wire_count) * pagesize;
    natural_t mem_free = vm_stat.free_count * pagesize;
    natural_t mem_total = mem_used + mem_free;
    
    // https://github.com/nst/RuntimeBrowser/blob/master/iOS/Classes/InfoVC.m
    float giga = (float)(1024 * 1024);
    NSString *used = [NSString stringWithFormat:@"%.2f", mem_used / giga ];
    NSString *free = [NSString stringWithFormat:@"%.2f", mem_free / giga];
    NSString *total = [NSString stringWithFormat:@"%.2f", mem_total / giga];
    
    // Write to txt file
    // We should load the contents of the file into an array, edit as appropriate, then write the resulting strings to the file.
    NSError *error;
    NSString *filePath = @"/var/mobile/Library/RAMStats.txt";
    
    /*NSMutableArray *lines = [[NSString stringWithContentsOfFile:filePath
                                                       encoding:NSUTF8StringEncoding
                                                          error:nil]
                             componentsSeparatedByString:@"\n"];*/
    
    NSString *fileString = [NSString stringWithContentsOfFile:filePath
                                                     encoding:NSUTF8StringEncoding
                                                        error:nil];
    
    NSMutableArray *lines = [NSMutableArray arrayWithArray:[fileString componentsSeparatedByString:@"\n"]];
    
    // Free
    [lines removeObjectAtIndex:1];
    [lines insertObject:[@"Free: %@" stringByAppendingString:free] atIndex:1];
    
    // Used
    [lines removeObjectAtIndex:2];
    [lines insertObject:[@"Used: %@" stringByAppendingString:used] atIndex:2];
    
    // Total
    [lines removeObjectAtIndex:3];
    [lines insertObject:[@"Total: %@" stringByAppendingString:total] atIndex:3];
    
    NSString *write = [lines componentsJoinedByString:@"\n"];
    
    [write writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
    
    // Done!
}

%end

%hook SBAwayController

// Works on 7.0, 6.0+ :)
-(void)undimScreen:(BOOL)arg1 {
    %orig;
    
    // Let's set our new levels/states when coming out of sleep!
    [(SpringBoard*)[UIApplication sharedApplication] ramChanged];
}

// iOS 5.0+ compatibilty
-(void)undimScreen {
    %orig;
    
    // Let's set our new levels/states when coming out of sleep!
    [(SpringBoard*)[UIApplication sharedApplication] ramChanged];
}

%end
