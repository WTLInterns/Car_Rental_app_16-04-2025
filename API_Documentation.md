# Car Rental App - API Documentation & Testing Guide

## Overview
This document explains the APIs used in the Car Rental Flutter app and provides comprehensive Postman tests for both **One Way** and **Round Trip** bookings.

## API Architecture

### 1. Main Booking API
**Base URL:** `https://api.worldtriplink.com/api`
**Primary Endpoint:** `/cab1`
**Method:** POST
**Content-Type:** `application/x-www-form-urlencoded`

This is the core API that handles vehicle availability, pricing calculations, and trip information for all booking types.

### 2. Google Maps Integration
**Base URL:** `https://maps.googleapis.com/maps/api`
**API Key:** `AIzaSyCelDo4I5cPQ72TfCTQW-arhPZ7ALNcp8w`

Used for:
- **Reverse Geocoding:** Convert coordinates to addresses
- **Places Autocomplete:** Location suggestions during booking

### 3. ETS (Employee Transportation System)
**Base URL:** `https://ets.worldtriplink.com`

Specialized APIs for corporate/employee transportation services.

## API Flow Explanation

### Booking Process Flow:
1. **Location Input** → Google Places Autocomplete API
2. **Current Location** → Google Geocoding API  
3. **Vehicle Selection** → Main Booking API (`/cab1`)
4. **Price Calculation** → Response processing
5. **Booking Confirmation** → Navigate to passenger details

### Key Parameters for `/cab1` API:

| Parameter | Type | Description | Required |
|-----------|------|-------------|----------|
| `tripType` | String | `oneWay`, `roundTrip`, or `rental` | Yes |
| `pickupLocation` | String | Full pickup address | Yes |
| `dropLocation` | String | Full destination address | Yes |
| `date` | String | Pickup date (YYYY-MM-DD) | Yes |
| `time` | String | Pickup time (HH:MM AM/PM) | Yes |
| `hours` | String | Duration for rental trips only | Conditional |
| `Returndate` | String | Return date for round trips only | Conditional |

### API Response Structure:
```json
{
  "distance": "150",
  "tripinfo": [
    {
      "hatchback": 12,
      "sedan": 15,
      "sedanpremium": 18,
      "suv": 22,
      "suvplus": 28
    }
  ]
}
```

## Vehicle Categories & Pricing

The app supports 5 vehicle categories with dynamic pricing:

1. **HatchBack** (Maruti Swift)
   - 4 Seats, 2 Bags
   - Features: Petrol, USB Charging, AC, Music System

2. **Sedan** (Maruti Swift Dzire)
   - 4 Seats, 3 Bags  
   - Features: Diesel, USB Charging, AC, Music System

3. **SedanPremium** (Honda City)
   - 5 Seats, 4 Bags
   - Features: Diesel, USB Charging, AC, Music System, Leather Seats

4. **SUV** (Toyota Innova)
   - 7 Seats, 5 Bags
   - Features: Diesel, USB Charging, AC, Music System, Spacious

5. **SUVPlus** (Toyota Fortuner)
   - 7 Seats, 6 Bags
   - Features: Diesel, USB Charging, AC, Music System, Premium Interior

## Postman Collection Usage

### Setup Instructions:
1. Import `Car_Rental_API_Tests.postman_collection.json` into Postman
2. The collection includes environment variables:
   - `{{base_url}}`: https://api.worldtriplink.com/api
   - `{{ets_base_url}}`: https://ets.worldtriplink.com
   - `{{google_maps_key}}`: AIzaSyCelDo4I5cPQ72TfCTQW-arhPZ7ALNcp8w

### Test Categories:

#### 1. One Way Trip Booking
- **Route:** Mumbai → Pune
- **Date:** 2025-06-20
- **Time:** 10:30 AM
- **Expected:** Vehicle options with per-km pricing

#### 2. Round Trip Booking  
- **Route:** Delhi → Agra → Delhi
- **Departure:** 2025-06-22, 08:00 AM
- **Return:** 2025-06-23
- **Expected:** Round trip pricing calculation

#### 3. Rental Trip Booking
- **Route:** Bangalore local
- **Duration:** 8 hours
- **Date:** 2025-06-25, 09:00 AM
- **Expected:** Hourly rental rates

#### 4. Google Maps APIs
- **Reverse Geocoding:** Convert Mumbai coordinates to address
- **Places Autocomplete:** Get location suggestions for "Mumbai"

#### 5. ETS APIs
- **Cab Finder:** Employee transportation booking
- **Invoice Generation:** Generate fare breakdown

#### 6. Test Scenarios
- **Long Distance:** Mumbai → Goa (600km)
- **Hill Station:** Delhi → Manali (Weekend trip)
- **City Rental:** Bangalore Airport → City (8 hours)

## Testing Focus Areas

### One Way Trips:
- ✅ Distance calculation accuracy
- ✅ Vehicle availability by category
- ✅ Per-kilometer pricing
- ✅ Single date validation

### Round Trips:
- ✅ Return date validation (must be after departure)
- ✅ Round trip pricing logic
- ✅ Multi-day booking handling
- ✅ Vehicle availability for extended periods

### Common Test Cases:
- ✅ Invalid location handling
- ✅ Past date validation
- ✅ Empty parameter responses
- ✅ API timeout handling
- ✅ Rate limiting behavior

## Expected API Responses

### Successful Response:
```json
{
  "status": "success",
  "distance": "150",
  "tripinfo": [
    {
      "hatchback": 12,
      "sedan": 15,
      "sedanpremium": 18,
      "suv": 22,
      "suvplus": 28
    }
  ]
}
```

### Error Response:
```json
{
  "status": "error",
  "message": "Invalid location provided"
}
```

## Price Calculation Logic

**Base Fare = Distance × Rate per KM**
**Platform Fee = Base Fare × 10%**
**GST = Base Fare × 5%**
**Total Fare = Base Fare + Platform Fee + GST**

Example for 150km SUV trip:
- Base Fare: 150 × 22 = ₹3,300
- Platform Fee: ₹330
- GST: ₹165
- **Total: ₹3,795**

## Troubleshooting

### Common Issues:
1. **No vehicles available:** Check if locations are valid Indian addresses
2. **API timeout:** Retry with shorter location names
3. **Invalid date:** Ensure date is in YYYY-MM-DD format and not in past
4. **Google Maps errors:** Verify API key is active and has quota

### Debug Tips:
- Use Postman Console to view raw responses
- Check HTTP status codes (200 = success)
- Validate request parameters match expected format
- Test with known working location pairs first

This documentation covers the complete API testing strategy for both one-way and round-trip car rental bookings.
