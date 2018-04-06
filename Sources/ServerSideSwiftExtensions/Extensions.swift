import Foundation
import FluentProvider

public extension Collection {
    /// Convert self to JSON String.
    /// - Returns: Returns the JSON as String or empty string if error while parsing.
    func json() -> String {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: self, options: [.prettyPrinted])
            guard let jsonString = String(data: jsonData, encoding: String.Encoding.utf8) else {
                print("Can't create string with data.")
                return "{}"
            }
            return jsonString
        } catch let parseError {
            print("json serialization error: \(parseError)")
            return "{}"
        }
    }
}

extension String {
    func split(len: Int) -> [String] {
        return stride(from: 0, to: self.count, by: len).map {
            let start = self.index(self.startIndex, offsetBy: $0)
            let end = self.index(start, offsetBy: len, limitedBy: self.endIndex) ?? self.endIndex
            return String(self[start..<end])
        }
    }
    
    func componentsAppendingSeparators(separatedBy separators: Set<String>) -> [String] {
        let separatorString = "SomeStringThatYouDoNotExpectToOccurInSelf"
        var preparedString: String = self
        
        for separator in separators {
            preparedString = preparedString.replacingOccurrences(of: separator, with: "\(separator)\(separatorString)")
        }
        
        return preparedString.components(separatedBy: separatorString)
            .map { $0.trim() }
            .filter { $0 != "" }
    }
}


extension Formatter {
    static let iso8601: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        return formatter
    }()
}
extension Date {
    var iso8601: String {
        return Formatter.iso8601.string(from: self)
    }
}

extension String {
    var dateFromISO8601: Date? {
        return Formatter.iso8601.date(from: self)   // "Mar 22, 2017, 10:22 AM"
    }
}

extension Timestampable {
    
    func formattedCreatedAt(dateFormat: String) -> String? {
        
        let formatter = DateFormatter()
        formatter.dateFormat = dateFormat
        
        return createdAt.map { formatter.string(from: $0) }
    }
    
    func formattedUpdatedAt(dateFormat: String) -> String? {
        
        let formatter = DateFormatter()
        formatter.dateFormat = dateFormat
        
        return updatedAt.map { formatter.string(from: $0) }
    }
}

extension Dictionary where Key == String {
    func toJSON() -> Vapor.JSON? {
        guard let node = try? self.makeNode(in: jsonContext) else {
            return nil
        }
        return Vapor.JSON(node)
    }
}

extension Vapor.JSON {
    func toString() -> String? {
        return try? self.makeBytes().makeString()
    }
    
    func toStringDictionary() throws -> [String: String]? {
        do {
            return try self.object?.mapValues({ (oldValue) -> String in
                guard let newValue = oldValue.string else {
                    throw Exception.IllegalArgumentException
                }
                return newValue
            })
        } catch {
            return nil
        }
    }
}

enum Exception: Error {
    case IllegalArgumentException
}

extension String {
    func toJSON() -> Vapor.JSON? {
        return try? Vapor.JSON(bytes: self.bytes)
    }
}
