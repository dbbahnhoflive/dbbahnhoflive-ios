// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//


#import "MBSingleParkingOverviewViewController.h"
#import "MBParkingOccupancyManager.h"
#import "MBUrlOpening.h"
#import "MBUIHelper.h"

@interface MBSingleParkingOverviewViewController ()<UIScrollViewDelegate>

@property(nonatomic,strong) UIScrollView* contentScrollView;

@property(nonatomic,strong) UIImageView* parkingAllocation;
@property(nonatomic,strong) UILabel *allocationLabel;

@property(nonatomic,strong) UIRefreshControl *refreshControl;

@property(atomic) BOOL isRefreshing;
@property(nonatomic) NSInteger calculatedContentHeight;

@end

@implementation MBSingleParkingOverviewViewController

#define spacing 43

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.titleLabel.text = self.title;

    self.contentScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, self.headerView.sizeHeight, self.contentView.sizeWidth, self.contentView.sizeHeight-self.headerView.sizeHeight)];
    [self.contentView addSubview:self.contentScrollView];
    self.contentView.backgroundColor = [UIColor whiteColor];
    self.headerView.backgroundColor = [UIColor db_HeaderColor];
    self.headerView.layer.shadowOffset = CGSizeMake(1.0, 2.0);
    self.headerView.layer.shadowColor = [[UIColor db_dadada] CGColor];
    self.headerView.layer.shadowRadius = 1.5;
    self.headerView.layer.shadowOpacity = 1.0;

    int y = 16;
    
    if(self.showTarif){
        //tarif
        y = [self addTitle:@"" withText:@"Alle Angaben in EUR, inkl. MwSt." atY:y];
        
        if(self.parking.tarifNotes.length > 0){
            y = [self addTitle:@"Hinweis: " withText:self.parking.tarifNotes atY:y];
        }
        if(self.parking.tarifDiscount.length > 0){
            y = [self addTitle:@"Rabatt: " withText:self.parking.tarifDiscount atY:y];
        }
        if(self.parking.tarifSpecial.length > 0){
            y = [self addTitle:@"Sondertarif: " withText:self.parking.tarifSpecial atY:y];
        }
        if(self.parking.paymentTypes.length > 0){
            y = [self addTitle:@"Zahlungsmittel: " withText:self.parking.paymentTypes atY:y];
        }

        if(self.parking.tarifFreeParkTime.length > 1){
            //NOTE: >1 because string can contain "N" meaning there is no free parking
            NSString* header = @"Frei Parken: ";
            y = [self addTitle:header withText:self.parking.tarifFreeParkTime atY:y];
        }
        
        NSArray* tarifList = self.parking.tarifPricesList;
        for(NSArray* tarif in tarifList){
            NSString* key = tarif.firstObject;
            NSString* val = tarif.lastObject;
            y = [self addTitle:[NSString stringWithFormat:@"%@: ",key] withText:val atY:y];
        }


        
        
        
    } else {
        //details overview
        UIImage* icon = nil;
        if(icon && !self.parking.isOutOfOrder){
            
            self.contentScrollView.delegate = self;
            
            UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
            self.refreshControl = refreshControl;
            [self.contentScrollView addSubview:refreshControl];
            
            self.contentScrollView.alwaysBounceVertical = YES;
            
            //allocation status
            UIImageView* parkingAllocation = [[UIImageView alloc] initWithFrame:CGRectMake(spacing, y, 63,15)];
            self.parkingAllocation = parkingAllocation;
            [self.contentScrollView addSubview:parkingAllocation];
            
            int labelx = spacing+self.parkingAllocation.sizeWidth+5;
            UILabel *allocationLabel =  [[UILabel alloc] initWithFrame:CGRectMake(labelx, parkingAllocation.frame.origin.y, self.view.frame.size.width-labelx-spacing, 16)];
            self.allocationLabel = allocationLabel;
            allocationLabel.font = [UIFont db_RegularTen];
            allocationLabel.textColor = [UIColor db_646973];
            [self.contentScrollView addSubview:allocationLabel];
            
            self.parkingAllocation.image = icon;
            self.allocationLabel.text = [self.parking textForAllocation];
            
            y = CGRectGetMaxY(allocationLabel.frame)+30;
        }
        
        y = [self addTitle:@"Zufahrt: " withText:self.parking.accessDescription atY:y];
        y = [self addTitle:@"Zufahrt (Details): " withText:self.parking.accessDetailsDay atY:y];
        y = [self addTitle:@"Zufahrt (Nachts): " withText:self.parking.accessDetailsNight atY:y];
        y = [self addTitle:@"Öffnungszeiten: " withText:self.parking.openingTimes atY:y];
        y = [self addTitle:@"Maximale Parkdauer: " withText:self.parking.maximumParkingTime atY:y];
        y = [self addTitle:@"Nächster Bahnhofseingang: " withText:self.parking.distanceToStation atY:y];
        y = [self addTitle:@"Austattung: " withText:self.parking.equipment atY:y];
        y = [self addTitle:@"Stellplätze: " withText:self.parking.numberOfParkingSpaces atY:y];
        y = [self addTitle:@"Stellplätze Behindertengerecht: " withText:self.parking.numberOfParkingSpacesHandicapped atY:y];
        y = [self addTitle:@"Eltern-Kind Stellplätze: " withText:self.parking.numberOfParkingSpacesParentChild atY:y];
        y = [self addTitle:@"Stellplätze für Frauen: " withText:self.parking.numberOfParkingSpacesWoman atY:y];
        y = [self addTitle:@"Betreiber: " withText:self.parking.operatorCompany atY:y];
        

    }
    self.calculatedContentHeight = y;
    self.contentScrollView.contentSize = CGSizeMake(self.contentScrollView.frame.size.width, y);
}

