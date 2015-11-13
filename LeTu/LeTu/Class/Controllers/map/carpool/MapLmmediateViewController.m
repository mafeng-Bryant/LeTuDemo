//
//  MapLmmediateViewController.m
//  LeTu
//
//  Created by DT on 14-6-11.
//
//

#import "MapLmmediateViewController.h"
#import "MapLmmediateCell.h"
#import "MapLocationViewController.h"
#import "MapPopupView.h"
#import "MapCarpoolBoxViewController.h"
#import "MapActivityAddressViewController.h"

#define INTNUM @"0123456789"

@interface MapLmmediateViewController ()<UITableViewDataSource,UITableViewDelegate,UITextFieldDelegate>
{
    NSOperationQueue *queue;
}
@property(nonatomic,strong)MapPopupView *popupView;
@property(nonatomic,strong)UITableView *tableView;
@property(nonatomic,strong)UIView *tableHeaderView;

@property(nonatomic,strong)DTButton *driverButton;
@property(nonatomic,strong)DTButton *passengerButton;

@property(nonatomic,strong)DTButton *onlineButton;
@property(nonatomic,strong)DTButton *thelineButton;
@property(nonatomic,strong)UIButton *publishButton;

@property(nonatomic,strong)NSDictionary *locationStart;//出发地
@property(nonatomic,strong)NSDictionary *locationEnd;//目的地
@property(nonatomic,copy)NSString *startTime;//时间
@property(nonatomic,copy)NSString *seating;//人数
@property(nonatomic,copy)NSString *fee;//金额
@property(nonatomic,assign)int type;
@property(nonatomic,assign)BOOL isWillShow;

@end

@implementation MapLmmediateViewController

-(id)initWithStartCoordinate:(CLLocationCoordinate2D)startCoordinate startAddress:(NSString*)startAddress endCoordinate:(CLLocationCoordinate2D)endCoordinate endAddress:(NSString*)endAddress;
{
    self = [super init];
    if (self) {
        self.startTime = [DateUtil stringFormatDate:[NSDate date]];
        self.seating = @"0";
        self.fee = @"0";
        self.type = 1;
        self.isWillShow = YES;
        
        self.locationStart = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSString stringWithFormat:@"%f",startCoordinate.latitude],@"latitude",
                              [NSString stringWithFormat:@"%f",startCoordinate.longitude],@"longitude",
                              startAddress,@"address",nil];
        
        self.locationEnd = [NSDictionary dictionaryWithObjectsAndKeys:
                            [NSString stringWithFormat:@"%f",endCoordinate.latitude],@"latitude",
                            [NSString stringWithFormat:@"%f",endCoordinate.longitude],@"longitude",
                            endAddress,@"address",nil];
    }
    return self;
}
-(id)init
{
    self = [super init];
    if (self) {
        self.startTime = [DateUtil stringFormatDate:[NSDate date]];
        self.seating = @"0";
        self.fee = @"0";
        self.type = 1;
        self.isWillShow = YES;
        
        self.locationStart = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSString stringWithFormat:@"%f",self.appDelegate.currentLocation.latitude],@"latitude",
                              [NSString stringWithFormat:@"%f",self.appDelegate.currentLocation.longitude],@"longitude",
                              self.appDelegate.address,@"address",nil];
        
        self.locationEnd = [NSDictionary dictionaryWithObjectsAndKeys:
                            [NSString stringWithFormat:@"%f",self.appDelegate.currentLocation.latitude],@"latitude",
                            [NSString stringWithFormat:@"%f",self.appDelegate.currentLocation.longitude],@"longitude",
                            self.appDelegate.address,@"address",nil];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = RGBCOLOR(239, 238, 244);
    [self setTitle:@"即时拼车" andShowButton:YES];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];//键盘改变的通知
    
    [self initTableView];
    
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}
- (void)clickButton:(DTButton*)button
{
    if (button.tag==1) {//车主按钮
        if (![button isSelect]) {
            button.isSelect = ![button isSelect];
            self.passengerButton.isSelect = NO;
            [self.tableView reloadData];
        }
    }else if (button.tag ==2){//乘客按钮
        if (![button isSelect]) {
            button.isSelect = ![button isSelect];
            self.driverButton.isSelect = NO;
            [self.tableView reloadData];
        }
    }else if (button.tag ==3){//线上支付
        if (![button isSelect]) {
            button.isSelect = ![button isSelect];
            self.thelineButton.isSelect = NO;
        }
    }else if (button.tag == 4){//线下支付
        if (![button isSelect]) {
            button.isSelect = ![button isSelect];
            self.onlineButton.isSelect = NO;
        }
    }else if (button.tag == 5){//发布按钮
        NSString *shareType = [NSString stringWithFormat:@"%i",self.type];
        NSString *userType = nil;
        NSString *payType = nil;
        if ([self.driverButton isSelect]) {
            userType = @"1";
        }else{
            userType = @"2";
        }
        if ([self.onlineButton isSelect]) {
            payType = @"1";
        }else{
            payType = @"2";
        }
        if ([[self.locationStart objectForKey:@"address"] isEqualToString:[self.locationEnd objectForKey:@"address"]]) {
            [self messageToast:@"出发地和目的地距离太近,不能发起拼车!"];
            return;
        }
        if ([self.driverButton isSelect]) {
            MapLmmediateCell *cell = (MapLmmediateCell*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:3 inSection:0]];
            self.fee = cell.textField.text;
            
            if ([self.seating isEqualToString:@"0"] || self.seating==nil || [self.seating isEqualToString:@""]) {
                [self messageToast:@"人数不能为空"];
                return;
            }
            if ([self.fee isEqualToString:@""]) {
                [self messageToast:@"金额不能为空"];
                return;
            }
        }else{
            self.fee = @"";
        }
        
        self.publishButton.enabled = NO;
        [self createCarpool:shareType userType:userType routeStart:[self.locationStart objectForKey:@"address"] routeEnd:[self.locationEnd objectForKey:@"address"] startTime:self.startTime seating:self.seating fee:self.fee payType:payType longitudeStart:[self.locationStart objectForKey:@"latitude"] latitudeStart:[self.locationStart objectForKey:@"longitude"] longitudeEnd:[self.locationEnd objectForKey:@"latitude"] latitudeEnd:[self.locationEnd objectForKey:@"longitude"]];
    }
}
/**
 *  初始化tableHeaderView
 */
