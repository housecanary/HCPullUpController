//
//  PullUpController.swift
//  PullUpControllerDemo
//
//  Created by Mario on 03/11/2017.
//  Copyright © 2017 Mario. All rights reserved.
//

import UIKit

open class PullUpController: UIViewController {
    
    public enum Action {
        /**
         The action used when the pull up controller's view is added to its parent view
         */
        case add
        /**
         The action used when the pull up controller's view is removed to its parent view
         */
        case remove
        /**
         The action used when the pull up controller's view position change
         */
        case move
    }
    
    // MARK: - Open properties
    public enum PullupConstraints {
        case fullWidth(height: CGFloat)
        case insetFromLeft(width: CGFloat, height: CGFloat)
        case insetFromRight(width: CGFloat, height: CGFloat)
    }

    open var pullupControllerPrefferedConstraints: PullupConstraints {
        return .fullWidth(height: 400)
    }

    /**
     A list of y values, in screen units expressed in the pull up controller coordinate system.
     At the end of the gestures the pull up controller will scroll to the nearest point in the list.
     
     Please keep in mind that this array should contains only sticky points in the middle of the pull up controller's view;
     There is therefore no need to add the fist one (pullUpControllerPreviewOffset), and/or the last one (pullUpControllerPreferredSize.height).
     
     For a complete list of all the sticky points you can use `pullUpControllerAllStickyPoints`.
     */
    open var pullUpControllerMiddleStickyPoints: [CGFloat] {
        return []
    }
    
    /**
     A CGFloat value that determines how much the pull up controller's view can bounce outside it's size.
     The default value is 0 and that means the the view cannot expand beyond its size.
     */
    open var pullUpControllerBounceOffset: CGFloat {
        return 0
    }
    
    /**
     A CGFloat value that represent the current point, expressed in the pull up controller coordinate system,
     where the pull up controller's view is positioned.
     */
    open var pullUpControllerCurrentPointOffset: CGFloat {
        let bottomOffset: CGFloat = bottomConstraint?.constant ?? 0
        return pullUpHeight - bottomOffset
    }

    private final var pullUpHeight: CGFloat {
        switch pullupControllerPrefferedConstraints {
        case .fullWidth(let height): return height
        case .insetFromLeft(_, let height): return height
        case .insetFromRight(_, let height): return height
        }
    }
    
    /**
     A CGFloat value that represent the vertical velocity threshold (expressed in points/sec) beyond wich
     the target sticky point is skippend and the view is positioned to the next one.
    */
    open var pullUpControllerSkipPointVerticalVelocityThreshold: CGFloat {
        return 700
    }
    
    // MARK: - Public properties
    
    /**
     A list of y values, in screen units expressed in the pull up controller coordinate system.
     At the end of the gesture the pull up controller will scroll at the nearest point in the list.
     */
    public final var pullUpControllerAllStickyPoints: [CGFloat] {
        var allStickyPoints = [pullUpHeight]
        allStickyPoints.append(contentsOf: pullUpControllerMiddleStickyPoints)
        return allStickyPoints.sorted()
    }

    private var leftConstraint: NSLayoutConstraint?
    private var rightConstraint: NSLayoutConstraint?
    private var bottomConstraint: NSLayoutConstraint?
    private var widthConstraint: NSLayoutConstraint?
    private var heightConstraint: NSLayoutConstraint?
    private var panGestureRecognizer: UIPanGestureRecognizer?
    
    private var portraitPreviousStickyPointIndex: Int?
    
    fileprivate weak var internalScrollView: UIScrollView?
    
    private var initialInternalScrollViewContentOffset: CGPoint = .zero
    private var currentStickyPointIndex: Int {
        let stickyPointsLessCurrentPosition = pullUpControllerAllStickyPoints.map { abs($0 - pullUpControllerCurrentPointOffset) }
        guard let minStickyPointDifference = stickyPointsLessCurrentPosition.min() else { return 0 }
        return stickyPointsLessCurrentPosition.firstIndex(of: minStickyPointDifference) ?? 0
    }
    
    // MARK: - Open methods
    
    /**
     This method is called before the pull up controller's view move to a point.
     The default implementation of this method does nothing.
     - parameter point: The target point, expressed in the pull up controller coordinate system
     */
    open func pullUpControllerWillMove(to point: CGFloat) { }
    
    /**
     This method is called after the pull up controller's view move to a point.
     The default implementation of this method does nothing.
     - parameter point: The target point, expressed in the pull up controller coordinate system
     */
    open func pullUpControllerDidMove(to point: CGFloat) { }
    
