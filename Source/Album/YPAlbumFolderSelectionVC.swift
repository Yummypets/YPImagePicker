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
    
    var didSelectAlbum: ((Album) -> Void)?
    var albums = [Album]()
    
    let v = YPAlbumFolderSelectionView()
    override func loadView() { view = v }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpTableView()
        albums = AlbumsManager.default.fetchAlbums()
        v.tableView.reloadData()
    }
    
    func setUpTableView() {
        v.tableView.dataSource = self
        v.tableView.delegate = self
        v.tableView.rowHeight = UITableViewAutomaticDimension
        v.tableView.estimatedRowHeight = 80
    }
}

extension YPAlbumFolderSelectionVC: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return albums.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let album = albums[indexPath.row]
        let cell = YPAlbumFolderCell()
        cell.thumbnail.backgroundColor = .gray
        cell.thumbnail.image = album.thumbnail
        cell.title.text = album.title
        cell.numberOfPhotos.text = "\(album.numberOfPhotos)"
        return cell
    }
}

extension YPAlbumFolderSelectionVC: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        didSelectAlbum?(albums[indexPath.row])
    }
}
