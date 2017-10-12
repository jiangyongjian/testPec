//
//  FBHomeViewController.m
//  FBFlashbikeTest
//
//  Created by JYJ on 2017/6/21.
//  Copyright © 2017年 baobeikeji. All rights reserved.
//

#import "FBHomeViewController.h"
#import "FBScanQRCodeViewController.h"
#import "FBMapViewController.h"
#import "FBCommenItem.h"
#import "FBHomeInfoCell.h"
#import <MJExtension.h>
#import "FBTotalData.h"
#import "FBBikeData.h"
#import "FBDeviceData.h"
#import <AMapSearchKit/AMapSearchAPI.h>
#import "ErrorInfoUtility.h"
#import "FBButton.h"

#import "AQBluetoothTools.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import "AFNetworking.h"
#import "NSString+MD5.h"

@interface FBHomeViewController () <UITableViewDelegate, UITableViewDataSource, AMapSearchDelegate, AQBluetoothToolsDelegate, AQBluetoothDeviceDelegate, CBCentralManagerDelegate>

@property (nonatomic, strong) AMapSearchAPI *search;

@property (nonatomic,strong)AQBluetoothTools *tools;

/** 中心管家 */
@property (nonatomic, strong) CBCentralManager *mgr;

/** device */
@property (nonatomic, strong) AQBluetoothDevice *device;

/** textField */
@property (nonatomic, weak) UITextField *textField;
/** searchBtn */
@property (nonatomic, weak) UIButton *searchBtn;
/** bluetoothBtn */
@property (nonatomic, weak) UIButton *bluetoothBtn;
/** openCarBtn */
@property (nonatomic, weak) UIButton *openCarBtn;
/** openBatteryBtn */
@property (nonatomic, weak) UIButton *openBatteryBtn;

@property (weak, nonatomic) UILabel *stateLabel;
/** UIDLabel */
@property (nonatomic, weak) UILabel *UIDLabel;
/** refreshBtn */
@property (nonatomic, weak) UIButton *refreshBtn;

/** tableView */
@property (nonatomic, weak) UITableView *tableView;
/** groupData */
@property (nonatomic, strong) NSArray *groupData;
/** bikeDatas */
@property (nonatomic, strong) NSArray *bikeDatas;
/** deviceDatas */
@property (nonatomic, strong) NSArray *deviceDatas;
/** totalDate */
@property (nonatomic, strong) FBTotalData *totalDate;
/** coordinate */
@property (nonatomic, assign) CLLocationCoordinate2D coordinate;
/** requestManager */
@property (nonatomic, strong) AFHTTPSessionManager *requestManager;
/** hasBuleth */
@property (nonatomic, assign) BOOL hasBuleth;
@end

@implementation FBHomeViewController

- (AFHTTPSessionManager *)requestManager {
    if (!_requestManager) {
        self.requestManager = [AFHTTPSessionManager manager];
        self.requestManager.requestSerializer = [AFHTTPRequestSerializer serializer];
        self.requestManager.responseSerializer = [AFHTTPResponseSerializer serializer];
        
        // 不限制类型
        self.requestManager.responseSerializer.acceptableContentTypes = nil;
        self.requestManager.responseSerializer.acceptableStatusCodes = nil;
    }
    return _requestManager;
}




- (NSArray *)groupData {
    if (!_groupData) {
        self.groupData = [NSArray array];
    }
    return _groupData;
}

- (NSArray *)bikeDatas {
    if (!_bikeDatas) {
        self.bikeDatas = [NSArray array];
    }
    return _bikeDatas;
}

- (NSArray *)deviceDatas {
    if (!_deviceDatas) {
        self.deviceDatas = [NSArray array];
    }
    return _deviceDatas;
}

- (AMapSearchAPI *)search {
    if (!_search) {
        self.search = [[AMapSearchAPI alloc] init];
        self.search.delegate = self;
    }
    return _search;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"首页";
    [self setupUI];
    [self setupData];
    
    NSDictionary *options = @{CBCentralManagerOptionShowPowerAlertKey:@NO};
    self.mgr = [[CBCentralManager alloc] initWithDelegate:self queue:nil options:options];
}

