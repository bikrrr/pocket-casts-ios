import Foundation

public enum FeatureFlag: String, CaseIterable {

    /// Whether logging of Tracks events in console are enabled
    case tracksLogging

    /// Whether logging of Firebase events in console are enabled
    case firebaseLogging

    /// Whether network debugging with Pulse is enabled
    case networkDebugging

    /// Whether End Of Year feature is enabled
    case endOfYear

    /// Enable show notes using the new endpoint
    case newShowNotesEndpoint

    /// Enable retrieving episode artwork from the RSS feed
    case episodeFeedArtwork

    /// Enable chapters to be loaded from the RSS feed
    case rssChapters

    /// Enable a quicker and more responsive player transition
    case newPlayerTransition

    /// Avoid logging out user on non-authorization HTTP errors
    case errorLogoutHandling

    /// Enable the ability to rate podcasts
    case giveRatings

    /// Enable selecting/deselecting episode chapters
    case deselectChapters

    /// Store settings as JSON in User Defaults (global) or SQLite (podcast)
    case newSettingsStorage

    /// Syncing all app and podcast settings
    case settingsSync

    /// Show the modal about the partnership with Slumber Studios
    case slumber

    /// Enable the new flow for Account upgrade prompt where it start IAP flow directly from account cell
    case newAccountUpgradePromptFlow

    /// Enable the AVExportSession parallel download of any playing episode
    case streamAndCachePlayingEpisode

    case categoriesRedesign

    /// show UpNext tab on the main tab bar
    case upNextOnTabBar

    /// When enabled it updates the code on filter callback to use a safer method to convert unmanaged player references
    /// This is to fix this: https://a8c.sentry.io/share/issue/39a6d2958b674ec3b7a4d9248b4b5ffa/
    case defaultPlayerFilterCallbackFix

    case downloadFixes

    /// When a user sign in, we always mark ALL podcasts as unsynced
    /// This recently caused issues, syncing changes that shouldn't have been synced
    /// When `true`, we only mark podcasts as unsynced if the user never signed in before
    case onlyMarkPodcastsUnsyncedForNewUsers

    /// Only update an episode if it fails playing
    /// If set to `false`, it will use the previous mechanism that always update
    /// but can lead to a bigger time between tapping play and actually playing it
    case whenPlayingOnlyUpdateEpisodeIfPlaybackFails

    /// Use the Accelerate framework to speed up custom effects
    case accelerateEffects

    case newSharing

    /// Enable the transcripts feature on podcasts episodes
    case transcripts

    /// Enables the Kids banner
    case kidsProfile

    /// Enable the new Upgrade Experiments
    case upgradeExperiment

    /// When enabled, we ignore audio interruptions with InterruptionReason set to routeDisconnected
    /// (introduced in iOS 17 and watchOS 10) because these are not really interruptions as we have
    /// implemented them previously. If the route is disconnected, audio stops indefinitely
    /// until a new route connects (for which we'll received a different notification and handle accordingly)
    /// See: https://github.com/Automattic/pocket-casts-ios/issues/2049
    case ignoreRouteDisconnectedInterruption

    /// Enable the Referrals feature
    case referrals

    /// Enables the referrals Send Flow
    case referralsSend

    /// Enables the referrals Claim Flow
    case referralsClaim

    /// When accessing Stats, it checks if the local stats are behind remote
    /// If it is, it updates it
    /// This is meant to fix an issue for users that were losing stats
    case syncStats

    /// Enable the refactored discover collection view
    case discoverCollectionView

    /// Uses the `isReadyToPlay` function to decide what logic to use when skipping.
    /// There's some scenario when the Default player switched to the Effects player when the stream is paused.
    /// This makes the skip unusable as the player doesn't have its task set yet.
    /// If the player is not ready to play, we should use the same logic we use when the player doesn't exist yet.
    case playerIsReadyToPlay

    // Shows the searchbar in Listening History view
    case listeningHistorySearch

    /// Use the Mimetype library to check the file mimetype
    case useMimetypePackage

    /// Enable the Segmented Control into the Effects Player panel
    /// to apply the Global or local settings
    case customPlaybackSettings

