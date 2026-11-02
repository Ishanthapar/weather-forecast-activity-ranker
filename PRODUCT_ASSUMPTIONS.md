Product Assumptions

Location Search
- Users can search for cities and town globally
- Seaech results display the location name, administrative region and country
- Users must explicitly select a location when multiple results are returned
- Location coordinates and timezone are obtained from Geocoding API
- GPS-based location detetction and search history are out of scope

Forecast Period
- The forecast covers today and the following six calendar days
- Dates are interpreted using the selected location's timezone
- Only future forecast hours are considered when calculating today's suitability
- Exch day receives equal weight in the overall seven day assessment

Ranking
- Each activity receives ann individual daily score between 0 and 100 when siuffcient data is available
- The overall suitability score is the arithmetic mean of the seven daily scores
- Daily suitability scores and the best individual day are also displayed
- Missing essential data results in an unavailable assessment rather than an assumed score of zero

Technical Assumptions
- SwiftUI is used for presentation layer
- MVVM is used with separate domain and data layers
- Networking uses URLSession and asyn/await
- Dependencies are injected through protocols

Out of Scope
- Authentication and user accounts
- Backend services
- GPS-based location detection
- Saved locations and favourites
- Historical weather forecasts
- Attraction discovery and opening hours
- Push notifications

Open Product Questions
- Should suitability represent weather conditions alone or should it account whether an activity is geographically possible at the searched location?
- Should the rankings represent average suitability over the seven days, the best day or something else? - The product assumes average suitability across all seven days
- Should users be able to understand why a particular activity received a certain score?
- What should happen if the forecast API returns incomplete data?
- Should users be able to select alternative measurement units?
- What level of forecast confidence should be communicated to the users?
- Should indoor sightseeing incorporate actual attraction availability?

Important Limitations
- This application provides indicative weather-based assessments. It does not guarantee that an activity is possible, safe or operational at a given location.
