//
//  SCCardView.m
//  SCPortfolio
//
//  Created by chen Yuheng on 15/9/4.
//  Copyright (c) 2015年 chen Yuheng. All rights reserved.
//

#import "SCCardView.h"
#import "NSString+FontAwesome.h"
#import "UITextView+RCT.h"

@implementation SCCardView


- (id)initWithFrame:(CGRect)frame withContentDict:(NSDictionary *)contentDict
{
    self = [super initWithFrame:frame];
    if(self)
    {
        [self setBackgroundColor:[UIColor whiteColor]];
        [self.layer setShadowColor:[UIColor blackColor].CGColor];
        [self.layer setShadowOpacity:0.5f];
        [self.layer setShadowOffset:CGSizeMake(0.0f, 0.0f)];
        [self.layer setBorderColor:[UIColor whiteColor].CGColor];
        [self.layer setBorderWidth:10.0f];
        [self.layer setCornerRadius:4.0f];
        
        UILabel *labelView = [[UILabel alloc] initWithFrame:CGRectMake(10.0f, 10.0f, 260.0f, 23.0f)];
        [labelView setFont:[UIFont boldSystemFontOfSize:20.0f]];
        [labelView setTextAlignment:NSTextAlignmentLeft];
        [labelView setTextColor:[UIColor blackColor]];
        [labelView setText:[contentDict objectForKey:@"title"]];
        [self addSubview:labelView];
        
        UITextView *contentView = [[UITextView alloc] initWithFrame:CGRectMake(10.0f, 40.0f, 260.0f, 450.0f)];
        contentView.font = [UIFont systemFontOfSize:15.0f];
        contentView.editable = NO;
        contentView.text = [contentDict objectForKey:@"content"];
        contentView.textColor = [UIColor darkGrayColor];
        contentView.scrollEnabled = NO;
        [contentView rct_attributed];
        [self addSubview:contentView];
        
        if([[contentDict objectForKey:@"title"] isEqualToString:@"More"])
        {
            id github  = [NSString fontAwesomeIconStringForEnum:FAGithubSquare];
            UIButton *githubBtn = [[UIButton alloc]initWithFrame:CGRectMake(10.0f, self.frame.size.height - 60.0f, 40.0f, 40.0f)];
            [githubBtn setTitle:github forState:UIControlStateNormal];
            githubBtn.titleLabel.font = [UIFont fontWithName:kFontAwesomeFamilyName size:40.0f];
            [githubBtn setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
            [githubBtn addTarget:self action:@selector(githubGo) forControlEvents:UIControlEventTouchUpInside];
            [self addSubview:githubBtn];
            
            id linkedIn = [NSString fontAwesomeIconStringForEnum:FALinkedinSquare];
            UIButton *linkedInBtn = [[UIButton alloc]initWithFrame:CGRectMake(60.0f, self.frame.size.height - 60.0f, 40.0f, 40.0f)];
            [linkedInBtn setTitle:linkedIn forState:UIControlStateNormal];
            linkedInBtn.titleLabel.font = [UIFont fontWithName:kFontAwesomeFamilyName size:40.0f];
            [linkedInBtn setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
            [linkedInBtn addTarget:self action:@selector(linkedInGo) forControlEvents:UIControlEventTouchUpInside];
            [self addSubview:linkedInBtn];
        }
    }
    return self;
}

- (void)githubGo
{
    NSURL *url= [NSURL URLWithString:@"https://github.com/SergioChan"];
    [[UIApplication sharedApplication] openURL:url];
}

- (void)linkedInGo
{
    NSURL *url= [NSURL URLWithString:@"https://cn.linkedin.com/pub/sergio-chan/42/14b/a6"];
    [[UIApplication sharedApplication] openURL:url];
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