- (void)initTableHeaderView
{
    self.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, FRAME_WIDTH, 67)];
    
    self.driverButton = [[DTButton alloc] initWithFrame:CGRectMake(7, 12, 152.5, 42)];
    self.driverButton.normalImage = [UIImage imageNamed:@"driver_qiehuan_normal"];
    self.driverButton.pressImage = [UIImage imageNamed:@"driver_qiehuan_press"];
    self.driverButton.isSelect = YES;
    self.driverButton.tag = 1;
    [self.driverButton addTarget:self action:@selector(clickButton:) forControlEvents:UIControlEventTouchUpInside];
    [self.tableHeaderView addSubview:self.driverButton];
    
    self.passengerButton = [[DTButton alloc] initWithFrame:CGRectMake(159.5, 12, 152.5, 42)];
    self.passengerButton.normalImage = [UIImage imageNamed:@"passage_qiehuan_normal"];
    self.passengerButton.pressImage = [UIImage imageNamed:@"passage_qiehuan_press"];
    self.passengerButton.isSelect = NO;
    self.passengerButton.tag = 2;
    [self.passengerButton addTarget:self action:@selector(clickButton:) forControlEvents:UIControlEventTouchUpInside];
    [self.tableHeaderView addSubview:self.passengerButton];
}
/**
 *  初始化tableView
 */