- (void)setupUI {
    UIView *bgView = [[UIView alloc] init];
    bgView.frame = CGRectMake(15, 10, FBScreenW - 30, 44);
    bgView.backgroundColor = [UIColor colorWithHexString:@"E9E9E9"];
    [self.view addSubview:bgView];
    
    UITextField *textField = [[UITextField alloc] init];
    textField.y = 0;
    textField.height = bgView.height;
    textField.x = 5;
    textField.width = bgView.width - 44 - 10;
    textField.font = [UIFont fontWithTwoLine:14];
    textField.keyboardType = UIKeyboardTypeNumberPad;
    textField.clearButtonMode = UITextFieldViewModeWhileEditing;
    textField.placeholder = @"请输入单车编号";
    [bgView addSubview:textField];
    self.textField = textField;
    
    UIButton *scanCodeButton = [UIButton buttonWithTitle:@"" titleColor:nil font:nil imageName:@"button_feedbackQuestion_scan_nor" target:self action:@selector(scanCodeButtonClick)];
    scanCodeButton.frame = CGRectMake(bgView.width - 44, 0, 44, 44);
    [bgView addSubview:scanCodeButton];
    
    // 4个按钮
    /** searchBtn */
    FBButton *searchBtn = [[FBButton alloc] init];
    [searchBtn setTitle:@"蓝牙关\r\n车" forState:UIControlStateNormal];
    searchBtn.titleLabel.font = [UIFont systemFontOfSize:14];
    searchBtn.titleLabel.numberOfLines = 0;
    [searchBtn setTitleColor:[UIColor colorWithHexString:@"333333"] forState:UIControlStateNormal];
    [searchBtn addTarget:self action:@selector(searchBtnClick) forControlEvents:UIControlEventTouchUpInside];
    [searchBtn setTitle:@"蓝牙开\r\n车" forState:UIControlStateSelected];
    [searchBtn setBackgroundImage:[UIImage createImageWithColor:[UIColor colorWithHexString:@"E9E9E9"]] forState:UIControlStateSelected];
    [searchBtn setBackgroundImage:[UIImage createImageWithColor:[UIColor redColor]] forState:UIControlStateNormal];
    searchBtn.adjustsImageWhenHighlighted = NO;
    [searchBtn setTitleColor:FBMainRedColor forState:UIControlStateSelected];
    //    UIButton *searchBtn = [UIButton buttonWithTitle:@"查找蓝牙" titleColor:[UIColor colorWithHexString:@"333333"] font:[UIFont fontWithTwoLine:14] target:self action:@selector(searchBtnClick)];
    [searchBtn setTitleColor:FBMainRedColor forState:UIControlStateSelected];
    searchBtn.backgroundColor = [UIColor colorWithHexString:@"E9E9E9"];
    CGFloat butW = (FBScreenW - 15 * 2 - 10 * 3) / 4;
    CGFloat butY = CGRectGetMaxY(bgView.frame) + 15;
    CGFloat butH = 60;
    searchBtn.frame = CGRectMake(15, butY, butW, butH);
    [self.view addSubview:searchBtn];
    self.searchBtn = searchBtn;
    //
    //    UIButton *bluetoothBtn = [UIButton buttonWithTitle:@"蓝牙开关\r\n电池锁" titleColor:[UIColor colorWithHexString:@"333333"] font:[UIFont fontWithTwoLine:14] target:self action:@selector(bluetoothBtnClick)];
    //    bluetoothBtn.titleLabel.numberOfLines = 0;
    //    [bluetoothBtn setTitleColor:FBMainRedColor forState:UIControlStateSelected];
    //    bluetoothBtn.backgroundColor = [UIColor colorWithHexString:@"E9E9E9"];
    
    FBButton *bluetoothBtn = [[FBButton alloc] init];
    [bluetoothBtn setTitle:@"蓝牙关\r\n电池锁" forState:UIControlStateNormal];
    bluetoothBtn.titleLabel.font = [UIFont systemFontOfSize:14];
    bluetoothBtn.titleLabel.numberOfLines = 0;
    [bluetoothBtn setTitleColor:[UIColor colorWithHexString:@"333333"] forState:UIControlStateNormal];
    [bluetoothBtn addTarget:self action:@selector(bluetoothBtnClick) forControlEvents:UIControlEventTouchUpInside];
    [bluetoothBtn setTitle:@"蓝牙开\r\n电池锁" forState:UIControlStateSelected];
    [bluetoothBtn setBackgroundImage:[UIImage createImageWithColor:[UIColor colorWithHexString:@"E9E9E9"]] forState:UIControlStateSelected];
    [bluetoothBtn setBackgroundImage:[UIImage createImageWithColor:[UIColor redColor]] forState:UIControlStateNormal];
    bluetoothBtn.adjustsImageWhenHighlighted = NO;
    [bluetoothBtn setTitleColor:FBMainRedColor forState:UIControlStateSelected];
    bluetoothBtn.frame = CGRectMake(15 + (butW + 10), butY, butW, butH);
    [self.view addSubview:bluetoothBtn];
    self.bluetoothBtn = bluetoothBtn;
    
    FBButton *openCarBtn = [[FBButton alloc] init];
    [openCarBtn setTitle:@"车未锁" forState:UIControlStateNormal];
    openCarBtn.titleLabel.font = [UIFont systemFontOfSize:14];
    [openCarBtn setTitleColor:[UIColor colorWithHexString:@"333333"] forState:UIControlStateNormal];
    [openCarBtn addTarget:self action:@selector(openCarBtnClick) forControlEvents:UIControlEventTouchUpInside];
    //    [FBButton buttonWithTitle:@"车未锁" titleColor:[UIColor colorWithHexString:@"333333"] font:[UIFont fontWithTwoLine:14] target:self action:@selector(openCarBtnClick)];
    //    openCarBtn.backgroundColor = [UIColor colorWithHexString:@"E9E9E9"];
    [openCarBtn setTitle:@"车已锁" forState:UIControlStateSelected];
    [openCarBtn setBackgroundImage:[UIImage createImageWithColor:[UIColor colorWithHexString:@"E9E9E9"]] forState:UIControlStateSelected];
    [openCarBtn setBackgroundImage:[UIImage createImageWithColor:[UIColor redColor]] forState:UIControlStateNormal];
    openCarBtn.adjustsImageWhenHighlighted = NO;
    [openCarBtn setTitleColor:FBMainRedColor forState:UIControlStateSelected];
    openCarBtn.frame = CGRectMake(15 + (butW + 10) * 2, butY, butW, butH);
    [self.view addSubview:openCarBtn];
    self.openCarBtn = openCarBtn;
    
    FBButton *openBatteryBtn = [[FBButton alloc] init];
    [openBatteryBtn setTitle:@"电池未锁" forState:UIControlStateNormal];
    openBatteryBtn.titleLabel.font = [UIFont systemFontOfSize:14];
    [openBatteryBtn setTitleColor:[UIColor colorWithHexString:@"333333"] forState:UIControlStateNormal];
    [openBatteryBtn addTarget:self action:@selector(openBatteryBtnClick) forControlEvents:UIControlEventTouchUpInside];
    //    [FBButton buttonWithTitle:@"电池未锁" titleColor:[UIColor colorWithHexString:@"333333"] font:[UIFont fontWithTwoLine:14] target:self action:@selector(openBatteryBtnClick)];
    [openBatteryBtn setTitle:@"电池已锁" forState:UIControlStateSelected];
    [openBatteryBtn setBackgroundImage:[UIImage createImageWithColor:[UIColor colorWithHexString:@"E9E9E9"]] forState:UIControlStateSelected];
    openBatteryBtn.adjustsImageWhenHighlighted = NO;
    [openBatteryBtn setBackgroundImage:[UIImage createImageWithColor:[UIColor redColor]] forState:UIControlStateNormal];
    [openBatteryBtn setTitleColor:FBMainRedColor forState:UIControlStateSelected];
    openBatteryBtn.frame = CGRectMake(15 + (butW + 10) * 3, butY, butW, butH);
    [self.view addSubview:openBatteryBtn];
    self.openBatteryBtn = openBatteryBtn;
    
    UILabel *stateLabel = [UILabel labelWithTitle:@"蓝牙状态:" color:[UIColor colorWithHexString:@"666666"] font:[UIFont fontWithTwoLine:14]];
    stateLabel.frame = CGRectMake(15, CGRectGetMaxY(openBatteryBtn.frame) + 15, FBScreenW - 30, 44);
    [self.view addSubview:stateLabel];
    self.stateLabel = stateLabel;
    
    UIButton *refreshBtn = [UIButton buttonWithTitle:@"刷新" titleColor:[UIColor whiteColor] font:[UIFont fontWithTwoLine:15] target:self action:@selector(refreshBtnClick)];
    refreshBtn.backgroundColor = FBMainRedColor;
    refreshBtn.frame = CGRectMake(FBScreenW - 15 - 50, CGRectGetMaxY(stateLabel.frame) + 15, 50, 44);
    [self.view addSubview:refreshBtn];
    self.refreshBtn = refreshBtn;
    
    
    /** UIDLabel */
    UILabel *UIDLabel = [UILabel labelWithTitle:@"UID:" color:[UIColor colorWithHexString:@"666666"] font:[UIFont fontWithTwoLine:14]];
    UIDLabel.textAlignment = NSTextAlignmentLeft;
    UIDLabel.frame = CGRectMake(15, refreshBtn.y, refreshBtn.x - 15, refreshBtn.height);
    [self.view addSubview:UIDLabel];
    self.UIDLabel = UIDLabel;
    
    //    UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.UIDLabel.frame) + 15, FBScreenW, FBScreenH - CGRectGetMaxY(self.UIDLabel.frame) - 15 - FBNavigationBarH) style:UITableViewStyleGrouped];
    UITableView *tableView = [[UITableView alloc] init];
    tableView.frame = CGRectMake(0, CGRectGetMaxY(self.UIDLabel.frame) + 15, FBScreenW, FBScreenH - CGRectGetMaxY(self.UIDLabel.frame) - 15 - FBNavigationBarH);
    tableView.delegate = self;
    tableView.dataSource = self;
    //    tableView.separatorStyle = UITableViewCellSelectionStyleNone;
    tableView.showsVerticalScrollIndicator = NO;
    tableView.backgroundColor = FBGlobalBg;
    tableView.contentInset = UIEdgeInsetsMake(0, 0, 10, 0);
    [self.view addSubview:tableView];
    self.tableView = tableView;
}

