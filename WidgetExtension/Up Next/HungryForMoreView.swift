import Foundation
import SwiftUI

struct HungryForMoreView: View {
    @Environment(\.widgetColorScheme) var colorScheme
    @Environment(\.isAccentedRenderingMode) var isAccentedRenderingMode

    var body: some View {
        Link(destination: URL(string: "pktc://discover?source=widget")!) {
            VStack(alignment: .center, spacing: 3) {
                Text(L10n.widgetsDiscoverPromptTitle)
                    .font(.footnote)
                    .fontWeight(.semibold)
                    .foregroundColor(colorScheme.bottomTextColor)
                    .lineLimit(1)
                    .backwardWidgetAccentable(isAccentedRenderingMode)
                Text(L10n.widgetsDiscoverPromptMsg)
                    .font(.caption2)
                    .foregroundColor(colorScheme.bottomTextColor.opacity(0.8))
                    .lineLimit(1)
                    .backwardWidgetAccentable(isAccentedRenderingMode)
            }
            .offset(x: -8, y: 0)
        }
    }
}

struct HungryForMoreLargeView: View {
    @Environment(\.widgetColorScheme) var colorScheme
    @Environment(\.isAccentedRenderingMode) var isAccentedRenderingMode

    var body: some View {
        Link(destination: URL(string: "pktc://discover?source=widget")!) {
            VStack(alignment: .center, spacing: 4) {
                Text(L10n.widgetsDiscoverPromptTitle)
                    .font(.footnote)
                    .fontWeight(.semibold)
                    .foregroundColor(colorScheme.bottomTextColor)
                    .lineLimit(1)
                    .backwardWidgetAccentable(isAccentedRenderingMode)
                Text(L10n.widgetsDiscoverPromptMsg)
                    .font(.caption2)
                    .foregroundColor(colorScheme.bottomTextColor.opacity(0.8))
                    .lineLimit(1)
                    .backwardWidgetAccentable(isAccentedRenderingMode)
            }
        }
    }
}