- (void)initTableView
{
    [self initTableHeaderView];
    UIView *tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, FRAME_WIDTH, 60)];
    self.publishButton = [[UIButton alloc] initWithFrame:CGRectMake(45, 15, 230, 40)];
    [self.publishButton setImage:[UIImage imageNamed:@"fabu_normal"] forState:UIControlStateNormal];
    [self.publishButton setImage:[UIImage imageNamed:@"fabu_press"] forState:UIControlStateHighlighted];
    self.publishButton.tag = 5;
    [self.publishButton addTarget:self action:@selector(clickButton:) forControlEvents:UIControlEventTouchUpInside];
    [tableFooterView addSubview:self.publishButton];
    
    
    int height = [UIScreen mainScreen].bounds.size.height-STATUSBAR_HEIGHT-NAVBAR_HEIGHT;
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, NAVBAR_HEIGHT, self.view.frame.size.width, height) style:UITableViewStyleGrouped];
    self.tableView.backgroundColor = RGBCOLOR(239, 238, 244);
    self.tableView.backgroundView = nil;
    self.tableView.tableHeaderView = self.tableHeaderView;
    self.tableView.tableFooterView = tableFooterView;
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
//    UITapGestureRecognizer *gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard)];
//    gestureRecognizer.cancelsTouchesInView = NO;
//    [self.tableView addGestureRecognizer:gestureRecognizer];
    
    [self.view addSubview:self.tableView];
    
    UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(singleTap:)];
    singleTap.cancelsTouchesInView = NO;
    [self.tableView addGestureRecognizer:singleTap];
}
#pragma mark UITableViewDataSource
//- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
//{
//    if ([self.driverButton isSelect]) {
//        return 2;
//    }
//    return 1;
//}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([self.driverButton isSelect]) {
        if (section==0) {
            return 4;
        }
        return 1;
    }
    return 2;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    if ([self.driverButton isSelect]) {
        if (indexPath.section==0) {
            static NSString *CellIdentifier = @"Cell";
            MapLmmediateCell * cell = [[MapLmmediateCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
//            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            
            if (!iOS_7_Above) {
                cell.keyLabel.frame = CGRectMake(15, (cell.frame.size.height-30)/2, 60, 30);
                CGRect frame = cell.arrowImage.frame;
                frame.origin.x -= 5;
                cell.arrowImage.frame = frame;
            }
            switch (indexPath.row) {
                case 0:{
//                    cell.selectionStyle = UITableViewCellSelectionStyleNone;
//                    cell.arrowImage.hidden = YES;
                    cell.keyLabel.text = @"出发地";
                    cell.valueLabel.text = [self.locationStart objectForKey:@"address"];
                    if ([self.locationStart objectForKey:@"address"]==nil || [[self.locationStart objectForKey:@"address"] isEqualToString:@""]) {
                        cell.valueLabel.text = @"请选择出发地";
                        cell.valueLabel.textColor = [UIColor grayColor];
                    }
                    break;
                }case 1:{
//                    cell.selectionStyle = UITableViewCellSelectionStyleNone;
//                    cell.arrowImage.hidden = YES;
                    cell.keyLabel.text = @"目的地";
                    cell.valueLabel.text = [self.locationEnd objectForKey:@"address"];
                    if ([self.locationEnd objectForKey:@"address"]==nil || [[self.locationEnd objectForKey:@"address"] isEqualToString:@""]) {
                        cell.valueLabel.text = @"请选择目的地";
                        cell.valueLabel.textColor = [UIColor grayColor];
                    }
                    break;
                }case 2:{
                    cell.keyLabel.text = @"人数";
                    cell.valueLabel.text = @"请输入人数";
                    cell.valueLabel.textColor = [UIColor grayColor];
                    break;
                }case 3:{
                    cell.arrowImage.hidden = YES;
                    if (!iOS_7_Above) {
                        cell.keyLabel.frame = CGRectMake(15, (cell.frame.size.height-30)/2, 60, 30);
                        CGRect frame = cell.arrowImage.frame;
                        frame.origin.x -= 5;
                        cell.arrowImage.frame = frame;
                    }
                    cell.keyLabel.text = @"金额";
                    cell.showTextField = YES;
                    CGRect frame = cell.textField.frame;
                    frame.size.width -=10;
                    cell.textField.frame = frame;
                    cell.textField.delegate = self;
                }
                default:
                    break;
            }
            return cell;
        }
        /*
        else if (indexPath.section==1){
            static NSString *CellIdentifier = @"Cell";
            MapLmmediateCell *cell = [[MapLmmediateCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.arrowImage.hidden = YES;
//            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            if (!iOS_7_Above) {
                cell.keyLabel.frame = CGRectMake(15, (cell.frame.size.height-30)/2, 60, 30);
                CGRect frame = cell.arrowImage.frame;
                frame.origin.x -= 5;
                cell.arrowImage.frame = frame;
            }
//            cell.keyLabel.text = @"金额";
//            cell.valueLabel.text = @"请输入金额";
//            cell.valueLabel.textColor = [UIColor grayColor];
         
            //*
            cell.keyLabel.text = @"金额";
            cell.showTextField = YES;
            CGRect frame = cell.textField.frame;
            frame.size.width -=10;
            cell.textField.frame = frame;
            cell.textField.delegate = self;
             //*/
        
//        }
    }
    if (indexPath.section==0) {
        static NSString *CellIdentifier = @"Cell";
        MapLmmediateCell * cell = [[MapLmmediateCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        
        if (!iOS_7_Above) {
            cell.keyLabel.frame = CGRectMake(15, (cell.frame.size.height-30)/2, 60, 30);
            CGRect frame = cell.arrowImage.frame;
            frame.origin.x -= 5;
            cell.arrowImage.frame = frame;
        }
        switch (indexPath.row) {
            case 0:{
//                cell.selectionStyle = UITableViewCellSelectionStyleNone;
//                cell.arrowImage.hidden = YES;
                cell.keyLabel.text = @"出发地";
                cell.valueLabel.text = [self.locationStart objectForKey:@"address"];
                if ([self.locationStart objectForKey:@"address"]==nil || [[self.locationStart objectForKey:@"address"] isEqualToString:@""]) {
                    cell.valueLabel.text = @"请选择出发地";
                    cell.valueLabel.textColor = [UIColor grayColor];
                }
                break;
            }case 1:{
//                cell.selectionStyle = UITableViewCellSelectionStyleNone;
//                cell.arrowImage.hidden = YES;
                cell.keyLabel.text = @"目的地";
                cell.valueLabel.text = [self.locationEnd objectForKey:@"address"];
                if ([self.locationEnd objectForKey:@"address"]==nil || [[self.locationEnd objectForKey:@"address"] isEqualToString:@""]) {
                    cell.valueLabel.text = @"请选择目的地";
                    cell.valueLabel.textColor = [UIColor grayColor];
                }
                break;
            }case 2:{
                cell.keyLabel.text = @"时间";
                cell.valueLabel.text = @"请选择时间";
                cell.valueLabel.textColor = [UIColor grayColor];
                break;
            }
            default:
                break;
        }
        return cell;
    }
    return nil;
}
#pragma mark UITableViewDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self hideKeyboard];
    if (indexPath.section==0) {
        switch (indexPath.row) {
            case 0:{//出发地
                MapActivityAddressViewController *addressVC =
                [[MapActivityAddressViewController alloc]
                 initWithTitle:@"出发地"
                 latitude:[[self.locationStart objectForKey:@"latitude"] floatValue]
                 longitude:[[self.locationStart objectForKey:@"longitude"] floatValue]
                 address:[self.locationStart objectForKey:@"address"]];
                [self.navigationController pushViewController:addressVC animated:YES];
                [addressVC setCallBack:^(float latitude, float longitude, NSString *address) {
                    self.locationStart = [NSDictionary dictionaryWithObjectsAndKeys:
                                          [NSString stringWithFormat:@"%f",latitude],@"latitude",
                                          [NSString stringWithFormat:@"%f",longitude],@"longitude",
                                          address,@"address",nil];
                    MapLmmediateCell *cell = (MapLmmediateCell*)[self.tableView cellForRowAtIndexPath:indexPath];
                    cell.valueLabel.textColor = [UIColor blackColor];
                    cell.valueLabel.text = address;
                    [cell setNeedsLayout];
                }];
                break;
            }case 1:{//目的地
                MapActivityAddressViewController *addressVC =
                [[MapActivityAddressViewController alloc]
                 initWithTitle:@"目的地"
                 latitude:[[self.locationEnd objectForKey:@"latitude"] floatValue]
                 longitude:[[self.locationEnd objectForKey:@"longitude"] floatValue]
                 address:[self.locationEnd objectForKey:@"address"]];
                [self.navigationController pushViewController:addressVC animated:YES];
                [addressVC setCallBack:^(float latitude, float longitude, NSString *address) {
                    self.locationEnd = [NSDictionary dictionaryWithObjectsAndKeys:
                                          [NSString stringWithFormat:@"%f",latitude],@"latitude",
                                          [NSString stringWithFormat:@"%f",longitude],@"longitude",
                                          address,@"address",nil];
                    MapLmmediateCell *cell = (MapLmmediateCell*)[self.tableView cellForRowAtIndexPath:indexPath];
                    cell.valueLabel.textColor = [UIColor blackColor];
                    cell.valueLabel.text = address;
                    [cell setNeedsLayout];
                }];
                break;
            }
                /*
            case 0:{//出发地
                MapLocationViewController *locationVC = [[MapLocationViewController alloc] initWithType:1 location:self.locationStart block:^(int type, NSString *latitude, NSString *longitude, NSString *location) {
                    if (type ==1) {
                        self.locationStart = [NSDictionary dictionaryWithObjectsAndKeys:
                                              latitude,@"latitude",
                                              longitude,@"longitude",
                                              location,@"address",nil];
                        MapLmmediateCell *cell = (MapLmmediateCell*)[self.tableView cellForRowAtIndexPath:indexPath];
                        cell.valueLabel.textColor = [UIColor blackColor];
                        cell.valueLabel.text = location;
                        [cell setNeedsLayout];
                    }
                }];
                [self.navigationController pushViewController:locationVC animated:YES];
                break;
            }case 1:{//目的地
                MapLocationViewController *locationVC = [[MapLocationViewController alloc] initWithType:2 location:self.locationEnd block:^(int type, NSString *latitude, NSString *longitude, NSString *location) {
                    if (type ==2) {
                        self.locationEnd = [NSDictionary dictionaryWithObjectsAndKeys:
                                            latitude,@"latitude",
                                            longitude,@"longitude",
                                            location,@"address",nil];
                        MapLmmediateCell *cell = (MapLmmediateCell*)[self.tableView cellForRowAtIndexPath:indexPath];
                        cell.valueLabel.textColor = [UIColor blackColor];
                        cell.valueLabel.text = location;
                        [cell setNeedsLayout];
                    }
                }];
                [self.navigationController pushViewController:locationVC animated:YES];
                break;
            }
                 //*/
            case 2:{//时间
                /*
                MapSelectDateViewController *dateVC = [[MapSelectDateViewController alloc]
                                                       initWithBlock:^(NSString *date) {
                                                           self.startTime = date;
                                                           NSLog(@"%@",self.startTime);
                                                           MyselfDetailCell *cell = (MyselfDetailCell*)[tableView cellForRowAtIndexPath:indexPath];
                                                           cell.value = [date substringToIndex:[date length]-3];
                                                           cell.valueLabel.textColor = [UIColor blackColor];
                                                       }];
                [self.navigationController pushViewController:dateVC animated:YES];
                 //*/
                
//                [self showPopupView:2];
                [self showPopupView:1];
                break;
            }case 3:{//人数
                /*
                MyselfDetailCell *cell = (MyselfDetailCell*)[self.tableView cellForRowAtIndexPath:indexPath];
                NSString *value = cell.valueLabel.text;
                if ([value isEqualToString:@"请输入人数"]) {
                    value = @"";
                }
                MapCarpoolBoxViewController *boxVC = [[MapCarpoolBoxViewController alloc] initWithType:1 content:value block:^(NSString *value) {
                    self.seating = value;
                    cell.valueLabel.text = value;
                    cell.valueLabel.textColor = [UIColor blackColor];
                }];
                [self.navigationController pushViewController:boxVC animated:YES];
                 //*/
                [self showPopupView:1];
                break;
            }
            default:
                break;
        }
    }
    /*
    else if (indexPath.section==1) {//金额
        MapLmmediateCell *cell = (MapLmmediateCell*)[self.tableView cellForRowAtIndexPath:indexPath];
        NSString *value = cell.valueLabel.text;
        if ([value isEqualToString:@"请输入金额"]) {
            value = @"";
        }
        MapCarpoolBoxViewController *boxVC = [[MapCarpoolBoxViewController alloc] initWithType:2 content:value block:^(NSString *value) {
            self.fee = value;
            cell.valueLabel.text = value;
            cell.valueLabel.textColor = [UIColor blackColor];
        }];
        [self.navigationController pushViewController:boxVC animated:YES];
    }
     //*/
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section==1 || section==2) {
        return 10;
    }
    return 0;
}

/*
-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    self.isWillShow = NO;
    if (!self.isWillShow) {
//        int height = [UIScreen mainScreen].bounds.size.height - NAVBAR_HEIGHT - STATUSBAR_HEIGHT;
//        self.tableView.frame = CGRectMake(0, 44, 320, height);
        MapLmmediateCell *cell = (MapLmmediateCell*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]];
        [cell.textField resignFirstResponder];
        self.isWillShow = YES;
    }
}
 //*/
#pragma mark UITextFieldDelegate
- (void)keyboardWillChangeFrame:(NSNotification *)notification
{
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:NO];
    NSDictionary *info = [notification userInfo];
    CGFloat duration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    CGRect beginKeyboardRect = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    CGRect endKeyboardRect = [[info objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGFloat yOffset = endKeyboardRect.origin.y - beginKeyboardRect.origin.y;
    CGRect commentBoxRect = self.tableView.frame;
    commentBoxRect.size.height += yOffset;
    [UIView animateWithDuration:duration animations:^{
        self.tableView.frame = commentBoxRect;
    }];
//    if (yOffset <0) {
//        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1] atScrollPosition:UITableViewScrollPositionBottom animated:NO];
//        self.isWillShow = NO;
//    }
}
- (void) hideKeyboard {
    if ([self.driverButton isSelect]) {
        MapLmmediateCell *cell = (MapLmmediateCell*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:3 inSection:0]];
        self.isWillShow = YES;
        [cell.textField resignFirstResponder];
    }
 }


/**
 *  显示弹出试图
 */
-(void)showPopupView:(int)type
{
    if (!self.popupView) {
        int height = [UIScreen mainScreen].bounds.size.height - STATUSBAR_HEIGHT;
        self.popupView = [[MapPopupView alloc] initWithFrame:CGRectMake(0, 20, 320, height)];
        self.popupView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
        [self.appDelegate.window addSubview:self.popupView];
        
        __block MapLmmediateViewController *blockSelf = self;
        [self.popupView setCallBack:^(int type, int status,NSString *value) {
            if (status ==2) {
                [blockSelf hidePopupView];
            }else{
                if (type==2) {//时间
                    MapLmmediateCell *cell = (MapLmmediateCell*)[blockSelf.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
                    blockSelf.startTime = [value stringByAppendingString:@":00"];
                    cell.valueLabel.text = value;
                    cell.valueLabel.textColor = [UIColor blackColor];
                    [cell setNeedsLayout];
                }else if (type==1){//人数
                    MapLmmediateCell *cell = (MapLmmediateCell*)[blockSelf.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
                    blockSelf.seating = value;
                    cell.valueLabel.text = value;
                    cell.valueLabel.textColor = [UIColor blackColor];
                    [cell setNeedsLayout];
                }
                [blockSelf hidePopupView];
            }
        }];
    }
    self.popupView.type = type;
    
    self.popupView.hidden = NO;
    CGRect frame = self.popupView.showView.frame;
    frame.origin.y +=self.popupView.showView.frame.size.height;
    self.popupView.showView.frame = frame;
    [UIView animateWithDuration:0.25 animations:^{
        int height = [UIScreen mainScreen].bounds.size.height - STATUSBAR_HEIGHT;
        self.popupView.showView.frame = CGRectMake(0, height-250, 320, 250);
    }];
}
-(void)hidePopupView
{
    [UIView animateWithDuration:0.25 animations:^{
        int height = [UIScreen mainScreen].bounds.size.height - STATUSBAR_HEIGHT;
        self.popupView.showView.frame = CGRectMake(0, height, 320, 250);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.25 animations:^{
            self.popupView.hidden = YES;
        }];
    }];
}
- (void)singleTap:(UITapGestureRecognizer *)gestureRecognizer
{
    if ([self.driverButton isSelect]) {
        MapLmmediateCell *cell = (MapLmmediateCell*)[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:1]];
        [cell.textField resignFirstResponder];
    }
}

/**
 *  创建拼车数据
 *
 *  @param shareType      拼车类型 1:即时 2:预约 3:活动
 *  @param userType       用户类型 1:车主 2:乘客
 *  @param routeStart     出发地点
 *  @param routeEnd       目的地点
 *  @param startTime      出发时间
 *  @param seating        拼车人数
 *  @param fee            金额
 *  @param payType        支付方式 1:线上支付 2:线下支付
 *  @param longitudeStart 出发地点经度
 *  @param latitudeStart  出发地点纬度
 *  @param longitudeEnd   目的地点经度
 *  @param latitudeEnd    目的地点纬度
 */
-(void)createCarpool:(NSString*)shareType userType:(NSString*)userType routeStart:(NSString*)routeStart routeEnd:(NSString*)routeEnd startTime:(NSString*)startTime seating:(NSString*)seating fee:(NSString*)fee payType:(NSString*)payType longitudeStart:(NSString*)longitudeStart latitudeStart:(NSString*)latitudeStart longitudeEnd:(NSString*)longitudeEnd latitudeEnd:(NSString*)latitudeEnd
{
    NSString *requestUrl = [NSString stringWithFormat:@"%@carsharing/carSharingService.jws?create", SERVERAPIURL];
    if (queue == nil)
    {
        queue = [[ NSOperationQueue alloc ] init];
    }
    
    NSMutableDictionary *paramDict = [NSMutableDictionary dictionaryWithCapacity:1];
    [paramDict setObject:[UserDefaultsHelper getStringForKey:@"key"] forKey:@"l_key"];
    [paramDict setObject:shareType forKey:@"shareType"];
    [paramDict setObject:userType forKey:@"userType"];
    [paramDict setObject:routeStart==nil?@"":routeStart forKey:@"routeStart"];
    [paramDict setObject:routeEnd==nil?@"":routeEnd forKey:@"routeEnd"];
    [paramDict setObject:startTime forKey:@"startTime"];
    [paramDict setObject:seating forKey:@"seating"];
    [paramDict setObject:fee forKey:@"fee"];
    [paramDict setObject:payType forKey:@"payType"];
    [paramDict setObject:longitudeStart forKey:@"longitudeStart"];
    [paramDict setObject:latitudeStart forKey:@"latitudeStart"];
    [paramDict setObject:longitudeEnd forKey:@"longitudeEnd"];
    [paramDict setObject:latitudeEnd forKey:@"latitudeEnd"];
    [paramDict setObject:
     [NSString stringWithFormat:@"%f",self.appDelegate.currentLocation.latitude] forKey:@"phoneLatitude"];
    [paramDict setObject:
     [NSString stringWithFormat:@"%f",self.appDelegate.currentLocation.longitude] forKey:@"phoneLongitude"];
    
    RequestParseOperation *operation = [[RequestParseOperation alloc] initWithURLAndPostParams:requestUrl delegate:self params:paramDict];
    operation.RequestTag = 1;
    [queue addOperation :operation];
}
-(void)reponseDatas:(NSDictionary *)data operationTag:(NSInteger)tag
{
    if (tag == 1) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"createCarpoolSuccess" object:nil ];
        if (self.callBack) {
            self.callBack();
        }
        self.publishButton.enabled = YES;
        [self messageToast:@"发起拼车成功"];
        [self.navigationController popViewControllerAnimated:YES];
    }
}
-( void )reponseFaild:(NSInteger)tag
{
    self.publishButton.enabled = YES;
}

#pragma mark UITextFieldDelegate
-(BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    // 支持 0元, 并删除掉 0(头部)
    if ([textField.text isEqualToString:@"0"])
        textField.text = @"";
    return YES;

    if (textField.text.length==0) {
        if ([string length]>0) {
            unichar single=[string characterAtIndex:0];//当前输入的字符
            if (single == '0') {
                [textField.text stringByReplacingCharactersInRange:range withString:@""];
                return NO;
            }
        }
    }
    NSCharacterSet *cs;
    cs = [[NSCharacterSet characterSetWithCharactersInString:INTNUM] invertedSet];
    NSString *filtered = [[string componentsSeparatedByCharactersInSet:cs]componentsJoinedByString:@""]; //按cs分离出数组,数组按@""分离出字符串
    BOOL canChange = [string isEqualToString:filtered];
    return canChange;
}
@end