-(void)configureButton:(UIButton*)button{
    button.backgroundColor = [UIColor db_GrayButton];
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [button.titleLabel setFont:[UIFont db_BoldEighteen]];
    button.width = self.contentScrollView.frame.size.width-16*2;
    button.height = 60;
    [button centerViewVerticalInSuperView];
    [button centerViewHorizontalInSuperView];
    button.layer.cornerRadius = button.frame.size.height / 2.0;
    button.layer.shadowOffset = CGSizeMake(1.0, 2.0);
    button.layer.shadowColor = [[UIColor db_dadada] CGColor];
    button.layer.shadowRadius = 1.5;
    button.layer.shadowOpacity = 1.0;
}




-(void)scrollViewDidScroll:(UIScrollView *)scrollView{
    if(!self.refreshControl){
        return;
    }
    
    //NSLog(@"didScroll: %f",scrollView.contentOffset.y);
    if(!self.isRefreshing && scrollView.isDragging){
        if(scrollView.contentOffset.y < -80){
            // NSLog(@"start refresh");
            self.isRefreshing = YES;
            [self.refreshControl beginRefreshing];
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                
                dispatch_group_t group = dispatch_group_create();

                if(self.parking.hasPrognosis){
                    NSString* num = self.parking.idValue;
                    // NSLog(@"request occupancy for id %@",num);
                    dispatch_group_enter(group);
                    
                    [[MBParkingOccupancyManager client] requestParkingOccupancy:num success:^(NSNumber *allocationCategory) {
                        //update allocationCategory
                        self.parking.allocationCategory = allocationCategory;
                        
                        // NSLog(@"request occupancy done for id %@",num);
                        dispatch_group_leave(group);
                        
                    } failureBlock:^(NSError *error) {
                        //ignore
                        // NSLog(@"request occupancy failed for id %@, %@",num,error);
                        dispatch_group_leave(group);
                    }];
                    
                }
                
                dispatch_group_notify(group, dispatch_get_main_queue(), ^{
                    [self.contentScrollView setContentOffset:CGPointZero animated:YES];
                    self.isRefreshing = NO;
                    [self.refreshControl endRefreshing];
                    
                    UIImage* icon = self.parking.iconForAllocation;
                    self.parkingAllocation.image = icon;
                    self.allocationLabel.text = [self.parking textForAllocation];
                    
                    // NSLog(@"refresh end");
                });
                
            });
        }
    } else if(self.isRefreshing){
        self.contentScrollView.contentOffset = CGPointMake(0, -80);
    }
}


-(int)addTitle:(NSString*)title withText:(NSString*)text atY:(int)y{
    if(text.length == 0){
        return y;
    }
    UILabel *label = [UILabel new];
    label.text = title;
    label.font = [UIFont db_BoldFourteen];
    label.textColor = UIColor.db_333333;

    CGSize maxSize = CGSizeMake(self.contentView.frame.size.width - 32.0, CGFLOAT_MAX);
    CGSize wrappedSize = [label sizeThatFits:maxSize];
    label.frame = CGRectMake(16.0, y, wrappedSize.width, wrappedSize.height);
    [self.contentScrollView addSubview:label];
    y = label.frame.origin.y + label.frame.size.height + 8;
    
    UILabel *label2 = [UILabel new];
    label2.text = text;
    label2.numberOfLines = 0;
    label2.font = [UIFont db_RegularFourteen];
    label2.textColor = UIColor.db_333333;

    maxSize = CGSizeMake(self.contentView.frame.size.width - 32.0, CGFLOAT_MAX);
    wrappedSize = [label2 sizeThatFits:maxSize];
    label2.frame = CGRectMake(16.0, y, wrappedSize.width, wrappedSize.height);
    [self.contentScrollView addSubview:label2];
    return label2.frame.origin.y + label2.frame.size.height + 16;
}

-(void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    //resize view for content

    UIEdgeInsets safeArea = self.view.safeAreaInsets;
    CGSize size = self.contentScrollView.contentSize;
    size.height = self.calculatedContentHeight+safeArea.bottom;
    self.contentScrollView.contentSize = size;

    int totalHeight = MIN(self.view.sizeHeight-40, self.contentScrollView.contentSize.height+self.headerView.sizeHeight);
    [self.contentView setHeight:totalHeight];
    [self.contentView setGravityBottom:0];
    self.contentScrollView.frame = CGRectMake(0, self.headerView.sizeHeight, self.contentView.sizeWidth, self.contentView.sizeHeight-self.headerView.sizeHeight);

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)didInteractWithURL:(NSURL *)url
{
    [MBUrlOpening openURL:url];
}

@end