    /**
     This method is called after the pull up controller's view is dragged to a point.
     The default implementation of this method does nothing.
     - parameter stickyPoint: The target point, expressed in the pull up controller coordinate system
     */
    open func pullUpControllerDidDrag(to point: CGFloat) { }
    
    /**
     This method will move the pull up controller's view in order to show the provided visible point.
     
     You may use on of `pullUpControllerAllStickyPoints` item to provide a valid visible point.
     - parameter visiblePoint: the y value to make visible, in screen units expressed in the pull up controller coordinate system.
     - parameter animated: Pass true to animate the move; otherwise, pass false.
     - parameter completion: The closure to execute after the animation is completed. This block has no return value and takes no parameters. You may specify nil for this parameter.
     */
    open func pullUpControllerMoveToVisiblePoint(_ visiblePoint: CGFloat, animated: Bool, completion: (() -> Void)? = nil) {
        let targetPoint = pullUpHeight - visiblePoint
        bottomConstraint?.constant = targetPoint
        pullUpControllerWillMove(to: visiblePoint)
        pullUpControllerAnimate(
            action: .move,
            withDuration: animated ? 0.3 : 0,
            animations: { [weak self] in
                self?.parent?.view?.layoutIfNeeded()
            },
            completion: { [weak self] _ in
                self?.pullUpControllerDidMove(to: visiblePoint)
                completion?()
        })
    }

    /**
     This method will be called when an animation needs to be performed.
     You can consider override this method and customize the animation using the method
     `UIView.animate(withDuration:, delay:, usingSpringWithDamping:, initialSpringVelocity:, options:, animations:, completion:)`
     - parameter action: The action that is about to be performed, see `PullUpController.Action` for more info
     - parameter duration: The total duration of the animations, measured in seconds. If you specify a negative value or 0, the changes are made without animating them.
     - parameter animations: A block object containing the changes to commit to the views.
     - parameter completion: A block object to be executed when the animation sequence ends.
    */
    final func pullUpControllerAnimate(action: Action,
                                      withDuration duration: TimeInterval,
                                      animations: @escaping () -> Void,
                                      completion: ((Bool) -> Void)?) {
        UIView.animate(withDuration: duration, animations: animations, completion: completion)
    }

