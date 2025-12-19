AkilliKampus Application - Technical Report

1. Abstract

This technical report details the design and implementation of the "AkilliKampus" (SmartCampus) mobile application. The primary objective of this project is to enhance campus safety and facility management by enabling students and staff to report incidents using geolocation services. The system leverages modern mobile development frameworks and cloud-based backend services to ensure scalability, real-time data synchronization, and secure user authentication.

2. Introduction

University campuses are complex environments where maintenance issues (e.g., broken equipment, lighting failures) or safety hazards require prompt attention. Traditional reporting methods are often slow and lack location precision. 

The AkilliKampus application addresses these challenges by providing a user-friendly iOS interface for instant incident reporting. Users can categorize issues, provide descriptions, and pinpoint exact locations on a map. The system employs Role-Based Access Control (RBAC) to distinguish between standard users (reporters) and administrators (managers), facilitating an efficient workflow for incident resolution.

3. System Architecture

The application is built using the MVVM (Model-View-ViewModel) architectural pattern, separating the user interface logic from the business logic and data models.

Model: Represents the data structures, such as User and Incident. These models conform to Codable and Identifiable protocols for seamless data parsing and state management.
View: Built with SwiftUI, the views provide a declarative and reactive user interface. They subscribe to ViewModels to reflect real-time state changes.
ViewModel: Acts as the intermediary, handling business logic (e.g., AuthManager, IncidentManager). It communicates with Firebase services and exposes formatted data to the Views via @Published properties.

3.1. Cloud Integration

The backend infrastructure is completely serverless, relying on Google Firebase for:
Authentication: Manages user identity via Email/Password and OAuth protocols.
Database: Uses Cloud Firestore, a NoSQL database, for storing user profiles and incident reports in a hierarchical collection structure.

4. Technologies and Tools Used

4.1. Mobile Development (iOS)

Language: Swift 5
Framework: SwiftUI (Declarative UI framework)
Minimum OS Version: iOS 15.0
IDE: Xcode 14+

4.2. Backend as a Service (BaaS)

Firebase Authentication:
Secure user session management.
Integration with Google Sign-In SDK for federated identity (OAuth 2.0).
Cloud Firestore:
Real-time data listeners (addSnapshotListener) for instant UI updates.
Secure data storage for users and incidents collections.

4.3. Location Services

CoreLocation: Used for retrieving the user's current geolocation coordinates.
MapKit: Renders the interactive campus map, allowing users to drop pins and visualize incident clusters.

4.4. Third-Party Libraries (Swift Package Manager)

firebase-ios-sdk: Core Firebase integration.
google-sign-in-ios: Google authentication flow.

5. Screen List and User Interface

(Please refer to the attached screenshots for visual representation)

5.1. Authentication Screens

Login View: Features secure credential entry and a dedicated "Sign in with Google" button. Handles error states and navigation.
Register View: Registration form enforcing strict domain constraints (@kampus.edu.tr) to ensure only authorized campus personnel can join.

5.2. Core Features

Dashboard (Home View): Displays essential announcements and quick access buttons.
Map Interface (Map View): An interactive map showing the user's location and markers for reported incidents.
Incident Reporting (Report View): A form allowing users to select an incident type (Health, Technical, Security), write a description, and confirm the location on the map.

5.3. User Management

Profile View: Displays user details fetched from Firestore (Name, Department, Role). Includes session management options (Logout).

6. Future Work

Future iterations of the project aim to include:
Push Notifications: Alerting admins of new reports via Firebase Cloud Messaging (FCM).
Image Uploads: Allowing users to attach photos to incident reports using Firebase Storage.
Admin Dashboard: A dedicated iPad-compatible view for managing ticket status (Open, In Progress, Resolved).

7. Conclusion

The AkilliKampus application successfully demonstrates a modern, scalable approach to campus incident management. By combining the reactive nature of SwiftUI with the robustness of Firebase, the system delivers a responsive and reliable user experience.
