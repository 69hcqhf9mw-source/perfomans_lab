import SwiftUI

struct ThemePickerView: View {
    @Binding var selectedTheme: String
    @Environment(\.dismiss) private var dismiss
    
    private let themes = [
        ("system", "circle.lefthalf.filled", "System", "Follow system appearance"),
        ("light", "sun.max.fill", "Light", "Always use light mode"),
        ("dark", "moon.fill", "Dark", "Always use dark mode")
    ]
    
    var body: some View {
        List {
            ForEach(themes, id: \.0) { theme in
                Button(action: {
                    selectedTheme = theme.0
                    dismiss()
                }) {
                    HStack(spacing: 16) {
                        Image(systemName: theme.1)
                            .font(.title2)
                            .foregroundColor(.accentColor)
                            .frame(width: 30)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(theme.2)
                                .font(.headline)
                            Text(theme.3)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        if selectedTheme == theme.0 {
                            Image(systemName: "checkmark")
                                .foregroundColor(.accentColor)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
    }
}
