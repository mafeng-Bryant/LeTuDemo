//
//  MessageBoxViewController.m
//  LeTu
//
//  Created by mac on 14-5-12.
//
//



#import "MessageBoxViewController.h"
#import "EGOImageView.h"
#import "ChatViewController.h"
#import "ContactPersonsViewController.h"
#import "MessageModel.h"
#import "DateUtil.h"
#import "CacheSql.h"
#import "NSObject+SBJson.h"

#if IMPORT_LETUIM_H
#import "LeTuIM.h"
#import "Reachability.h"
#endif

#ifdef IMPORT_LETUIM_H
@interface NetWorkAlertLabel : UILabel
@end
@implementation NetWorkAlertLabel : UILabel
- (instancetype)init
{
    self = [super init];
    if (self) {
        //wechat 251 232 232
        //mobileQQ 255 242 192
        self.backgroundColor = [UIColor colorWithRed:255/255.f green:242/255.f  blue:192/255.f  alpha:1];
        self.frame = CGRectMake(0, 44, 320, 30);
    }
    return self;
}

+ (NetWorkAlertLabel *)netWorkAlertLabelWithAlert:(NSString *)str {
    
    NetWorkAlertLabel *label = [[NetWorkAlertLabel alloc] init];
    label.text = str;
    
    return label;
}
@end

@interface MessageBoxViewController ()<LeTuIMDelegate, JSChatMessageDelegate> {
    NSMutableArray *_lastMessageList;
    
    BOOL _isSelfShow;
    BOOL _haveNewMessag;
    DTButton *_tabButton;
    UILabel *_netWorkAlertLabel;
    
}
@end
#endif

@implementation MessageBoxViewController
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"letu_bg"]];
    [self setTitle:@"消息" andShowButton:NO];
    [self initRightBarButtonItem:[UIImage imageNamed:@"message1_icon_profile"] highlightedImage:nil];
    
//    newFriendTimer = [NSTimer scheduledTimerWithTimeInterval:3 target:self
//                                                    selector:@selector(GetNewFriendRequestCount) userInfo:nil repeats:YES];
    [self GetNewFriendRequestCount];
    [self initViews];
    
#ifdef IMPORT_LETUIM_H
    _tabButton = self.appDelegate.tabBar.buttonArray[1];
    
    _haveNewMessag = [NSUserDefaults boolForKeyInStandardUserDefaults:@"RedDotMessageBoxViewController"];
    _tabButton.isRedDot = _haveNewMessag;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(newMessage:) name:LETUMESSAGE_SAVEDMESSAGE object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
#endif
}
-(void)viewWillAppear:(BOOL)animated
{
    
    [super viewWillAppear:YES];
    self.appDelegate.navigation.isSlide = NO;
    isOpen=NO;
    SHOWTABBAR;
#ifdef IMPORT_LETUIM_H
    _lastMessageList = [[LeTuIM sharedInstance] lastMessageList];
    
    _isSelfShow = YES;
    if (_haveNewMessag) {
        _haveNewMessag = NO;
        [self performSelector:@selector(showTabButtonReddot) withObject:nil afterDelay:1];
    }
    
    [mTableView reloadData];
    [[LeTuIM sharedInstance] setMessageDelegate:self];
    
//    if ([[LeTuIM sharedInstance] currentStatus] <=ServerStatusDidDisconnect) [self checkLetuIMServer];
    [self checkLetuIMServer];
#else
    [self reloadRefreshDataSource:0];
#endif
    
}


