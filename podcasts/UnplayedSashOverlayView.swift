import PocketCastsDataModel
import UIKit

class UnplayedSashOverlayView: UIView {
    private let badgeLabel = UILabel()

    private var labelWidthConstraint: NSLayoutConstraint!

    override init(frame: CGRect) {
        super.init(frame: frame)

        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)

        setup()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func populateFrom(podcast: Podcast, badgeType: BadgeType, libraryType: LibraryType) {
        updateBadge(count: podcast.cachedUnreadCount, badgeType: badgeType)
    }

    func populateFrom(folder: Folder, badgeType: BadgeType, libraryType: LibraryType) {
        updateBadge(count: folder.cachedUnreadCount, badgeType: badgeType)
    }

    private func updateBadge(count: Int, badgeType: BadgeType) {
        if count > 0 {
            badgeLabel.isHidden = false
            badgeLabel.text = count < 99 ? "\(count)" : "99"
            if count > 9 {
                labelWidthConstraint.constant = 26
            } else {
                labelWidthConstraint.constant = 20
            }
        } else {
            badgeLabel.isHidden = true
        }
    }

    private func setup() {
        badgeLabel.font = UIFont.systemFont(ofSize: 11, weight: .semibold)
        badgeLabel.translatesAutoresizingMaskIntoConstraints = false
        badgeLabel.textAlignment = .center
        addSubview(badgeLabel)
        labelWidthConstraint = badgeLabel.widthAnchor.constraint(equalToConstant: 20)
        NSLayoutConstraint.activate([
            badgeLabel.heightAnchor.constraint(equalToConstant: 20),
            labelWidthConstraint,
            badgeLabel.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])

        NotificationCenter.default.addObserver(self, selector: #selector(themeDidChange), name: Constants.Notifications.themeChanged, object: nil)

        updateBadgeColors()
    }

    @objc private func themeDidChange() {
        updateBadgeColors()
    }

    private func updateBadgeColors() {
        badgeLabel.clipsToBounds = true
        backgroundColor = .clear
        badgeLabel.textColor = ThemeColor.primaryInteractive02()
        badgeLabel.backgroundColor = ThemeColor.primaryInteractive01()
        badgeLabel.layer.borderColor = ThemeColor.primaryUi02().cgColor
        badgeLabel.layer.borderWidth = 2
        badgeLabel.layer.cornerRadius = 10
    }
}
