//
//  CreateImageTool.swift
//  DAChat
//
//  Created by Rizal Hilman on 29/10/25.
//

import Foundation
import FoundationModels
import ImagePlayground
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

struct CreateImageTool: Tool {
    let name = "createImage"
    let description = "Generate images from a prompt with optional style and limit using ImagePlayground."
    
    @Generable
    struct Arguments {
        @Guide(description: "Text prompt describing the image to generate")
        let prompt: String
        
        @Guide(description: "Image style, e.g., photographic, painting, sketch (optional)")
        let style: String?
        
        @Guide(description: "Number of images to generate (max 4 for most models) by default is 1")
        let limit: Int
    }
    
    struct ImageResult: Codable {
        let images: [String] // base64 image data strings or file URLs
    }
    
    func oldCall(arguments: Arguments) async throws -> String {
        print("LOG TOOL: Creating images...")
        
        let creator = try await ImageCreator()
        let prompt = arguments.prompt
        let styleInput = (arguments.style ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let style: ImagePlaygroundStyle = {
            switch styleInput {
            case "animation", "animasi", "animate":
                return .animation
            case "illustration", "ilustrate":
                return .illustration
            case "sketch", "drawing":
                return .sketch
            default:
                return .sketch
            }
        }()
        
        print("LOG TOOL: \(prompt)")
        let playgroundConcept = ImagePlaygroundConcept.text("A robot dancing in a colorful room")
        let images = creator.images(for: [playgroundConcept], style: .animation, limit: 1)
        
        var encodedImages: [String] = []
        var i = 1
        for try await createdImage in images {
            print("LOG TOOL: Creating image... \(i + 1)/\(arguments.limit)")
            i += 1
            
            #if canImport(UIKit)
            let uiImage = UIImage(cgImage: createdImage.cgImage)
            if let data = uiImage.jpegData(compressionQuality: 0.9) {
                encodedImages.append(data.base64EncodedString())
            }
            #elseif canImport(AppKit)
            if let tiffData = createdImage.image.tiffRepresentation,
               let bitmap = NSBitmapImageRep(data: tiffData),
               let data = bitmap.representation(using: .jpeg, properties: [:]) {
                encodedImages.append(data.base64EncodedString())
            }
            #endif
        }
        
        let result = ImageResult(images: encodedImages)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        let data = try encoder.encode(result)
        
        return String(data: data, encoding: .utf8) ?? "{\"images\":[]}"
    }
    
    func call(arguments: Arguments) async throws -> String {
        print("LOG TOOL: Creating images...")
        
        let prompt = arguments.prompt
        
        guard let createdImage = try await generateImage(from: prompt) else {
            return "{\"images\":[]}"
        }
        
        let savedURL = try savePNG(from: createdImage)
        
        let result = ImageResult(images: [savedURL.absoluteString])
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted]
        let data = try encoder.encode(result)
        return String(data: data, encoding: .utf8) ?? "{\"images\":[]}"
    }
    
    func savePNG(from cgImage: CGImage) throws -> URL {
        // Bridge CGImage -> UIImage
        let uiImage = UIImage(cgImage: cgImage)

        // Encode as PNG
        guard let data = uiImage.pngData() else {
            struct EncodingError: Error {}
            throw EncodingError()
        }

        // Build a destination URL in Documents
        let url = URL.documentsDirectory.appendingPathComponent("\(UUID().uuidString).png")

        // Write to disk
        try data.write(to: url)
        return url
    }
    private func generateImage(from prompt: String) async throws -> CGImage? {
        let imageCreator = try await ImageCreator()
        let playgroundConcept = ImagePlaygroundConcept.text(prompt)
        let sequence = imageCreator.images(for: [playgroundConcept], style: .animation, limit: 1)
        
        // Try to consume the first generated image from the async sequence
        //let cgimg = try await sequence.first(where: { _ in true })?.cgImage
        if let cgimg = try await sequence.first(where: { _ in true })?.cgImage {
            return cgimg
        }
        return nil
    }
}
