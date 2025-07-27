**Team Members:** Suhani Goswami, Ritika Banepali, Abha Misaqi, Julia Mergel

**Name of Project:** Travel Diary

**Special Instructions:**
- Chat GPT API Key Set up for Generate Itinerary
  - Create a Secrets.plist File
  - In Xcode, right-click on your project navigator and select New File.
  - Choose Property List and name it: Secrets.plist
  - Add a key-value pair:
    - Key: OPENAI_API_KEY
    - Type: String
    - Value: your OpenAI API key here
  - Ensure Secrets.plist is in your .gitignore to prevent exposing your API key.
 
**Logins for testing functionality (but can make your own!)**

| Feature  | Description   | Percentages |
| :---  |  :---  | :--- |
| Login  | Allows the user to create an account and sign in  | Suhani (90%) Abha (10%) |
| UI  | Creating screens, navigation, buttons, navigation, etc. | Suhani (25%) Ritika (25%) <br/> Abha (25%) <br/> Julia (25%) |
| Create Trip | Allows users to create a trip to any location and set the trip start and end dates  | Suhani (50%) Abha (50%) |
| Future Trips| Allows users to view their upcoming trips and view and interact with aspects of their trip, such as the trip preferences survey, view/generate trip itinerary, view trip photo album, and view other travellers on the trip| Ritika (25%) Suhani (25%) <br/> Julia (25%) <br/> Abha (25%) |
| Past Trips | Allows users to view their previous trips and trip wrapped details | Ritika (25%) Suhani (25%) Abha (25%) <br/> Julia (25%) |
| Photo Album | Users can upload pictures from their photo album or use the camera to take pictures to save in a group album | Julia (100%) |
| Fullscreen Photo | Screen to view individual photos. Can like or delete photos from this screen. | Julia (100%) |
| Trip Group Chat | Chat to talk to other members of your trip. | Julia (100%) |
| Itinerary | Users can access AI-customized itineraries for each trip according to collective travellers’ survey responses. The owner of the trip (the user who created the trip) is responsible for generating the itinerary, and other travellers can view it. The owner of the trip can also clear the itinerary, regenerate a new one, and save it, which will update the itinerary view of other travellers in the trip simultaneously. | Abha (100%) |
| Survey | User can fill out their preferences for trip activities/dining/timings | Abha (100%) |
| Invitations | Users can view their incoming trip invitations and accept/decline people who are a part of the same trip, and also view who has joined. | Ritika (90%) Suhani (10%) |
| Map | The user’s current location is used to view locations in their travel destination and load information about the locations | Ritika (100%) |
| Trip Wrapped | The user can view trip data once the trip dates have ended, including trip information, top liked photos, and group step counts through HealthKit | Suhani (50%) Julia (50%) |
| Settings | User can save notification and theme preferences, updated throughout app screens | Suhani (100%) |
