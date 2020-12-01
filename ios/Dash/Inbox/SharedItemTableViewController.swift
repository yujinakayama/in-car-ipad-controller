//
//  SharedItemTableViewController.swift
//  Dash
//
//  Created by Yuji Nakayama on 2020/01/27.
//  Copyright © 2020 Yuji Nakayama. All rights reserved.
//

import UIKit
import FirebaseAuth

class SharedItemTableViewController: UITableViewController, SharedItemDatabaseDelegate {
    var database: SharedItemDatabase?

    lazy var dataSource = SharedItemTableViewDataSource(tableView: tableView) { [weak self] (tableView, indexPath, itemIdentifier) in
        guard let self = self else { return nil }
        let cell = tableView.dequeueReusableCell(withIdentifier: "SharedItemTableViewCell") as! SharedItemTableViewCell
        cell.item = self.item(for: indexPath)
        return cell
    }

    var authentication: FirebaseAuthentication {
        return Firebase.shared.authentication
    }

    var isVisible: Bool {
        return isViewLoaded && view.window != nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.dataSource = dataSource

        NotificationCenter.default.addObserver(self, selector: #selector(firebaseAuthenticationDidChangeVehicleID), name: .FirebaseAuthenticationDidChangeVehicleID, object: nil)

        buildDatabase()
        setUpNavigationItem()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if authentication.vehicleID == nil {
            showSignInView()
        }
    }

    @objc func firebaseAuthenticationDidChangeVehicleID() {
        buildDatabase()
        setUpNavigationItem()
    }

    @objc func buildDatabase() {
        if let vehicleID = authentication.vehicleID {
            let database = SharedItemDatabase(vehicleID: vehicleID)
            database.delegate = self
            database.startUpdating()
            self.database = database
        } else {
            database = nil
            dataSource.setItems([])
            if isVisible {
                showSignInView()
            }
        }
    }

    func setUpNavigationItem() {
        navigationItem.leftBarButtonItem = editButtonItem

        let pairingMenuItem = UIAction(title: "Pair with Dash Remote") { [unowned self] (action) in
            self.sharePairingURL()
        }

        let signOutMenuItem = UIAction(title: "Sign out") { (action) in
            try? Auth.auth().signOut()
        }

        navigationItem.rightBarButtonItem?.menu = UIMenu(title: authentication.email ?? "", children: [pairingMenuItem, signOutMenuItem])
    }

    func database(_ database: SharedItemDatabase, didUpdateItems items: [SharedItemProtocol], withChanges changes: [SharedItemDatabase.Change]) {
        dataSource.setItems(items, changes: changes, animated: !dataSource.isEmpty)
        updateBadge()
    }

    func updateBadge() {
        if let database = database {
            let unopenedCount = database.items.filter { !$0.hasBeenOpened }.count
            navigationController?.tabBarItem.badgeValue = (unopenedCount == 0) ? nil : "\(unopenedCount)"
        } else {
            navigationController?.tabBarItem.badgeValue = nil
        }
    }

    func showSignInView() {
        self.performSegue(withIdentifier: "showSignIn", sender: self)
    }

    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let headerView = view as! UITableViewHeaderFooterView
        headerView.textLabel?.font = UIFont.preferredFont(forTextStyle: .subheadline)
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = dataSource.item(for: indexPath)
        item.open()

        if let indexPathForSelectedRow = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: indexPathForSelectedRow, animated: true)
        }
    }

    func item(for indexPath: IndexPath) -> SharedItemProtocol {
        return dataSource.item(for: indexPath)
    }

    func sharePairingURL() {
        guard let vehicleID = authentication.vehicleID else { return }

        let pairingURLItem = PairingURLItem(vehicleID: vehicleID)
        let activityViewController = UIActivityViewController(activityItems: [pairingURLItem], applicationActivities: nil)
        activityViewController.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
        present(activityViewController, animated: true)
    }
}
