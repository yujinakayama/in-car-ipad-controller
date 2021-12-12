//
//  SharedItemTableViewCell.swift
//  Dash
//
//  Created by Yuji Nakayama on 2020/02/04.
//  Copyright © 2020 Yuji Nakayama. All rights reserved.
//

import UIKit
import PINRemoteImage

class SharedItemTableViewCell: UITableViewCell {
    enum IconType {
        case template
        case image
    }

    typealias Icon = (image: UIImage, color: UIColor)

    static let screenScale = UIScreen.main.scale

    @IBOutlet weak var iconBackgroundView: BorderedView!
    @IBOutlet weak var iconImageView: UIImageView!
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var actionStackView: UIStackView!

    let openStatusView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBlue
        return view
    }()

    @IBOutlet weak var iconImageViewSmallWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var iconImageViewSmallHeightConstraint: NSLayoutConstraint!

    @IBOutlet var iconImageViewNoMarginConstraints: [NSLayoutConstraint]!

    let parkingSearchButton: UIButton = {
        let fontMetrics = UIFontMetrics(forTextStyle: .subheadline)
        let font = fontMetrics.scaledFont(for: .boldSystemFont(ofSize: 15))

        var configuration = UIButton.Configuration.gray()
        configuration.buttonSize = .small
        configuration.cornerStyle = .capsule
        configuration.attributedTitle = AttributedString(String(localized: "駐車場検索"), attributes: .init([.font: font]))

        let button = UIButton(configuration: configuration)
        button.setContentHuggingPriority(.required, for: .horizontal)
        return button
    }()

    var defaultIconCornerRadius: CGFloat!

    var iconImageTask: Task<Void, Never>?

    override func awakeFromNib() {
        defaultIconCornerRadius = iconBackgroundView.cornerRadius

        addOpenStatusView()

        actionStackView.addArrangedSubview(parkingSearchButton)

        // Not sure why but constraints are reset to Storyboard's state when app goes background and back to foreground
        // https://stackoverflow.com/questions/58376388/constraints-resets-when-app-is-going-in-background-ios-13
        NotificationCenter.default.addObserver(forName: UIScene.willEnterForegroundNotification, object: nil, queue: .main) { [weak self] (notification) in
            self?.setNeedsUpdateConstraints()
        }
    }

    private func addOpenStatusView() {
        // We add openStatusView to UITableViewCell itself rather than its contentView
        // so that openStatusView won't be indented in editing mode.
        addSubview(openStatusView)

        openStatusView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            openStatusView.leadingAnchor.constraint(equalTo: leadingAnchor),
            openStatusView.widthAnchor.constraint(equalToConstant: 4),
            openStatusView.topAnchor.constraint(equalTo: topAnchor),
            bottomAnchor.constraint(equalTo: openStatusView.bottomAnchor)
        ])
    }

    override func prepareForReuse() {
        super.prepareForReuse()

        iconImageTask?.cancel()
        iconImageTask = nil

        iconImageView.pin_cancelImageDownload()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        // The unintentional constraints reset also happens when changing to dark mode
        setNeedsUpdateConstraints()

        updateActionButtonVisibility()
    }

    var item: SharedItemProtocol? {
        didSet {
            iconBackgroundView.cornerRadius = defaultIconCornerRadius

            switch item {
            case let location as Location:
                configureView(for: location)
            case let musicItem as MusicItem:
                configureView(for: musicItem)
            case let website as Website:
                configureView(for: website)
            default:
                configureView(for: item)
            }

            updateActionButtonVisibility()

            openStatusView.isHidden = item?.hasBeenOpened ?? true
        }
    }

    private func configureView(for location: Location) {
        let icon = icon(for: location)

        iconType = .template
        iconImageView.image = icon.image
        iconBackgroundView.backgroundColor = icon.color

        nameLabel.text = location.name
        detailLabel.text = location.formattedAddress ?? location.address.country
    }

    private func icon(for location: Location) -> Icon {
        for category in location.categories {
            if let icon = icon(for: category) {
                return icon
            }
        }

        if location.categories.contains(.touristAttraction) {
            return (
                image: UIImage(systemName: "star.fill")!,
                color: UIColor(rgb: 0x969696)
            )
        }

        return (
            image: UIImage(systemName: "mappin")!,
            color: UIColor(rgb: 0xEB5956)
        )
    }

    private func icon(for category: Location.Category) -> Icon? {
        let image: UIImage?
        let color: UIColor?

        switch category {
        case .airport:
            image = UIImage(systemName: "airplane")
            color = UIColor(rgb: 0x6599F8)
        case .buddhistTemple:
            image = UIImage(named: "manji")
            color = UIColor(rgb: 0xA8825B)
        case .cafe:
            image = UIImage(systemName: "cup.and.saucer.fill")
            color = UIColor(rgb: 0xEA9A52)
        case .carRepair:
            image = UIImage(systemName: "wrench.fill")
            color = UIColor(rgb: 0x7381AF)
        case .cityHall, .localGovernmentOffice, .museum:
            image = UIImage(systemName: "building.columns.fill")
            color = UIColor(rgb: 0x7381AF)
        case .doctor:
            image = UIImage(systemName: "stethoscope")
            color = UIColor(rgb: 0xE9675F)
        case .gasStation:
            image = UIImage(systemName: "fuelpump.fill")
            color = UIColor(rgb: 0x4B9EF8)
        case .hospital:
            image = UIImage(systemName: "cross.fill")
            color = UIColor(rgb: 0xE9675F)
        case .hotel, .lodging:
            image = UIImage(systemName: "bed.double.fill")
            color = UIColor(rgb: 0x9688F7)
        case .mealTakeaway, .mealDelivery, .food:
            image = UIImage(systemName: "takeoutbag.and.cup.and.straw.fill")
            color = UIColor(rgb: 0xEA9A52)
        case .park, .nationalPark:
            image = UIImage(systemName: "leaf.fill")
            color = UIColor(rgb: 0x54B741)
        case .parking:
            image = UIImage(systemName: "parkingsign")
            color = UIColor(rgb: 0x4C9EF8)
        case .pharmacy, .drugstore:
            image = UIImage(systemName: "pills")
            color = UIColor(rgb: 0xEC6860)
        case .publicTransport, .trainStation, .subwayStation, .lightRailStation, .transitStation:
            image = UIImage(systemName: "tram.fill")
            color = UIColor(rgb: 0x4C9EF8)
        case .restaurant:
            image = UIImage(systemName: "fork.knife")
            color = UIColor(rgb: 0xEA9A52)
        case .shintoShrine:
            image = UIImage(named: "torii")
            color = UIColor(rgb: 0xA8825B)
        case .spa:
            image = UIImage(named: "hotspring")
            color = UIColor(rgb: 0xEC6860)
        case .store, .bookStore, .clothingStore, .departmentStore, .electronicsStore, .furnitureStore, .hardwareStore, .homeGoodsStore, .jewelryStore, .shoppingMall:
            image = UIImage(systemName: "bag.fill")
            color = UIColor(rgb: 0xF3B63F)
        case .supermarket, .foodMarket, .groceryOrSupermarket:
            image = UIImage(systemName: "cart")
            color = UIColor(rgb: 0xF3B63F)
        case .theater, .movieTheater:
            image = UIImage(systemName: "theatermasks.fill")
            color = UIColor(rgb: 0xD673D1)
        default:
            image = nil
            color = nil
        }

        if let image = image, let color = color {
            return (image: image, color: color)
        } else {
            return nil
        }
    }

    private func configureView(for musicItem: MusicItem) {
        iconType = .template
        iconImageView.image = UIImage(systemName: "music.note")
        iconBackgroundView.backgroundColor = .systemPink

        if let artworkURL = musicItem.artworkURL(size: iconImagePixelSize) {
            setRemoteImage(url: artworkURL) { (error) in
                if error == nil {
                    self.iconBackgroundView.cornerRadius = 2
                }
            }
        }

        nameLabel.text = musicItem.name
        detailLabel.text = musicItem.creator
    }

    private func configureView(for website: Website) {
        iconType = .template
        iconImageView.image = UIImage(systemName: "safari.fill")
        iconBackgroundView.backgroundColor = .systemBlue

        iconImageTask = Task {
            if let iconURL = await website.icon.getURL() {
                DispatchQueue.main.async {
                    self.setRemoteImage(url: iconURL)
                }
            }
        }

        nameLabel.text = website.title ?? website.url.absoluteString
        detailLabel.text = website.url.host
    }

    private func configureView(for unknownItem: SharedItemProtocol?) {
        iconType = .template
        iconImageView.image = UIImage(systemName: "questionmark")
        iconBackgroundView.backgroundColor = .gray

        nameLabel.text = String(localized: "Unknown Item")
        detailLabel.text = unknownItem?.url.absoluteString
    }

    private func setRemoteImage(url: URL, completionHandler: ((Error?) -> Void)? = nil) {
        let originalIconType = iconType
        let originalImage = iconImageView.image
        let originalBackgroundColor = iconBackgroundView.backgroundColor

        DispatchQueue.main.async {
            self.iconImageView.pin_setImage(from: url) { (result) in
                if result.error == nil {
                    self.iconType = .image
                    self.iconBackgroundView.backgroundColor = .white
                } else {
                    self.iconType = originalIconType
                    self.iconImageView.image = originalImage
                    self.iconBackgroundView.backgroundColor = originalBackgroundColor
                }

                completionHandler?(result.error)
            }
        }
    }

    private func updateActionButtonVisibility() {
        let visible = item is Location && traitCollection.horizontalSizeClass != .compact
        parkingSearchButton.isHidden = !visible

        actionStackView.isHidden = actionStackView.arrangedSubviews.allSatisfy { $0.isHidden }
    }

    private var iconType: IconType = .template {
        didSet {
            switch iconType {
            case .template:
                iconImageView.contentMode = .scaleAspectFit
            case .image:
                iconImageView.contentMode = .scaleAspectFill
            }

            if iconType != oldValue {
                setNeedsUpdateConstraints()
            }
        }
    }

    override func updateConstraints() {
        switch iconType {
        case .template:
            NSLayoutConstraint.deactivate(iconImageViewNoMarginConstraints)
            iconImageViewSmallWidthConstraint.isActive = true
            iconImageViewSmallHeightConstraint.isActive = true
        case .image:
            iconImageViewSmallWidthConstraint.isActive = false
            iconImageViewSmallHeightConstraint.isActive = false
            NSLayoutConstraint.activate(iconImageViewNoMarginConstraints)
        }

        super.updateConstraints()
    }

    var iconImagePixelSize: CGSize {
        let pointSize = iconBackgroundView.bounds.size

        return CGSize(
            width: pointSize.width * SharedItemTableViewCell.screenScale,
            height: pointSize.height * SharedItemTableViewCell.screenScale
        )
    }
}

fileprivate extension UIColor {
    convenience init(red: Int, green: Int, blue: Int) {
       assert(red >= 0 && red <= 255, "Invalid red component")
       assert(green >= 0 && green <= 255, "Invalid green component")
       assert(blue >= 0 && blue <= 255, "Invalid blue component")

       self.init(red: CGFloat(red) / 255.0, green: CGFloat(green) / 255.0, blue: CGFloat(blue) / 255.0, alpha: 1.0)
   }

   convenience init(rgb: Int) {
       self.init(
           red: (rgb >> 16) & 0xFF,
           green: (rgb >> 8) & 0xFF,
           blue: rgb & 0xFF
       )
   }
}
