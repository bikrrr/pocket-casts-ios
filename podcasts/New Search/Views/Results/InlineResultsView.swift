import SwiftUI
import PocketCastsServer

struct InlineResultsView: View {
    @EnvironmentObject var theme: Theme

    @ObservedObject var searchResults: SearchResultsModel

    let searchHistory: SearchHistoryModel?

    /// If this view should show podcasts or episodes
    var showPodcasts = true

    var body: some View {
        VStack {
            ThemedDivider()
            ScrollViewIfNeeded {
                LazyVStack(spacing: 0) {
                    Section {
                        if showPodcasts {
                            ForEach(searchResults.podcasts, id: \.self) { podcast in

                                SearchEpisodeCell(episode: nil, podcast: podcast, searchHistory: searchHistory)
                            }
                        } else {
                            ForEach(searchResults.episodes, id: \.self) { episode in

                                SearchEpisodeCell(episode: episode, podcast: nil, searchHistory: searchHistory)
                            }
                        }
                    }
                }
            }
            .navigationBarTitle(Text(showPodcasts ? L10n.discoverAllPodcasts : "All Episodes"))
        }
    }
}

struct PodcastResultsView_Previews: PreviewProvider {
    static var previews: some View {
        InlineResultsView(searchResults: SearchResultsModel(), searchHistory: nil)
    }
}
