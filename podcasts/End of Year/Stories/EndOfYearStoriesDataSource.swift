import SwiftUI
import PocketCastsDataModel

class EndOfYearStoriesDataSource: StoriesDataSource {
    var numberOfStories: Int = 6

    var listeningTime: Double?

    var listenedCategories: [ListenedCategory] = []

    var listenedNumbers: ListenedNumbers?

    var topPodcasts: [TopPodcast] = []

    var longestEpisode: Episode?

    func story(for storyNumber: Int) -> any StoryView {
        switch storyNumber {
        case 0:
            return ListeningTimeStory(listeningTime: listeningTime!)
        case 1:
            return ListenedCategoriesStory(listenedCategories: listenedCategories)
        case 2:
            return TopListenedCategories(listenedCategories: listenedCategories)
        case 3:
            return ListenedNumbersStory(listenedNumbers: listenedNumbers!)
        case 4:
            return TopOnePodcastStory(topPodcast: topPodcasts[0])
        default:
            return TopFivePodcastsStory(podcasts: topPodcasts.map { $0.podcast })
        }
    }

    func isReady() async -> Bool {
        await withCheckedContinuation { continuation in
            self.listeningTime = DataManager.sharedManager.listeningTime()

            self.listenedCategories = DataManager.sharedManager.listenedCategories()

            self.listenedNumbers = DataManager.sharedManager.listenedNumbers()

            self.topPodcasts = DataManager.sharedManager.topPodcasts()

            self.longestEpisode = DataManager.sharedManager.longestEpisode()

            continuation.resume(returning: true)
        }
    }
}
