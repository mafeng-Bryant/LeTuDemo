//
//  MyselfDetailCell.m
//  LeTu
//
//  Created by DT on 14-5-20.
//
//

#import "MyselfDetailCell.h"
#import "MJPhotoBrowser.h"
#import "MJPhoto.h"

@interface MyselfDetailCell()
@property(nonatomic,strong)UIImageView *arrowImage;
@end

@implementation MyselfDetailCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        
        self.keyLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        self.keyLabel.backgroundColor = [UIColor clearColor];
        self.keyLabel.textColor = RGBCOLOR(54.0, 54.0, 54.0);
        self.keyLabel.font = [UIFont systemFontOfSize:17.0f];
        [self addSubview:self.keyLabel];
        
        self.valueLabel = [[UILabel alloc] initWithFrame:CGRectMake(220, 7, 200, 30)];
        self.valueLabel.backgroundColor = [UIColor clearColor];
        self.valueLabel.textColor = [UIColor blackColor];
        self.valueLabel.font = [UIFont systemFontOfSize:15.0f];
//        self.valueLabel.text = @"我们要一起很开心的一起去旅游呀。。。";
        [self addSubview:self.valueLabel];
        
        self.lineImage = [[UIImageView alloc] initWithFrame:CGRectZero];
        self.lineImage.image = [UIImage imageNamed:@"posting_line"];
        self.lineImage.alpha = 0.8;
        [self addSubview:self.lineImage];
        
        self.arrowImage = [[UIImageView alloc] initWithFrame:CGRectZero];
        self.arrowImage.image = [UIImage imageNamed:@"me_headphoto_copy_icon"];
        [self addSubview:self.arrowImage];
        

        
    }
    return self;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
}
- (void)setKey:(NSString *)key
{
    self.keyLabel.text = key;
}
- (void)setValue:(NSString *)value
{
    self.valueLabel.text = value;
}
- (void)setArrowHide:(BOOL)arrowHide
{
    self.arrowImage.hidden = arrowHide;
}
- (void)setFaceUrl:(NSString *)faceUrl
{
    NSLog(@"%@",faceUrl);
    
    _faceUrl = faceUrl;
  
    self.headImgView= [[UIImageView alloc] initWithFrame:CGRectMake(230, 5, 50, 50)];
    self.headImgView.userInteractionEnabled = YES;
    self.headImgView.layer.masksToBounds = NO;
    self.headImgView.clipsToBounds = YES;
    self.headImgView.layer.cornerRadius =25.0;
    

    
    //测试的.
    [self.headImgView setImageWithURL:[NSURL URLWithString:faceUrl] placeholderImage:PLACEHOLDER];
    
    //正式的
   // [self.headImgView setImageWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@", SERVERImageURL, faceUrl]] placeholderImage:PLACEHOLDER];
    
    UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapHandle:)];
    self.headImgView.userInteractionEnabled = YES;
    [self.headImgView addGestureRecognizer:gesture];
    [self addSubview:self.headImgView];
    
}

- (void)layoutSubviews
{
    self.backgroundColor = [UIColor whiteColor];
    if (isIOS7) {
        self.keyLabel.frame = CGRectMake(15, (self.frame.size.height-30)/2, 65, 30);
        self.arrowImage.frame = CGRectMake(296, (self.frame.size.height-13)/2, 9, 13);
        self.lineImage.frame = CGRectMake(10, self.frame.size.height-1, 300, 1);
    }else{
        self.keyLabel.frame = CGRectMake(15, (self.frame.size.height-30)/2, 60, 30);
        self.arrowImage.frame = CGRectMake(296, (self.frame.size.height-13)/2, 9, 13);
        self.lineImage.frame = CGRectMake(10, self.frame.size.height-1, 300, 1);
    }
}

- (void)tapHandle:(UITapGestureRecognizer *)tap
{
    // 1.封装图片数据
    /*
    NSMutableArray *photos = [NSMutableArray arrayWithCapacity:1];

    MJPhoto *photo = [[MJPhoto alloc] init];
    photo.url = [NSURL URLWithString:[NSString stringWithFormat:@"%@%@", SERVERImageURL, _faceUrl]]; // 图片路径
    UIImageView * imageView = self.headImgView;
    photo.srcImageView = imageView;
    [photos addObject:photo];

    // 2.显示相册
    MJPhotoBrowser *browser = [[MJPhotoBrowser alloc] init];
    browser.photos = photos; // 设置所有的图片
    browser.currentPhotoIndex =  0; // 弹出相册时显示的第一张图片是？
    [browser show];
     //*/
    [self showBigImage:[NSString stringWithFormat:@"%@%@", SERVERImageURL, _faceUrl] imageView:self.headImgView];
}
/**
 *  显示大图
 *
 *  @param urlString 图片路径
 *  @param imageView 图片imageView
 */
-(void)showBigImage:(NSString*)urlString imageView:(UIImageView*)imageView
{
    // 1.封装图片数据
    NSMutableArray *photos = [NSMutableArray arrayWithCapacity:1];
    
    MJPhoto *photo = [[MJPhoto alloc] init];
    photo.url = [NSURL URLWithString:urlString]; // 图片路径
//    UIImageView * imageView = self.headImgView;
    photo.srcImageView = imageView;
    [photos addObject:photo];
    
    // 2.显示相册
    MJPhotoBrowser *browser = [[MJPhotoBrowser alloc] init];
    browser.photos = photos; // 设置所有的图片
    browser.currentPhotoIndex =  0; // 弹出相册时显示的第一张图片是？
    [browser show];
}
@end
