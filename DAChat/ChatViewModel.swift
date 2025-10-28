//
//  ChatViewModel.swift
//  DAChat
//
//  Created by Rizal Hilman on 28/10/25.
//

import Foundation
import Combine
import FoundationModels


struct ChatMessage {
    var id: UUID = UUID()
    var content: String
    var isFromUser: Bool
    var timestamp: Date = Date()
    var isPartial: Bool
    
    init(content: String, isFromUser: Bool, isPartial: Bool) {
        self.content = content
        self.isFromUser = isFromUser
        self.isPartial = isPartial
    }
}

@MainActor
class ChatViewModel: ObservableObject {
    @Published var isResponding = false
    @Published var errorMessage: String?
    @Published var instructions: String = ""
    @Published var messages: [ChatMessage] = []
    @Published var temperature: Double = 0.7
    @Published var maximumResponseTokens: Int = 200
    
    var languageModelSession: LanguageModelSession?
    
    init(){
        setupLanguageModel()
    }
    
    func setupLanguageModel(){
        
        languageModelSession = LanguageModelSession(tools: [CurrentDateTimeTool(), WebAnalyserTool(), UserInfoTool()],
                                                    instructions: instructions)
        print("Language model setup complete.")
    }
    
    
    func sendMessage(_ content: String) async {
        do {
            guard let languageModelSession else { return }
            var options = GenerationOptions()
            options.maximumResponseTokens = maximumResponseTokens
            options.temperature = temperature
            
            let stream = languageModelSession.streamResponse(to: content, options: options)
            
            let userMessage = ChatMessage(content: content, isFromUser: true, isPartial: false)
            messages.append(userMessage)
            
            var assistantMessage = ChatMessage(content: "", isFromUser: false, isPartial: true)
            messages.append(assistantMessage)
            
            isResponding = true
            errorMessage = nil
            
            for try await response in stream {
                print(response.content)
                
                if let idx = messages.firstIndex(where: { $0.id == assistantMessage.id }) {
                    messages[idx].content = response.content
                    messages[idx].timestamp = Date()
                    
                    // Keep it marked partial while streaming.
                    messages[idx].isPartial = true
                    assistantMessage = messages[idx]
                }
            }
            
            // 4) Mark the assistant message as finalized.
            if let idx = messages.firstIndex(where: { $0.id == assistantMessage.id }) {
                messages[idx].isPartial = false
            }
            
            isResponding = false
            
        } catch {
            isResponding = false
            errorMessage = error.localizedDescription
            print("sendMessage error:", error)
        }
    }
    
    func reset() {
        messages.removeAll()
    }
}
