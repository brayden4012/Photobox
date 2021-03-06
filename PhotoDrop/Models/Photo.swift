//
//  Photo.swift
//  Photobox
//
//  Created by Nathan Andrus on 3/12/19.
//  Copyright © 2019 Nathan Andrus. All rights reserved.
//

import UIKit
import CloudKit

class Photo { 
    
    static let typeKey = "Photo"
    static let timestampKey = "timestamp"
    static let eventReferenceKey = "eventReference"
    static let userReferenceKey = "userReference"
    static let imageAssetKey = "imageAsset"
    static let recordID = "photoRecordID"
    static let numTimesReportedKey = "numberOfTimesReported"
    static let usersThatReportedKey = "usersThatReported"
    
    var photoData: Data?
    let timestamp: Date
    var eventReference: CKRecord.Reference?
    let userReference: CKRecord.Reference
    let photoRecordID: CKRecord.ID
    var image: UIImage? {
        get {
            guard let photoData = photoData else { return nil }
            return UIImage(data: photoData)
        }
        set {
            photoData = newValue?.jpegData(compressionQuality: 0.5)
        }
    }
    
    var imageAsset: CKAsset? {
        get {
            let temporaryDirectory = NSTemporaryDirectory()
            let temporaryDirectoryURL = URL(fileURLWithPath: temporaryDirectory)
            let fileURL = temporaryDirectoryURL.appendingPathComponent(photoRecordID.recordName).appendingPathExtension("jpg")
            do {
                try photoData?.write(to: fileURL)
            } catch let error {
                print("Error writing to URL: \(error), \(error.localizedDescription)")
            }
            return CKAsset(fileURL: fileURL)
        }
    }
    
    var numberOfTimesReported: Int
    var usersThatReported: [CKRecord.Reference]?
    
    init(image: UIImage, timestamp: Date = Date(), eventReference: CKRecord.Reference?, userReference: CKRecord.Reference, photoRecordID: CKRecord.ID = CKRecord.ID(recordName: UUID().uuidString), numberOfTimesReported: Int = 0, usersThatReported: [CKRecord.Reference]? = []) {
        self.timestamp = timestamp
        self.eventReference = eventReference
        self.userReference = userReference
        self.photoRecordID = photoRecordID
        self.numberOfTimesReported = numberOfTimesReported
        self.usersThatReported = usersThatReported
        self.image = image
    }
    
    init?(ckRecord: CKRecord) {
        guard let timestamp = ckRecord[Photo.timestampKey] as? Date,

            let userReference = ckRecord[Photo.userReferenceKey] as? CKRecord.Reference,
            let imageAsset = ckRecord[Photo.imageAssetKey] as? CKAsset,
            let numberOfTimesReported = ckRecord[Photo.numTimesReportedKey] as? Int else { return nil }
        
        guard let photoData = try? Data(contentsOf: imageAsset.fileURL!) else { return nil }
        
        let eventReference = ckRecord[Photo.eventReferenceKey] as? CKRecord.Reference
        let usersThatReported = ckRecord[Photo.usersThatReportedKey] as? [CKRecord.Reference]
        
        
        self.photoData = photoData
        self.timestamp = timestamp
        self.photoRecordID = ckRecord.recordID
        self.eventReference = eventReference
        self.userReference = userReference
        self.numberOfTimesReported = numberOfTimesReported
        self.usersThatReported = usersThatReported
    }
}
extension CKRecord {
    convenience init?(photo: Photo) {
        self.init(recordType: Photo.typeKey, recordID: photo.photoRecordID)
        setValue(photo.imageAsset, forKey: Photo.imageAssetKey)
        setValue(photo.timestamp, forKey: Photo.timestampKey)
        setValue(photo.eventReference, forKey: Photo.eventReferenceKey)
        setValue(photo.userReference, forKey: Photo.userReferenceKey)
        setValue(photo.numberOfTimesReported, forKey: Photo.numTimesReportedKey)
        if photo.usersThatReported != nil && !photo.usersThatReported!.isEmpty {
            setValue(photo.usersThatReported, forKey: Photo.usersThatReportedKey)
        }
    }
}

extension Photo: Equatable {
    static func == (lhs: Photo, rhs: Photo) -> Bool {
        return lhs.photoRecordID == rhs.photoRecordID
    }
}

