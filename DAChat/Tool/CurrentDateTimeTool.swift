//
//  Untitled.swift
//  DAChat
//
//  Created by Rizal Hilman on 28/10/25.
//

import Foundation
import FoundationModels

struct CurrentDateTimeTool: Tool {
    let name = "getCurrentDateTime"
    let description = "Returns the current date and time as a formatted string."
    
    @Generable
    struct Arguments  {
        // No arguments needed in this example
    }
    
    func call(arguments: Arguments) async throws -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        
        let now = Date()
        let dateTimeString = formatter.string(from: now)
        
        return dateTimeString
        
        
    }
}
