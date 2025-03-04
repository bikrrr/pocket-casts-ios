import SwiftUI
import PocketCastsServer

struct StoriesView: View {
    @ObservedObject private var model: StoriesModel

    @ObservedObject private var syncProgressModel: SyncYearListeningProgress

    @Environment(\.accessibilityShowButtonShapes) var showButtonShapes: Bool

    /// The maximum tap time for a gesture to be recognized as tap
    /// If it's longer than that, it's considered a gesture
    private let maximumTapTime: Double = 0.35

    init(dataSource: StoriesDataSource, configuration: StoriesConfiguration = StoriesConfiguration(), syncProgressModel: SyncYearListeningProgress = .shared) {
        model = StoriesModel(dataSource: dataSource, configuration: configuration)
        self.syncProgressModel = syncProgressModel
    }

    @StateObject private var pauseState = PauseState()

    @ViewBuilder
    var body: some View {
        if model.isReady {
            stories
            .onAppear {
                model.start()
            }
        } else if model.failed {
            failed
        } else {
            loading
        }
    }

    var stories: some View {
        ZStack {
            Spacer()

            storiesToPreload

            ZStack {
                // Manually set the zIndex order to ensure we can change the order when needed
                model.story(index: model.currentStoryIndex)
                    .zIndex(3)
                    .modify {
                        if model.overlaidShareView() != nil {
                            $0.ignoresSafeArea(edges: .bottom)
                        }
                    }
                    .environment(\.animated, true)
                    .environment(\.pauseState, pauseState)

                if model.shouldShowUpsell() {
                    model.paywallView().zIndex(6).onAppear {
                        model.pause()
                    }
                }

                // By default the story switcher will appear above the story and override all
                // interaction, but if the story contains interactive elements then move the
                // switcher to appear behind the view to allow the story override the switcher, or
                // allow the story to pass switcher events thru by controlling the allowsHitTesting
                storySwitcher.zIndex(model.isInteractiveView(index: model.currentStoryIndex) ? 2 : 5)
            }

            header
                .foregroundStyle(model.indicatorColor)

            // Hide the share button if needed
            if model.showShareButton(index: model.currentStoryIndex) && !model.shouldShowUpsell(), let shareView = model.overlaidShareView() {
                VStack {
                    Spacer()
                    shareView
                }
            }
        }
        .modify {
            if model.showShareButton(index: model.currentStoryIndex) && !model.shouldShowUpsell(), let footerView = model.footerShareView() {
                $0.safeAreaInset(edge: .bottom) {
                    footerView
                }
            } else {
                $0
            }
        }
        .background(Color.black)
        .alert(L10n.eoyShareThisStoryTitle,
               isPresented: $model.screenshotTaken) {
            Button(L10n.eoyNotNow) { model.start() }
            Button(L10n.share) { model.share() }.keyboardShortcut(.defaultAction)
        } message: {
            Text(L10n.eoyShareThisStoryMessage)
        }
        .onChange(of: pauseState.isPaused) { isPaused in
            if isPaused {
                model.pause()
            } else {
                model.start()
            }
        }
    }

    // View shown while data source is preparing
    var loading: some View {
        ZStack {
            Spacer()

            VStack(spacing: 15) {
                let progress = syncProgressModel.progress
                CircularProgressView(value: progress, stroke: model.indicatorColor, strokeWidth: 6)
                    .frame(width: 40, height: 40)
                Text(L10n.loading)
                    .foregroundColor(model.indicatorColor)
                    .font(style: .body)
            }

            storySwitcher
            header
        }
        .background(model.primaryBackgroundColor)
    }

    var failed: some View {
        ZStack {
            Spacer()

            Text(L10n.eoyStoriesFailed)
                .foregroundColor(model.indicatorColor)

            storySwitcher
            header
        }
        .background(model.primaryBackgroundColor)
        .onAppear {
            Analytics.track(.endOfYearStoriesFailedToLoad)
        }
    }

    // Header containing the close button and the rectangles
    var header: some View {
        ZStack {
            VStack {
                HStack(spacing: 2) {
                    ForEach(0 ..< model.numberOfStories, id: \.self) { x in
                        StoryIndicator(index: x)
                    }
                }
                .frame(height: Constants.storyIndicatorHeight)
                .padding(.top, 4)
                Spacer()
            }
            .padding(.leading, Constants.storyIndicatorVerticalPadding)
            .padding(.trailing, Constants.storyIndicatorVerticalPadding)

            closeButton
                .foregroundColor(model.indicatorColor)
        }
        .padding(.top, Constants.headerTopPadding)
    }

