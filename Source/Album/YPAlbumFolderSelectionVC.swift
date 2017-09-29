//
//  YPAlbumFolderSelectionVC.swift
//  YPImagePicker
//
//  Created by Sacha Durand Saint Omer on 20/07/2017.
//  Copyright © 2017 Yummypets. All rights reserved.
//

import UIKit
import Stevia
import Photos

class YPAlbumFolderSelectionVC: UIViewController {
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    var didSelectAlbum: ((Album) -> Void)?
    var albums = [Album]()
    var noVideos = false
    let albumsManager = AlbumsManager.default
    
    let v = YPAlbumFolderSelectionView()
    override func loadView() { view = v }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Albums"
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel,
                                                           target: self,
                                                           action: #selector(close))
        setUpTableView()
        albumsManager.noVideos = noVideos
        fetchAlbumsInBackground()
    }
    
    func fetchAlbumsInBackground() {
        v.spinner.startAnimating()
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.albums = self?.albumsManager.fetchAlbums() ?? []
            DispatchQueue.main.async {
                self?.v.spinner.stopAnimating()
                self?.v.tableView.isHidden = false
                self?.v.tableView.reloadData()
            }
        }
    }
    
    @objc
    func close() {
        dismiss(animated: true, completion: nil)
    }
    
    func setUpTableView() {
        v.tableView.isHidden = true
        v.tableView.dataSource = self
        v.tableView.delegate = self
        v.tableView.rowHeight = UITableViewAutomaticDimension
        v.tableView.estimatedRowHeight = 80
        v.tableView.separatorStyle = .none
        v.tableView.register(YPAlbumFolderCell.self, forCellReuseIdentifier: "AlbumCell")
    }
}

extension YPAlbumFolderSelectionVC: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return albums.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let album = albums[indexPath.row]
        if let cell = tableView.dequeueReusableCell(withIdentifier: "AlbumCell", for: indexPath) as? YPAlbumFolderCell {
            cell.thumbnail.backgroundColor = .gray
            cell.thumbnail.image = album.thumbnail
            cell.title.text = album.title
            cell.numberOfPhotos.text = "\(album.numberOfPhotos)"
            return cell
        }
        return UITableViewCell()
    }
}

extension YPAlbumFolderSelectionVC: UITableViewDelegate {
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        didSelectAlbum?(albums[indexPath.row])
    }
}
