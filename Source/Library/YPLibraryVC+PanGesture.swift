//
//  YPLibraryVC+PanGesture.swift
//  YPImagePicker
//
//  Created by Sacha DSO on 26/01/2018.
//  Copyright © 2018 Yummypets. All rights reserved.
//

import UIKit

extension YPLibraryVC: UIGestureRecognizerDelegate {
    
    func registerForPanGesture() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(panned(_:)))
        panGesture.delegate = self
        v.addGestureRecognizer(panGesture)
    }
  
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith
        otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
    
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let p = gestureRecognizer.location(ofTouch: 0, in: v)
        // Desactivate pan on image when it is shown.
        if isImageShown {
            if p.y < v.imageCropView.frame.height {
                return false
            }
        }
        return true
    }
    
    @objc
    func panned(_ sender: UIPanGestureRecognizer) {
        
        let containerHeight = v.imageCropViewContainer.frame.height
        if sender.state == UIGestureRecognizerState.began {
            let view    = sender.view
            let loc     = sender.location(in: view)
            let subview = view?.hitTest(loc, with: nil)
            
            if subview == v.imageCropView
                && v.imageCropViewConstraintTop.constant == imageCropViewOriginalConstraintTop {
                return
            }
            
            dragStartPos = sender.location(in: v)
            cropBottomY = v.imageCropViewContainer.frame.origin.y + containerHeight
            
            // Move
            if dragDirection == .stop {
                dragDirection = (v.imageCropViewConstraintTop.constant == imageCropViewOriginalConstraintTop)
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
                v.imageCropViewConstraintTop.constant =
                    max(v.imageCropViewMinimalVisibleHeight - containerHeight,
                        currentPos.y + dragDiff - containerHeight)
            } else if dragDirection == .down && currentPos.y > cropBottomY {
                v.imageCropViewConstraintTop.constant =
                    min(imageCropViewOriginalConstraintTop, currentPos.y - containerHeight)
            } else if dragDirection == .stop && v.collectionView.contentOffset.y < 0 {
                dragDirection = .scroll
                imaginaryCollectionViewOffsetStartPosY = currentPos.y
            } else if dragDirection == .scroll {
                v.imageCropViewConstraintTop.constant =
                    v.imageCropViewMinimalVisibleHeight - containerHeight
                    + currentPos.y - imaginaryCollectionViewOffsetStartPosY
            }
        } else {
            imaginaryCollectionViewOffsetStartPosY = 0.0
            if sender.state == UIGestureRecognizerState.ended && dragDirection == .stop {
                return
            }
            let currentPos = sender.location(in: v)
            if currentPos.y < cropBottomY - dragDiff
                && v.imageCropViewConstraintTop.constant != imageCropViewOriginalConstraintTop {
                // The largest movement
                v.imageCropViewConstraintTop.constant =
                    v.imageCropViewMinimalVisibleHeight - containerHeight
                UIView.animate(withDuration: 0.3,
                               delay: 0.0,
                               options: .curveEaseOut,
                               animations: v.layoutIfNeeded,
                               completion: nil)
                dragDirection = .down
            } else {
                // Get back to the original position
                v.imageCropViewConstraintTop.constant = imageCropViewOriginalConstraintTop
                UIView.animate(withDuration: 0.3,
                               delay: 0.0,
                               options: .curveEaseOut,
                               animations: v.layoutIfNeeded,
                               completion: nil)
                dragDirection = .up
            }
        }
        
        // Update isImageShown
        isImageShown = v.imageCropViewConstraintTop.constant == 0
        
        v.refreshImageCurtainAlpha()
    }
}
