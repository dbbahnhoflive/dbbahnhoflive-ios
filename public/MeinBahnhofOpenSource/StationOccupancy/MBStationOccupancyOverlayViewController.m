// SPDX-FileCopyrightText: 2020 DB Station&Service AG <bahnhoflive-opensource@deutschebahn.com>
//
// SPDX-License-Identifier: Apache-2.0
//

#import "MBStationOccupancyOverlayViewController.h"
#import "MBUrlOpening.h"
#import "MBUIHelper.h"

@interface MBStationOccupancyOverlayViewController ()
@property(nonatomic,strong) UIScrollView* contentScrollView;

@end

@implementation MBStationOccupancyOverlayViewController

- (void)viewDidLoad {
    [super viewDidLoad];
        
    self.title = @"Besucheraufkommen";
    self.titleLabel.text = self.title;

    self.contentScrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, self.headerView.sizeHeight, self.contentView.sizeWidth, self.contentView.sizeHeight-self.headerView.sizeHeight)];
    [self.contentView addSubview:self.contentScrollView];
    
    NSInteger y = 16+20;
    
    NSArray* texts = @[
    @"Weniger Besucher als üblich",@"Vor Ort ist aktuell mit weniger Besuchern als gewöhnlich zu rechnen. In der Regel ist das Besucheraufkommen zu dieser Uhrzeit an diesem Wochentag höher.",
    @"Übliches Besucheraufkommen",@"Die Anzahl der Besucher vor Ort entspricht dem gewöhnlichen Besucheraufkommen zu dieser Uhrzeit an diesem Wochentag.",
    @"Mehr Besucher als üblich",@"Vor Ort ist aktuell mit mehr Besuchern als gewöhnlich zu rechnen. In der Regel ist das Besucheraufkommen zu dieser Uhrzeit an diesem Wochentag geringer.",
    @"Hinweise",@"Bitte beachten Sie: Diese Info-Grafik gibt Auskunft über das aktuelle Besucheraufkommen im Vergleich zum durchschnittlichen Besucheraufkommen der vergangenen acht Wochen. Für diese Grafik werden Näherungswerte errechnet und keine absoluten Zahlen verwendet. Folglich sind Abweichungen zum tatsächlichen Besucheraufkommen vor Ort möglich. Diese Grafik gibt außerdem keine Auskunft hinsichtlich des Besucheraufkommens im Verhältnis zu den räumlichen Kapazitäten vor Ort. Alle Angaben sind ohne Gewähr.",
    ];
    for(NSInteger i=0; i<texts.count; ){
        NSString* header = texts[i++];
        NSString* body = texts[i++];
        UILabel* headerLabel = [UILabel new];
        headerLabel.text = header;
        headerLabel.font = [UIFont db_BoldFourteen];
        headerLabel.textColor = UIColor.blackColor;
        headerLabel.numberOfLines = 0;
        CGSize size = [headerLabel sizeThatFits:CGSizeMake(self.view.frame.size.width-2*20, 5000)];
        [headerLabel setSize:size];
        [self.contentScrollView addSubview:headerLabel];
        [headerLabel setY:y];
        [headerLabel setX:20];
        y += headerLabel.sizeHeight + 5;
        
        UILabel* bodyLabel = [UILabel new];
        bodyLabel.numberOfLines = 0;
        NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
        paragraphStyle.lineSpacing = 6;
        bodyLabel.attributedText = [[NSAttributedString alloc] initWithString:body attributes:@{
            NSParagraphStyleAttributeName:paragraphStyle,
            NSForegroundColorAttributeName:UIColor.blackColor,
            NSFontAttributeName:[UIFont db_RegularFourteen]
        }];
        
        size = [bodyLabel sizeThatFits:CGSizeMake(self.view.frame.size.width-2*20, 5000)];
        [bodyLabel setSize:size];
        [self.contentScrollView addSubview:bodyLabel];
        [bodyLabel setY:y];
        [bodyLabel setX:20];
        y += bodyLabel.sizeHeight + 25;

    }
    y += 20;
    self.contentScrollView.contentSize = CGSizeMake(self.contentScrollView.frame.size.width, y);
}

-(void)viewDidLayoutSubviews{
    [super viewDidLayoutSubviews];
    //resize view for content
    int totalHeight = MIN(self.view.sizeHeight-40, self.contentScrollView.contentSize.height+self.headerView.sizeHeight);
    [self.contentView setHeight:totalHeight];
    [self.contentView setGravityBottom:0];
    self.contentScrollView.frame = CGRectMake(0, self.headerView.sizeHeight, self.contentView.sizeWidth, self.contentView.sizeHeight-self.headerView.sizeHeight);
}

@end
