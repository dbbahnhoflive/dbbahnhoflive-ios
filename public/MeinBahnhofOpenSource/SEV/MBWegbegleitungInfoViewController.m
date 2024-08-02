// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//

#import "MBWegbegleitungInfoViewController.h"
#import "UIView+Frame.h"
#import "UIColor+DBColor.h"
#import "UIImage+MBImage.h"
#import "MBTextView.h"
#import "MBExpandableHeaderButton.h"
#import "MBUrlOpening.h"

@interface MBWegbegleitungInfoViewController ()<MBTextViewDelegate>
@property(nonatomic,strong) UIScrollView* contentScrollView;
@property(nonatomic,strong) UIView* iconBackground;
@property(nonatomic,strong) MBTextView* textView;
@property(nonatomic,strong) MBExpandableHeaderButton* header1;
@property(nonatomic,strong) MBTextView* subtextView1;
@property(nonatomic,strong) MBExpandableHeaderButton* header2;
@property(nonatomic,strong) MBTextView* subtextView2;

@end

@implementation MBWegbegleitungInfoViewController

-(instancetype)initWithStation:(MBStation *)station{
    self = [super init];
    self.station = station;
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = UIColor.whiteColor;
    self.title = @"So funktioniert DB Wegbegleitung";
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Zurück" style:UIBarButtonItemStyleDone target:self action:@selector(closeInfoView)];
    self.contentScrollView = [UIScrollView new];
    [self.view addSubview:self.contentScrollView];
    
    UIView* iconBackground = [UIView new];
    self.iconBackground = iconBackground;
    iconBackground.backgroundColor = [UIColor db_grayBackgroundColor];
    [self.contentScrollView addSubview:iconBackground];
    UIImageView *iconView = [[UIImageView alloc] initWithImage:[UIImage db_imageNamed:@"SEV_Icon"]];
    iconView.contentMode = UIViewContentModeScaleAspectFit;
    [iconView setSize:CGSizeMake(60, 300)];
    [iconBackground addSubview:iconView];
    
    self.textView = [[MBTextView alloc] init];
    self.textView.delegado = self;
    [self.textView setHtmlString:@"<p>Starten Sie Ihren Videoanruf am Bahnhof und lassen Sie sich von unserem geschulten Personal zu Ihrer Ersatzhaltestelle begleiten.</p><p>Um den Anruf zu starten, müssen Sie die <b>Kamera</b>, das <b>Mikrofon</b> und den <b>Standort</b> auf Ihrem Gerät freigeben. Ansonsten kann der Anruf nicht gestartet werden.</p><p>Bleiben Sie sich Ihrer eigenen Fähigkeiten bewusst und verlassen Sie sich stets auf Ihre eigenen Sinne. Mehr dazu erfahren Sie unter <a href=\"https://wegbegleitung.deutschebahn.com/bahnhof-live/static/legal-notice\">Nutzungsbedingungen</a>.</p><p>Der Service ist <b>täglich von 7:00 bis 19:00 Uhr</b> erreichbar.</p>"];
    [self.contentScrollView addSubview:self.textView];
    
    self.header1 = [[MBExpandableHeaderButton alloc] initWithText:@"Liste der Bahnhöfe"];
    self.header2 = [[MBExpandableHeaderButton alloc] initWithText:@"Infos zu den Berechtigungen"];
    self.subtextView1 = [[MBTextView alloc] init];
    NSMutableString* list = [NSMutableString new];
    [list appendString:@"<p>"];
    for(NSString* name in self.station.accompanimentStationsTitles){
        [list appendFormat:@"%@<br>",name];
    }
    [list appendString:@"</p>"];
    [self.subtextView1 setHtmlString:list];
    self.subtextView2 = [[MBTextView alloc] init];
    self.subtextView2.delegado = self;
    [self.subtextView2 setHtmlString:@"<p>Wenn Sie den Videoanruf zum ersten Mal starten, werden nacheinander die Berechtigungen für die <b>Kamera</b>, das <b>Mikrofon</b> und den <b>Standort</b> abgefragt.</p><p>Die Berechtigungen können auch über die <a href=\"settings://location\">Einstellungen</a> der App Bahnhof live angepasst werden.</p><p>Sie können die <b>DB Wegbegleitung</b> auch über <a href=\"https://db.de/wegbegleitung\">db.de/wegbegleitung</a> im mobilen Browser nutzen.</p>"];
    [self.contentScrollView addSubview:self.header1];
    [self.contentScrollView addSubview:self.header2];
    self.subtextView1.hidden = true;
    self.subtextView2.hidden = true;
    [self.contentScrollView addSubview:self.subtextView1];
    [self.contentScrollView addSubview:self.subtextView2];
    [self.header1 addTarget:self action:@selector(openSection:) forControlEvents:UIControlEventTouchUpInside];
    [self.header2 addTarget:self action:@selector(openSection:) forControlEvents:UIControlEventTouchUpInside];
}

-(void)didInteractWithURL:(NSURL *)url{
    if ([url.scheme isEqualToString:@"settings"]) {
        [MBUrlOpening openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
    } else {
        [MBUrlOpening openURL:url];
    }
}

-(void)openSection:(MBExpandableHeaderButton*)button{
    button.isExpanded = !button.isExpanded;
    if(button == self.header1){
        self.subtextView1.hidden = !button.isExpanded;
    } else {
        self.subtextView2.hidden = !button.isExpanded;
    }
    [self.view setNeedsLayout];
}

-(void)closeInfoView{
    [self.navigationController.presentingViewController dismissViewControllerAnimated:true completion:nil];
}

- (void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    self.contentScrollView.frame = CGRectMake(0, 0, self.view.sizeWidth, self.view.sizeHeight);
    self.iconBackground.frame = CGRectMake(0, 0, self.contentScrollView.sizeWidth, 100);
    [self.iconBackground.subviews.firstObject centerViewInSuperView];
    NSInteger space = 20;
    NSInteger w = self.view.sizeWidth-2*space;
    [self.textView setGravityTop:120];
    [self.textView setGravityLeft:space];
    [self.textView resizeForWidth:w];

    [self.header1 setGravityLeft:space];
    [self.header1 setWidth:self.view.sizeWidth-2*space];
    [self.subtextView1 resizeForWidth:w];
    [self.subtextView2 resizeForWidth:w];
    [self.header2 setGravityLeft:space];
    [self.header2 setWidth:self.view.sizeWidth-2*space];

    NSInteger y = CGRectGetMaxY(self.textView.frame)+space;
    [self.header1 setGravityTop:y];
    y = CGRectGetMaxY(self.header1.frame)+space;
    if(self.header1.isExpanded){
        [self.subtextView1 setGravityTop:y];
        [self.subtextView1 setGravityLeft:space];
        y = CGRectGetMaxY(self.subtextView1.frame)+space;
    }
    if(self.header2 != nil){
        [self.header2 setGravityTop:y];
        y = CGRectGetMaxY(self.header2.frame)+space;
        if(self.header2.isExpanded){
            [self.subtextView2 setGravityTop:y];
            [self.subtextView2 setGravityLeft:space];
            y = CGRectGetMaxY(self.subtextView2.frame)+space;
        }
    }
    self.contentScrollView.contentSize = CGSizeMake(self.contentScrollView.sizeWidth, y);
}

@end
