//
//  L0DraggableView.h
//  Shard
//
//  Created by ∞ on 21/03/09.
//  Copyright 2009 Emanuele Vulcano. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol L0DraggableViewDelegate;

/*
 A draggable view is a view that the user can manipulate by (huh) dragging.
 It features the following:

 - Dragging (duh): the user can move the view by touching it and moving the touch.
 This works whenever the touch reaches the view, whether it's done directly upon
 it or through subviews that have userInteractionEnabled set to NO.

 - Inertial slide: If the user stops dragging the view with a certain speed, the
 draggable view will perform an "inertial slide", similar to UIScrollView's slowdown,
 by continuing in the direction it was "flicked" towards.
 
 - Attraction: The application can change the final point of arrival for a view
 after a drag by providing an "attraction point". Attractions integrate in the movement
 animations and do not feel awkward to the user.
 
 - Press + Press and Hold: In a way similar to UIControls, draggable views can detect
 presses, a gesture that works similarly to buttons inside scroll views
 (touch up inside the view without initiating a drag). Additionally, draggable views can
 detect 'press and hold' gestures, which happen when the user keeps the finger down on
 the view without dragging it. The delegate can optionally prevent the view from being
 dragged after a press and hold, for example because it wants to use the gesture for
 displaying e.g. a menu of options.
 
 To use, create one, set a delegate, and off you go.
*/

@interface L0DraggableView : UIView {
	BOOL pressingWithoutDrag;
	CGPoint pressLocation;
	
	BOOL notifyOfPressAndHoldEndOnTouchUp;
	BOOL draggingCanceledUntilTouchUp;
	
	BOOL dragging;
	CGPoint lastLocation;
	
	NSDate* dragStartDate;
	NSTimeInterval lastSpeedRecordingIntervalSinceStartOfDrag;
	CGPoint lastSpeedRecordingLocation;
	
	id <L0DraggableViewDelegate> delegate;
	BOOL delegateImplementsDidDragToPoint;
	
	NSTimeInterval pressAndHoldDelay;
	
	CGSize maximumSlideDistances;
	CGFloat slideSpeedDampeningFactor;
}

@property(assign) id <L0DraggableViewDelegate> delegate;
@property NSTimeInterval pressAndHoldDelay;

@property CGSize maximumSlideDistances;
@property CGFloat slideSpeedDampeningFactor;

@end

@protocol L0DraggableViewDelegate <NSObject>
@optional

// ==========================
// = PRESS + PRESS AND HOLD =
// ==========================

// Called when the view is touched (the first touch down) for the first time.
// Press-and-hold will be detected approximately view.pressAndHoldDelay seconds
// from this call.
- (void) draggableView:(L0DraggableView*) view didTouch:(UITouch*) t;

// Called when the view is pressed (touch down + touch up without dragging within a second).
- (void) draggableViewDidPress:(L0DraggableView*) view;

// Called when the view is tapped multiple times (a press followed by a touch down;
// the call is then repeated at every touch up and touch down after that.)
// Note that dragging is automatically cancelled if the view is tapped multiple times.
- (void) draggableView:(L0DraggableView*) view didTapMultipleTimesWithTouch:(UITouch*) t;

// Called when the view is pressed and held (touch down + no touch up in a second without
// dragging). Return YES to allow the drag to start anyway, NO to prevent dragging
// until after the next touch up.
// If not implemented, default is YES (allow dragging).
// Note that after this method is called, two things can
// happen: either the user drags the view away (thus calling the 'DRAGGING' methods below)
// or he ends the touching without moving, causing draggableViewDidEndPressAndHold: to
// be called instead.
- (BOOL) draggableViewShouldBeginDraggingAfterPressAndHold:(L0DraggableView*) view;

// Called when press-and-hold ends. Only called if the view was NOT dragged after p&h.
- (void) draggableViewDidEndPressAndHold:(L0DraggableView*) view;

// ============
// = DRAGGING =
// ============

// Called before dragging starts. NO prevents dragging.
- (BOOL) draggableViewShouldBeginDragging:(L0DraggableView*) view;

// Called as dragging has started.
- (void) draggableViewDidBeginDragging:(L0DraggableView*) view;

// Called as the user moves the view to a given point.
- (void) draggableView:(L0DraggableView*) view didDragToPoint:(CGPoint) point;

// Called as the user takes the finger off the view. If slide is YES, the view will NOT
// stop moving, as an inertial slide will begin instead.
- (void) draggableViewDidEndDragging:(L0DraggableView*) view continuesWithSlide:(BOOL) slide;

// ==================
// = INERTIAL SLIDE =
// ==================

// Called as the view begins performing an inertial slide to a given point.
// Call made within the animation block that performs the slide.
- (void) draggableView:(L0DraggableView*) view willBeginInertialSlideToPoint:(CGPoint) point;

// Called as the view stops performing an inertial slide to a given point.
// If finished == NO, the slide was interrupted (eg because the user started dragging
// the view again).
- (void) draggableView:(L0DraggableView*) view didEndInertialSlideByFinishing:(BOOL) finished;

// ==============
// = ATTRACTION =
// ==============

// Called to determine if there's an attraction point we want the view to move towards
// at the end of a drag. "start" is the point where the draggable view would end up with no
// attraction, either the point where it was left by the user or the slide's endpoint if
// a flick initiates an inertial slide.
// Note that interrupting a slide animation (eg by dragging the view again) prevents
// attraction.
// Works like this:
// - If the user ends the drag still, it will move towards the attraction point with an ease-in-out curve.
// - TODO: If the user ends the drag with a slide, <strike>and the slide's endpoint is one lenght or less away from the attraction point</strike>, the slide will move to the attraction point rather than the endpoint.
// Currently, all interactions between an attraction point and a slide cause the attraction point to replace the slide's endpoint (so the above IS implemented, just not for some slides -- for all of them.)
// TODO: - If the user ends the drag with a slide and the endpoint is more than one length away from the attraction point, it will slide towards the endpoint for about half of the way, then curve towards the attraction point.
- (BOOL) draggableView:(L0DraggableView*) view shouldMoveFromPoint:(CGPoint) currentEndpoint toAttractionPoint:(CGPoint*) outPoint;

// Called as an attraction point animation ends.
// If finished == NO, the attraction was interrupted (eg because the user started dragging
// the view again).
- (void) draggableView:(L0DraggableView*) view didEndAttractionByFinishing:(BOOL) finished;

@end