#ifdef IMPORT_LETUIM_H
- (void)checkLetuIMServer {
    
//    if (DEBUG) {
        ServerStatus currentStatus = [[LeTuIM sharedInstance] currentStatus];
        NetworkStatus currentHostReachabilityStatus = [[LeTuIM sharedInstance] currentHostReachabilityStatus];
        NSLog(@"\ncheckLetuIMServer(currentStatus %d, currentHostReachabilityStatus %d)", currentStatus, currentHostReachabilityStatus);
//    }
    
    // NotReachable==0
    if ([[LeTuIM sharedInstance] currentHostReachabilityStatus]) {
        
        if (_netWorkAlertLabel) {
            _netWorkAlertLabel.text = @"    👌 网络已经连接";
            
            [UIView animateWithDuration:1.2 animations:^{
                
                _netWorkAlertLabel.alpha = .012;
            } completion:^(BOOL finished) {
                
                [_netWorkAlertLabel removeFromSuperview];
                _netWorkAlertLabel = nil;
            }];
        }
        
        [[LeTuIM sharedInstance] startServe];
    } else {
        
        if (!_netWorkAlertLabel) {
            _netWorkAlertLabel = [NetWorkAlertLabel netWorkAlertLabelWithAlert:@"   ❌ 服务器连接不正常"];
            
            [self.view addSubview:_netWorkAlertLabel];
        }
        
        // object
        [self performSelector:@selector(checkLetuIMServer) withObject:nil afterDelay:5];
    }
}
- (void)reachabilityChanged:(NSNotification *)notification {
    [self checkLetuIMServer];
}
#endif

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:YES];
    //    self.appDelegate.navigation.isSlide = YES;
#ifdef IMPORT_LETUIM_H
    _isSelfShow = NO;
    _haveNewMessag = NO;
    [self showTabButtonReddot];
    
    [[LeTuIM sharedInstance] setMessageDelegate:nil];
#else
    [timer invalidate];
    timer=nil;
#endif
}

#ifdef IMPORT_LETUIM_H
#pragma mark - ChatMessageDelegate
- (void)newMessage:(NSNotification *)notification {
    LeTuMessage *msg = [notification object];
    if (![msg isBuddySpeak])
        return;
//    if (self.navigationController.topViewController != self) {
        _haveNewMessag = YES;
        [self showTabButtonReddot];
//    }
}
- (void)didDialogsChanged:(NSArray *)dialogs
{
    _lastMessageList = [[LeTuIM sharedInstance] lastMessageList];
    [mTableView reloadData];
}
- (void)didChatChanged:(NSDictionary *)changedInfomation
{
    _lastMessageList = [[LeTuIM sharedInstance] lastMessageList];
    [mTableView reloadData];
}

- (void)showTabButtonReddot {
//    _haveNewMessag = show;
    [NSUserDefaults setBoolInStandardUserDefaults:_haveNewMessag forKey:@"RedDotMessageBoxViewController"];
    _tabButton.isRedDot = _haveNewMessag;
}
#endif

