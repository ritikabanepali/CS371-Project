//
//  ChatGPTManager.swift
//  CS371-Project
//
//  Created by Abha on 7/18/25.
//

import Foundation

class ChatGPTManager {
    static let shared = ChatGPTManager()
    private init() {}
    
    private let apiKey: String = {
        if let path = Bundle.main.path(forResource: "Secrets", ofType: "plist"),
           let dict = NSDictionary(contentsOfFile: path),
           let key = dict["OPENAI_API_KEY"] as? String {
            return key
        }
        fatalError("OPENAI_API_KEY not found in Secrets.plist")
    }()
    
    func generateItinerary(prompt: String, completion: @escaping (String?) -> Void) {
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        
        let headers = [
            "Content-Type": "application/json",
            "Authorization": "Bearer \(apiKey)"
        ]
        
        let messages: [[String: String]] = [
            ["role": "system", "content": "You are a helpful travel planner assistant."],
            ["role": "user", "content": prompt]
        ]
        
        let requestBody: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": messages,
            "temperature": 0.7
        ]
        
        guard let bodyData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            completion(nil)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers
        request.httpBody = bodyData
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(nil)
                return
            }
            
            guard let data = data else {
                
                completion(nil)
                return
            }
            
            // Attempt to parse
            if let responseJSON = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let choices = responseJSON["choices"] as? [[String: Any]],
               let message = choices.first?["message"] as? [String: Any],
               let content = message["content"] as? String {
                completion(content)
            } else {
                
                completion(nil)
            }
        }.resume()
        
    }
}
