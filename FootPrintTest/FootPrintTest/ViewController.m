//
//  ViewController.m
//  FootPrintTest
//
//  Created by 鲁强 on 2018/5/25.
//  Copyright © 2018年 鲁强. All rights reserved.
//

#import "ViewController.h"

#import <sys/sysctl.h>
#import <mach/mach.h>


@interface ViewController ()

@property (nonatomic, weak) UIScrollView *scrollView;
@property (nonatomic, weak) UILabel *label;
@property (nonatomic, strong) NSMutableString *picMemorys;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    // scroll view
    UIScrollView *scrollView = [[UIScrollView alloc] init];
    [self.view addSubview:scrollView];
    scrollView.frame = self.view.bounds;
    scrollView.backgroundColor = [UIColor whiteColor];
    self.scrollView = scrollView;
    
    // button
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(100, 100, self.view.bounds.size.width-200, 100);
    button.backgroundColor = [UIColor cyanColor];
    [button setTitle:@"click here" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(buttonClick:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
    
    // label
    UILabel *label = [[UILabel alloc] init];
    [self.view addSubview:label];
    label.frame = CGRectMake(40, 230, self.view.bounds.size.width-80, 400);
    label.numberOfLines = 0;
    label.font = [UIFont systemFontOfSize:12.f];
    label.backgroundColor = [UIColor whiteColor];
    self.label = label;
    
    [NSTimer scheduledTimerWithTimeInterval:1.f target:self selector:@selector(timerTarget) userInfo:nil repeats:YES];
    
    //
    self.picMemorys = [NSMutableString string];
}

- (void)timerTarget {
    NSMutableString *labelStr = [NSMutableString string];
    [labelStr appendFormat:@"%@\n", [self getPhysicalMemory]];
    [labelStr appendFormat:@"%@\n", [self getTaskVMInfo]];
    [labelStr appendFormat:@"%@\n", [self getTaskBasicInfo]];
    [labelStr appendFormat:@"%@\n", [self getHostInfo]];
    [labelStr appendFormat:@"%@", [self picMemorys]];
    self.label.text = [labelStr copy];
}

- (void)buttonClick:(id)sender {
    // 每次点击增1个图片
    static NSUInteger picIndex = 0;
    
    // image url
    //    NSString *picUrl = [NSString stringWithFormat:@"https://gratisography.com/pictures/%lu_1.jpg", 400+picIndex];
    NSString *picUrl = [NSString stringWithFormat:@"https://gratisography.com/fullsize/gratisography-%luH.jpg", 400+picIndex];
    UIImage *image = [self imageWithUrl:[NSURL URLWithString:picUrl]];
    [self.picMemorys appendFormat:@"%lu - %f\t", picIndex+1, image.size.width*image.size.height*4/1024.f/1024.f];
    
    // image view
    CGFloat width = CGRectGetWidth([UIScreen mainScreen].bounds);
    CGFloat height = width*0.56;
    UIImageView *imageView = [[UIImageView alloc] init];
    imageView.frame = CGRectMake(10, picIndex*height+10, width-20, height-10);
    imageView.image = image;
    [self.scrollView addSubview:imageView];
    
    // scrollview fit
    picIndex ++;
    self.scrollView.contentSize = CGSizeMake(width, height*picIndex);
}

// 1个简单的cache，方便调试
- (UIImage *)imageWithUrl:(NSURL *)url {
    NSString *cachesDir = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) firstObject];

    // get cache
    NSString *base64 = [[url.absoluteString dataUsingEncoding:NSUTF8StringEncoding] base64EncodedStringWithOptions:0];
    NSString *filePath = [NSString stringWithFormat:@"%@%@", cachesDir, base64];
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
        NSData *data = [NSData dataWithContentsOfFile:filePath];
        return [UIImage imageWithData:data];
    }
    
    // net
    NSData *data = [NSData dataWithContentsOfURL:url];
    [data writeToFile:filePath atomically:YES];
    return [UIImage imageWithData:data];
}

#pragma mark - utility
- (NSString *)getPhysicalMemory {
    return [NSString stringWithFormat:@"==========Physical Memory==========\n%fMB\n", [NSProcessInfo processInfo].physicalMemory/1024.f/1024.f];
}