- (void)dealloc
{
#ifdef IMPORT_LETUIM_H
    [[NSNotificationCenter defaultCenter] removeObserver:self name:LETUMESSAGE_SAVEDMESSAGE object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kReachabilityChangedNotification object:nil];
#else
    [newFriendTimer invalidate];
    newFriendTimer=nil;
#endif
}
- (void)clickRightButton:(UIButton *)button
{
    ContactPersonsViewController *vc= [[ContactPersonsViewController alloc]init];
    [self.navigationController pushViewController:vc animated:YES];
}
- (void)initViews
{
    
    
    //联系人按钮
    /*
    contactPersonBtn= [UIButton buttonWithType:UIButtonTypeCustom];
    contactPersonBtn.frame = CGRectMake(320-88, 0, 88, 88);
    contactPersonBtn.backgroundColor = [UIColor yellowColor];
    [contactPersonBtn setImage:[UIImage imageNamed:@"message1_icon_profile"] forState:UIControlStateNormal];
    //    [contactPersonBtn setImage:[UIImage imageNamed:@"ic_coach_top_add_btn_cur"] forState:UIControlStateHighlighted];
    [contactPersonBtn addTarget:self action:@selector(buttonEvents:) forControlEvents:UIControlEventTouchUpInside];
    contactPersonBtn.tag=1;
    [self.view addSubview:contactPersonBtn];
     //*/
    
    tipLabel = [[UILabel alloc]initWithFrame:CGRectMake(298, 0, 22.5f, 22.5f)];
    tipLabel.textAlignment = UITextAlignmentCenter;
    tipLabel.textColor = [UIColor whiteColor];
    [self.view addSubview:tipLabel];
    tipLabel.hidden = YES;
    
    CGFloat tableH=[[UIScreen mainScreen]bounds].size.height-20-44-49;
    //消息列表
    mTableView = [[TableView alloc] initWithFrame:CGRectMake(0, 44, 320, tableH)];
    mTableView.backgroundColor = [UIColor clearColor];
    mTableView.dataSource = self;
    mTableView.delegate = self;
    //    mTableView.refreshDelegate = self;
    mTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    //    [mTableView addMoreView];
    
#ifdef IMPORT_LETUIM_H
#else
    [mTableView addRefreshView];
    mTableView.refreshDelegate = self;
#endif
    //    [mTableView addRefreshView];
    [self.view addSubview:mTableView];
    
    
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
#ifdef IMPORT_LETUIM_H
    return _lastMessageList.count;
#else
    return mTableView.tableArray.count;
    //    return 10;
    
#endif
    
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 60;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = nil;
    if (cell == nil)
    {
        cell=[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    //    MessageModel *model = [mTableView.tableArray objectAtIndex:indexPath.row];
    
    
    UIView *itemView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 60)];
    
    
    //删除按钮
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.tag = 2;
    button.frame = CGRectMake(491/2, 0, 74, 60);
    [button setImage:[UIImage imageNamed:@"contacts_btn_cancel_normal"] forState:UIControlStateNormal];
    [button setImage:[UIImage imageNamed:@"contacts_btn_cancel_current"] forState:UIControlStateHighlighted];
    [button addTarget:self action:@selector(buttonEvents:) forControlEvents:UIControlEventTouchUpInside];
    [itemView addSubview:button];
    
    
    UIImage *contentBG = [UIImage imageNamed:@"message1_itemlist_normal"];
    
    UIView *contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 60)];
    contentView.tag = indexPath.row;
    [contentView setBackgroundColor:[UIColor colorWithPatternImage:contentBG]];
    
    
    UITapGestureRecognizer *tapGes = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(selectItem:)];
    swipeGes = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(selectItem:)];
    swipeGes.direction = UISwipeGestureRecognizerDirectionLeft;
    
    [contentView addGestureRecognizer:tapGes];
    [contentView addGestureRecognizer:swipeGes];
    
    
    
    
    //头像
    EGOImageView *headimageView = [[EGOImageView alloc] init];
    headimageView.frame = CGRectMake(7, 12, 41, 41);
    //    headimageView.imageURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@",SERVERImageURL,[model userPhoto]]];
    //    [headimageView setImage:[UIImage imageNamed:@"message1_photo"]];
    [contentView addSubview:headimageView];
    
    
    
    //name
    UILabel * nameLabel =[[UILabel alloc]initWithFrame:CGRectMake(58, 18 -8, 180, 20)];
    nameLabel.backgroundColor=[UIColor clearColor];
    nameLabel.textColor=[Utility colorWithHexString:@"#222222"];
    nameLabel.font = [UIFont fontWithName:@"Arial" size:16];
    //    nameLabel.text=[model targetName];
    //    nameLabel.text=@"Blue";
    [contentView addSubview:nameLabel];
    
    
    
    
    //content
    UILabel * contentLab =[[UILabel alloc]initWithFrame:CGRectMake(57, 38 -5, 200, 20)];
    contentLab.backgroundColor=[UIColor clearColor];
    contentLab.textColor=[Utility colorWithHexString:@"#666666"];
    contentLab.font = [UIFont fontWithName:@"Arial" size:13];
    //    contentLab.text=[model content];
    //    contentLab.text=@"一起旅行吧...";
    [contentView addSubview:contentLab];
    
    
    //time
    UILabel * timeLabel =[[UILabel alloc]initWithFrame:CGRectMake(240, 25, 120, 15)];
    timeLabel.backgroundColor=[UIColor clearColor];
    timeLabel.textColor=[Utility colorWithHexString:@"#999999"];
    timeLabel.font = [UIFont fontWithName:@"Arial" size:11];
    //      timeLabel.text=[DateUtil intervalSinceNow:model.createdDate];
    //    timeLabel.text=@"30分钟前";
    [contentView addSubview:timeLabel];
    
