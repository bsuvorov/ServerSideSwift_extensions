import Foundation

public class DateFormatters {
    
    private(set) lazy var BackendDateFormat: DateFormatter = {
        var formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
    
    private(set) lazy var USDateFormat: DateFormatter = {
        var formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yyyy"
        return formatter
    }()
}
