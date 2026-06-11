import Foundation
import UIKit
import PDFKit

class PDFExporter {
    static let shared = PDFExporter()
    
    private init() {}
    
    func exportPDF(devices: [DetectedDevice]) -> URL? {
        let pdfMetaData = [
            kCGPDFContextCreator: "NearbyGlasses App",
            kCGPDFContextAuthor: "User",
            kCGPDFContextTitle: "Security Audit Report"
        ]
        
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = pdfMetaData as [String: Any]
        
        let pageWidth = 8.5 * 72.0
        let pageHeight = 11 * 72.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        
        let data = renderer.pdfData { (context) in
            context.beginPage()
            let attributes = [
                NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 24)
            ]
            
            let text = "NearbyGlasses Security Audit Report"
            text.draw(at: CGPoint(x: 50, y: 50), withAttributes: attributes)
            
            var yOffset: CGFloat = 100
            
            let subAttributes = [
                NSAttributedString.Key.font: UIFont.systemFont(ofSize: 12)
            ]
            
            for device in devices {
                if yOffset > pageHeight - 100 {
                    context.beginPage()
                    yOffset = 50
                }
                
                let deviceText = "• \(device.name) (\(device.type)) - RSSI: \(device.rssi)\n   Detected: \(device.timestamp.formatted())\n   Threat: \(device.threatLevel)"
                deviceText.draw(at: CGPoint(x: 50, y: yOffset), withAttributes: subAttributes)
                yOffset += 60
            }
        }
        
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("SecurityAuditReport.pdf")
        do {
            try data.write(to: url)
            return url
        } catch {
            print("Could not save PDF: \(error)")
            return nil
        }
    }
}