#ifdef IMPORT_LETUIM_H
    LeTuLastMessage *msg = _lastMessageList[indexPath.row];
    LeTuUser *chatWith = msg.chatWith;
    if (chatWith.userPhoto && chatWith.userName && chatWith.userId) {
        [[LeTuIM sharedInstance] userInfomationWithLoginName:chatWith.name];
    }
    NSString *name = (chatWith.userName) ? chatWith.userName : chatWith.loginName;
    
    contentLab.text=msg.body;
    nameLabel.text = name;
    headimageView.imageURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@",SERVERImageURL, chatWith.userPhoto]];
    
    timeLabel.text=[NSDate dateTimeStringSinceNow:msg.receivedDate];
#else
    MessageModel *model = [mTableView.tableArray objectAtIndex:indexPath.row];
    headimageView.imageURL = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@",SERVERImageURL,[model userPhoto]]];
    nameLabel.text=[model targetName];
    contentLab.text=[model content];
    timeLabel.text=[DateUtil intervalSinceNow:model.createdDate];
#endif
    
    [cell addSubview:itemView];
    [itemView addSubview:contentView];
    cell.tag = indexPath.row;
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    return cell;
}



- (TableView *) getTableView
{
    return mTableView;
}

//开始移动
- (void)scrollViewWillBeginDecelerating:(UIScrollView *)sv
{
    TableView *tb = [self getTableView];
    if (tb)
    {
        [tb scrollViewWillBeginDecelerating:sv];
    }
}

//下拉table
- (void)scrollViewDidScroll:(UIScrollView *)sv
{
    TableView *tb = [self getTableView];
    if (tb)
    {
        [tb scrollViewDidScroll:sv];
    }
}

//刷新table  当scrollView 停止滚动拖动
- (void)scrollViewDidEndDragging:(UIScrollView *)sv willDecelerate:(BOOL)decelerate{
    TableView *tb = [self getTableView];
    
    if (tb)
    {
        [tb scrollViewDidEndDragging:sv];
    }
}

- (void)selectItem:(UIGestureRecognizer *)ges
{
    UIView *selectView = ges.view;
    if ([ges isKindOfClass:[UITapGestureRecognizer class]])
    {
        if (isOpen)
        {
            [UIView animateWithDuration:0.1 animations:^{
                selectView.center = CGPointMake(selectView.center.x + 74, selectView.center.y);
            } completion:^(BOOL finished) {
                
            }];
            isOpen=NO;
            
            
            [selectView removeGestureRecognizer:swipeGes];
            swipeGes = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(selectItem:)];
            swipeGes.direction = UISwipeGestureRecognizerDirectionLeft;
            [selectView addGestureRecognizer:swipeGes];
            
            if (timer==nil)
            {
                //开启线程
                timer=[NSTimer scheduledTimerWithTimeInterval:3
                                                       target:self
                                                     selector:@selector(timerForGetNewMessage)
                                                     userInfo:nil
                                                      repeats:YES];
            }
            
            
        }
        else
        {
            
            selectView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"message1_itemlist_current"]];
            
            int Index = selectView.tag;
            //            if([[UIDevice currentDevice].systemVersion intValue]>=7.0)
            //            {
            //                Index= selectView.superview.superview.superview.tag;
            //            }
            //            Index = selectView.superview.superview.tag;
            
            //            MessageModel *model = [mTableView.tableArray objectAtIndex:Index];
            
            //跳转到聊天窗口
            ChatViewController *vc= [[ChatViewController alloc]init];
#ifdef IMPORT_LETUIM_H
            LeTuLastMessage *msg = _lastMessageList[Index];
            vc.titleString = msg.chatWith.userName;
            vc.buddy = msg.chatWith;
