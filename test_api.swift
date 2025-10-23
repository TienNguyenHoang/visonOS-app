#!/usr/bin/env swift

import Foundation

// Test script for API
let url = URL(string: "https://rc-api.synode.ai/account/auth/login")!
var request = URLRequest(url: url)
request.httpMethod = "POST"
request.setValue("application/json", forHTTPHeaderField: "Content-Type")

let payload = [
    "scope": "synode",
    "email": "priffollavada-6662@yopmail.com", 
    "password": "aaaaa!A1"
]

do {
    request.httpBody = try JSONSerialization.data(withJSONObject: payload, options: [])
    
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            print("❌ Error: \(error)")
            return
        }
        
        if let httpResponse = response as? HTTPURLResponse {
            print("📊 Status Code: \(httpResponse.statusCode)")
        }
        
        if let data = data {
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📝 Response: \(jsonString)")
            }
        }
        
        exit(0)
    }
    
    task.resume()
    RunLoop.main.run()
    
} catch {
    print("❌ Failed to encode JSON: \(error)")
}
