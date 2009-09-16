//
//  L0DraggableView.m
//  Shard
//
//  Created by ∞ on 21/03/09.
//  Copyright 2009 Emanuele Vulcano. All rights reserved.
//

#if TARGET_OS_IPHONE

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

- (void) _beginPressingWithTouch:(UITouch*) t;
- (BOOL) _tryEndingPressWithTouch:(UITouch*) t;
- (void) _detectPressAndHold;
- (void) _detectPressUp;

- (void) performDraggableViewInitialization;

@end

#pragma mark -
#pragma mark L0DraggableView itself

#define kL0DraggableViewDefaultMaximumSlideDistance 150.0
#define kL0DraggableViewDefaultSpeedDampeningFactor 0.50

@implementation L0DraggableView

- (id) initWithFrame:(CGRect) frame;
{
	if (self = [super initWithFrame:frame])
		[self performDraggableViewInitialization];
	
	return self;
}

- (id) initWithCoder:(NSCoder*) coder;
{
	if (self = [super initWithCoder:coder])
		[self performDraggableViewInitialization];

	return self;
}

- (void) performDraggableViewInitialization;
{
	self.maximumSlideDistances = CGSizeMake(kL0DraggableViewDefaultMaximumSlideDistance, kL0DraggableViewDefaultMaximumSlideDistance);
	self.slideSpeedDampeningFactor = kL0DraggableViewDefaultSpeedDampeningFactor;
}

@synthesize maximumSlideDistances, slideSpeedDampeningFactor;

#define kL0DraggableViewPressAndHoldDefaultDelay (0.7)

- (NSTimeInterval) pressAndHoldDelay;
{
	if (pressAndHoldDelay <= 0.1) {
		L0Log(@"Resetting p&h delay to default %f from %f", kL0DraggableViewPressAndHoldDefaultDelay, pressAndHoldDelay);
		pressAndHoldDelay = kL0DraggableViewPressAndHoldDefaultDelay;
	}
	
	return pressAndHoldDelay;
}

- (void) setPressAndHoldDelay:(NSTimeInterval) i;
{
	pressAndHoldDelay = i;
}
	
- (void) dealloc;
{
	[dragStartDate release];
    [super dealloc];
}

