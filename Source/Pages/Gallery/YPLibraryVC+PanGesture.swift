//
//  YPLibraryVC+PanGesture.swift
//  YPImagePicker
//
//  Created by Sacha DSO on 26/01/2018.
//  Copyright © 2018 Yummypets. All rights reserved.
//

import UIKit

public class PanGestureHelper: NSObject, UIGestureRecognizerDelegate {
    
    var v: YPLibraryView!
    private let assetViewContainerOriginalConstraintTop: CGFloat = 0
    private var dragDirection = YPDragDirection.up
    private var imaginaryCollectionViewOffsetStartPosY: CGFloat = 0.0
    private var cropBottomY: CGFloat  = 0.0
    private var dragStartPos: CGPoint = .zero
    private let dragDiff: CGFloat = 0
    private var _isImageShown = true
    
    var isImageShown: Bool {
        get { return self._isImageShown }
        set {
            if newValue != isImageShown {
                self._isImageShown = newValue
                v.assetViewContainer.isShown = newValue
                // Update imageCropContainer
                v.assetZoomableView.isScrollEnabled = isImageShown
            }
        }
    }
    
    func registerForPanGesture(on view: YPLibraryView) {
        v = view
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(panned(_:)))
        panGesture.delegate = self
        view.addGestureRecognizer(panGesture)
        v.assetViewContainerConstraintTop.constant = 0
    }
    
    func resetToOriginalState() {
        v.assetViewContainerConstraintTop.constant = assetViewContainerOriginalConstraintTop
        UIView.animate(withDuration: 0.3,
                       delay: 0.0,
                       options: .curveEaseOut,
                       animations: v.layoutIfNeeded,
                       completion: nil)
        dragDirection = .up
    }

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith
        otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let p = gestureRecognizer.location(ofTouch: 0, in: v)
        // Desactivate pan on image when it is shown.
        if isImageShown {
            if p.y < v.assetZoomableView.frame.height {
                return false
            }
        }
        return true
    }
    
    @objc
    func panned(_ sender: UIPanGestureRecognizer) {
        
        let containerHeight = v.assetViewContainer.frame.height
        if sender.state == UIGestureRecognizerState.began {
            let view    = sender.view
            let loc     = sender.location(in: view)
            let subview = view?.hitTest(loc, with: nil)
            
            if subview == v.assetZoomableView
                && v.assetViewContainerConstraintTop.constant == assetViewContainerOriginalConstraintTop {
                return
            }
            
            dragStartPos = sender.location(in: v)
            cropBottomY = v.assetViewContainer.frame.origin.y + containerHeight
            
            // Move
            if dragDirection == .stop {
                dragDirection = (v.assetViewContainerConstraintTop.constant == assetViewContainerOriginalConstraintTop)
                    ? .up
                    : .down
            }
            
            // Scroll event of CollectionView is preferred.
            if (dragDirection == .up && dragStartPos.y < cropBottomY + dragDiff) ||
                (dragDirection == .down && dragStartPos.y > cropBottomY) {
                dragDirection = .stop
            }
        } else if sender.state == UIGestureRecognizerState.changed {
            let currentPos = sender.location(in: v)
            if dragDirection == .up && currentPos.y < cropBottomY - dragDiff {
                v.assetViewContainerConstraintTop.constant =
                    max(v.assetZoomableViewMinimalVisibleHeight - containerHeight,
                        currentPos.y + dragDiff - containerHeight)
            } else if dragDirection == .down && currentPos.y > cropBottomY {
                v.assetViewContainerConstraintTop.constant =
                    min(assetViewContainerOriginalConstraintTop, currentPos.y - containerHeight)
            } else if dragDirection == .stop && v.collectionView.contentOffset.y < 0 {
                dragDirection = .scroll
                imaginaryCollectionViewOffsetStartPosY = currentPos.y
            } else if dragDirection == .scroll {
                v.assetViewContainerConstraintTop.constant =
                    v.assetZoomableViewMinimalVisibleHeight - containerHeight
                    + currentPos.y - imaginaryCollectionViewOffsetStartPosY
            }
        } else {
            imaginaryCollectionViewOffsetStartPosY = 0.0
            if sender.state == UIGestureRecognizerState.ended && dragDirection == .stop {
                return
            }
            let currentPos = sender.location(in: v)
            if currentPos.y < cropBottomY - dragDiff
                && v.assetViewContainerConstraintTop.constant != assetViewContainerOriginalConstraintTop {
                // The largest movement
                v.assetViewContainerConstraintTop.constant =
                    v.assetZoomableViewMinimalVisibleHeight - containerHeight
                UIView.animate(withDuration: 0.3,
                               delay: 0.0,
                               options: .curveEaseOut,
                               animations: v.layoutIfNeeded,
                               completion: nil)
                dragDirection = .down
            } else {
                // Get back to the original position
                resetToOriginalState()
            }
        }
        
        // Update isImageShown
        isImageShown = v.assetViewContainerConstraintTop.constant == 0
        
        v.refreshImageCurtainAlpha()
    }
}
