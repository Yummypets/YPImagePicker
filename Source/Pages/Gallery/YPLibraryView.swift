//
//  YPLibraryView.swift
//  YPImgePicker
//
//  Created by Sacha Durand Saint Omer on 2015/11/14.
//  Copyright © 2015 Yummypets. All rights reserved.
//

import UIKit
import Stevia
import Photos

final class YPLibraryView: UIView {
    
    let assetZoomableViewMinimalVisibleHeight: CGFloat  = 50
    
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var assetZoomableView: YPAssetZoomableView!
    @IBOutlet weak var assetViewContainer: YPAssetViewContainer!
    @IBOutlet weak var assetViewContainerConstraintTop: NSLayoutConstraint!
    
    let maxNumberWarningView = UIView()
    let maxNumberWarningLabel = UILabel()
    let progressView = UIProgressView()
    let line = UIView()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        sv(
            line
        )
        
        layout(
            assetViewContainer,
            |line| ~ 1
        )
        
        line.backgroundColor = .white
        
        setupMaxNumberOfItemsView()
        setupProgressBarView()
    }
    
    /// At the bottom there is a view that is visible when selected a limit of items with multiple selection
    func setupMaxNumberOfItemsView() {
        // View Hierarchy
        sv(
            maxNumberWarningView.sv(
                maxNumberWarningLabel
            )
        )
        
        // Layout
        |maxNumberWarningView|.bottom(0)
        if #available(iOS 11.0, *) {
            maxNumberWarningView.Top == safeAreaLayoutGuide.Bottom - 40
            maxNumberWarningLabel.centerHorizontally().top(11)
        } else {
            maxNumberWarningView.height(40)
            maxNumberWarningLabel.centerInContainer()
        }
        
        // Style
        maxNumberWarningView.backgroundColor = UIColor(r: 246, g: 248, b: 248)
        maxNumberWarningLabel.font = UIFont(name: "Helvetica Neue", size: 14)
        maxNumberWarningView.isHidden = true
    }
    
    /// When video is processing this bar appears
    func setupProgressBarView() {
        sv(
            progressView
        )
        
        progressView.height(5)
        progressView.Top == line.Top
        progressView.Width == line.Width
        progressView.progressViewStyle = .bar
        progressView.trackTintColor = YPConfig.colors.progressBarTrackColor
        progressView.progressTintColor = YPConfig.colors.progressBarCompletedColor ?? YPConfig.colors.tintColor
        progressView.isHidden = true
        progressView.isUserInteractionEnabled = false
    }
}

// MARK: - UI Helpers

extension YPLibraryView {
    
    class func xibView() -> YPLibraryView? {
        let bundle = Bundle(for: YPPickerVC.self)
        let nib = UINib(nibName: "YPLibraryView",
                        bundle: bundle)
        let xibView = nib.instantiate(withOwner: self, options: nil)[0] as? YPLibraryView
        return xibView
    }
    
    // MARK: - Grid
    
    func hideGrid() {
        assetViewContainer.grid.alpha = 0
    }
    
    // MARK: - Loader and progress
    
    func fadeInLoader() {
        UIView.animate(withDuration: 0.2) {
            self.assetViewContainer.spinnerView.alpha = 1
        }
    }
    
    func hideLoader() {
        assetViewContainer.spinnerView.alpha = 0
    }
    
    func updateProgress(_ progress: Float) {
        progressView.isHidden = progress > 0.99 || progress == 0
        progressView.progress = progress
        UIView.animate(withDuration: 0.1, animations: progressView.layoutIfNeeded)
    }
    
    // MARK: - Crop Rect
    
    func currentCropRect() -> CGRect {
        guard let cropView = assetZoomableView else {
            return CGRect.zero
        }
        let normalizedX = min(1, cropView.contentOffset.x &/ cropView.contentSize.width)
        let normalizedY = min(1, cropView.contentOffset.y &/ cropView.contentSize.height)
        let normalizedWidth = min(1, cropView.frame.width / cropView.contentSize.width)
        let normalizedHeight = min(1, cropView.frame.height / cropView.contentSize.height)
        return CGRect(x: normalizedX, y: normalizedY, width: normalizedWidth, height: normalizedHeight)
    }
    
    // MARK: - Curtain
    
    func refreshImageCurtainAlpha() {
        let imageCurtainAlpha = abs(assetViewContainerConstraintTop.constant)
            / (assetViewContainer.frame.height - assetZoomableViewMinimalVisibleHeight)
        assetViewContainer.curtain.alpha = imageCurtainAlpha
    }
    
    func cellSize() -> CGSize {
        let size = UIScreen.main.bounds.width/4 * UIScreen.main.scale
        return CGSize(width: size, height: size)
    }
}