- (void)setupData {
    [self setupBtnStatus];
    [self setupGroup1];
    [self setupGroup2];
    [self.tableView reloadData];
    
}

//- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
//    [self httpGet];
//}

- (void)setupGroup1 {
    FBDeviceData *deviceData = self.totalDate.deviceData;
    self.UIDLabel.text = [NSString stringWithFormat:@"UID:%@", deviceData.udid];
    FBCommenItem *online = [FBCommenItem itemWithTitle:@"是否在线：" subtitle:deviceData.onlineStr];
    /** 1角度 */
    FBCommenItem *course = [FBCommenItem itemWithTitle:@"角度：" subtitle:[NSString stringWithFormat:@"%.02f", deviceData.course]];
    /** 2当前速度(米 / 时) speed */
    FBCommenItem *speed = [FBCommenItem itemWithTitle:@"当前速度(米/时)：" subtitle:[NSString stringWithFormat:@"%zd", deviceData.speed]];
    /** 3GPS信号强度(分档:0-10) */
    FBCommenItem *gps_signal = [FBCommenItem itemWithTitle:@"GPS信号强度(分档:0-10)：" subtitle:[NSString stringWithFormat:@"%zd", deviceData.gps_signal]];
    /** 4GSM 经度(有 GPS 经度，则不需要存) */
    FBCommenItem *gsm_latlng = [FBCommenItem itemWithTitle:@"GSM经纬度：" subtitle:[NSString stringWithFormat:@"经度:%f\r\n纬度:%f", deviceData.gsm_lat, deviceData.gsm_lng]];
    //    /** 5GSM 纬度(有 GPS 维度，则不需要存 */
    //    FBCommenItem *gsm_lng = [FBCommenItem itemWithTitle:@"GSM度：" subtitle:[NSString stringWithFormat:@"%f", deviceData.gsm_lng]];
    /** 6GPS 经度 */
    FBCommenItem *latlng = [FBCommenItem itemWithTitle:@"GPS经纬度：" subtitle:[NSString stringWithFormat:@"经度:%f\r\n纬度:%f", deviceData.lat, deviceData.lng]];
    //    /** 7GPS 纬度 */
    //    FBCommenItem *lng = [FBCommenItem itemWithTitle:@"GPS纬度：" subtitle:[NSString stringWithFormat:@"%f", deviceData.lng]];
    /** 当前位置 */
    FBCommenItem *address = [FBCommenItem itemWithTitle:@"当前位置：" subtitle:deviceData.address];
    /** 8GSM 信号强度(分档:0-10) */
    FBCommenItem *gsm_signal = [FBCommenItem itemWithTitle:@"GSM信号强度(分档:0-10)：" subtitle:[NSString stringWithFormat:@"%zd", deviceData.gsm_signal]];
    /** 9时间戳(秒级) */
    FBCommenItem *createTime = [FBCommenItem itemWithTitle:@"时间戳(秒级)：" subtitle:deviceData.createTime];
    self.deviceDatas = @[online, createTime, gsm_latlng, latlng, address, speed, course, gps_signal, gsm_signal];
    
}

