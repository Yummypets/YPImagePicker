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
        |-(16)-label.centerHorizontally()-arrow-(>=8)-|

        label.firstBaselineAnchor.constraint(equalTo: buttonContainerView.bottomAnchor, constant: -24).isActive = true
        arrow.bottomAnchor.constraint(equalTo: label.bottomAnchor, constant: -4).isActive = true

        buttonContainerView.heightAnchor.constraint(equalToConstant: 60).isActive = true
        return buttonContainerView
    }()

    public let multipleSelectionButton: UIButton = {
        let v = UIButton()
        v.setImage(YPConfig.icons.multipleSelectionOffIcon, for: .normal)
        return v
    }()

    public let bulkUploadRemoveAllButton: UIButton = {
        var container = AttributeContainer()
        container.font = YPConfig.fonts.bulkUploadCountFont
        container.foregroundColor = UIColor.ypLabel
        var configuration = UIButton.Configuration.plain()
        configuration.attributedTitle = AttributedString("", attributes: container)
        configuration.image = YPConfig.icons.closeIcon
        configuration.imagePadding = 8
        configuration.imagePlacement = .trailing

        let v = UIButton(configuration: configuration)
        v.isHidden = true
        v.backgroundColor = UIColor.ypSystemBackground
        v.accessibilityLabel = "Bulk Uploads Remove All Button"
        return v
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
        let normalizedWidth = min(1, cropView.frame.width / cropView.contentSize.width.rounded())
        let normalizedHeight = min(1, cropView.frame.height / cropView.contentSize.height.rounded())
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
        if YPConfig.library.isBulkUploading {
            subviews(
                collectionContainerView.subviews(
                    collectionView
                ),
                YPConfig.showsLibraryButtonInTitle ? UIView() : showAlbumsButton,
                line,
                progressView,
                maxNumberWarningView.subviews(
                    maxNumberWarningLabel
                )
            )
        } else {
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
        }

        collectionContainerView.fillContainer()
        collectionView.fillHorizontally().bottom(0)

        if !YPConfig.showsLibraryButtonInTitle {
            if let footerView = YPConfig.library.assetPreviewFooterView {
                subviews(footerView)
                footerView.fillHorizontally()
                assetViewContainer.Bottom == footerView.Top
                footerView.Bottom == showAlbumsButton.Top
            } else {
                assetViewContainer.Bottom == showAlbumsButton.Top
            }
            showAlbumsButton.Bottom == line.Top
            showAlbumsButton.height(60)
            showAlbumsButton.Bottom == collectionView.Top
        } else {
            assetViewContainer.Bottom == line.Top
            line.Bottom == collectionView.Top
        }

        line.height(1)
        line.fillHorizontally()

        assetViewContainer.top(0).fillHorizontally()

        if YPConfig.library.isBulkUploading {
            // Hide Asset Preview during bulk uploads
            (assetViewContainer.Height <= 0).priority = .required
        } else if let assetPreviewMaxHeight = YPConfig.library.assetPreviewMaxHeight {
            let heightConstraint = NSLayoutConstraint(item: assetViewContainer, attribute: .height, relatedBy: .lessThanOrEqual, toItem: assetViewContainer, attribute: .width, multiplier: 1, constant: 0)
            heightConstraint.priority = .defaultHigh
            heightConstraint.isActive = true
            assetViewContainer.addConstraint(heightConstraint)

            let heightEqualsWidthConstraint = NSLayoutConstraint(item: assetViewContainer, attribute: .height, relatedBy: .equal, toItem: assetViewContainer, attribute: .width, multiplier: 1, constant: 0)
            heightEqualsWidthConstraint.priority = .defaultLow
            heightEqualsWidthConstraint.isActive = true
            assetViewContainer.addConstraint(heightEqualsWidthConstraint)
            (assetViewContainer.Height <= assetPreviewMaxHeight).priority = .required
        } else {
            assetViewContainer.heightEqualsWidth()
        }

        self.assetViewContainerConstraintTop = assetViewContainer.topConstraint
        assetZoomableView.width(0)
        assetZoomableView.height(0)
        assetZoomableView.centerInContainer()

        assetViewContainer.sendSubviewToBack(assetZoomableView)

        progressView.height(5).fillHorizontally()
        progressView.Bottom == line.Top

        |maxNumberWarningView|.bottom(0)
        maxNumberWarningView.Top == safeAreaLayoutGuide.Bottom - 40
        maxNumberWarningLabel.centerHorizontally().top(11)

        if (YPConfig.library.isBulkUploading) {
            subviews(bulkUploadRemoveAllButton)
            bulkUploadRemoveAllButton.height(25).trailing(16)
            bulkUploadRemoveAllButton.layer.cornerRadius = 12.5
            align(horizontally: showAlbumsButton, bulkUploadRemoveAllButton)
        } else {
            subviews(multipleSelectionButton)
            multipleSelectionButton.size(30).trailing(16)
            align(horizontally: showAlbumsButton, multipleSelectionButton)
        }
    }

    @objc
    func albumsButtonTapped() {
        onAlbumsButtonTap?()
    }
}
