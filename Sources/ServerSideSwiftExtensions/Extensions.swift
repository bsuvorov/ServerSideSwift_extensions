import Foundation
import FluentProvider

public extension Collection {
    /// Convert self to JSON String.
    /// - Returns: Returns the JSON as String or empty string if error while parsing.
    public func json() -> String {
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

public extension String {
    public func split(len: Int) -> [String] {
        return stride(from: 0, to: self.count, by: len).map {
            let start = self.index(self.startIndex, offsetBy: $0)
            let end = self.index(start, offsetBy: len, limitedBy: self.endIndex) ?? self.endIndex
            return String(self[start..<end])
        }
    }
    
    public func componentsAppendingSeparators(separatedBy separators: Set<String>) -> [String] {
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

public extension Timestampable {
    
    public func formattedCreatedAt(dateFormat: String) -> String? {
        
        let formatter = DateFormatter()
        formatter.dateFormat = dateFormat
        
        return formattedCreatedAt(formatter: formatter)
    }
    
    public func formattedUpdatedAt(dateFormat: String) -> String? {
        
        let formatter = DateFormatter()
        formatter.dateFormat = dateFormat
        
        return formattedUpdatedAt(formatter: formatter)
    }
    
    public func formattedCreatedAt(formatter: DateFormatter) -> String? {
        return createdAt.map { formatter.string(from: $0) }
    }
    
    public func formattedUpdatedAt(formatter: DateFormatter) -> String? {
        return updatedAt.map { formatter.string(from: $0) }
    }
}

public extension Dictionary where Key == String {
    public func toJSON() -> Vapor.JSON? {
        guard let node = try? self.makeNode(in: jsonContext) else {
            return nil
        }
        return Vapor.JSON(node)
    }
}

public extension Vapor.JSON {
    public func toString() -> String? {
        return try? self.makeBytes().makeString()
    }
    
    public func toStringDictionary() throws -> [String: String]? {
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

public enum Exception: Error {
    case IllegalArgumentException
}

public extension String {
    public func toJSON() -> Vapor.JSON? {
        return try? Vapor.JSON(bytes: self.bytes)
    }
}
