import SwiftUI

struct WordOfDayCardView: View {
    let wordOfDay: WordOfDayEntry
    let action: () -> Void
    let dismiss: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                Button(action: action) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Word of the Day")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text(wordOfDay.entry.word)
                            .font(.system(size: 22, weight: .semibold, design: .serif))
                            .foregroundStyle(.primary)

                        Text(wordOfDay.entry.subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)

                        if let definition = wordOfDay.entry.meanings.first?.definitions.first?.definition {
                            Text(definition)
                                .font(.callout)
                                .foregroundStyle(.primary)
                                .lineLimit(2)
                                .multilineTextAlignment(.leading)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)

                Button(action: dismiss) {
                    Image(systemName: "xmark")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .padding(8)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Dismiss Word of the Day")
            }
        }
        .padding(14)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(.separator.opacity(0.55), lineWidth: 1)
        }
    }
}
