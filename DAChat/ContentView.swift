import SwiftUI
import FoundationModels
import Playgrounds
import MarkdownUI

struct ContentView: View {
    @State private var prompt: String = ""
    @State private var isShowingInspector = false
    @StateObject private var viewModel: ChatViewModel = .init()
    
    @State private var messages: [String] = []
    
    let sampleQuestions: [String] = [
        "What is the capital of Brazil?",
        "Who wrote 'To Kill a Mockingbird'?",
        "What are the 5 most populated cities in the world?",
    ]
    
    private let tokenFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.minimumIntegerDigits = 2
        return formatter
    }()
    
    var body: some View {
        VStack {
            switch SystemLanguageModel.default.availability {
            case .available:
                messagesList
                    .task {
                        
                    }
                    .safeAreaInset(edge: .bottom) {
                        HStack {
                            TextField("Type your message here and press ⏎", text: $prompt)
                                .padding(5)
                                .textFieldStyle(.plain)
                                .padding(5)
                                .onSubmit {
                                    Task {
                                        await viewModel.sendMessage(prompt)
                                        prompt = ""
                                    }
                                }
                        }
                        .padding()
                    }
                    .toolbar {
                        ToolbarItem {
                            Button {
                                viewModel.reset()
                                viewModel.setupLanguageModel()
                            } label: {
                                Image(systemName: "eraser")
                            }
                        }
                        ToolbarSpacer(.flexible)
                        ToolbarItem {
                            Button {
                                isShowingInspector.toggle()
                            } label: {
                                Image(systemName: "sidebar.trailing")
                            }
                            
                        }
                    }
                    .inspector(isPresented: $isShowingInspector) {
                        VStack(alignment: .leading) {
                            Text("Generation Options")
                                .font(.headline)
                                .padding(.bottom)
                            
                            VStack(alignment: .leading) {
                                Text("Temperature: \(viewModel.temperature, specifier: "%.1f")")
                                    .font(.callout)
                                    .monospacedDigit()
                                Slider(value: $viewModel.temperature, in: 0.0...1.0, step: 0.1)
                            }
                            .padding(.bottom)
                            
                            HStack {
                                Text("Max ToKens:")
                                    .font(.callout)
                                TextField("Enter a number", value: $viewModel.maximumResponseTokens, formatter: tokenFormatter)
                            }
                            .padding(.bottom)
                            
                            VStack(alignment: .leading) {
                                Text("Instructions:")
                                    .font(.callout)
                                TextEditor(text: $viewModel.instructions)
                                    .frame(height: 80)
                                
                                Button {
                                    viewModel.setupLanguageModel()
                                } label: {
                                    Text("Save")
                                }
                            }
                            
                            Spacer()
                        }
                        .padding()
                    }
            case .unavailable(_):
                ContentUnavailableView("Apple Intelligence is not available.", systemImage: "exclamationmark.octagon")
            }
        }
    }
    
    @ViewBuilder
    var message: some View {
        let dateFormatter = Date.FormatStyle(date: .abbreviated, time: .standard)
        VStack(alignment: .center, spacing: 10) {
            HStack {
                Group {
                    ForEach(sampleQuestions, id: \.self) { question in
                        Button(question) {
                            prompt = question
                            Task { await viewModel.sendMessage(prompt) }
                        }
                    }
                }
                .buttonStyle(.borderless)
                .padding()
                
                
            }
            
            ForEach(viewModel.messages, id: \.id) { message in
                
                
                HStack {
                    if message.isFromUser {
                        Spacer()
                        Markdown(message.content)
//                        Text(message.content)
//                            .font(.body)
//                            .multilineTextAlignment(.leading)
//                            .frame(width: .infinity, alignment: .leading)
                        
                    } else {
                        Markdown(message.content)
//                        Text(message.content)
//                            .font(.body)
//                            .multilineTextAlignment(.leading)
//                            .frame(width: .infinity, alignment: .leading)
                        Spacer()
                    }
                }
                .padding()
                
            }
        }
    }
    
    @ViewBuilder
    var messagesList: some View {
        ScrollView {
            ScrollViewReader { scrollView in
                message
                    .onAppear {
                        scrollToBottom(scrollView: scrollView)
                    }
                    .onChange(of: messages) {
                        scrollToBottom(scrollView: scrollView)
                    }
            }
        }
    }
    
    private func scrollToBottom(scrollView: ScrollViewProxy) {
        if let lastMessage = messages.last {
            withAnimation {
                scrollView.scrollTo(lastMessage, anchor: .bottom)
            }
        }
    }
    
    
    
    private func generate() async {
        
    }
}

#Preview {
    ContentView()
}

#Playground("AIML") {
    let session = LanguageModelSession()
    let response = try await session.respond(to: "Who is Steve Jobs?")
    print(response.content)
}