#warning showTabButtonReddot
#else
            MessageModel *model = [mTableView.tableArray objectAtIndex:Index];
            
            vc.titleString=model.targetName;
            vc.targetType=model.targetType;
            vc.targetId=model.targetId;
#endif
            [self.navigationController pushViewController:vc animated:YES];
            
            
            
        }
        
    }
    else
    {
        UISwipeGestureRecognizer *swGes = (UISwipeGestureRecognizer *)ges;
        if (swGes.direction == UISwipeGestureRecognizerDirectionLeft)
        {
            
            //暂停线程
            
            [timer invalidate];
            timer=nil;
            
            isOpen=YES;
            swGes.direction = UISwipeGestureRecognizerDirectionRight;
            [UIView animateWithDuration:0.1 animations:^{
                selectView.center = CGPointMake(selectView.center.x - 74, selectView.center.y);
            } completion:^(BOOL finished) {
                
            }];
            
            
            
            
            
        }
        else
        {
            isOpen=NO;
            swGes.direction = UISwipeGestureRecognizerDirectionLeft;
            [UIView animateWithDuration:0.1 animations:^{
                selectView.center = CGPointMake(selectView.center.x + 74, selectView.center.y);
            } completion:^(BOOL finished) {
                
            }];
            
            if (timer==nil)
            {
                //开启线程
                timer=[NSTimer scheduledTimerWithTimeInterval:3
                                                       target:self
                                                     selector:@selector(timerForGetNewMessage)
                                                     userInfo:nil
                                                      repeats:YES];
            }
            
            
            
        }
    }
}



//点击事件
- (void)buttonEvents:(UIButton *)button
{
    switch (button.tag)
    {
            // 联系人页面
        case 1:
        {
            ContactPersonsViewController *vc= [[ContactPersonsViewController alloc]init];
            [self.navigationController pushViewController:vc animated:YES];
            break;
        }
            
            // 删除
        case 2:
        {
            
            //没有网络删除不了对象
            if(![Utility connectedToNetwork])
            {
                [self messageShow:@"请检查您的网络"];
            }
            //有网络时
            else
            {
#ifdef IMPORT_LETUIM_H
                int msgIndex = button.superview.superview.tag;
                if([[UIDevice currentDevice].systemVersion intValue]>=7.0)
                    msgIndex= button.superview.superview.superview.tag;
                
                LeTuLastMessage *msg = _lastMessageList[msgIndex];
                [LeTuMessage deleteBuddyMessageWithBuddyName:msg.chatWith.name];
#else
                
                int delIndex;
                if([[UIDevice currentDevice].systemVersion intValue]>=7.0)
                {
                    delIndex= button.superview.superview.superview.tag;
                }
                delIndex = button.superview.superview.tag;
                MessageModel *model = [mTableView.tableArray objectAtIndex:delIndex];
                [self DelMessageTarget:model];
                
#endif
            }
            break;
        }
            
            
        default:
            break;
    }
}


-(void)DelMessageTarget:(MessageModel*)model
{
    NSString *requestURL = [NSString stringWithFormat:
                            @"%@ms/messageService.jws?clear&&l_key=%@&targetType=%@&targetId=%@",SERVERAPIURL,[UserDefaultsHelper getStringForKey:@"key"],model.targetType,model.targetId];
    
    NSLog(@"APIUrl---%@",requestURL);
    
    if (queue == nil ){
        queue = [[ NSOperationQueue alloc ] init ];
    }
    
    RequestParseOperation * operation=[[RequestParseOperation alloc] initWithURLString:requestURL delegate:self ];
    operation.RequestTag = 333;
    
    [queue addOperation :operation]; // 开始处理
}

-(void)GetNewFriendRequestCount
{
    NSString *requestURL = [NSString stringWithFormat:
                            @"%@ms/friendService.jws?checkNewApply&l_key=%@",SERVERAPIURL,[UserDefaultsHelper getStringForKey:@"key"]];
    
    NSLog(@"APIUrl---%@",requestURL);
    
    if (queue == nil ){
        queue = [[ NSOperationQueue alloc ] init ];
    }
    
    RequestParseOperation * operation=[[RequestParseOperation alloc] initWithURLString:requestURL delegate:self ];
    operation.RequestTag = 444;
    
    [queue addOperation :operation]; // 开始处理
}

