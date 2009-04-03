//
//  L0DraggableView.m
//  Shard
//
//  Created by ∞ on 21/03/09.
//  Copyright 2009 Emanuele Vulcano. All rights reserved.
//

#import "L0DraggableView.h"

static inline BOOL L0VectorHasPointWithinAbsolute(CGPoint vector, CGFloat rangeAbs) {
	return
	ABS(vector.x) < rangeAbs && ABS(vector.y) < rangeAbs;
}

static inline CGFloat L0ClampToMaximumAbsolute(CGFloat value, CGFloat maximumAbs) {
	maximumAbs = ABS(maximumAbs);
	
	if (value > maximumAbs)
		value = maximumAbs;
	else if (value < -maximumAbs)
		value = -maximumAbs;
	
	return value;
}

static inline CGFloat L0ClampToMinimumAbsolute(CGFloat value, CGFloat maximumAbs) {
	maximumAbs = ABS(maximumAbs);
	
	if (value < maximumAbs && value > 0)
		value = maximumAbs;
	else if (value > -maximumAbs && value < 0)
		value = -maximumAbs;
	
	return value;
}

#pragma mark -
#pragma mark L0DraggableView private methods

@interface L0DraggableView ()

- (void) _beginDraggingWithTouch:(UITouch*) t;
- (void) _moveByDraggingWithTouch:(UITouch*) t;
- (void) _endDraggingWithTouch:(UITouch*) t;

@end

#pragma mark -
#pragma mark L0DraggableView itself

@implementation L0DraggableView

- (void)dealloc {
	[dragStartDate release];
    [super dealloc];
}

#pragma mark -
#pragma mark L0DraggableView dragging methods

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
{
	[self _beginDraggingWithTouch:[touches anyObject]];
}

- (void) _beginDraggingWithTouch:(UITouch*) t;
{
	if (delegate && [delegate respondsToSelector:@selector(draggableViewShouldBeginDragging:)]) {
		BOOL go = [delegate draggableViewShouldBeginDragging:self];
		if (!go) return;
	}
	
	dragging = YES;
	lastLocation = [t locationInView:self.superview];
	lastSpeedRecordingLocation = lastLocation;
	dragStartDate = [NSDate new];
	lastSpeedRecordingIntervalSinceStartOfDrag = 0;
	
	self.center = self.center; // stops animation.
	
	if (delegate && [delegate respondsToSelector:@selector(draggableViewDidBeginDragging:)]) 
		[delegate draggableViewDidBeginDragging:self];
	
	[self performSelector:@selector(_recordSpeed) withObject:nil afterDelay:0.05];	
}

