//
//  FirestoreQuerySubscription.swift
//  Dash
//
//  Created by Yuji Nakayama on 2022/02/13.
//  Copyright © 2022 Yuji Nakayama. All rights reserved.
//

import Foundation
import FirebaseFirestore

class FirestoreQuerySubscription<DocumentObject> {
    typealias DocumentDecoder = (DocumentSnapshot) -> DocumentObject?
    typealias Update = (documents: [DocumentObject], changes: [FirestoreDocumentChange])
    typealias UpdateHandler = (Result<Update, Error>) -> Void

    let query: Query
    let documentDecoder: DocumentDecoder
    let updateHandler: UpdateHandler

    private var querySnapshotListener: ListenerRegistration?

    init(query: Query, decodingDocumentWith documentDecoder: @escaping DocumentDecoder, onUpdate updateHandler: @escaping UpdateHandler) {
        self.query = query
        self.documentDecoder = documentDecoder
        self.updateHandler = updateHandler
    }

    deinit {
        querySnapshotListener?.remove()
    }

    func activate() {
        querySnapshotListener = query.addSnapshotListener { [weak self] (querySnapshot, error) in
            guard let self = self else { return }

            if let error = error {
                self.updateHandler(.failure(error))
            } else if let querySnapshot = querySnapshot {
                let documents = querySnapshot.documents.compactMap { self.documentDecoder($0) }
                let changes = querySnapshot.documentChanges.map { FirestoreDocumentChange($0) }
                let update = (documents: documents, changes: changes)
                self.updateHandler(.success(update))
            }
        }
    }
}