-(void)reponseDatas:(NSDictionary *)data operationTag:(NSInteger)tag
{
    switch (tag)
    {
        case 333:
        {
            NSDictionary *errDict = [data objectForKey:@"error"];
            int errCode = [[errDict objectForKey:@"err_code"] intValue];
            if (errCode == 0 || errCode == 1)
            {
                [self reloadRefreshDataSource:0];
            }
            break;
        }
        case 444:
        {
            NSDictionary *errDict = [data objectForKey:@"error"];
            int errCode = [[errDict objectForKey:@"err_code"] intValue];
            if (errCode == 0 || errCode == 1)
            {
                //                if ([[dict objectForKey:@"obj"] objectForKey:@"newFriendCount"] || [[[dict objectForKey:@"obj"] objectForKey:@"newFriendCount"] isKindOfClass:[NSArray class]])
                if ([[data objectForKey:@"obj"] objectForKey:@"newApplyCount"]!=nil&&![[[data objectForKey:@"obj"] objectForKey:@"newApplyCount"] isKindOfClass:[NSNull class]])
                {
                    int count=[[[data objectForKey:@"obj"] objectForKey:@"newApplyCount"]intValue];
                    
                    DTButton *button = [self.appDelegate.tabBar.buttonArray objectAtIndex:1];
                    if (count == 0)
                    {
#ifdef IMPORT_LETUIM_H
                        button.isRedDot = NO || _haveNewMessag;
#else
                        button.isRedDot = NO;
#endif
                        
                        tipLabel.hidden = YES;
                        contactPersonBtn.frame = CGRectMake(286, 9, 24, 24.5);
                    }
                    else
                    {
                        button.isRedDot = YES;
                        
                        tipLabel.hidden = NO;
                        UIImage *tipImgBg = [UIImage imageNamed:count>9?@"2unit":@"1unit"];
                        if (count < 10)
                        {
                            contactPersonBtn.frame = CGRectMake(280, 9, 24, 24.5);
                            tipLabel.frame = CGRectMake(298, 0, 22.5f, 22.5f);
                        }
                        else
                        {
                            contactPersonBtn.frame = CGRectMake(267, 9, 24, 24.5);
                            tipLabel.frame = CGRectMake(285, 0, 38.5f, 22.5f);
                        }
                        tipLabel.backgroundColor = [UIColor colorWithPatternImage:tipImgBg];
                        tipLabel.text = [NSString stringWithFormat:@"%d", count];
                    }
                }
                dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 10 * NSEC_PER_SEC);
                dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
                    [self GetNewFriendRequestCount];
                });
                
            }
            break;
        }
        default:
            break;
    }
    
    
    
}

- (void)reponseFaild:(NSInteger)tag
{
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, 10 * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self GetNewFriendRequestCount];
    });
}

//获取消息记录
- (void)reloadRefreshDataSource:(int)pageIndex
{
    //没有网络获取数据库最新缓存数据
    if(![Utility connectedToNetwork])
    {
        
        
        //暂停线程
        
        [timer invalidate];
        timer=nil;
        [self getCacheData];
        
        
        
    }
    //有网络时
    else
    {
        //刷新时暂停线程
        [timer invalidate];
        timer=nil;
        NSString *requestURL = [NSString stringWithFormat:@"%@ms/messageService.jws?lastestList&&",SERVERAPIURL] ;
        NSURL *url = [NSURL URLWithString:requestURL];
        NSLog(@"APIUrl---%@",url);
        ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
        [request setPostValue:[UserDefaultsHelper getStringForKey:@"key"] forKey:@"l_key"];
        [request setTag:111];
        [request buildPostBody];
        [request setDelegate:self];
        [request setTimeOutSeconds:240];
        [request startAsynchronous];
        
    }
}

