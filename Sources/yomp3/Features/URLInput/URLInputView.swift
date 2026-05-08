import SwiftUI

struct URLInputView: View {
    @State private var input: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("URL do YouTube")
                .font(.headline)
            TextField("https://youtube.com/watch?v=…", text: $input)
                .textFieldStyle(.roundedBorder)
            HStack {
                Button("Adicionar") {}
                    .disabled(true)
                Spacer()
            }
        }
        .padding()
    }
}