- (void) _recordSpeed;
{
	lastSpeedRecordingLocation = lastLocation;
	lastSpeedRecordingIntervalSinceStartOfDrag = -[dragStartDate timeIntervalSinceNow];
	
	L0Log(@"speed = %@, interval since start = %f", NSStringFromCGPoint(lastSpeedRecordingLocation), lastSpeedRecordingIntervalSinceStartOfDrag);
	
	[self performSelector:@selector(_recordSpeed) withObject:nil afterDelay:0.2];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event;
{
	[self _moveByDraggingWithTouch:[touches anyObject]];
}

- (void) _moveByDraggingWithTouch:(UITouch*) t;
{
	if (!dragging) return;
	
	CGPoint newLocation = [t locationInView:self.superview];
	
	CGFloat deltaX = newLocation.x - lastLocation.x;
	CGFloat deltaY = newLocation.y - lastLocation.y;
	
	CGPoint center = self.center;
	center.x += deltaX;
	center.y += deltaY;
	
	self.center = center;
	
	if (delegate && delegateImplementsDidDragToPoint)
		[delegate draggableView:self didDragToPoint:center];
	
	lastLocation = newLocation;	
}

#define kL0DraggableViewMinimumMovementSpeedIn100MSForSlide 7.0

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event;
{
	[self _endDraggingWithTouch:[touches anyObject]];
}

- (void) _endDraggingWithTouch:(UITouch*) t;
{
	if (!dragging) return;
	
	dragging = NO;
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_recordSpeed) object:nil];
	
	NSAssert(self.superview != nil, @"No events should be received without a superview.");
	CGPoint here = [t locationInView:self.superview];
	
	CGPoint movementVector;
	movementVector.x = here.x - lastSpeedRecordingLocation.x;
	movementVector.y = here.y - lastSpeedRecordingLocation.y;
	
	NSTimeInterval movementTime = (-[dragStartDate timeIntervalSinceNow]) - lastSpeedRecordingIntervalSinceStartOfDrag;
	[dragStartDate release];
	dragStartDate = nil;
	
	CGPoint speedPointsPer100MS;
	speedPointsPer100MS.x = (movementVector.x / movementTime) * 0.1;
	speedPointsPer100MS.y = (movementVector.y / movementTime) * 0.1;
	
	BOOL continuesWithSlide = !L0VectorHasPointWithinAbsolute(speedPointsPer100MS, kL0DraggableViewMinimumMovementSpeedIn100MSForSlide);
	
	if (delegate && [delegate respondsToSelector:@selector(draggableViewDidEndDragging:continuesWithSlide:)])
		[delegate draggableViewDidEndDragging:self continuesWithSlide:continuesWithSlide];
	
	if (!continuesWithSlide) {
		// Determine attraction.
		if (delegate && [delegate respondsToSelector:@selector(draggableView:shouldMoveFromPoint:toAttractionPoint:)]) {
			
			CGPoint to;
			BOOL shouldMove = [delegate draggableView:self shouldMoveFromPoint:self.center toAttractionPoint:&to];
			
			if (shouldMove) {
				[UIView beginAnimations:nil context:NULL];
				[UIView setAnimationDelegate:self];
				[UIView setAnimationDidStopSelector:@selector(_attractionAnimation:didEndByFinishing:context:)];
				
				[UIView setAnimationDuration:1.2];
				[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
				self.center = to;
				
				[UIView commitAnimations];
			}
		}
		
		// No slide? Return.
		return;
	}
	
	// ===========
	// == SLIDE ==
	// ===========
	
#define kL0DraggableViewSpeedDampeningFactor 0.45
#define kL0DraggableViewMaximumSlideDistanceX 150.0
#define kL0DraggableViewMaximumSlideDistanceY 350.0
	CGPoint delta = movementVector;
	int timeScale = 1;
	while (!L0VectorHasPointWithinAbsolute(movementVector, 5.0)) {
		movementVector.x *= kL0DraggableViewSpeedDampeningFactor;
		movementVector.y *= kL0DraggableViewSpeedDampeningFactor;
		
		delta.x += movementVector.x;
		delta.y += movementVector.y;
		
		timeScale++;
		
		if (ABS(delta.x) > kL0DraggableViewMaximumSlideDistanceX || 
			ABS(delta.y) > kL0DraggableViewMaximumSlideDistanceY)
			break;
	}
	
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
	[UIView setAnimationBeginsFromCurrentState:YES];
	[UIView setAnimationDuration:movementTime * timeScale];
	
	if (delegate) {
		L0Log(@"delegate is %@, so setting up animation delegate/stop selector for slide.", delegate);
		[UIView setAnimationDelegate:self];
		[UIView setAnimationDidStopSelector:@selector(_slideAnimation:didEndByFinishing:context:)];
	}
	L0LogIf(!delegate, @"no delegate set");
	
	CGPoint center = self.center;
	center.x += delta.x;
	center.y += delta.y;
	
	// ~~~~~~~~~~~~~~~
	
	if (delegate && [delegate respondsToSelector:@selector(draggableView:willBeginInertialSlideToPoint:)])
		[delegate draggableView:self willBeginInertialSlideToPoint:center];
	
	
	if (delegate && [delegate respondsToSelector:@selector(draggableView:shouldMoveFromPoint:toAttractionPoint:)]) {
		CGPoint to;
		BOOL shouldMove = [delegate draggableView:self shouldMoveFromPoint:center toAttractionPoint:&to];
		
		if (shouldMove) {
			// TODO two-part "curve" animation for long attractions
			center = to;
		}
	}
	
	self.center = center;
	
	[UIView commitAnimations];	
}

- (void) _slideAnimation:(NSString*) name didEndByFinishing:(BOOL) finished context:(void*) nothing;
{
	L0Log(@"%@, finished = %d", self, finished);
	
	if (delegate && [delegate respondsToSelector:@selector(draggableView:didEndInertialSlideByFinishing:)])
		[delegate draggableView:self didEndInertialSlideByFinishing:finished];
}

- (void) _attractionAnimation:(NSString*) name didEndByFinishing:(BOOL) finished context:(void*) nothing;
{
	L0Log(@"%@, finished = %d", self, finished);
	
	if (delegate && [delegate respondsToSelector:@selector(draggableView:didEndAttractionByFinishing:)])
		[delegate draggableView:self didEndAttractionByFinishing:finished];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event;
{
	if (dragging) {
		dragging = NO;
		if (delegate && [delegate respondsToSelector:@selector(draggableViewDidEndDragging:continuesWithSlide:)])
			[delegate draggableViewDidEndDragging:self continuesWithSlide:NO];
	}
}

@synthesize delegate;
- (void) setDelegate:(id <L0DraggableViewDelegate>) d;
{
	delegate = d;
	delegateImplementsDidDragToPoint = [d respondsToSelector:@selector(draggableView:didDragToPoint:)];
}

@end
