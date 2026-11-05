# weather-forecast-activity-ranker

# Activity Planner

This is a native iOS application built with SwiftUI that helps users evaluate weather conditions and rank the suitability of four outdoor and indoor activities over the next seven days.

The application uses the Open-Meteo Geocoding API to search for locations and the Open-Meteo Forecast API to retrieve weather forecasts.

This project builds a focused, maintainable application while making sound engineering decisions, documenting assumptions, and verifying the behavior of the implementation.

Please refer to PRODUCT_ASSUMPTIONS.md for details about assumptions made during this implementation.

Before implementation, I broke the problem into a few independent areas:

1) Location discovery and selection.
2) Weather forecast retrieval.
3) Activity-specific suitability calculations.
4) Presentation of daily and overall rankings.
5) Error handling and test coverage.

# How I Worked

### Design decisions and trade-offs

**Native SwiftUI**

I used SwiftUI for the presentation layer while keeping networking and suitability calculations independent of the views.

### MVVM and separation of responsibilities

The application follows an MVVM-oriented structure with separate responsibilities for presentation, domain logic, and networking.

- Views: Render application state and handle user interaction.
- View models: Coordinate user actions, asynchronous operations, and presentation state.
- Services: Communicate with external APIs and provide application data.
- Domain models: Represent locations, forecasts, and suitability results.
- Scoring engine: Calculate activity suitability independently of the presentation layer.

I avoided placing networking or scoring calculations directly inside SwiftUI views.

### Protocol-oriented dependency injection

Services and the scoring engine are accessed through protocols.

For example:
GeocodingServiceProtocol
WeatherForecastServiceProtocol
SuitabilityScoringEngine

Dependencies are supplied through initialisers rather than accessed through global singletons.

AppContainer acts as the composition root. It creates the shared networking client and constructs the services and scoring engine that are injected into the application.

This way production implementations can be replaced with deterministic test doubles and view models and other application components depend on abstractions rather than concrete networking implementations.
