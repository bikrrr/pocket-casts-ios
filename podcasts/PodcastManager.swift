import Foundation
import PocketCastsDataModel
import PocketCastsServer
import PocketCastsUtils

class PodcastManager: NSObject {
    private static let maxAutoDownloadSeperationTime = 12.hours

    @objc static let shared = PodcastManager(dataManager: DataManager.sharedManager, downloadManager: DownloadManager.shared)

    lazy var isoFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        return formatter
    }()

    lazy var subscribeQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1

        return queue
    }()

    lazy var importerQueue: OperationQueue = {
        let queue = OperationQueue()
        queue.maxConcurrentOperationCount = 1

        return queue
    }()

    let dataManager: DataManager
    let downloadManager: DownloadManager

    init(dataManager: DataManager, downloadManager: DownloadManager) {
        self.dataManager = dataManager
        self.downloadManager = downloadManager
    }

    // MARK: - Notifications

    #if !os(watchOS)
        func setNotificationsEnabled(podcast: Podcast, enabled: Bool) {
            if enabled {
                if !NotificationsHelper.shared.pushEnabled() {
                    // this is the first podcast to enable push, to work around the fact that we defaulted that to on at the data layer, turn it off for every podcast
                    // this means it just ends up being on for this one podcast, not all of them
                    let podcasts = dataManager.allPodcasts(includeUnsubscribed: false)
                    var foundPushOff = false
                    for podcast in podcasts {
                        if !podcast.isPushEnabled {
                            foundPushOff = true
                            break
                        }
                    }

                    if !foundPushOff {
                        dataManager.setPushForAllPodcasts(pushEnabled: false)
                    }

                    NotificationsHelper.shared.enablePush()
                }
            }

            if FeatureFlag.newSettingsStorage.enabled {
                podcast.settings.notification = enabled
                podcast.syncStatus = SyncStatus.notSynced.rawValue
                dataManager.save(podcast: podcast)
            } else {
                dataManager.savePushSetting(podcast: podcast, pushEnabled: enabled)
            }
        }
    #endif

    func allPodcastsSorted(in sortOrder: LibrarySort, reloadFromDatabase: Bool = false) -> [Podcast] {
        if sortOrder == .titleAtoZ {
            return dataManager.allPodcastsOrderedByTitle(reloadFromDatabase: reloadFromDatabase)
        } else if sortOrder == .episodeDateNewestToOldest {
            return dataManager.allPodcastsOrderedByNewestEpisodes(reloadFromDatabase: reloadFromDatabase)
        } else if sortOrder == .dateAddedNewestToOldest {
            return dataManager.allPodcastsOrderedByAddedDate(reloadFromDatabase: reloadFromDatabase)
        } else {
            return dataManager.allPodcasts(includeUnsubscribed: false, reloadFromDatabase: reloadFromDatabase)
        }
    }

    func didReceiveToken(_ token: String) {
        #if !os(watchOS)
            let currentToken = ServerSettings.pushToken()

            if currentToken == token { return } // they are the same, no need to do anything

            ServerSettings.setPushToken(token: token)

            RefreshManager.shared.refreshPodcasts(forceEvenIfRefreshedRecently: true)
        #endif
    }

    // MARK: - Downloads

    func checkForPendingAndAutoDownloads() {
        // check if any existing episode that have been queued need to be downloading
        if NetworkUtils.shared.isConnectedToWifi() {
            let queuedEpisodes = dataManager.findEpisodesWhere(customWhere: "episodeStatus == ?", arguments: [DownloadStatus.waitingForWifi.rawValue])
            for episode in queuedEpisodes {
                downloadManager.addToQueue(episodeUuid: episode.uuid, fireNotification: false, autoDownloadStatus: AutoDownloadStatus(rawValue: episode.autoDownloadStatus) ?? .notSpecified)
            }
        }

        // check if any existing episodes were downloading, but aren't currently (caused by app force quit while episode was downloading)
        let stuckDownloadingEpisodes = dataManager.findEpisodesWhere(customWhere: "episodeStatus == ?", arguments: [DownloadStatus.downloading.rawValue])
        for episode in stuckDownloadingEpisodes {
            if !downloadManager.isEpisodeDownloading(episode) {
                if Settings.autoDownloadMobileDataAllowed() || NetworkUtils.shared.isConnectedToWifi() {
                    downloadManager.addToQueue(episodeUuid: episode.uuid, fireNotification: false, autoDownloadStatus: AutoDownloadStatus(rawValue: episode.autoDownloadStatus) ?? .notSpecified)
                }
                else {
                    // If we're not downloading over cellular, clear task id so its not removed by the "stuck download" cleaner, and queue it for later
                    dataManager.clearDownloadTaskId(episode: episode)
                    downloadManager.queueForLaterDownload(episodeUuid: episode.uuid, fireNotification: false, autoDownloadStatus: AutoDownloadStatus(rawValue: episode.autoDownloadStatus) ?? .notSpecified)
                }
            }
        }

        checkIfAutoDownloadsRequired()

        // fire off a single notification for any action that might have been performed above
        NotificationCenter.postOnMainThread(notification: Constants.Notifications.manyEpisodesChanged)
    }

    private func checkIfAutoDownloadsRequired() {
        // then check if there's any new auto download ones we should be adding to that queue
        if !Settings.autoDownloadEnabled() { return }

        let podcasts = dataManager.allPodcasts(includeUnsubscribed: false)
        for podcast in podcasts {
            checkForEpisodesToDownload(podcast: podcast)
        }
    }

    func applyAutoArchivingToAllPodcasts() {
        let podcasts = dataManager.allPodcasts(includeUnsubscribed: false)
        for podcast in podcasts {
            ArchiveHelper.applyAutoArchivingToPodcast(podcast)
        }
    }

    private func checkForEpisodesToDownload(podcast: Podcast) {
        if !podcast.autoDownloadOn() { return }
        let episodesLimit = FeatureFlag.autoDownloadOnSubscribe.enabled ? Settings.autoDownloadLimits().rawValue : 4
        let latestEpisodes = dataManager.findEpisodesWhere(customWhere: "podcast_id == ? ORDER BY publishedDate DESC, addedDate DESC LIMIT ?", arguments: [podcast.id, episodesLimit])
        guard let latestEpisode = latestEpisodes.first else { return } // no episodes to download

        for episode in latestEpisodes {
            if episode.played() || episode.archived { return } // as soon as we hit a played or archived episode don't look any further

            // as soon as we hit an episode that's too old to download don't look any further
            if let latestPubDate = latestEpisode.publishedDate, let episodePubDate = episode.publishedDate {
                if latestEpisode != episode, fabs(episodePubDate.timeIntervalSince(latestPubDate)) > PodcastManager.maxAutoDownloadSeperationTime {
                    return
                }
            }

            if episode.exemptFromAutoDownload() || episode.downloaded(pathFinder: downloadManager) || episode.queued() || episode.downloading() { continue }

            if Settings.autoDownloadMobileDataAllowed() || NetworkUtils.shared.isConnectedToWifi() {
                downloadManager.addToQueue(episodeUuid: episode.uuid, fireNotification: false, autoDownloadStatus: .autoDownloaded)
            } else {
                downloadManager.queueForLaterDownload(episodeUuid: episode.uuid, fireNotification: false, autoDownloadStatus: .autoDownloaded)
            }
        }
    }

    // MARK: - Import

    #if !os(watchOS)
        func importSharedItemFromUrl(_ strippedUrl: String, completion: @escaping (IncomingShareItem?) -> Void) {
            importerQueue.cancelAllOperations()

            let importer = SharedItemImporter(strippedUrl: strippedUrl, completion: completion)
            importerQueue.addOperation(importer)
        }

        func importPodcastsFromOpml(_ opmlFile: URL, progressWindow: ShiftyLoadingAlert? = nil) {
            importerQueue.cancelAllOperations()

            let importer = OpmlImporter(opmlFile: opmlFile, progressWindow: progressWindow)
            importerQueue.addOperation(importer)
        }
    #endif

    class func episodeCountForPodcast(_ podcast: Podcast, excludeArchive: Bool) -> Int {
        let archivedFilter = excludeArchive ? " AND archived = 0" : ""
        let query = "SELECT COUNT(*) FROM \(DataManager.episodeTableName) WHERE podcast_id = ?\(archivedFilter)"

        return DataManager.sharedManager.count(query: query, values: [podcast.id])
    }
}
