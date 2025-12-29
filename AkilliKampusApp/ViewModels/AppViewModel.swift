import Foundation
import SwiftUI

class AppViewModel: ObservableObject {
    @Published var selectedTab: Int = 0
    @Published var showingReportSheet: Bool = false
    
    // global errors or alerts managed here
    @Published var errorMessage: String?
    
    static let shared = AppViewModel()
    
    private init() {}
}