- (void)setupGroup2 {
    FBBikeData *bikeData = self.totalDate.bikeData;
    
    FBCommenItem *online = [FBCommenItem itemWithTitle:@"是否在线：" subtitle:bikeData.onlineStr];
    /** 1车辆振动(0:正常;1:振动或倾倒) vibrate */
    //    FBCommenItem *vibrate = [FBCommenItem itemWithTitle:@"车辆振动(0:正常;1:振动或倾倒)：" subtitle:[NSString stringWithFormat:@"%zd", bikeData.vibrate]];
    FBCommenItem *vibrate = [FBCommenItem itemWithTitle:@"车辆振动(0:正常;1:振动或倾倒)：" subtitle:bikeData.vibrateStr];
    
    /** 2当前速度 speed */
    FBCommenItem *speed = [FBCommenItem itemWithTitle:@"当前速度：" subtitle:[NSString stringWithFormat:@"%zd", bikeData.speed]];
    /** 3实时总里程（米） mileage */
    FBCommenItem *mileage = [FBCommenItem itemWithTitle:@"实时总里程：" subtitle:[NSString stringWithFormat:@"%zd", bikeData.mileage]];
    /** 4档位(1-4 档) */
    FBCommenItem *gear = [FBCommenItem itemWithTitle:@"档位(1-4 档)：" subtitle:[NSString stringWithFormat:@"%zd", bikeData.gear]];
    /** 5主电池电压(*10mV) */
    FBCommenItem *voltage = [FBCommenItem itemWithTitle:@"主电池电压(*10mV)：" subtitle:[NSString stringWithFormat:@"%zd", bikeData.voltage]];
    /** 6副电池电量百分 */
    FBCommenItem *subbt_percent = [FBCommenItem itemWithTitle:@"副电池电量百分：" subtitle:[NSString stringWithFormat:@"%zd", bikeData.subbt_percent]];
    /** 7电池锁状态(0:未锁;1:已锁) */
    //    FBCommenItem *bt_lock = [FBCommenItem itemWithTitle:@"电池锁状态(0:未锁;1:已锁)：" subtitle:[NSString stringWithFormat:@"%zd", bikeData.bt_lock]];
    FBCommenItem *bt_lock = [FBCommenItem itemWithTitle:@"电池锁状态：" subtitle:bikeData.bt_lockStr];
    /** 8状态发生时间戳(秒级) */
    FBCommenItem *createTime = [FBCommenItem itemWithTitle:@"时间戳(秒级)：" subtitle:bikeData.createTime];
    /** 9电门状态(0:关闭;1:打开)，电 为 0 时，以下数据 都 效 */
    //    FBCommenItem *ev_key = [FBCommenItem itemWithTitle:@"电门状态(0:关闭;1:打开)：" subtitle:[NSString stringWithFormat:@"%zd", bikeData.ev_key]];
    FBCommenItem *ev_key = [FBCommenItem itemWithTitle:@"电门状态(0:关闭;1:打开)：" subtitle:bikeData.ev_keyStr];
    /** 10锁车状态(0:未锁;1:已锁) */
    //    FBCommenItem *ev_lock = [FBCommenItem itemWithTitle:@"锁车状态(0:未锁;1:已锁)：" subtitle:[NSString stringWithFormat:@"%zd", bikeData.ev_lock]];
    FBCommenItem *ev_lock = [FBCommenItem itemWithTitle:@"锁车状态(0:未锁;1:已锁)：" subtitle:bikeData.ev_lockStr];
    
    /** 当前电量百分  */
    FBCommenItem *percent = [FBCommenItem itemWithTitle:@"当前电量百分：" subtitle:[NSString stringWithFormat:@"%zd", bikeData.percent]];
    /** 电机转动(0:静 ;1:有转动) */
    //    FBCommenItem *move = [FBCommenItem itemWithTitle:@"电机转动(0:静止;1:有转动)：" subtitle:[NSString stringWithFormat:@"%zd", bikeData.move]];
    FBCommenItem *move = [FBCommenItem itemWithTitle:@"电机转动(0:静止;1:有转动)：" subtitle:bikeData.moveStr];
    FBLog(@"%zd - - %@", bikeData.fault, bikeData.faultStr);
    
    
    [bikeData getAllStatus];
    /** 手把异常 */
    FBCommenItem *handlebar = [FBCommenItem itemWithTitle:@"手把异常：" subtitle:bikeData.handlebar];
    /** MOS管故障 */
    FBCommenItem *famos = [FBCommenItem itemWithTitle:@"MOS管故障：" subtitle:bikeData.famos];
    /** 短路故障（硬件过流） */
    FBCommenItem *shortCir = [FBCommenItem itemWithTitle:@"短路故障（硬件过流）：" subtitle:bikeData.shortCir];
    /** 过压 */
    FBCommenItem *overvoltage = [FBCommenItem itemWithTitle:@"MOS管故障：" subtitle:bikeData.overvoltage];
    /** 欠压 */
    FBCommenItem *undervoltage = [FBCommenItem itemWithTitle:@"欠压：" subtitle:bikeData.undervoltage];
    /** 刹车故障 */
    FBCommenItem *brake = [FBCommenItem itemWithTitle:@"刹车故障：" subtitle:bikeData.brake];
    /** 霍尔故障 */
    FBCommenItem *harnal = [FBCommenItem itemWithTitle:@"霍尔故障：" subtitle:bikeData.harnal];
    /** 软件过流 */
    FBCommenItem *software = [FBCommenItem itemWithTitle:@"软件过流：" subtitle:bikeData.software];
    
    
    self.bikeDatas = @[online, createTime, percent, vibrate, speed, mileage, gear, voltage, subbt_percent, bt_lock, ev_key, ev_lock, move, handlebar, famos, shortCir, overvoltage, undervoltage, brake, harnal, software];
}

