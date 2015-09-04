//
//  ViewController.m
//  SCPortfolio
//
//  Created by chen Yuheng on 15/9/4.
//  Copyright (c) 2015年 chen Yuheng. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
@property (strong,nonatomic) NSMutableArray *dataArray;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    NSString *path = [[NSBundle mainBundle] pathForResource:@"content" ofType:@"plist"];
    self.dataArray = [[NSMutableArray alloc]initWithContentsOfFile:path];
    
    UPCardsCarousel *carousel = [[UPCardsCarousel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    [carousel setAutoresizingMask:UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth];
    [carousel setDelegate:self];
    [carousel setDataSource:self];
    [self.view addSubview:carousel];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - CardsCarouselDataSource

- (NSUInteger)numberOfCardsInCarousel:(UPCardsCarousel *)carousel
{
    return self.dataArray.count;
}

- (UIView*)carousel:(UPCardsCarousel *)carousel viewForCardAtIndex:(NSUInteger)index
{
    
    return [self createCardViewWithLabel:(NSDictionary *)[self.dataArray objectAtIndex:index]];
}

#pragma mark - Helpers

- (UIView*)createCardViewWithLabel:(NSDictionary*)contentDict
{
    SCCardView *cardView = [[SCCardView alloc] initWithFrame:CGRectMake(0, 0, 280, 500) withContentDict:contentDict];
    return cardView;
}

@end
