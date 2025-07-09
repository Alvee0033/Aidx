# Google Places API Setup Guide

This guide will help you set up Google Places API to get real doctor and pharmacy data in the Medigay app.

## Prerequisites

1. A Google account
2. Access to Google Cloud Console

## Step-by-Step Setup

### 1. Create a Google Cloud Project

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Click on "Select a project" at the top
3. Click "New Project"
4. Enter a project name (e.g., "Medigay App")
5. Click "Create"

### 2. Enable Required APIs

1. In your project, go to "APIs & Services" > "Library"
2. Search for and enable the following APIs:
   - **Places API** - For finding doctors and pharmacies
   - **Geocoding API** - For address lookup
   - **Maps JavaScript API** - For map integration

### 3. Create API Key

1. Go to "APIs & Services" > "Credentials"
2. Click "Create Credentials" > "API Key"
3. Copy the generated API key

### 4. Restrict API Key (Recommended for Security)

1. Click on the created API key
2. Under "Application restrictions", select "Android apps"
3. Add your app's package name: `com.medigay.app.medigay_app`
4. Under "API restrictions", select "Restrict key"
5. Select the APIs you enabled (Places API, Geocoding API, Maps JavaScript API)
6. Click "Save"

### 5. Configure the App

1. Open `lib/config/api_config.dart`
2. Replace `YOUR_GOOGLE_PLACES_API_KEY_HERE` with your actual API key:

```dart
static const String googlePlacesApiKey = 'your_actual_api_key_here';
```

### 6. Test the Integration

1. Run the app
2. Navigate to "Professionals & Pharmacy"
3. Select "Find Doctors" or "Find Pharmacy"
4. Set your search criteria and tap "Search"
5. You should see real data from Google Places API

## API Quotas and Limits

- **Free Tier**: 1,000 requests per day for Places API
- **Paid Tier**: $17 per 1,000 requests after free tier
- **Rate Limits**: 100 requests per 100 seconds per user

## Troubleshooting

### Common Issues

1. **"REQUEST_DENIED" Error**
   - Check if your API key is correct
   - Verify that Places API is enabled
   - Ensure API key restrictions are properly configured

2. **"OVER_QUERY_LIMIT" Error**
   - You've exceeded your daily quota
   - Wait until tomorrow or upgrade to paid tier

3. **"ZERO_RESULTS" Error**
   - No places found for your search criteria
   - Try expanding the search radius
   - Check if the location is correct

### Debug Information

The app includes fallback sample data if the API fails. Check the console logs for detailed error messages.

## Security Best Practices

1. **Never commit API keys to version control**
2. **Use API key restrictions** to limit usage to your app
3. **Monitor API usage** in Google Cloud Console
4. **Consider using environment variables** for production

## Cost Optimization

1. **Cache results** to reduce API calls
2. **Use appropriate search radius** to avoid unnecessary requests
3. **Implement pagination** for large result sets
4. **Monitor usage** to stay within free tier limits

## Support

If you encounter issues:
1. Check Google Cloud Console for API status
2. Review the [Google Places API documentation](https://developers.google.com/maps/documentation/places/web-service)
3. Check the app's console logs for detailed error messages 