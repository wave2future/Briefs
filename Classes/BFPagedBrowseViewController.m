//
//  BFPagedBrowseViewController.m
//  Briefs
//
//  Created by Rob Rhyne on 3/19/10.
//  Copyright Digital Arch Design, 2009-2010. See LICENSE file for details.


#import "BFPagedBrowseViewController.h"

@interface BFPagedBrowseViewController (PrivateMethods)

- (CGFloat)totalWidthOfScrollView;
- (CGFloat)widthOfPage:(UIScrollView *)scrollView;
- (CGPoint)pageOriginAtIndex:(NSInteger)index;
- (CGFloat)fractionalPageAtCurrentScroll:(UIScrollView *)scrollView;

- (void)applyNewIndex:(NSInteger)newIndex pageController:(BFPreviewBriefViewController *)pageController;
- (BOOL)isPageAlreadyAssigned:(NSInteger)index;
- (BFPreviewBriefViewController *)findFarthestFromIndex:(NSInteger)index;


@end



@implementation BFPagedBrowseViewController
@synthesize dataSource, pages;


///////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark UIViewController methods

- (id)initWithDataSource:(id<BFBriefDataSource>)ref
{
    if (self = [super initWithNibName:@"BFPagedBrowseViewController" bundle:nil]) {
        dataSource = ref;
    }
    
    return self;
}

- (void)viewDidLoad 
{
    [super viewDidLoad];
    
    self.title = @"Briefs";
    
    // Initialize page views
    self.pages = [NSMutableArray arrayWithCapacity:3];
    for (int i=0; i < 3; i++) {
        BFPreviewBriefViewController *controller = [[BFPreviewBriefViewController alloc] init];
        controller.dataSource = dataSource;
        [pagedHorizontalView addSubview:controller.view];
        
        [self.pages addObject:controller];
        [controller release];
    }
    
    
    // Expand Scroll View to accomodate all records
    pagedHorizontalView.contentSize = CGSizeMake([self totalWidthOfScrollView], pagedHorizontalView.frame.size.height);
	
    // Initialize the controls
    pagedHorizontalView.contentOffset = CGPointMake(0, 0);
    pagedHorizontalView.clipsToBounds = NO;
    pagedHorizontalView.showsHorizontalScrollIndicator = NO;
	pageControl.numberOfPages = [dataSource numberOfRecords];
	pageControl.currentPage = 0;
	
    // load initial pages
    int pagesToLoad = ([dataSource numberOfRecords] >= 3) ? 3 : [dataSource numberOfRecords];
    for (int index=0; index < pagesToLoad; index++) {
        [self applyNewIndex:index pageController:[self.pages objectAtIndex:index]];
    }
}

- (void)viewDidUnload 
{
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}

- (void)dealloc 
{
    [self.pages release];
    [super dealloc];
}



- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}


///////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark UIScrollView Delegate methods

- (void)scrollViewDidScroll:(UIScrollView *)sender
{
	CGFloat currentPageAsFraction = [self fractionalPageAtCurrentScroll:pagedHorizontalView];
    
	NSInteger lowerLimit = floor(currentPageAsFraction);
	NSInteger upperLimit = lowerLimit + 1;
    
    if (![self isPageAlreadyAssigned:lowerLimit])
        [self applyNewIndex:lowerLimit pageController:[self findFarthestFromIndex:lowerLimit]];
    
    if (![self isPageAlreadyAssigned:upperLimit]) 
        [self applyNewIndex:upperLimit pageController:[self findFarthestFromIndex:upperLimit]];
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)newScrollView
{
    CGFloat currentPageAsFraction = [self fractionalPageAtCurrentScroll:pagedHorizontalView];
    currentIndex = lround(currentPageAsFraction);
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)newScrollView
{
    [self scrollViewDidEndScrollingAnimation:newScrollView];
    pageControl.currentPage = currentIndex;
}

///////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Scrolling Utility methods

- (void)applyNewIndex:(NSInteger)newIndex pageController:(BFPreviewBriefViewController *)pageController
{
	NSInteger pageCount = [dataSource numberOfRecords];
	BOOL outOfBounds = newIndex >= pageCount || newIndex < 0;
    
	if (!outOfBounds) {
        pageController.view.alpha = 0.0f;
        
        CGRect pageFrame = pageController.view.frame;
		pageFrame.origin = [self pageOriginAtIndex:newIndex];
		pageController.view.frame = pageFrame;
        
        // Fade the view in
        [UIView beginAnimations:@"fade PageController" context:nil];
        pageController.view.alpha = 1.0f;
	}
    
	else {
        // Fade the view out
        [UIView beginAnimations:@"fade PageController" context:nil];
        pageController.view.alpha = 0.0f;
    }
    
    
    [UIView commitAnimations];
    pageController.pageIndex = newIndex;
}

- (IBAction)changePage:(id)sender
{
	NSInteger pageIndex = pageControl.currentPage;
    
	// update the scroll view to the appropriate page
    CGRect frame = pagedHorizontalView.frame;
    frame.origin = [self pageOriginAtIndex:pageIndex];
    [pagedHorizontalView scrollRectToVisible:frame animated:YES];
}

///////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark Private methods

- (CGFloat)totalWidthOfScrollView
{
    NSInteger totalNumberOfPages = ([dataSource numberOfRecords] < 1) ? 1 : [dataSource numberOfRecords];
    return (pagedHorizontalView.frame.size.width) * totalNumberOfPages;
}

- (CGFloat)widthOfPage:(UIScrollView *)scrollView
{
    return scrollView.frame.size.width;
}

- (CGPoint)pageOriginAtIndex:(NSInteger)index
{
    return CGPointMake((pagedHorizontalView.frame.size.width) * index + 20.0f, 0);
}

- (CGFloat)fractionalPageAtCurrentScroll:(UIScrollView *)scrollView
{
    return scrollView.contentOffset.x / [self widthOfPage:scrollView];
}

- (BOOL)isPageAlreadyAssigned:(NSInteger)index
{
    for (BFPreviewBriefViewController *controller in self.pages) {
        if (controller.pageIndex == index)
            return YES;
    }
    
    return NO;
}

- (BFPreviewBriefViewController *)findFarthestFromIndex:(NSInteger)index
{
    BFPreviewBriefViewController *farthestFrom;
    int distanceToIndex = 0;
    for (BFPreviewBriefViewController *controller in self.pages) {
        int distance = abs(controller.pageIndex - index);
        if (distance > distanceToIndex) {
            distanceToIndex = distance;
            farthestFrom = controller;
        }
    }
    
    return farthestFrom;
}


///////////////////////////////////////////////////////////////////////////////

@end