#pragma mark -
#pragma mark Event handling

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event;
{
	[self _beginPressingWithTouch:[touches anyObject]];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event;
{
	UITouch* t = [touches anyObject];
	
	L0Log(@"Touches moved, is pressing? %d, is canceled until touch up? %d", pressingWithoutDrag, draggingCanceledUntilTouchUp);
	
	if (pressingWithoutDrag) {
		if (![self _tryEndingPressWithTouch:t]) {
			// NO = do not start with drag yet.
			return;
		}
	}
	
	if (!draggingCanceledUntilTouchUp) {
		if (!dragging)
			[self _beginDraggingWithTouch:t];
		else
			[self _moveByDraggingWithTouch:t];
	}
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event;
{
	if (pressingWithoutDrag) {
		[self _detectPressUp];
		return;
	}
	
	if (notifyOfPressAndHoldEndOnTouchUp) {
		if (delegate && [delegate respondsToSelector:@selector(draggableViewDidEndPressAndHold:)])
			[delegate draggableViewDidEndPressAndHold:self];
		
		notifyOfPressAndHoldEndOnTouchUp = NO;
	}
	
	if (!draggingCanceledUntilTouchUp)
		[self _endDraggingWithTouch:[touches anyObject]];
	
	draggingCanceledUntilTouchUp = NO;
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event;
{
	if (!draggingCanceledUntilTouchUp)
		[self _endDraggingWithTouch:nil]; // nil == canceled -- no attraction, no slide
	
	if (notifyOfPressAndHoldEndOnTouchUp) {
		if (delegate && [delegate respondsToSelector:@selector(draggableViewDidEndPressAndHold:)])
			[delegate draggableViewDidEndPressAndHold:self];
		
		notifyOfPressAndHoldEndOnTouchUp = NO;
	}
	
	draggingCanceledUntilTouchUp = NO;
}

#pragma mark -
#pragma mark Pressing methods

- (void) _beginPressingWithTouch:(UITouch*) t;
{
	if (pressingWithoutDrag || dragging) return;
	
	if (t.tapCount > 1) {
		L0Log(@"Tapping multiple times detected: %@", t);
		
		if (delegate && [delegate respondsToSelector:@selector(draggableView:didTapMultipleTimesWithTouch:)])
			[delegate draggableView:self didTapMultipleTimesWithTouch:t];
		
		draggingCanceledUntilTouchUp = YES;
		return;
	} else {
		L0Log(@"First touch detected: %@", t);
		if (delegate && [delegate respondsToSelector:@selector(draggableView:didTouch:)])
			[delegate draggableView:self didTouch:t];
	}
	
	L0Log(@"%@, press and hold delay = %f", t, self.pressAndHoldDelay);
	
	pressingWithoutDrag = YES;
	pressLocation = [t locationInView:self.superview];
	[self performSelector:@selector(_detectPressAndHold) withObject:nil afterDelay:self.pressAndHoldDelay];
}

- (void) _endPressing;
{
	L0Log(@"Finished press");
	
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_detectPressAndHold) object:nil];
	pressingWithoutDrag = NO;
}

// YES if dragging should be allowed afterwards, NO otherwise.
- (void) _detectPressAndHold;
{
	if (!pressingWithoutDrag || dragging) return;
	
	draggingCanceledUntilTouchUp = NO;
	if (delegate && [delegate respondsToSelector:@selector(draggableViewShouldBeginDraggingAfterPressAndHold:)]) {
		
		draggingCanceledUntilTouchUp = ![delegate draggableViewShouldBeginDraggingAfterPressAndHold:self];
	}
	
	notifyOfPressAndHoldEndOnTouchUp = YES;

	L0Log(@"Detected press and hold -- will cancel dragging until touch up: %d", draggingCanceledUntilTouchUp);
	
	[self _endPressing];
}

- (void) _detectPressUp;
{
	if (!pressingWithoutDrag || dragging) return;
	
	L0Log(@"Detected press up");
	if (delegate && [delegate respondsToSelector:@selector(draggableViewDidPress:)]) {
		[delegate draggableViewDidPress:self];
	}
	
	// TODO warn delegate of press up
	[self _endPressing];
}

#define kL0DraggableViewPressTolerance 10.0

// if YES, pressing has ended because the user started dragging instead.
- (BOOL) _tryEndingPressWithTouch:(UITouch*) t;
{
	CGPoint here = [t locationInView:self.superview];
	here.x -= pressLocation.x;
	here.y -= pressLocation.y;
	
	L0Log(@"Will check with delta: %@", NSStringFromCGPoint(here));
	
	if (!L0VectorHasPointWithinAbsolute(here, kL0DraggableViewPressTolerance)) {
		[self _endPressing];
		return YES;
	} else
		return NO;
}

#pragma mark -
#pragma mark Dragging methods

- (void) _beginDraggingWithTouch:(UITouch*) t;
{
	if (dragging) return;
	
	L0Log(@"%@", t);
	
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
	if (!dragging) return;
	
	lastSpeedRecordingLocation = lastLocation;
	lastSpeedRecordingIntervalSinceStartOfDrag = -[dragStartDate timeIntervalSinceNow];
	
	L0Log(@"speed = %@, interval since start = %f", NSStringFromCGPoint(lastSpeedRecordingLocation), lastSpeedRecordingIntervalSinceStartOfDrag);
	
	[self performSelector:@selector(_recordSpeed) withObject:nil afterDelay:0.2];
}

- (void) _moveByDraggingWithTouch:(UITouch*) t;
{
	if (!dragging) return;
	
	L0Log(@"%@", t);
	
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

// If t == nil, we stop where we are and never continue with a slide or an attraction.
- (void) _endDraggingWithTouch:(UITouch*) t;
{
	if (!dragging) return;

	L0Log(@"%@", t);
	
	dragging = NO;
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_recordSpeed) object:nil];
	
	NSTimeInterval movementTime = (-[dragStartDate timeIntervalSinceNow]) - lastSpeedRecordingIntervalSinceStartOfDrag;
	[dragStartDate release];
	dragStartDate = nil;
	
	BOOL continuesWithSlide = NO;
	CGPoint movementVector;
	
	if (t) {
		NSAssert(self.superview != nil, @"No events should be received without a superview.");
		CGPoint here = [t locationInView:self.superview];
		
		movementVector.x = here.x - lastSpeedRecordingLocation.x;
		movementVector.y = here.y - lastSpeedRecordingLocation.y;
		
		CGPoint speedPointsPer100MS;
		speedPointsPer100MS.x = (movementVector.x / movementTime) * 0.1;
		speedPointsPer100MS.y = (movementVector.y / movementTime) * 0.1;
		
		continuesWithSlide = !L0VectorHasPointWithinAbsolute(speedPointsPer100MS, kL0DraggableViewMinimumMovementSpeedIn100MSForSlide);		
	}
	
	if (delegate && [delegate respondsToSelector:@selector(draggableViewDidEndDragging:continuesWithSlide:)])
		[delegate draggableViewDidEndDragging:self continuesWithSlide:continuesWithSlide];
	
	if (!continuesWithSlide) {
		// Determine attraction.
		// If t == nil, then we have been canceled and we never perform attraction
		// in this case.
		if (!t && delegate && [delegate respondsToSelector:@selector(draggableView:shouldMoveFromPoint:toAttractionPoint:)]) {
			
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

	CGSize maxSlideDistances = self.maximumSlideDistances;
	CGFloat dampening = self.slideSpeedDampeningFactor;
	
	CGFloat startingSlideDistance = sqrt(pow(movementVector.x, 2) + pow(movementVector.y, 2));
	if (startingSlideDistance < 30) {
		// nx = k*x, ny = k*y
		// 30 = sqrt(nx^2 + ny^2)
		// 900 = nx^2 + ny^2
		// 900 = k^2 * x^2 + k^2 * y^2
		// 900 = 2k^2 * (x^2 + y^2)
		// 2k^2 = (x^2 + y^2) / 900
		// k^2 = (x^2 + y^2) / (900 * 2)
		// k = sqrt((x^2 + y^2) / (900 * 2))
		CGFloat k = sqrt((pow(movementVector.x, 2) + pow(movementVector.y, 2)) / (900 * 2));
		movementVector.x *= k;
		movementVector.y *= k;
	}
	
	CGPoint delta = movementVector;
	int timeScale = 1;
	while (!L0VectorHasPointWithinAbsolute(movementVector, 5.0)) {
		movementVector.x *= dampening;
		movementVector.y *= dampening;
		
		delta.x += movementVector.x;
		delta.y += movementVector.y;
		
		timeScale++;
		
		if (ABS(delta.x) > maxSlideDistances.width || 
			ABS(delta.y) > maxSlideDistances.height)
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
	L0LogDebugIf(!delegate, @"no delegate set");
	
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
	L0Log(@"finished? = %d", finished);
	
	if (delegate && [delegate respondsToSelector:@selector(draggableView:didEndInertialSlideByFinishing:)])
		[delegate draggableView:self didEndInertialSlideByFinishing:finished];
}

- (void) _attractionAnimation:(NSString*) name didEndByFinishing:(BOOL) finished context:(void*) nothing;
{
	L0Log(@"finished? = %d", finished);
	
	if (delegate && [delegate respondsToSelector:@selector(draggableView:didEndAttractionByFinishing:)])
		[delegate draggableView:self didEndAttractionByFinishing:finished];
}

@synthesize delegate;
- (void) setDelegate:(id <L0DraggableViewDelegate>) d;
{
	delegate = d;
	delegateImplementsDidDragToPoint = [d respondsToSelector:@selector(draggableView:didDragToPoint:)];
}

@end

#endif
