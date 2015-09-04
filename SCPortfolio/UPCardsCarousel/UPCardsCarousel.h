//
//  UPCardsCarousel.h
//  UPCardsCarousel
//
//  Created by Paul ULRIC on 08/06/2014.
//  Copyright (c) 2014 Paul ULRIC. All rights reserved.
//

#import <UIKit/UIKit.h>



typedef enum {
    UPCardsCarouselLabelBannerLocation_bottom = 0,
    UPCardsCarouselLabelBannerLocation_top
} UPCardsCarouselLabelBannerLocation_e;


@protocol UPCardsCarouselDataSource, UPCardsCarouselDelegate;


@interface UPCardsCarousel : UIView

@property (nonatomic, unsafe_unretained) IBOutlet id<UPCardsCarouselDataSource> dataSource;
@property (nonatomic, unsafe_unretained) IBOutlet id<UPCardsCarouselDelegate> delegate;

@property (nonatomic, readwrite) NSUInteger maxVisibleCardsCount;
@property (nonatomic, readwrite) NSTimeInterval movingAnimationDuration;
@property (nonatomic, readwrite) BOOL doubleTapToTop;

@property (nonatomic, strong)    UIView *labelBanner;
@property (nonatomic, readwrite) UPCardsCarouselLabelBannerLocation_e labelBannerPosition;


/* Reloads the carousel data and recreates the visible cards
 * Moves to the top of the cards deck */
- (void)reloadData;
/* Reloads the carousel data and recreates the visible cards
 * Moves to the specified index in the cards deck */
- (void)reloadDataWithCurrentIndex:(NSUInteger)index;
/* Reloads only the number of cards in the carousel
 * Doesn't change the visible cards */
- (void)reloadNumberOfCards;
/* Recreates the card at the specified index */
- (void)reloadCardAtIndex:(NSUInteger)index;

- (UIView*)cardAtIndex:(NSUInteger)index;

- (void)setLabelFont:(UIFont *)font;
- (void)setLabelTextColor:(UIColor*)color;

@end


@protocol UPCardsCarouselDataSource <NSObject>

@required
- (NSUInteger)numberOfCardsInCarousel:(UPCardsCarousel *)carousel;
- (UIView *)carousel:(UPCardsCarousel *)carousel viewForCardAtIndex:(NSUInteger)index;

@optional
/* If the data source doesn't implement this method, the label banner will not be displayed */
- (NSString *)carousel:(UPCardsCarousel *)carousel labelForCardAtIndex:(NSUInteger)index;

@end


@protocol UPCardsCarouselDelegate <NSObject>

@optional
- (void)carousel:(UPCardsCarousel *)carousel didTouchCardAtIndex:(NSUInteger)index;
- (void)carousel:(UPCardsCarousel *)carousel willDisplayCardAtIndex:(NSUInteger)index;
- (void)carousel:(UPCardsCarousel *)carousel willHideCardAtIndex:(NSUInteger)index;
- (void)carousel:(UPCardsCarousel *)carousel didDisplayCardAtIndex:(NSUInteger)index;
- (void)carousel:(UPCardsCarousel *)carousel didHideCardAtIndex:(NSUInteger)index;

@end