- (void)setupBtnStatus {
    //    self.bluetoothBtn.selected = self.totalDate.bikeData.bt_lock;
    //    self.openCarBtn.selected = self.totalDate.bikeData.ev_lock;
    //    self.openBatteryBtn.selected = self.totalDate.bikeData.bt_lock;
}

#pragma mark - TableView DataSource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return self.deviceDatas.count;
    } else {
        return self.bikeDatas.count;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    FBHomeInfoCell *cell = [FBHomeInfoCell cellWithTableView:tableView];
    if (indexPath.section == 0) {
        cell.item = self.deviceDatas[indexPath.row];
    } else {
        cell.item = self.bikeDatas[indexPath.row];
    }
    return cell;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    
    UILabel *title = [UILabel labelWithTitle:@"" color:[UIColor colorWithHexString:@"FFFFFF"] font:[UIFont fontWithTwoLine:14]];
    title.height = 50;
    title.backgroundColor = [UIColor redColor];
    if (section == 0) {
        title.text = @"设备实时数据表";
        return title;
    } else {
        title.text = @"电动车辆实时状态表";
        return title;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 50;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 0.01;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)   indexPath {
    return 50;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (self.coordinate.longitude == 0 && self.coordinate.latitude == 0) {
        ShowMsg(@"暂无定位，请获取后再点击");
        return;
    }
    
    
    FBMapViewController *vc = [[FBMapViewController alloc] init];
    vc.userCoordinate = self.coordinate;
    FBDeviceData *deviceData = self.totalDate.deviceData;
    vc.uuid = deviceData.udid;
    [self.navigationController pushViewController:vc animated:YES];
}


#pragma mark - AMapSearchDelegate
- (void)AMapSearchRequest:(id)request didFailWithError:(NSError *)error {
    self.totalDate.deviceData.address = @"获取位置信息失败";
    [self setupData];
    
    FBLog(@"Error: %@ - %@", error, [ErrorInfoUtility errorDescriptionWithCode:error.code]);
}

#pragma mark - AMapSearchDelegate
/* 逆地理编码回调. */
- (void)onReGeocodeSearchDone:(AMapReGeocodeSearchRequest *)request response:(AMapReGeocodeSearchResponse *)response {
    if (response.regeocode != nil) {
        AMapAddressComponent *addressComponent = response.regeocode.addressComponent;
        
        FBLog(@"%@---%@", addressComponent.township, addressComponent.province);
        NSString *finalStr = response.regeocode.formattedAddress;
        if ([response.regeocode.formattedAddress containsString:addressComponent.province]) {
            finalStr = [finalStr stringByReplacingOccurrencesOfString:addressComponent.province withString:@""];
        }
        if ([response.regeocode.formattedAddress containsString:addressComponent.township]) {
            finalStr = [finalStr stringByReplacingOccurrencesOfString:addressComponent.township withString:@""];
        }
        self.totalDate.deviceData.address = finalStr;
        if ([finalStr isEqualToString:@""]) {
            self.totalDate.deviceData.address = @"未知地址";
        }
        
    } else {
        self.totalDate.deviceData.address = nil;
    }
    [self setupData];
}


- (void)setSearchLoaction {
    CLLocationCoordinate2D coordinate;
    if (self.totalDate.deviceData.gsm_lat != 0) {
        coordinate = CLLocationCoordinate2DMake(self.totalDate.deviceData.gsm_lat, self.totalDate.deviceData.gsm_lng);
    } else {
        coordinate = CLLocationCoordinate2DMake(self.totalDate.deviceData.lat, self.totalDate.deviceData.lng);
    }
    self.coordinate = coordinate;
    [self setupLocation:coordinate];
}
/**
 *  setupLocation
 */
- (void)setupLocation:(CLLocationCoordinate2D)userCoordinate {
    AMapReGeocodeSearchRequest *regeo = [[AMapReGeocodeSearchRequest alloc] init];
    regeo.location = [AMapGeoPoint locationWithLatitude:userCoordinate.latitude longitude:userCoordinate.longitude];
    regeo.requireExtension = YES;
    [self.search AMapReGoecodeSearch:regeo];
}


#pragma mark - 私有方法
/**
 * 刷新
 */
- (void)refreshBtnClick {
    [self.view endEditing:YES];
    
    // 参数
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    NSString *str = self.textField.text;
    if (self.textField.text.length == 0) {
        str = @"188002";
    }
    //    [self.tools scanForDevice:str];
    
    params[@"id"] = str;
    FBWeakSelf;
    ShowActy(@"正在加载中...");
    [[FBRequestManager sharedManager] get:@"http://tools.flashbike.cn/fb/status" params:params success:^(id responseObj) {
        HideActy;
        FBLog(@"%@", responseObj);
        if ([responseObj[@"code"] integerValue] == 200) {
            NSDictionary *dict = responseObj;
            weakSelf.totalDate = [FBTotalData mj_objectWithKeyValues:dict];
            [weakSelf setupData];
            [weakSelf setSearchLoaction];
            //            [weakSelf.tools scanForDevice: weakSelf.totalDate.deviceData.udid];
            
            [weakSelf httpGet];
        } else {
            ShowMsg(responseObj[@"message"]);
        }
    } failure:^(NSError *error) {
        HideActy;
        NSString *str = [NSString stringWithFormat:@"出错了%@", error];
        ShowMsg(str);
    }];
}

/**
 * 开关电池
 */
- (void)openBatteryBtnClick {
    // 参数
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    NSString *str = self.textField.text;
    if (self.textField.text.length == 0) {
        str = @"230033001957334834353720";
    }
    //    params[@"ctl"] = @"unlock";
    
    if (self.openBatteryBtn.selected) {
        params[@"ctl"] = @"p_unlock";
    } else {
        params[@"ctl"] = @"p_lock";
    }
    params[@"id"] = str;
    //    ctl: 可选命令字符串有 lock,unlock,p_lock,p_unlock
    FBWeakSelf;
    ShowActy(@"正在加载中...");
    [[FBRequestManager sharedManager] get:@"http://tools.flashbike.cn/fb/control" params:params success:^(id responseObj) {
        HideActy;
        FBLog(@"%@", responseObj);
        if ([responseObj[@"code"] integerValue] == 200) {
            ShowMsg(responseObj[@"message"]);
            self.openBatteryBtn.selected = !self.openBatteryBtn.selected;
        } else {
            ShowMsg(responseObj[@"message"]);
        }
    } failure:^(NSError *error) {
        HideActy;
        NSString *str = [NSString stringWithFormat:@"出错了%@", error];
        ShowMsg(str);
    }];
}

/**
 * 开关车
 */
- (void)openCarBtnClick {
    
    // 参数
    NSMutableDictionary *params = [NSMutableDictionary dictionary];
    NSString *str = self.textField.text;
    if (self.textField.text.length == 0) {
        str = @"230033001957334834353720";
    }
    //    params[@"ctl"] = @"unlock";
    
    if (self.openCarBtn.selected) {
        params[@"ctl"] = @"unlock";
    } else {
        params[@"ctl"] = @"lock";
    }
    params[@"id"] = str;
    //    ctl: 可选命令字符串有 lock,unlock,p_lock,p_unlock
    FBWeakSelf;
    ShowActy(@"正在加载中...");
    [[FBRequestManager sharedManager] get:@"http://tools.flashbike.cn/fb/control" params:params success:^(id responseObj) {
        HideActy;
        FBLog(@"%@", responseObj);
        if ([responseObj[@"code"] integerValue] == 200) {
            ShowMsg(responseObj[@"message"]);
            self.openCarBtn.selected = !self.openCarBtn.selected;
        } else {
            ShowMsg(responseObj[@"message"]);
        }
    } failure:^(NSError *error) {
        HideActy;
        NSString *str = [NSString stringWithFormat:@"出错了%@", error];
        ShowMsg(str);
    }];
    
}

/**
 * 查找蓝牙
 */
- (void)searchBtnClick {
    if (!self.totalDate.deviceData.udid) {
        ShowError(@"udid为空", nil);
        return;
    }
    //    self.bluetoothBtn.selected = !self.bluetoothBtn.selected;
    if (self.searchBtn.selected) {
        //        [self.device sendCommand:AQBluetoothDeviceCommandLock];
        [self.device sendCommand:AQBluetoothDeviceCommandLockEbike];
        ShowActy(@"正在关锁中....");
    } else {
        //        [self.device sendCommand:AQBluetoothDeviceCommandUnlock];
        [self.device sendCommand:AQBluetoothDeviceCommandUnlockEbike];
        ShowActy(@"正在开锁中....");
    }
}


/**
 * 蓝牙开关电池锁
 */
- (void)bluetoothBtnClick {
#warning TODO self.UIDLabel.text.length 上面有UID:不可能为空
    if (!self.totalDate.deviceData.udid) {
        ShowError(@"udid为空", nil);
        return;
    }
    //    self.bluetoothBtn.selected = !self.bluetoothBtn.selected;
    if (self.bluetoothBtn.selected) {
        [self.device sendCommand:AQBluetoothDeviceCommandBatteryLock];
        ShowActy(@"正在关锁中....");
    } else {
        [self.device sendCommand:AQBluetoothDeviceCommandBatteryUnlock];
        ShowActy(@"正在开锁中....");
    }
}

- (NSString *)dataToString:(NSDictionary *)data {
    NSArray *keysArray = [data allKeys];
    
    NSString *string0 =  [keysArray firstObject];
    
    NSString *stringA = [NSString stringWithFormat:@"%@=%@", string0, data[string0]];
    
    for(int i=1; i<keysArray.count; i++) {
        NSString *file = [keysArray objectAtIndex:i];
        NSString *string =[NSString stringWithFormat:@"%@=%@", file, [data objectForKey:file]];
        stringA = [stringA stringByAppendingFormat:@"&%@",string];
    }
    return  stringA;
}


- (void)httpGet {
    // 构造http请求
    if (!self.hasBuleth) {
        ShowMsg(@"请打开蓝牙");
        return;
    }
    self.tools =  [[AQBluetoothTools alloc] initInstance:@"shanqi" key:@"aVRgHjGCygDMMCj4DtXPMyuy"];
    self.tools.delegate = self;
    [self.tools scanForDevice:self.totalDate.deviceData.udid];
    
}

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    
    NSLog(@"%zd-------", central.state);
    
    // 在开启蓝牙状态下才进行扫描外部设备
    if (central.state == CBCentralManagerStatePoweredOn) {
        
        self.hasBuleth = YES;
        //        self.tools =  [[AQBluetoothTools alloc] initInstance:@"aVRgHjGCygDMMCj4DtXPMyuy"];
        //        self.tools.delegate = self;
        
    } else {
        UIAlertController *alertVc = [UIAlertController alertControllerWithTitle:@"打开蓝牙来" message:nil preferredStyle:UIAlertControllerStyleAlert];
        
        // 2.创建并添加按钮
        UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            NSLog(@"OK Action");
        }];
        //        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        //            NSLog(@"Cancel Action");
        //        }];
        //
        [alertVc addAction:okAction];           // A
        //        [alertVc addAction:cancelAction];       // B
        
        // 3.呈现UIAlertContorller
        [self presentViewController:alertVc animated:YES completion:nil];
    }
}

