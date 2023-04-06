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

internal final class YPLibraryView: UIView {

    static let ALBUMS_LABEL_TAG = 100

    // MARK: - Public vars

    internal let assetZoomableViewMinimalVisibleHeight: CGFloat  = 50
    internal var assetViewContainerConstraintTop: NSLayoutConstraint?
    internal let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        let v = UICollectionView(frame: .zero, collectionViewLayout: layout)
        v.backgroundColor = YPConfig.colors.libraryScreenBackgroundColor
        v.collectionViewLayout = layout
        v.showsHorizontalScrollIndicator = false
        v.alwaysBounceVertical = true
        return v
    }()
    internal lazy var assetViewContainer: YPAssetViewContainer = {
        let v = YPAssetViewContainer(frame: .zero, zoomableView: assetZoomableView)
        v.accessibilityIdentifier = "assetViewContainer"
        return v
    }()
    internal let assetZoomableView: YPAssetZoomableView = {
        let v = YPAssetZoomableView(frame: .zero)
        v.accessibilityIdentifier = "assetZoomableView"
        return v
    }()
    /// At the bottom there is a view that is visible when selected a limit of items with multiple selection
    internal let maxNumberWarningView: UIView = {
        let v = UIView()
        v.backgroundColor = .ypSecondarySystemBackground
        v.isHidden = true
        return v
    }()
    internal let maxNumberWarningLabel: UILabel = {
        let v = UILabel()
        v.font = YPConfig.fonts.libaryWarningFont
        return v
    }()

    internal let showAlbumsButton: UIView = {
        let buttonContainerView = UIView()

        let label = UILabel()
        label.text = YPConfig.wordings.libraryTitle
        // Use YPConfig font
        label.font = YPConfig.fonts.pickerTitleFont
        label.textColor = YPConfig.colors.libraryScreenAlbumsButtonColor
        label.tag = ALBUMS_LABEL_TAG

        let arrow = UIImageView()
        arrow.image = YPConfig.icons.arrowDownIcon.withRenderingMode(.alwaysTemplate)
        arrow.tintColor = YPConfig.colors.libraryScreenAlbumsButtonColor
        arrow.setContentCompressionResistancePriority(.required, for: .horizontal)

        let button = UIButton()
        button.addTarget(self, action: #selector(albumsButtonTapped), for: .touchUpInside)
        button.setBackgroundColor(YPConfig.colors.assetViewBackgroundColor.withAlphaComponent(0.4), forState: .highlighted)

        buttonContainerView.subviews(
            label,
            arrow,
            button
        )
        button.fillContainer()
        |-(24)-label.centerHorizontally()-arrow-(>=8)-|

        label.firstBaselineAnchor.constraint(equalTo: buttonContainerView.bottomAnchor, constant: -24).isActive = true
        arrow.bottomAnchor.constraint(equalTo: label.bottomAnchor, constant: -4).isActive = true

        buttonContainerView.heightAnchor.constraint(equalToConstant: 60).isActive = true
        return buttonContainerView
    }()

    var onAlbumsButtonTap: (() -> Void)?

    // MARK: - Private vars

    private let line: UIView = {
        let v = UIView()
        v.backgroundColor = YPConfig.colors.libraryScreenBackgroundColor
        return v
    }()
    /// When video is processing this bar appears
    private let progressView: UIProgressView = {
        let v = UIProgressView()
        v.progressViewStyle = .bar
        v.trackTintColor = YPConfig.colors.progressBarTrackColor
        v.progressTintColor = YPConfig.colors.progressBarCompletedColor ?? YPConfig.colors.tintColor
        v.isHidden = true
        v.isUserInteractionEnabled = false
        return v
    }()
    private let collectionContainerView: UIView = {
        let v = UIView()
        v.accessibilityIdentifier = "collectionContainerView"
        return v
    }()
    private var shouldShowLoader = false {
        didSet {
            DispatchQueue.main.async {
                self.assetViewContainer.squareCropButton.isEnabled = !self.shouldShowLoader
                self.assetViewContainer.multipleSelectionButton.isEnabled = !self.shouldShowLoader
                self.assetViewContainer.spinnerIsShown = self.shouldShowLoader
                self.shouldShowLoader ? self.hideOverlayView() : ()
            }
        }
    }

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)

        setupLayout()
        clipsToBounds = true
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        fatalError("Only code layout.")
    }

    // MARK: - Public Methods

    // MARK: Overlay view

    func hideOverlayView() {
        assetViewContainer.itemOverlay?.alpha = 0

        // disable grid for images
        assetViewContainer.itemOverlay?.isHidden = !assetZoomableView.isVideoMode
    }

    // MARK: Loader and progress

    func fadeInLoader() {
        shouldShowLoader = true
        // Only show loader if full res image takes more than 0.5s to load.
        if #available(iOS 10.0, *) {
            Timer.scheduledTimer(withTimeInterval: 0.3, repeats: false) { _ in
                if self.shouldShowLoader == true {
                    UIView.animate(withDuration: 0.2) {
                        self.assetViewContainer.spinnerView.alpha = 1
                    }
                }
            }
        } else {
            // Fallback on earlier versions
            UIView.animate(withDuration: 0.2) {
                self.assetViewContainer.spinnerView.alpha = 1
            }
        }
    }

    func hideLoader() {
        shouldShowLoader = false
        assetViewContainer.spinnerView.alpha = 0
    }

    func updateProgress(_ progress: Float) {
        progressView.isHidden = progress > 0.99 || progress == 0
        progressView.progress = progress
        UIView.animate(withDuration: 0.1, animations: progressView.layoutIfNeeded)
    }

    func setAlbumButtonTitle(aTitle: String) {
        guard !YPConfig.showsLibraryButtonInTitle else { return }
        if let label = showAlbumsButton.viewWithTag(YPLibraryView.ALBUMS_LABEL_TAG) as? UILabel {
            label.text = aTitle
        }
    }

    // MARK: Crop Rect

    func currentCropRect() -> CGRect {
        let cropView = assetZoomableView
        let normalizedX = min(1, cropView.contentOffset.x &/ cropView.contentSize.width)
        let normalizedY = min(1, cropView.contentOffset.y &/ cropView.contentSize.height)
        let normalizedWidth = min(1, cropView.frame.width / cropView.contentSize.width)
        let normalizedHeight = min(1, cropView.frame.height / cropView.contentSize.height)
        return CGRect(x: normalizedX, y: normalizedY, width: normalizedWidth, height: normalizedHeight)
    }

    // MARK: Curtain

    func refreshImageCurtainAlpha() {
        let imageCurtainAlpha = abs(assetViewContainerConstraintTop?.constant ?? 0)
        / (assetViewContainer.frame.height - assetZoomableViewMinimalVisibleHeight)
        assetViewContainer.curtain.alpha = imageCurtainAlpha
    }

    func cellSize() -> CGSize {
        var screenWidth: CGFloat = UIScreen.main.bounds.width
        if UIDevice.current.userInterfaceIdiom == .pad && YPImagePickerConfiguration.widthOniPad > 0 {
            screenWidth =  YPImagePickerConfiguration.widthOniPad
        }
        let size = screenWidth / 4 * UIScreen.main.scale
        return CGSize(width: size, height: size)
    }

    // MARK: - Private Methods

    private func setupLayout() {
        subviews(
            collectionContainerView.subviews(
                collectionView
            ),
            YPConfig.showsLibraryButtonInTitle ? UIView() : showAlbumsButton,
            line,
            assetViewContainer.subviews(
                assetZoomableView
            ),
            progressView,
            maxNumberWarningView.subviews(
                maxNumberWarningLabel
            )
        )

        collectionContainerView.fillContainer()
        collectionView.fillHorizontally().bottom(0)

        if !YPConfig.showsLibraryButtonInTitle {
            assetViewContainer.Bottom == showAlbumsButton.Top
            showAlbumsButton.Bottom == line.Top
            showAlbumsButton.height(60)
            assetZoomableView.Bottom == collectionView.Top - 60
        } else {
            assetViewContainer.Bottom == line.Top
            assetZoomableView.Bottom == collectionView.Top
        }

        line.height(1)
        line.fillHorizontally()

        assetViewContainer.top(0).fillHorizontally().heightEqualsWidth()
        self.assetViewContainerConstraintTop = assetViewContainer.topConstraint
        assetZoomableView.fillContainer().heightEqualsWidth()

        assetViewContainer.sendSubviewToBack(assetZoomableView)

        progressView.height(5).fillHorizontally()
        progressView.Bottom == line.Top

        |maxNumberWarningView|.bottom(0)
        maxNumberWarningView.Top == safeAreaLayoutGuide.Bottom - 40
        maxNumberWarningLabel.centerHorizontally().top(11)
    }

    @objc
    func albumsButtonTapped() {
        onAlbumsButtonTap?()
    }
}
