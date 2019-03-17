//
//  This file is part of the NineAnimator project.
//
//  Copyright © 2018-2019 Marcus Zhou. All rights reserved.
//
//  NineAnimator is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  NineAnimator is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with NineAnimator.  If not, see <http://www.gnu.org/licenses/>.
//

import UIKit

/// The scene that list anime from a ContentProvider
class ContentListViewController: UITableViewController, ContentProviderDelegate {
    private var providerError: Error?
    
    // swiftlint:disable:next implicitly_unwrapped_optional
    private var contentSource: ContentProvider!

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.rowHeight = 160
        tableView.tableFooterView = UIView()
        tableView.makeThemable()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        providerError = nil
        
        // Make sure the content source exists
        guard contentSource != nil else { return }
        
        // Set delegate
        contentSource.delegate = self
        title = contentSource.title
        
        // Request the first page
        if contentSource.availablePages == 0 && contentSource.moreAvailable {
            contentSource.more()
        }
    }
    
    override func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let height = scrollView.frame.size.height
        let contentYoffset = scrollView.contentOffset.y
        let distanceFromBottom = scrollView.contentSize.height - contentYoffset
        if distanceFromBottom < height { contentSource.more() }
    }
}

// MARK: - Initializing the SearchViewController
extension ContentListViewController {
    /// Configure the ContentListViewController to display contents
    /// from the provided ContentProvider
    ///
    /// This method should be called before the scene appears.
    ///
    /// Upon viewWillAppear(), the first invokation to Provider.more()
    /// will be performed. The next invokations will be made when
    /// the user scroll down to the end of the page.
    func setPresenting(contentProvider provider: ContentProvider) {
        self.contentSource = provider
    }
}

// MARK: - Table view data source
extension ContentListViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        guard contentSource != nil else { return 0 }
        return contentSource.availablePages + (contentSource.moreAvailable || contentSource.totalPages == 0 ? 1 : 0)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == contentSource.availablePages || contentSource.availablePages == 0 {
            tableView.separatorStyle = .none
            return 1
        }
        tableView.separatorStyle = .singleLine
        return contentSource.links(on: section).count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let providerError = providerError {
            let cell = tableView.dequeueReusableCell(withIdentifier: "search.notfound", for: indexPath) as! ContentErrorTableViewCell
            cell.error = providerError
            cell.makeThemable()
            return cell
        }
        
        if contentSource.availablePages == indexPath.section {
            let cell = tableView.dequeueReusableCell(withIdentifier: "search.loading", for: indexPath) as! ContentListingLoadingTableViewCell
            cell.activates()
            cell.makeThemable()
            return cell
        } else {
            guard let cell = tableView.dequeueReusableCell(withIdentifier: "search.result", for: indexPath) as? ListingEntryTableViewCell else { fatalError("cell type dequeued is not AnimeSearchResultTableViewCell") }
            cell.link = contentSource.links(on: indexPath.section)[indexPath.item]
            cell.makeThemable()
            return cell
        }
    }
}

// MARK: - Delegate taps
extension ContentListViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        defer { tableView.deselectSelectedRow() }
        guard let cell = tableView.cellForRow(at: indexPath) else { return }
        
        // Open the link if it exists
        if let cell = cell as? ListingEntryTableViewCell,
            let link = cell.link {
            RootViewController.shared?.open(immedietly: link, in: self)
        }
    }
}

// MARK: - ContentProvider delegate methods
extension ContentListViewController {
    func onError(_ error: Error, from: ContentProvider) {
        self.providerError = error
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.tableView.rowHeight = 300
            self.tableView.reloadSections([0], with: .automatic)
        }
    }
    
    func pageIncoming(_ sectionNumber: Int, from page: ContentProvider) {
        DispatchQueue.main.async(execute: tableView.reloadData)
    }
}