//
//  YPLibraryVC+PanGesture.swift
//  YPImagePicker
//
//  Created by Sacha DSO on 26/01/2018.
//  Copyright © 2018 Yummypets. All rights reserved.
//

import UIKit

public class PanGestureHelper: NSObject, UIGestureRecognizerDelegate {

    var pannedView: YPLibraryViewPanning!
    var targetView: UIView!
    private let assetViewContainerOriginalConstraintTop: CGFloat = 0
    private var dragDirection = YPDragDirection.up
    private var imaginaryCollectionViewOffsetStartPosY: CGFloat = 0.0
    private var originalCollectionViewOffsetY: CGFloat = 0.0
    private var cropBottomY: CGFloat  = 0.0
    private var dragStartPos: CGPoint = .zero
    private var dragDiff: CGFloat = 0
    private var _isImageShown = true

    // The height constraint of the view with main selected image
    var topHeight: CGFloat {
        get {
            return pannedView.imageContainerConstraintTop?.constant ?? 0
        }
        set {
            if newValue >= pannedView.imageScrollViewMinimalVisibleHeight - pannedView.imageContainerFrame.size.height {
                pannedView.imageContainerConstraintTop?.constant = newValue
            }
        }
    }

    // Is the main image shown
    var isImageShown: Bool {
        get { return self._isImageShown }
        set {
            if newValue != isImageShown {
                self._isImageShown = newValue
                pannedView.assetViewContainerIsShown = newValue
                // Update imageCropContainer
                pannedView.imageScrollViewScrollEnabled = isImageShown
            }
        }
    }

    public func registerForPanGesture(on view: YPLibraryViewPanning) {
        pannedView = view
        targetView = view.targetView
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(panned(_:)))
        panGesture.delegate = self
        view.targetView.addGestureRecognizer(panGesture)
        topHeight = 0
    }

    public func resetToOriginalState() {
        topHeight = assetViewContainerOriginalConstraintTop
        animateView()
        dragDirection = .up
    }

    public func animateUp() {
        topHeight = pannedView.imageScrollViewMinimalVisibleHeight - pannedView.imageContainerFrame.size.height
        animateView()
        dragDirection = .down
    }

    fileprivate func animateView() {
        UIView.animate(withDuration: 0.2,
                       delay: 0.0,
                       options: [.curveEaseInOut, .beginFromCurrentState],
                       animations: {
                           self.pannedView.updateImageContainerLayout()
                           self.pannedView.targetView.layoutIfNeeded()
                       },
                       completion: nil)
    }

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith
        otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let p = gestureRecognizer.location(ofTouch: 0, in: targetView)
        // Desactivate pan on image when it is shown.
        if isImageShown {
            if p.y < pannedView.imageContainerFrame.height {
                return false
            }
        }
        return true
    }

    @objc
    func panned(_ sender: UIPanGestureRecognizer) {

        let containerHeight = pannedView.imageContainerFrame.size.height + (pannedView.collectionViewFrame.minY - pannedView.imageContainerFrame.maxY)
        let currentPos = sender.location(in: targetView)
        let overYLimitToStartMovingUp = currentPos.y * 1.4 < cropBottomY
        switch sender.state {
        case .began:
            let view    = sender.view
            let loc     = sender.location(in: view)
            let subview = view?.hitTest(loc, with: nil)

            if subview == pannedView.imageContainerView
                && topHeight == assetViewContainerOriginalConstraintTop {
                return
            }

            dragStartPos = sender.location(in: view)
            cropBottomY = pannedView.collectionViewFrame.minY

            // Move
            if dragDirection == .stop {
                dragDirection = (topHeight == assetViewContainerOriginalConstraintTop)
                    ? .up
                    : .down
            }

            // Scroll event of CollectionView is preferred.
            if dragDirection == .down && dragStartPos.y > cropBottomY {
                dragDirection = .stop
            }
            if (dragDirection == .up || dragDirection == .down) && currentPos.y < pannedView.collectionViewFrame.minY {
                dragDiff = currentPos.y - pannedView.collectionViewFrame.minY
            }

        case .changed:
            switch dragDirection {
            case .up:
                let diff = pannedView.collectionViewFrame.minY - currentPos.y
                if diff > 0 {
                    topHeight =
                        min(assetViewContainerOriginalConstraintTop,
                            max(pannedView.imageScrollViewMinimalVisibleHeight - containerHeight,
                                (currentPos.y - dragDiff) - containerHeight))
                }
            case .down:
                topHeight = min(assetViewContainerOriginalConstraintTop, currentPos.y - dragDiff - containerHeight)
            case .scroll:
                let newTopHeightValue = pannedView.imageScrollViewMinimalVisibleHeight - pannedView.imageContainerFrame.size.height
                + (currentPos.y - pannedView.collectionViewContentOffset.y) - imaginaryCollectionViewOffsetStartPosY
                topHeight = newTopHeightValue
            case .stop:
                if topHeight != assetViewContainerOriginalConstraintTop && pannedView.collectionViewContentOffset.y < 0 {
                    dragDirection = .scroll
                    imaginaryCollectionViewOffsetStartPosY = currentPos.y
                }
            }

        default:
            imaginaryCollectionViewOffsetStartPosY = 0.0
            dragDiff = 0.0
            if sender.state == UIGestureRecognizer.State.ended && dragDirection == .stop {
                return
            }
            let velocity = sender.velocity(in: targetView)
            if (overYLimitToStartMovingUp && isImageShown == false) || (isImageShown == false && velocity.y < 0) {
                // The largest movement
                animateUp()
            } else {
                // Get back to the original position
                resetToOriginalState()
            }
        }

        // Update isImageShown
        isImageShown = topHeight == assetViewContainerOriginalConstraintTop
    }
}


public protocol YPLibraryViewPanning {
    var imageScrollViewMinimalVisibleHeight: CGFloat { get }
    var imageContainerConstraintTop: NSLayoutConstraint? { get }
    var imageContainerFrame: CGRect { get }
    var collectionViewFrame: CGRect { get }
    var imageContainerView: UIView { get }
    var imageScrollViewScrollEnabled: Bool { get set }
    var collectionViewContentOffset: CGPoint { get }
    var assetViewContainerIsShown: Bool { get set }
    var targetView: UIView { get }

    func updateImageContainerLayout()
}

extension YPLibraryView: YPLibraryViewPanning {
    public var imageContainerView: UIView {
        assetZoomableView
    }

    public var imageScrollViewScrollEnabled: Bool {
        get {
            assetZoomableView.isScrollEnabled
        }
        set {
            assetZoomableView.isScrollEnabled = newValue
        }
    }

    public var imageContainerConstraintTop: NSLayoutConstraint? {
        assetViewContainerConstraintTop
    }

    public var imageContainerFrame: CGRect {
        assetViewContainer.frame
    }

    public var imageScrollViewMinimalVisibleHeight: CGFloat {
        assetZoomableViewMinimalVisibleHeight
    }

    public var collectionViewContentOffset: CGPoint {
        collectionView.contentOffset
    }

    public var collectionViewFrame: CGRect {
        collectionView.frame
    }

    public var assetViewContainerIsShown: Bool {
        get {
            assetViewContainer.isShown
        }
        set {
            assetViewContainer.isShown = newValue
        }
    }

    public var targetView: UIView {
        return self
    }

    public func updateImageContainerLayout() {
        refreshImageCurtainAlpha()
    }
}
