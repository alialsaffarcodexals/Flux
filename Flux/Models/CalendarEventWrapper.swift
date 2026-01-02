import Foundation

enum CalendarEventType {
    case booking(status: String) // e.g., "requested", "confirmed", "completed"
    case availability // A generic available slot
    case blocked(reason: String?) // Manually blocked
}

struct CalendarEventWrapper: Identifiable {
    let id: String
    let title: String
    let startDate: Date
    let endDate: Date
    let type: CalendarEventType
    
    // Potentially hold references to the underlying models if needed for actions
    let originalBookingId: String?
    let originalSlotId: String?
    let originalBlockedSlotId: String?
}