    open override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        
        let currentStickyPointIndex: Int = self.currentStickyPointIndex
        coordinator.animate(alongsideTransition: nil) { [weak self] _ in
            guard let self = self else {
                return
            }
            
            let initialPoint: CGFloat = self.pullUpControllerAllStickyPoints[currentStickyPointIndex]
            self.pullUpControllerWillMove(to: initialPoint)
            self.setupConstraints(initialPoint: initialPoint)
            self.parent?.view.layoutIfNeeded()
            self.pullUpControllerDidMove(to: initialPoint)
        }
    }

    // MARK: - Setup
    fileprivate func setup(superview: UIView, initialPoint: CGFloat) {
        view.translatesAutoresizingMaskIntoConstraints = false
        superview.addSubview(view)
        setupConstraints(initialPoint: initialPoint)
        setupPanGestureRecognizer()
    }
    
    fileprivate func addInternalScrollViewPanGesture() {
        internalScrollView?.panGestureRecognizer.addTarget(self, action: #selector(handleScrollViewGestureRecognizer(_:)))
    }
    
    fileprivate func removeInternalScrollViewPanGestureRecognizer() {
        internalScrollView?.panGestureRecognizer.removeTarget(self, action: #selector(handleScrollViewGestureRecognizer(_:)))
    }
    
    private func setupPanGestureRecognizer() {
        addInternalScrollViewPanGesture()
        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanGestureRecognizer(_:)))
        panGestureRecognizer?.minimumNumberOfTouches = 1
        panGestureRecognizer?.maximumNumberOfTouches = 1
        if let panGestureRecognizer = panGestureRecognizer {
            view.addGestureRecognizer(panGestureRecognizer)
        }
    }
    
    private func setupConstraints(initialPoint: CGFloat) {

        var allConstraints = [leftConstraint,
                              rightConstraint,
                              widthConstraint,
                              heightConstraint,
                              bottomConstraint].compactMap { $0 }

        NSLayoutConstraint.deactivate(allConstraints)

        guard
            let parentView = parent?.view
            else { return }


        switch pullupControllerPrefferedConstraints {
        case .fullWidth(let height):
            leftConstraint = view.leftAnchor.constraint(equalTo: parentView.leftAnchor)
            rightConstraint = view.rightAnchor.constraint(equalTo: parentView.rightAnchor)
            bottomConstraint = view.bottomAnchor.constraint(equalTo: parentView.bottomAnchor, constant: height - initialPoint)
            heightConstraint = view.heightAnchor.constraint(equalToConstant: height)
            widthConstraint = nil
        case .insetFromLeft(let width, let height):
            leftConstraint = view.leftAnchor.constraint(equalTo: parentView.leftAnchor, constant: 10.0)
            rightConstraint = nil
            bottomConstraint = view.bottomAnchor.constraint(equalTo: parentView.bottomAnchor, constant: height - initialPoint)
            heightConstraint = view.heightAnchor.constraint(equalToConstant: height)
            widthConstraint = view.widthAnchor.constraint(equalToConstant: width)
        case .insetFromRight(let width, let height):
            leftConstraint = nil
            rightConstraint = view.rightAnchor.constraint(equalTo: parentView.rightAnchor, constant: 10.0)
            bottomConstraint = view.bottomAnchor.constraint(equalTo: parentView.bottomAnchor, constant: height - initialPoint)
            heightConstraint = view.heightAnchor.constraint(equalToConstant: height)
            widthConstraint = view.widthAnchor.constraint(equalToConstant: width)
        }

        allConstraints = [leftConstraint,
                          rightConstraint,
                          widthConstraint,
                          heightConstraint,
                          bottomConstraint].compactMap { $0 }

        NSLayoutConstraint.activate(allConstraints)
    }
    
    private func nearestStickyPointY(yVelocity: CGFloat) -> CGFloat {
        var currentStickyPointIndex = self.currentStickyPointIndex
        if abs(yVelocity) > pullUpControllerSkipPointVerticalVelocityThreshold {
            if yVelocity > 0 {
                currentStickyPointIndex = max(currentStickyPointIndex - 1, 0)
            } else {
                currentStickyPointIndex = min(currentStickyPointIndex + 1, pullUpControllerAllStickyPoints.count - 1)
            }
        }
        
        return pullUpControllerAllStickyPoints[currentStickyPointIndex]
    }
    
    @objc private func handleScrollViewGestureRecognizer(_ gestureRecognizer: UIPanGestureRecognizer) {
        guard
            let scrollView = internalScrollView,
            let bottomConstraint = bottomConstraint
            else { return }
        
        let isFullOpened = bottomConstraint.constant == 0
        let yTranslation = gestureRecognizer.translation(in: scrollView).y
        let isScrollingDown = gestureRecognizer.velocity(in: scrollView).y > 0
        
        /**
         The user should be able to drag the view down through the internal scroll view when
         - the scroll direction is down (`isScrollingDown`)
         - the internal scroll view is scrolled to the top (`scrollView.contentOffset.y <= 0`)
         */
        let shouldDragViewDown = isScrollingDown && scrollView.contentOffset.y <= 0
        
        /**
         The user should be able to drag the view up through the internal scroll view when
         - the scroll direction is up (`!isScrollingDown`)
         - the PullUpController's view is fully opened. (`topConstraint.constant <= parentViewHeight - lastStickyPoint`)
         */
        let shouldDragViewUp = !isScrollingDown && !isFullOpened
        let shouldDragView = shouldDragViewDown || shouldDragViewUp
        
        if shouldDragView {
            scrollView.bounces = false
            scrollView.setContentOffset(.zero, animated: false)
        }
        
        switch gestureRecognizer.state {
        case .began:
            initialInternalScrollViewContentOffset = scrollView.contentOffset
            
        case .changed:
            guard
                shouldDragView
                else { break }
            setBottomOffset(bottomConstraint.constant + yTranslation - initialInternalScrollViewContentOffset.y)
            gestureRecognizer.setTranslation(initialInternalScrollViewContentOffset, in: scrollView)
            
        case .ended:
            scrollView.bounces = true
            if scrollView.contentOffset.y <= 0 {
                goToNearestStickyPoint(verticalVelocity: gestureRecognizer.velocity(in: view).y)
            }
        default:
            break
        }
        
    }
    
    @objc private func handlePanGestureRecognizer(_ gestureRecognizer: UIPanGestureRecognizer) {
        guard let bottomConstraint = bottomConstraint else {
            return
        }

        let yTranslation = gestureRecognizer.translation(in: view).y
        
        switch gestureRecognizer.state {
        case .changed:
            setBottomOffset(bottomConstraint.constant + yTranslation, allowBounce: true)
            gestureRecognizer.setTranslation(.zero, in: view)
            
        case .ended:
            goToNearestStickyPoint(verticalVelocity: gestureRecognizer.velocity(in: view).y)
            
        default:
            break
        }
    }
    
    private func goToNearestStickyPoint(verticalVelocity: CGFloat) {
        let nearestStickPointY = nearestStickyPointY(yVelocity: verticalVelocity)
        let distanceToConver = nearestStickPointY - pullUpControllerCurrentPointOffset
        let animationDuration = max(0.08, min(0.3, TimeInterval(abs(distanceToConver/verticalVelocity))))
        let newBottomOffset: CGFloat = pullUpHeight - nearestStickPointY
        setBottomOffset(newBottomOffset, animationDuration: animationDuration)
    }
    
    private func setBottomOffset(_ value: CGFloat,
                                 animationDuration: TimeInterval? = nil,
                                 allowBounce: Bool = false) {
        let value: CGFloat = {
            guard
                let firstStickyPoint = pullUpControllerAllStickyPoints.first,
                let lastStickyPoint = pullUpControllerAllStickyPoints.last
                else {
                    return value
                }
            let bounceOffset = allowBounce ? pullUpControllerBounceOffset : 0
            let minValue = pullUpHeight - lastStickyPoint - bounceOffset
            let maxValue = pullUpHeight - firstStickyPoint + bounceOffset
            return max(min(value, maxValue), minValue)
        }()
        let targetPoint = pullUpHeight - value
        /*
         `willMoveToStickyPoint` and `didMoveToStickyPoint` should be
         called only if the user has ended the gesture
         */
        let shouldNotifyObserver = animationDuration != nil
        bottomConstraint?.constant = value
        pullUpControllerDidDrag(to: targetPoint)
        if shouldNotifyObserver {
            pullUpControllerWillMove(to: targetPoint)
        }
        pullUpControllerAnimate(
            action: .move,
            withDuration: animationDuration ?? 0,
            animations: { [weak self] in
                self?.parent?.view.layoutIfNeeded()
            },
            completion: { [weak self] _ in
                if shouldNotifyObserver {
                    self?.pullUpControllerDidMove(to: targetPoint)
                }
            }
        )
    }
    
    fileprivate func hide() {
        bottomConstraint?.constant = pullUpHeight
    }
}