-(void)timerForGetNewMessage
{
    
    //没有网络获取数据库最新缓存数据
    if(![Utility connectedToNetwork])
    {
        //暂停线程
        
        [timer invalidate];
        timer=nil;
        [self getCacheData];
    }
    
    else
    {
        
        NSString *requestURL = [NSString stringWithFormat:@"%@ms/messageService.jws?lastestList&&",SERVERAPIURL] ;
        NSURL *url = [NSURL URLWithString:requestURL];
        NSLog(@"APIUrl---%@",url);
        ASIFormDataRequest *request = [ASIFormDataRequest requestWithURL:url];
        [request setPostValue:[UserDefaultsHelper getStringForKey:@"key"] forKey:@"l_key"];
        [request setTag:222];
        [request buildPostBody];
        [request setDelegate:self];
        [request setTimeOutSeconds:240];
        [request startAsynchronous];
        
    }
    
}





- (void)requestFinished:(ASIHTTPRequest *)request
{
    // Use when fetching text data
    NSString *responseString = [request responseString];
    
    NSLog(@"-responseString--%@-----",responseString);
    
    NSError *error = [request error];
    if (!error)
    {
        
        switch (request.tag)
        {
            case 111:
            {
                
                
                [self loadData:responseString Request:request];
                
                if (timer==nil)
                {
                    //开启线程
                    timer=[NSTimer scheduledTimerWithTimeInterval:3
                                                           target:self
                                                         selector:@selector(timerForGetNewMessage)
                                                         userInfo:nil
                                                          repeats:YES];
                    
                }
                
            }
                
                break;
            case 222:
            {
                
                [self loadData:responseString Request:request];
                
            }
                break;
                
            default:
                break;
        }
    }
    
}


-(void)loadData:(NSString*)responseString Request:(ASIHTTPRequest *)request
{
    
    
    CacheSql *cacheSql = [[CacheSql alloc] init];
    if ([cacheSql getNewMessageJson]!=nil&&[[cacheSql getNewMessageJson] isEqualToString:responseString])
    {
        //与数据库相同
        [self getCacheData];
    }
    else
    {
        
        BOOL result=[self updateDatabaseData:responseString];
        
        if (result)
        {
            //显示
            JSONDecoder *decoder=[JSONDecoder decoder];
            NSDictionary *dict=[decoder objectWithData:request.responseData];
            
            NSDictionary *errDict=[dict objectForKey:@"error"];
            int errCode=[[errDict objectForKey:@"err_code"] intValue];
            if(errCode==0||errCode==1)
            {
                
                [mTableView.tableArray removeAllObjects];
                
                NSArray *datas = [dict objectForKey:@"list"];
                
                for (NSDictionary *dict in datas)
                {
                    MessageModel *model = [[MessageModel alloc] initWithDataDict:dict];
                    [mTableView.tableArray addObject:model];
                }
                
                [mTableView reload:datas.count];
                
            }
            
        }
        
        
    }
    
    
}


- (void)requestFailed:(ASIHTTPRequest *)request
{
    
    NSError *error = [request error];
    
    [self getCacheData];
    
    
    
}




-(BOOL)updateDatabaseData:(NSString*)json
{
    
    //先删除，然后新增
    CacheSql *cacheSql = [[CacheSql alloc] init];
    bool flag=YES;
    BOOL result=[cacheSql DelAllNewMessage];
    if (result)
    {
        flag =[cacheSql AddNewMessage:json];
    }
    return flag;
    
}

-(void)getCacheData
{
    
    //获取离线最新显示
    CacheSql *cacheSql=[[CacheSql alloc]init];
    NSString *json=[cacheSql getNewMessageJson];
    if (json!=nil||![json isEqualToString:@""])
    {
        [mTableView.tableArray removeAllObjects];
        
        NSArray *datas =[[json JSONValue]objectForKey:@"list"];
        
        for (NSDictionary *dict in datas)
        {
            MessageModel *model = [[MessageModel alloc] initWithDataDict:dict];
            [mTableView.tableArray addObject:model];
        }
        
        [mTableView reload:datas.count];
        
    }
    
}



- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