- (NSString *)getTaskVMInfo {
    NSMutableString *result = [NSMutableString string];
    [result appendFormat:@"==========TASK VM INFO==========\n"];
    task_vm_info_data_t vmInfo;
    mach_msg_type_number_t count = TASK_VM_INFO_COUNT;
    kern_return_t kernReturn = task_info(mach_task_self(), TASK_VM_INFO, (task_info_t) &vmInfo, &count);
    if (kernReturn != KERN_SUCCESS)
        return [result copy];
    
    [result appendFormat:@"footprint\t:%.2lfMb\n", vmInfo.phys_footprint/1024.f/1024.f];
    [result appendFormat:@"Resident\t:%.2lfMb\n", vmInfo.resident_size/1024.f/1024.f];
    
    kernReturn = task_info(mach_task_self(), TASK_VM_INFO_PURGEABLE, (task_info_t)&vmInfo, &count);
    if (kernReturn != KERN_SUCCESS)
        return 0;
    [result appendFormat:@"anonymous\t:%.2lfMb\n", (vmInfo.internal + vmInfo.compressed - vmInfo.purgeable_volatile_pmap)/1024.f/1024.f];
    
    return [result copy];
}

- (NSString *)getTaskBasicInfo {
    NSMutableString *result = [NSMutableString string];
    [result appendFormat:@"==========TASK BASIC INFO==========\n"];
    
    task_basic_info_data_t taskInfo;
    mach_msg_type_number_t infoCount = TASK_BASIC_INFO_COUNT;
    kern_return_t kernReturn = task_info(mach_task_self(),TASK_BASIC_INFO,(task_info_t)&taskInfo,&infoCount);
    if (kernReturn != KERN_SUCCESS) {
        return [result copy];
    }
    
    [result appendFormat:@"virtual\t:%.2lfMb\n", taskInfo.virtual_size/1024.f/1024.f];
    [result appendFormat:@"Resident\t:%.2lfMb\n", taskInfo.resident_size/1024.f/1024.f];
    return [result copy];
}

-(NSString *)getHostInfo {
    int mib[6];
    mib[0] = CTL_HW;
    mib[1] = HW_PAGESIZE;
    
    int pagesize;
    size_t length;
    length = sizeof (pagesize);
    if (sysctl (mib, 2, &pagesize, &length, NULL, 0) < 0)
    {
        fprintf (stderr, "getting page size");
    }
    
    mach_msg_type_number_t count = HOST_VM_INFO_COUNT;
    
    vm_statistics_data_t vmstat;
    if (host_statistics (mach_host_self (), HOST_VM_INFO, (host_info_t) &vmstat, &count) != KERN_SUCCESS) {
        fprintf (stderr, "Failed to get VM statistics.");
    }
    task_basic_info_64_data_t info;
    unsigned size = sizeof (info);
    task_info (mach_task_self (), TASK_BASIC_INFO_64, (task_info_t) &info, &size);
    
    double unit = 1024 * 1024;
    double total = (vmstat.wire_count + vmstat.active_count + vmstat.inactive_count + vmstat.free_count) * pagesize / unit;
    double wired = vmstat.wire_count * pagesize / unit;
    double active = vmstat.active_count * pagesize / unit;
    double inactive = vmstat.inactive_count * pagesize / unit;
    double free = vmstat.free_count * pagesize / unit;
    double resident = info.resident_size / unit;
    
    NSMutableString *result = [NSMutableString string];
    [result appendFormat:@"==========HOST BASIC INFO==========\n"];
    [result appendFormat:@"Total:%.2lfMb\n", total];
    [result appendFormat:@"Wired:%.2lfMb\n", wired];
    [result appendFormat:@"Active:%.2lfMb\n", active];
    [result appendFormat:@"Inactive:%.2lfMb\n", inactive];
    [result appendFormat:@"Free:%.2lfMb\n", free];
    [result appendFormat:@"Resident:%.2lfMb\n", resident];
    return [result copy];
}

- (void)didReceiveMemoryWarning {
    NSLog(@"%@", NSStringFromSelector(_cmd));
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