    /// Run a vacuum process on the database in order to optimize data fetch
    case runVacuumOnVersionUpdate

    /// Enable the End of Year 2024 recap
    case endOfYear2024

    /// Enable the Up Next shuffle button
    case upNextShuffle

    /// Push two auto downloads on subscribe of a podcast
    case autoDownloadOnSubscribe

    /// Replace Subscribe/Unsubscribe with Follow/Unfollow
    case useFollowNaming

    /// Use a cookie to manage `MTAudioProcessingTap` deallocation
    case useDefaultPlayerTapCookie

    /// Use single update query to mark all episodes selected synced
    case markAllSyncedInSingleStatement

    public var enabled: Bool {
        if let overriddenValue = FeatureFlagOverrideStore().overriddenValue(for: self) {
            return overriddenValue
        }

        return `default`
    }

    public var `default`: Bool {
        switch self {
        case .tracksLogging:
            false
        case .firebaseLogging:
            false
        case .networkDebugging:
            false
        case .endOfYear:
            false
        case .newShowNotesEndpoint:
            false
        case .episodeFeedArtwork:
            false
        case .rssChapters:
            false
        case .newPlayerTransition:
            true
        case .errorLogoutHandling:
            false
        case .giveRatings:
            false
        case .deselectChapters:
            false
        case .newSettingsStorage:
            shouldEnableSyncedSettings
        case .settingsSync:
            shouldEnableSyncedSettings
        case .slumber:
            false
        case .newAccountUpgradePromptFlow:
            false
        case .streamAndCachePlayingEpisode:
            true
        case .categoriesRedesign:
            true
        case .defaultPlayerFilterCallbackFix:
            true
        case .upNextOnTabBar:
            true
        case .downloadFixes:
            true
        case .onlyMarkPodcastsUnsyncedForNewUsers:
            true
        case .whenPlayingOnlyUpdateEpisodeIfPlaybackFails:
            true
        case .accelerateEffects:
            true
        case .newSharing:
            true
        case .transcripts:
            true
        case .kidsProfile:
            false
        case .upgradeExperiment:
            false
        case .ignoreRouteDisconnectedInterruption:
            true
        case .referrals:
            true
        case .referralsClaim:
            true
        case .referralsSend:
            true
        case .syncStats:
            true
        case .discoverCollectionView:
            true
        case .playerIsReadyToPlay:
            true
        case .listeningHistorySearch:
            true
        case .useMimetypePackage:
            true
        case .customPlaybackSettings:
            true
        case .runVacuumOnVersionUpdate:
            true
        case .endOfYear2024:
            true
        case .upNextShuffle:
            true
        case .autoDownloadOnSubscribe:
            true
        case .useFollowNaming:
            true
        case .useDefaultPlayerTapCookie:
            true
        case .markAllSyncedInSingleStatement:
            true
        }
    }

    private var shouldEnableSyncedSettings: Bool {
        false
    }

    /// Remote Feature Flag
    /// This should match a Firebase Remote Config Parameter name (key)
    public var remoteKey: String? {
        switch self {
        case .deselectChapters:
            "deselect_chapters_enabled"
        case .newAccountUpgradePromptFlow:
            "new_account_upgrade_prompt_flow"
        case .newSettingsStorage:
            shouldEnableSyncedSettings ? "new_settings_storage" : nil
        case .settingsSync:
            shouldEnableSyncedSettings ? "settings_sync" : nil
        case .newShowNotesEndpoint:
             "new_show_notes"
         case .episodeFeedArtwork:
             "episode_artwork"
         case .rssChapters:
             "rss_chapters"
        case .categoriesRedesign:
            "categories_redesign"
        case .defaultPlayerFilterCallbackFix:
            "default_player_filter_callback_fix"
        case .upNextOnTabBar:
            "up_next_on_tab_bar"
        default:
            rawValue.lowerSnakeCased()
        }
    }
}

extension FeatureFlag: OverrideableFlag {
    public var description: String {
        rawValue
    }

    public var canOverride: Bool {
        true
    }

    private static let isTestFlight = Bundle.main.appStoreReceiptURL?.lastPathComponent == "sandboxReceipt"
}
