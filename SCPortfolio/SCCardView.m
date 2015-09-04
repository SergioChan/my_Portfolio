//
//  SCCardView.m
//  SCPortfolio
//
//  Created by chen Yuheng on 15/9/4.
//  Copyright (c) 2015年 chen Yuheng. All rights reserved.
//

#import "SCCardView.h"

@implementation SCCardView


- (id)initWithFrame:(CGRect)frame withContentDict:(NSDictionary *)contentDict
{
    self = [super initWithFrame:frame];
    if(self)
    {
        [self setBackgroundColor:[UIColor whiteColor]];
        [self.layer setShadowColor:[UIColor blackColor].CGColor];
        [self.layer setShadowOpacity:.5];
        [self.layer setShadowOffset:CGSizeMake(0, 0)];
        [self.layer setBorderColor:[UIColor whiteColor].CGColor];
        [self.layer setBorderWidth:10.];
        [self.layer setCornerRadius:4.];
        
        UILabel *labelView = [[UILabel alloc] initWithFrame:CGRectMake(10.0f, 10.0f, 260.0f, 20.0f)];
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
        [self addSubview:contentView];
    }
    return self;
}
/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