extension UIViewController {
    
    /**
     Adds the specified pull up view controller as a child of the current view controller.
     - parameter pullUpController: the pull up controller to add as a child of the current view controller.
     - parameter initialPoint: The point where the provided `pullUpController`'s view will be initially placed expressed in screen units of the pull up controller coordinate system. If this value is not provided, the `pullUpController`'s view will be initially placed expressed
     - parameter animated: Pass true to animate the adding; otherwise, pass false.
     */
    open func addPullUpController(_ pullUpController: PullUpController) {
        assert(!(self is UITableViewController), "It's not possible to attach a PullUpController to a UITableViewController. Check this issue for more information: https://github.com/MarioIannotta/PullUpController/issues/14")
        addChild(pullUpController)
        pullUpController.setup(superview: view, initialPoint: 0)
        pullUpController.didMove(toParent: self)
        parent?.view.layoutIfNeeded()
    }
    
    /**
     Adds the specified pull up view controller as a child of the current view controller.
     - parameter pullUpController: the pull up controller to remove as a child from the current view controller.
     - parameter animated: Pass true to animate the removing; otherwise, pass false.
     */
    open func removePullUpController(_ pullUpController: PullUpController,
                                     animated: Bool,
                                     completion: (() -> Void)? = nil) {

        //check that pullup controller is in parent
        guard pullUpController.parent != nil else {
            completion?()
            return
        }

        pullUpController.hide()
        if animated {
            pullUpController.pullUpControllerAnimate(
                action: .remove,
                withDuration: 0.3,
                animations: { [weak self] in
                    self?.view.layoutIfNeeded()
                },
                completion: { _ in
                    pullUpController.willMove(toParent: nil)
                    pullUpController.view.removeFromSuperview()
                    pullUpController.removeFromParent()
                    completion?()
            })
        } else {
            view.layoutIfNeeded()
            pullUpController.willMove(toParent: nil)
            pullUpController.view.removeFromSuperview()
            pullUpController.removeFromParent()
            completion?()
        }
    }
    
}

extension UIScrollView {
    
    /**
     Attach the scroll view to the provided pull up controller in order to move it with the scroll view content.
     - parameter pullUpController: the pull up controller to move with the current scroll view content.
     */
    open func attach(to pullUpController: PullUpController) {
        pullUpController.internalScrollView?.detach(from: pullUpController)
        pullUpController.internalScrollView = self
        pullUpController.addInternalScrollViewPanGesture()
    }
    
    /**
     Remove the scroll view from the pull up controller so it no longer moves with the scroll view content.
     - parameter pullUpController: the pull up controller to be removed from controlling the scroll view.
     */
    open func detach(from pullUpController: PullUpController) {
        pullUpController.removeInternalScrollViewPanGestureRecognizer()
        pullUpController.internalScrollView = nil
    }

}