- (void)bluetoothToolsOnDeviceDiscovered:(AQBluetoothDevice *)device RSSI:(NSNumber *)RSSI {
    NSLog(@"bluetoothToolsOnDeviceDiscovered:%@, RSS I:%@", device.imei, RSSI);
    self.stateLabel.text = [NSString stringWithFormat:@"发现设备:%@, \r\nRSS I:%@", device.imei, RSSI];
    [self.tools connectDevice:device];
}

- (void)bluetoothToolsOnDeviceConnected:(AQBluetoothDevice *)device message:(NSString*)message {
    NSLog(@"bluetoothToolsOnDeviceConnected:%@, message:%@", device.imei, message);
    self.stateLabel.text = [NSString stringWithFormat:@"连接到设备:%@, \r\nmessage:%@", device.imei, message];
    device.delegate = self;
    //    [device sendCommand:AQBluetoothDeviceCommandLock];
    self.device = device;
}

- (void)bluetoothDeviceOnCommandCallback:(AQBluetoothDeviceCommandType)command result:(BOOL)result {
    NSLog(@"bluetoothDeviceOnCommandCallback:%ld, result:%d", (long)command, result);
    
    HideActy;
    
    if (result) {
        ShowMsg(@"成功");
        if (command == AQBluetoothDeviceCommandBatteryLock || command == AQBluetoothDeviceCommandBatteryUnlock) {
            self.bluetoothBtn.selected = !self.bluetoothBtn.selected;
        } else if (command == AQBluetoothDeviceCommandLockEbike || command == AQBluetoothDeviceCommandUnlockEbike) {
            self.searchBtn.selected = !self.searchBtn.selected;
        }
    } else {
        ShowMsg(@"失败");
    }
    
    switch (command) {
        case AQBluetoothDeviceCommandLock:
            NSLog(@"bluetoothDeviceOnCommandCallback:%ld, result:%d", (long)command, result);
            //            self.msgLabel.text = [NSString stringWithFormat:@"command:命令类型:锁车 \r\nresult:是否成功:%d", result];
            break;
        case AQBluetoothDeviceCommandUnlock:
            NSLog(@"bluetoothDeviceOnCommandCallback:%ld, result:%d", (long)command, result);
            //            self.msgLabel.text = [NSString stringWithFormat:@"command:命令类型:解锁 \r\nresult:是否成功:%d", result];
            break;
        case AQBluetoothDeviceCommandPowerOn:
            NSLog(@"bluetoothDeviceOnCommandCallback:%ld, result:%d", (long)command, result);
            //            self.msgLabel.text = [NSString stringWithFormat:@"command:命令类型:开电门 \r\nresult:是否成功:%d", result];
            break;
        case AQBluetoothDeviceCommandPowerOff:
            NSLog(@"bluetoothDeviceOnCommandCallback:%ld, result:%d", (long)command, result);
            //            self.msgLabel.text = [NSString stringWithFormat:@"command:命令类型:关电门 \r\nresult:是否成功:%d", result];
            break;
        case AQBluetoothDeviceCommandWarningSound:
            NSLog(@"bluetoothDeviceOnCommandCallback:%ld, result:%d", (long)command, result);
            //            self.msgLabel.text = [NSString stringWithFormat:@"command:命令类型:蜂鸣器 \r\nresult:是否成功:%d", result];
            break;
        case AQBluetoothDeviceCommandActive:
            NSLog(@"bluetoothDeviceOnCommandCallback:%ld, result:%d", (long)command, result);
            //            self.msgLabel.text = [NSString stringWithFormat:@"command:命令类型:激活 \r\nresult:是否成功:%d", result];
            break;
            //            NSLog(@"bluetoothDeviceOnCommandCallback:%ld, result:%d", (long)command, result);
            //            //            self.msgLabel.text = [NSString stringWithFormat:@"command:命令类型:电池锁 \r\nresult:是否成功:%d", result];
            //            break;
        case AQBluetoothDeviceCommandBatteryLock:
        case AQBluetoothDeviceCommandBatteryUnlock:
            NSLog(@"bluetoothDeviceOnCommandCallback:%ld, result:%d", (long)command, result);
            //            self.msgLabel.text = [NSString stringWithFormat:@"command:命令类型:电池解锁 \r\nresult:是否成功:%d", result];
            
            break;
        default:
            break;
    }
    
    
    //    static dispatch_once_t onceToken;
    //    dispatch_once(&onceToken, ^{
    //        [self.device sendCommand:AQBluetoothDeviceCommandLock];
    //    });
}

/**
 * 扫码
 */
- (void)scanCodeButtonClick {
    [self.textField endEditing:YES];
    FBScanQRCodeViewController *vc = [[FBScanQRCodeViewController alloc] init];
    FBWeakSelf;
    vc.scanQrcode = ^(NSString *string) {
        if(![string isEqualToString:@"false"]) {
            weakSelf.textField.text = string;
        }
    };
    [self.navigationController pushViewController:vc animated:YES];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
