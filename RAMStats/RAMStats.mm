#line 1 "/Users/Matt/iOS/Projects/RAMStats/RAMStats/RAMStats.xm"
#import <mach/mach.h>
#import <mach/mach_host.h>
#import <UIKit/UIKit.h>
#import <SpringBoard/SpringBoard.h>
#import <SpringBoard/SBAwayController.h>



#define settingsFile @"/var/mobile/Library/Preferences/RAMStats-prefs.plist"

static NSTimer *timer;

@interface SpringBoard (RAMStats)

-(void)ramChanged;

@end

#include <logos/logos.h>
#include <substrate.h>
@class SBAwayController; @class SpringBoard; 
static void (*_logos_orig$_ungrouped$SpringBoard$_performDeferredLaunchWork)(SpringBoard*, SEL); static void _logos_method$_ungrouped$SpringBoard$_performDeferredLaunchWork(SpringBoard*, SEL); static void _logos_method$_ungrouped$SpringBoard$ramChanged(SpringBoard*, SEL); static void (*_logos_orig$_ungrouped$SBAwayController$undimScreen$)(SBAwayController*, SEL, BOOL); static void _logos_method$_ungrouped$SBAwayController$undimScreen$(SBAwayController*, SEL, BOOL); static void (*_logos_orig$_ungrouped$SBAwayController$undimScreen)(SBAwayController*, SEL); static void _logos_method$_ungrouped$SBAwayController$undimScreen(SBAwayController*, SEL); 

#line 19 "/Users/Matt/iOS/Projects/RAMStats/RAMStats/RAMStats.xm"



static void _logos_method$_ungrouped$SpringBoard$_performDeferredLaunchWork(SpringBoard* self, SEL _cmd) {
    _logos_orig$_ungrouped$SpringBoard$_performDeferredLaunchWork(self, _cmd);
    
    
    BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:settingsFile];
    if (!fileExists) {
        NSMutableDictionary *data = [[NSMutableDictionary alloc] init];
        
        [data setObject:[NSNumber numberWithFloat:30] forKey:@"refreshRate"];
        
        [data writeToFile:settingsFile atomically:YES];
        [data release];
    }

    NSDictionary *settings = [[[NSDictionary alloc] initWithContentsOfFile:settingsFile] autorelease];
    double interval = [[settings objectForKey:@"refreshRate"] doubleValue];
    
    
    timer = [NSTimer scheduledTimerWithTimeInterval:interval target:self selector:@selector(ramChanged) userInfo:nil repeats:YES];
}

 
static void _logos_method$_ungrouped$SpringBoard$ramChanged(SpringBoard* self, SEL _cmd) {
        mach_port_t host_port;
    mach_msg_type_number_t host_size;
    vm_size_t pagesize;

    host_port = mach_host_self();
    host_size = sizeof(vm_statistics_data_t) / sizeof(integer_t);
    host_page_size(host_port, &pagesize);        

    vm_statistics_data_t vm_stat;

    if (host_statistics(host_port, HOST_VM_INFO, (host_info_t)&vm_stat, &host_size) != KERN_SUCCESS)
        NSLog(@"Failed to fetch vm statistics");

     
    natural_t mem_used = (vm_stat.active_count +
                          vm_stat.inactive_count +
                          vm_stat.wire_count) * pagesize;
    natural_t mem_free = vm_stat.free_count * pagesize;
    natural_t mem_total = mem_used + mem_free;
    
    
    float giga = (float)(1024 * 1024);
    NSString *used = [NSString stringWithFormat:@"%.2f", mem_used / giga ];
    NSString *free = [NSString stringWithFormat:@"%.2f", mem_free / giga];
    NSString *total = [NSString stringWithFormat:@"%.2f", mem_total / giga];
    
    
    
    NSError *error;
    NSString *filePath = @"/var/mobile/Library/RAMStats.txt";
    
    



    
    NSString *fileString = [NSString stringWithContentsOfFile:filePath
                                                     encoding:NSUTF8StringEncoding
                                                        error:nil];
    
    NSMutableArray *lines = [NSMutableArray arrayWithArray:[fileString componentsSeparatedByString:@"\n"]];
    
    
    [lines removeObjectAtIndex:1];
    [lines insertObject:[@"Free: %@" stringByAppendingString:free] atIndex:1];
    
    
    [lines removeObjectAtIndex:2];
    [lines insertObject:[@"Used: %@" stringByAppendingString:used] atIndex:2];
    
    
    [lines removeObjectAtIndex:3];
    [lines insertObject:[@"Total: %@" stringByAppendingString:total] atIndex:3];
    
    NSString *write = [lines componentsJoinedByString:@"\n"];
    
    [write writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:&error];
    
    
}






static void _logos_method$_ungrouped$SBAwayController$undimScreen$(SBAwayController* self, SEL _cmd, BOOL arg1) {
    _logos_orig$_ungrouped$SBAwayController$undimScreen$(self, _cmd, arg1);
    
    
    [(SpringBoard*)[UIApplication sharedApplication] ramChanged];
}


static void _logos_method$_ungrouped$SBAwayController$undimScreen(SBAwayController* self, SEL _cmd) {
    _logos_orig$_ungrouped$SBAwayController$undimScreen(self, _cmd);
    
    
    [(SpringBoard*)[UIApplication sharedApplication] ramChanged];
}


static __attribute__((constructor)) void _logosLocalInit() {
{Class _logos_class$_ungrouped$SpringBoard = objc_getClass("SpringBoard"); MSHookMessageEx(_logos_class$_ungrouped$SpringBoard, @selector(_performDeferredLaunchWork), (IMP)&_logos_method$_ungrouped$SpringBoard$_performDeferredLaunchWork, (IMP*)&_logos_orig$_ungrouped$SpringBoard$_performDeferredLaunchWork);{ char _typeEncoding[1024]; unsigned int i = 0; _typeEncoding[i] = 'v'; i += 1; _typeEncoding[i] = '@'; i += 1; _typeEncoding[i] = ':'; i += 1; _typeEncoding[i] = '\0'; class_addMethod(_logos_class$_ungrouped$SpringBoard, @selector(ramChanged), (IMP)&_logos_method$_ungrouped$SpringBoard$ramChanged, _typeEncoding); }Class _logos_class$_ungrouped$SBAwayController = objc_getClass("SBAwayController"); MSHookMessageEx(_logos_class$_ungrouped$SBAwayController, @selector(undimScreen:), (IMP)&_logos_method$_ungrouped$SBAwayController$undimScreen$, (IMP*)&_logos_orig$_ungrouped$SBAwayController$undimScreen$);MSHookMessageEx(_logos_class$_ungrouped$SBAwayController, @selector(undimScreen), (IMP)&_logos_method$_ungrouped$SBAwayController$undimScreen, (IMP*)&_logos_orig$_ungrouped$SBAwayController$undimScreen);} }
#line 127 "/Users/Matt/iOS/Projects/RAMStats/RAMStats/RAMStats.xm"
