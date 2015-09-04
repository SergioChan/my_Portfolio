//
//  UITextView+RCT.m
//  SCPortfolio
//
//  Created by chen Yuheng on 15/9/4.
//  Copyright (c) 2015年 chen Yuheng. All rights reserved.
//

#import "UITextView+RCT.h"

@implementation UITextView(RCT)
- (void)rct_attributed
{
    NSMutableAttributedString *t_string = [[NSMutableAttributedString alloc]initWithString:self.text];
    [t_string setAttributes:[NSDictionary dictionaryWithObjects:@[[UIFont systemFontOfSize:self.font.pointSize],self.textColor] forKeys:@[NSFontAttributeName,NSForegroundColorAttributeName]] range:NSMakeRange(0, self.text.length)];
    if(self.text.length < 7)
    {
        return;
    }
    
    NSMutableArray *elementsIndexToRemove = [[NSMutableArray alloc]init];
    
    NSInteger temp_start_index = 0;
    for(NSInteger i=0;i<self.text.length - 4;i++)
    {
        if([[self.text substringWithRange:NSMakeRange(i, 4)] isEqualToString:@"[b/]"])
        {
            [elementsIndexToRemove addObject:@(i)];
            temp_start_index = i;
        }
        else if([[self.text substringWithRange:NSMakeRange(i, 4)] isEqualToString:@"[/b]"])
        {
            [elementsIndexToRemove addObject:@(i)];
            [t_string setAttributes:[NSDictionary dictionaryWithObjects:@[[UIFont fontWithName:@"TimesNewRomanPS-BoldMT" size:self.font.pointSize + 2.0f],[UIColor blackColor]] forKeys:@[NSFontAttributeName,NSForegroundColorAttributeName]] range:NSMakeRange(temp_start_index, i - temp_start_index)];
            temp_start_index = 0;
        }
    }
    
    NSInteger offset = 0;
    for(NSInteger i=0;i<elementsIndexToRemove.count;i++)
    {
        [t_string replaceCharactersInRange:NSMakeRange([[elementsIndexToRemove objectAtIndex:i] integerValue] - offset, 4) withString:@""];
        offset += 4;
    }
    
    self.attributedText = t_string;
}
@end
