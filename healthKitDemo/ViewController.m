//
//  ViewController.m
//  healthKitDemo
//
//  Created by 刘东 on 16/8/31.
//  Copyright © 2016年 刘东. All rights reserved.
//

#import "ViewController.h"
#import <HealthKit/HealthKit.h>
@interface ViewController ()
@property (nonatomic, strong) HKHealthStore *healthStore;
@property (nonatomic, strong)  UILabel *stepsLabel;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.stepsLabel = [[UILabel alloc]initWithFrame:CGRectMake(50, 180,[UIScreen mainScreen].bounds.size.width-100, 50)];
    self.stepsLabel.textAlignment = 1;
    [self.view addSubview:self.stepsLabel];
    
    //查看healthKit在设备上是否可用，ipad不支持HealthKit
    if(![HKHealthStore isHealthDataAvailable])
    {
        NSLog(@"设备不支持healthKit");
    }
    
    //创建healthStore实例对象
    self.healthStore = [[HKHealthStore alloc] init];
    
    //设置需要获取的权限这里仅设置了步数
    HKObjectType *stepCount = [HKObjectType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
    NSSet *healthSet = [NSSet setWithObjects:stepCount, nil];
    
    /**
     要想获取健康数据中的步数，则需要通过用户许可才行。
     使用 requestAuthorizationToShareTypes: readTypes: completion:方法可以进行授权
     
     1、第一个参数传入一个NSSet类型数据，用于告知用户，我的app可能会在你的健康数据库中修改这些选项数据(显然目前我们不需要，传nil)
     2、第二个参数也是传入NSSet类型数据，告知用户，我的app可能会从你的数据库中读取以下几项数据
     3、第三个是授权许可回调，BOOL值success用于区分用户是否允许应用向数据库存取数据
     */
    
    [self.healthStore requestAuthorizationToShareTypes:nil readTypes:healthSet completion:^(BOOL success, NSError * _Nullable error) {
        if (success)
        {
            NSLog(@"获取步数权限成功");
            //获取步数后我们调用获取步数的方法
            [self readHealthStep];
            
        }else{
            
            NSLog(@"获取步数权限失败");
            
        }
    }];
    
}

-(void)readHealthStep{
    __weak ViewController *weakSelf = self;

    //查询采样信息样品类的实例，需要获取的数据是步数
    HKSampleType *sampleType = [HKQuantityType quantityTypeForIdentifier:HKQuantityTypeIdentifierStepCount];
    
    //NSSortDescriptors用来告诉healthStore怎么样将结果排序。
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:HKSampleSortIdentifierStartDate ascending:YES];
    
    //查询时间
    NSDateFormatter *formatter = [[NSDateFormatter alloc ]init];
    [formatter setDateFormat:@"yyyy-MM-dd"];
    NSDate *now = [NSDate date];
    NSString *todaystr = [formatter stringFromDate:now];
    NSDate *today = [formatter dateFromString:todaystr];
    NSDate *next = [today dateByAddingTimeInterval:24*60*60];
    
    //谓词查询条件,今天的步数
    NSPredicate *predicate = [HKQuery predicateForSamplesWithStartDate:today endDate:next options:HKQueryOptionStrictStartDate];
    
    //查询的基类是HKQuery，这是一个抽象类，能够实现每一种查询目标，这里我们需要查询的步数是一个HKSample类所以对应的查询类就是HKSampleQuery。
    HKSampleQuery *sampleQuery = [[HKSampleQuery alloc] initWithSampleType:sampleType predicate:predicate limit:HKObjectQueryNoLimit sortDescriptors:@[sortDescriptor] resultsHandler:^(HKSampleQuery * _Nonnull query, NSArray<__kindof HKSample *> * _Nullable results, NSError * _Nullable error) {
        
        //设置一个int型变量来作为步数统计
        int allStepCount = 0;
        for (int i = 0; i < results.count; i ++) {
            //把结果转换为字符串类型
            HKQuantitySample *result = results[i];
            HKQuantity *quantity = result.quantity;
            NSMutableString *stepCount = (NSMutableString *)quantity;
            NSString *stepStr =[NSString stringWithFormat:@"%@",stepCount];
            //获取 count此类字符串前面的数字
            NSString *str = [stepStr componentsSeparatedByString:@" "][0];
            int stepNum = [str intValue];
            //NSLog(@"%d",stepNum);
            //把一天中所有时间段中的步数加到一起
            allStepCount = allStepCount + stepNum;
        }
        
        //主线程刷新UI
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"今日步数：%d",allStepCount);
            weakSelf.stepsLabel.text = [NSString stringWithFormat:@"今日步数: %d",allStepCount];
        });
        
    }];
    //执行查询
    [self.healthStore executeQuery:sampleQuery];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
