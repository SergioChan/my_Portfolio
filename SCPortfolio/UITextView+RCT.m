//
//  UITextView+RCT.m
//  SCPortfolio
//
//  Created by chen Yuheng on 15/9/4.
//  Copyright (c) 2015年 chen Yuheng. All rights reserved.
//

#import "UITextView+RCT.h"

#define SCRemoveElementIndex @"SCRemoveElementIndex"
#define SCRemoveElementLength @"SCRemoveElementLength"

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
        if([[self.text substringWithRange:NSMakeRange(i, 4)] isEqualToString:@"[b/]"] || [[self.text substringWithRange:NSMakeRange(i, 4)] isEqualToString:@"[i/]"])
        {
            [elementsIndexToRemove addObject:[NSDictionary dictionaryWithObjects:@[@(i),@(4)] forKeys:@[SCRemoveElementIndex,SCRemoveElementLength]]];
            temp_start_index = i;
        }
        else if([[self.text substringWithRange:NSMakeRange(i, 4)] isEqualToString:@"[/b]"])
        {
            [elementsIndexToRemove addObject:[NSDictionary dictionaryWithObjects:@[@(i),@(4)] forKeys:@[SCRemoveElementIndex,SCRemoveElementLength]]];
            [t_string setAttributes:[NSDictionary dictionaryWithObjects:@[[UIFont fontWithName:@"TimesNewRomanPS-BoldMT" size:self.font.pointSize + 2.0f],[UIColor blackColor]] forKeys:@[NSFontAttributeName,NSForegroundColorAttributeName]] range:NSMakeRange(temp_start_index, i - temp_start_index)];
            temp_start_index = 0;
        }
        else if([[self.text substringWithRange:NSMakeRange(i, 4)] isEqualToString:@"[/i]"])
        {
            NSString *imageName = [self.text substringWithRange:NSMakeRange(temp_start_index + 4, i - temp_start_index - 4)];
            NSTextAttachment *textAttachment = [[NSTextAttachment alloc] initWithData:nil ofType:nil] ;
            textAttachment.image = [UIImage imageNamed:imageName];
            textAttachment.bounds = CGRectMake(0.0f, 0.0f, 160.0f, 300.0f);
            NSAttributedString *textAttachmentString = [NSAttributedString attributedStringWithAttachment:textAttachment] ;
            [t_string insertAttributedString:textAttachmentString atIndex:temp_start_index + 4];
            [elementsIndexToRemove addObject:[NSDictionary dictionaryWithObjects:@[@(temp_start_index + 4 + textAttachmentString.length),@(imageName.length)] forKeys:@[SCRemoveElementIndex,SCRemoveElementLength]]];
            [elementsIndexToRemove addObject:[NSDictionary dictionaryWithObjects:@[@(i + textAttachmentString.length),@(4)] forKeys:@[SCRemoveElementIndex,SCRemoveElementLength]]];
            temp_start_index = 0;
        }
    }
    
    NSInteger offset = 0;
    for(NSInteger i=0;i<elementsIndexToRemove.count;i++)
    {
        NSDictionary *ele_to_remove = [elementsIndexToRemove objectAtIndex:i];
        [t_string replaceCharactersInRange:NSMakeRange([[ele_to_remove objectForKey:SCRemoveElementIndex] integerValue] - offset, [[ele_to_remove objectForKey:SCRemoveElementLength] integerValue]) withString:@""];
        offset += [[ele_to_remove objectForKey:SCRemoveElementLength] integerValue];
    }
    
    self.attributedText = t_string;
}
@end
