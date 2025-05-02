//
//  OpenAIService.swift
//  VisionCollect
//
//  Created by Brady Davis on 9/5/24.
//

import Foundation

class OpenAIService {
    private let apiKey: String
    private let endpoint = "https://api.openai.com/v1/chat/completions"
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    func analyzeImage(_ imageData: Data, instrumentType: String, completion: @escaping (Result<String, Error>) -> Void) {
        let base64Image = imageData.base64EncodedString()
        
        let prompt = getPromptForInstrument(instrumentType)
        
        let parameters: [String: Any] = [
            "model": "gpt-4o",
            "messages": [
                [
                    "role": "user",
                    "content": [
                        [
                            "type": "text",
                            "text": prompt
                        ],
                        [
                            "type": "image_url",
                            "image_url": [
                                "url": "data:image/jpeg;base64,\(base64Image)"
                            ]
                        ]
                    ]
                ]
            ],
            "max_tokens": 300
        ]
        
        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")  // Use the stored API key
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: parameters)
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "No data in response"])))
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let firstChoice = choices.first,
                   let message = firstChoice["message"] as? [String: Any],
                   let content = message["content"] as? String {
                    completion(.success(content))
                } else {
                    completion(.failure(NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])))
                }
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    private func getPromptForInstrument(_ instrumentType: String) -> String {
        let basePrompt = "Analyze this instrument display image. Identify the type of instrument and extract all visible measurements. Respond in JSON format with the following structure: {\"instrument\": \"[Instrument Name]\", \"measurements\": {\"[Parameter1]\": \"[Value1] [Unit1]\", \"[Parameter2]\": \"[Value2] [Unit2]\", ...}}. Include all visible parameters."
        
        switch instrumentType {
        case "MultiRAE Pro":
            return basePrompt + " This is a MultiRAE Pro display."
        case "Gastec Tube":
            return basePrompt + " This is a Gastec Tube measurement."
        case "TSI 8530":
            return basePrompt + " This is a TSI 8530 display."
        case "UltraRAE":
            return basePrompt + " This is an UltraRAE instrument display."
        case "Horiba":
            return basePrompt + " This is a Horiba instrument display."
        default:
            return basePrompt
        }
    }
}

struct OpenAIResponse: Codable {
    let choices: [Choice]
}

struct Choice: Codable {
    let message: Message
}

struct Message: Codable {
    let content: String
}
