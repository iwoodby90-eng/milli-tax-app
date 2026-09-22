import SwiftUI
import Vision
import VisionKit

// MARK: - Receipt scanning
// Camera capture uses VisionKit's document scanner; text comes from on-device
// Vision OCR. Nothing leaves the device, and every parsed value is presented
// for the user to confirm before it becomes an expense or receipt.

struct ScannedReceipt {
    let merchant: String?
    let amount: Double?
    let date: Date?
    let imageFilename: String?
    let recognizedLines: [String]
}

enum ReceiptTextParser {
    /// Derives merchant, total and date from OCR lines. Anything the text does
    /// not support is returned as nil so the user fills it in themselves.
    static func parse(lines: [String], referenceDate: Date = Date()) -> ScannedReceipt {
        let cleaned = lines
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        return ScannedReceipt(
            merchant: merchant(in: cleaned),
            amount: total(in: cleaned),
            date: date(in: cleaned, referenceDate: referenceDate),
            imageFilename: nil,
            recognizedLines: cleaned
        )
    }

    static func attaching(_ filename: String?, to receipt: ScannedReceipt) -> ScannedReceipt {
        ScannedReceipt(
            merchant: receipt.merchant,
            amount: receipt.amount,
            date: receipt.date,
            imageFilename: filename,
            recognizedLines: receipt.recognizedLines
        )
    }

    // MARK: Merchant

    private static func merchant(in lines: [String]) -> String? {
        // Receipt headers carry the store name: the first few lines that read as
        // a name rather than an address, phone number or amount.
        for raw in lines.prefix(5) {
            // Store numbers ("SHELL #4821") are noise around the name itself.
            let line = (raw.components(separatedBy: "#").first ?? raw)
                .trimmingCharacters(in: .whitespacesAndNewlines)

            guard line.count >= 3, line.count <= 40 else { continue }
            guard line.rangeOfCharacter(from: .letters) != nil else { continue }
            if containsAmount(line) { continue }
            if line.lowercased().contains("receipt") { continue }

            // A leading number means a street address, not a merchant.
            if let firstWord = line.split(separator: " ").first, firstWord.allSatisfy(\.isNumber) {
                continue
            }

            let digits = line.filter(\.isNumber).count
            guard Double(digits) / Double(line.count) < 0.3 else { continue }

            return line.capitalizedIfShouting
        }
        return nil
    }

    // MARK: Total

    private static let totalKeywords = ["grand total", "total", "amount due", "balance due"]

    private static func total(in lines: [String]) -> Double? {
        // A labelled total wins; the keyword may sit on its own line with the
        // figure underneath, so the next line is checked too.
        for (index, line) in lines.enumerated() {
            let lowered = line.lowercased()
            guard totalKeywords.contains(where: lowered.contains) else { continue }
            if lowered.contains("subtotal") { continue }

            if let amount = amounts(in: line).last {
                return amount
            }
            if index + 1 < lines.count, let amount = amounts(in: lines[index + 1]).last {
                return amount
            }
        }

        // Unlabelled receipts: the largest figure is the total in practice.
        return lines.flatMap(amounts(in:)).max()
    }

    private static func containsAmount(_ line: String) -> Bool {
        !amounts(in: line).isEmpty
    }

    private static func amounts(in line: String) -> [Double] {
        guard let regex = try? NSRegularExpression(pattern: #"\d{1,3}(?:,\d{3})*\.\d{2}"#) else {
            return []
        }
        let range = NSRange(line.startIndex..<line.endIndex, in: line)
        return regex.matches(in: line, range: range).compactMap { match in
            guard let matched = Range(match.range, in: line) else { return nil }
            return Double(line[matched].replacingOccurrences(of: ",", with: ""))
        }
    }

    // MARK: Date

    private static func date(in lines: [String], referenceDate: Date) -> Date? {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue) else {
            return nil
        }

        let calendar = Calendar.current
        let earliest = calendar.date(byAdding: .year, value: -3, to: referenceDate) ?? referenceDate

        for line in lines {
            let range = NSRange(line.startIndex..<line.endIndex, in: line)
            for match in detector.matches(in: line, range: range) {
                guard let found = match.date else { continue }
                // Times without a day, and dates outside a plausible window, are
                // OCR noise rather than the purchase date.
                if found > referenceDate || found < earliest { continue }
                return found
            }
        }
        return nil
    }
}

private extension String {
    /// Receipt headers are usually all caps; title case reads better in the app.
    var capitalizedIfShouting: String {
        let letters = filter(\.isLetter)
        guard !letters.isEmpty, letters.allSatisfy(\.isUppercase) else { return self }
        return capitalized
    }
}

// MARK: - Storage

enum ReceiptImageStore {
    static var directory: URL? {
        guard let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        let folder = base.appendingPathComponent("Receipts", isDirectory: true)
        if !FileManager.default.fileExists(atPath: folder.path) {
            try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        }
        return folder
    }

    static func save(_ image: UIImage) -> String? {
        guard let directory, let data = image.jpegData(compressionQuality: 0.72) else { return nil }
        let filename = "\(UUID().uuidString).jpg"
        do {
            try data.write(to: directory.appendingPathComponent(filename), options: .atomic)
            return filename
        } catch {
            return nil
        }
    }

    static func image(named filename: String) -> UIImage? {
        guard let directory else { return nil }
        return UIImage(contentsOfFile: directory.appendingPathComponent(filename).path)
    }

    static func delete(filename: String) {
        guard let directory else { return }
        try? FileManager.default.removeItem(at: directory.appendingPathComponent(filename))
    }
}

// MARK: - Camera

/// VisionKit document scanner wrapped for SwiftUI. Pages are OCR'd on device and
/// the first page is stored alongside the parsed values.
struct ReceiptScannerView: UIViewControllerRepresentable {
    static var isSupported: Bool { VNDocumentCameraViewController.isSupported }

    let onScan: (ScannedReceipt) -> Void
    let onCancel: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onScan: onScan, onCancel: onCancel)
    }

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let controller = VNDocumentCameraViewController()
        controller.delegate = context.coordinator
        return controller
    }

    func updateUIViewController(_ controller: VNDocumentCameraViewController, context: Context) {}

    final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        private let onScan: (ScannedReceipt) -> Void
        private let onCancel: () -> Void

        init(onScan: @escaping (ScannedReceipt) -> Void, onCancel: @escaping () -> Void) {
            self.onScan = onScan
            self.onCancel = onCancel
        }

        func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFinishWith scan: VNDocumentCameraScan
        ) {
            guard scan.pageCount > 0 else {
                onCancel()
                return
            }

            let page = scan.imageOfPage(at: 0)
            let filename = ReceiptImageStore.save(page)

            ReceiptTextRecognizer.recognize(in: page) { [onScan] lines in
                let parsed = ReceiptTextParser.parse(lines: lines)
                onScan(ReceiptTextParser.attaching(filename, to: parsed))
            }
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            onCancel()
        }

        func documentCameraViewController(
            _ controller: VNDocumentCameraViewController,
            didFailWithError error: Error
        ) {
            onCancel()
        }
    }
}

enum ReceiptTextRecognizer {
    static func recognize(in image: UIImage, completion: @escaping ([String]) -> Void) {
        guard let cgImage = image.cgImage else {
            completion([])
            return
        }

        DispatchQueue.global(qos: .userInitiated).async {
            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = false

            let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up)
            try? handler.perform([request])

            let lines = (request.results ?? []).compactMap { observation in
                observation.topCandidates(1).first?.string
            }

            DispatchQueue.main.async {
                completion(lines)
            }
        }
    }
}