    var closeButton: some View {
            VStack {
                HStack {
                    Spacer()
                    Button("") {
                        Analytics.track(.endOfYearStoriesDismissed, properties: ["source": "close_button"])
                        model.stopAndDismiss()
                    }.buttonStyle(CloseButtonStyle(showButtonShapes: showButtonShapes))
                    // Inset the button a bit if we're showing the button shapes
                    .padding(.trailing, showButtonShapes ? Constants.storyIndicatorVerticalPadding : 5)
                    .padding(.top, 5)
                    .accessibilityLabel(L10n.accessibilityDismiss)
                }
                .padding(.top, Constants.closeButtonTopPadding)
                Spacer()
            }
        }

    // Invisible component to go to the next/prev story
    @ViewBuilder
    var storySwitcher: some View {
        var ignoreNextTap = false
        var lastDragGestureInteraction: TimeInterval = 0
        HStack(alignment: .center, spacing: Constants.storySwitcherSpacing) {
            Rectangle()
                .foregroundColor(.clear)
                .contentShape(Rectangle())
                .onTapGesture {
                    guard !ignoreNextTap else {
                        ignoreNextTap = false
                        return
                    }

                    model.previous()
                }
            Rectangle()
                .foregroundColor(.clear)
                .contentShape(Rectangle())
                .onTapGesture {
                    guard !ignoreNextTap else {
                        ignoreNextTap = false
                        return
                    }

                    model.next()
                }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .local)
                .onChanged { _ in
                    model.pause()
                    lastDragGestureInteraction = Date.timeIntervalSinceReferenceDate
                }
                .onEnded { value in
                    ignoreNextTap = Date.timeIntervalSinceReferenceDate - lastDragGestureInteraction < maximumTapTime ? false : true

                    let velocity = CGSize(
                        width: value.predictedEndLocation.x - value.location.x,
                        height: value.predictedEndLocation.y - value.location.y
                    )

                    // If a quick swipe down is performed, dismiss the view
                    if velocity.height > 200 {
                        Analytics.track(.endOfYearStoriesDismissed, properties: ["source": "swipe_down"])
                        model.stopAndDismiss()
                    } else {
                        model.start()
                    }
                }
        )
    }

    var storiesToPreload: some View {
        ZStack {
            if model.numberOfStoriesToPreload > 0 {
                ForEach(0...model.numberOfStoriesToPreload, id: \.self) { index in
                    model.preload(index: model.currentStoryIndex + index + 1)
                }
            }
        }
        .opacity(0)
        .allowsHitTesting(false)
    }
}

// MARK: - Constants

private extension StoriesView {
    struct Constants {
        static let storyIndicatorHeight: CGFloat = 2
        static let storyIndicatorVerticalPadding: CGFloat = 13
        static let headerTopPadding: CGFloat = 5

        static let closeButtonPadding: CGFloat = 13
        static let closeButtonTopPadding: CGFloat = 5

        static let storySwitcherSpacing: CGFloat = 0

        static let spaceBetweenShareAndStory: CGFloat = 15

        static let storyCornerRadius: CGFloat = 15
    }
}

// MARK: - Custom Buttons

private struct CloseButtonStyle: ButtonStyle {
    let showButtonShapes: Bool

    func makeBody(configuration: Configuration) -> some View {
        Image("eoy-close")
            .renderingMode(.template)
            .font(style: .body, maxSizeCategory: .extraExtraExtraLarge)
            .padding(Constants.closeButtonPadding)
            .background(showButtonShapes ? Color.white.opacity(0.2) : nil)
            .cornerRadius(Constants.closeButtonRadius)
            .contentShape(Rectangle())
            .applyButtonEffect(isPressed: configuration.isPressed)
    }

    private enum Constants {
        static let closeButtonPadding: CGFloat = 13
        static let closeButtonRadius: CGFloat = 5
    }
}

// MARK: - Preview Provider

struct StoriesView_Previews: PreviewProvider {
    static var previews: some View {
        StoriesView(dataSource: EndOfYearStoriesDataSource(model: EndOfYear2023StoriesModel()))
    }
}
