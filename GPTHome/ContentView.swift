import SwiftUI
import OpenAI
import Combine

struct ContentView: View {
    @State private var search: String = ""
    let openAI = OpenAI(apiToken: "sk-proj-nSGFORYMtYEHb9p9FbcXT3BlbkFJXPOZEF7hSlEdKneharVX")
    @State private var responses: [String] = []
    @State private var lastestResponse: String = ""
    @State private var cancellables = Set<AnyCancellable>()

    private var isFormValid: Bool {
        !search.isEmpty
    }

    private func performSearch() {
        responses.append("You: \(search)")

        let query = ChatQuery(messages: [.init(role: .user, content: search)!], model: .gpt3_5Turbo)
        
        responses.append("GPT: ")

        Task {
            do {
                // Stream the chat results
                for try await result in openAI.chatsStream(query: query) {
                    if let content = result.choices.first?.delta.content {
                        await MainActor.run {
                            if var lastResponse = responses.last {
                                lastResponse += content
                                responses[responses.count - 1] = lastResponse
                            }
                        }
                        
                        try await Task.sleep(nanoseconds: 50_000_000)
                    }
                }
            } catch {
                print("Streaming error: \(error.localizedDescription)")
            }
        }
    }

    var body: some View {
        VStack {
            HStack {
                TextField("Search...", text: $search)
                    .textFieldStyle(.roundedBorder)

                Button(action: {
                    performSearch()
                }, label: {
                    Image(systemName: "magnifyingglass.circle.fill")
                        .font(.title)
                })
                .buttonStyle(.borderless)
                .disabled(!isFormValid)
            }

            List(responses, id: \.self) { response in
                Text(response)
            }
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
