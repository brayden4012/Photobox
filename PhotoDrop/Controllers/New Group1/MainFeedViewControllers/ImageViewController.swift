//
//  ImageViewController.swift
//  Photobox
//
//  Created by Nathan Andrus on 3/22/19.
//  Copyright © 2019 Nathan Andrus. All rights reserved.
//

import UIKit
import CloudKit

class ImageViewController: UIViewController {

    @IBOutlet weak var eventImageDetailView: UIImageView!
    
    var photoLanding: Photo? {
        didSet {
            loadViewIfNeeded()
            updateViews()
        }
    }
    
    var eventLanding: Event? {
        didSet {
            updateRightBarButton()
        }
    }
    
    var isFirstIndex: Bool? {
        didSet {
            self.navigationItem.setRightBarButton(nil, animated: false)
        }
    }
    
    var isPoppingVC = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        updateRightBarButton()
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        isPoppingVC = false
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if !isPoppingVC {
            DispatchQueue.main.async {
                self.navigationController?.popToRootViewController(animated: false)
            }
        }
    }
    
    func updateRightBarButton() {
        guard let photo = photoLanding,
        let event = eventLanding,
        let user = UserController.shared.loggedInUser  else { return }
        let userReference = CKRecord.Reference(recordID: user.ckRecord, action: .none)
        
        if event.creatorReference == userReference || photo.userReference == userReference {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(deletePhotoButtonTapped(_:)))
        } else {
             self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Report Photo", style: .plain, target: self, action: #selector(reportPhotoButtonTapped(_:)))
        }
    }
    
    @objc func deletePhotoButtonTapped(_ sender: UIBarButtonItem) {
        guard let photo = photoLanding else { return }
        
        PhotoController.shared.deletePhoto(photo: photo) { (success) in
            if success {
                print("Success deleting from cloudkit and locally")
                self.isPoppingVC = true
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    @objc func reportPhotoButtonTapped(_ sender: UIBarButtonItem) {
        guard let photo = photoLanding else { return }
        
        if photo.numberOfTimesReported == 2 {
            PhotoController.shared.deletePhoto(photo: photo) { (didDelete) in
                if didDelete {
                    self.isPoppingVC = true
                    DispatchQueue.main.async {
                        self.navigationController?.popViewController(animated: true)
                    }
                    print("Photo deleted from photoBOX")
                }
            }
        } else {
            guard let user = UserController.shared.loggedInUser else { return }
            
            let reference = CKRecord.Reference(recordID: user.ckRecord, action: .none)
            
            var usersThatReported: [CKRecord.Reference] = []
            
            if photo.usersThatReported != nil {
                usersThatReported = photo.usersThatReported!
            }
            
            usersThatReported.append(reference)
            photo.numberOfTimesReported += 1
            photo.usersThatReported = usersThatReported
            
            // Hide photo locally on collection view
            guard let indexToDelete = PhotoController.shared.collectionViewPhotos.firstIndex(of: photo) else { return }
            PhotoController.shared.collectionViewPhotos.remove(at: indexToDelete)
            
            // Update in CloudKit
            PhotoController.shared.modifyPhoto(photo: photo, numberOfTimesReported: photo.numberOfTimesReported, usersThatReported: usersThatReported) { (didModify) in
                if didModify {
                    self.isPoppingVC = true
                    DispatchQueue.main.async {
                        self.navigationController?.popViewController(animated: true)
                    }
                }
            }
        }
    }
    
    func updateViews() {
        guard let photo = photoLanding else { return }
        eventImageDetailView.image = photo.image
    }
}
