import SwiftUI
struct PXSettingsPickerRow<T: Hashable>: View {
    var title: String
    var selection: Binding<T>
    var options: [(T, String)]
    var body: some View {
        HStack {
            Text(title).font(.system(size: 13)).foregroundStyle(PXTheme.textPrimary)
            Spacer()
            Picker("", selection: selection) {
                ForEach(Array(options.enumerated()), id: \.offset) { option in Text(option.element.1).tag(option.element.0) }
            }
            .labelsHidden()
        }
        .padding(.vertical, 6)
    }
}
