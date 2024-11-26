# Google tools

- go to https://console.cloud.google.com/apis/dashboard




Capturing all slides from a Google Slides presentation and exporting them as PNG images can be done using Google's API. To achieve this, you'll need to use the Google Slides API and Google Drive API. Here's a basic outline of how you could implement this in Python:

Prerequisites:

- Google Cloud Platform Account: Create a project in the Google Cloud Platform (GCP) Console.
- Enable APIs: Enable the Google Slides API and Google Drive API for your project.
- Create Credentials: Create credentials (OAuth client ID) in the GCP console. Download the JSON file containing these credentials.


## when it doesn't work

The error message "ValueError: Client secrets must be for a web or installed app" indicates that the type of credentials you are using with the Google API is not appropriate for your application type. This usually happens when you're using the wrong type of credentials (like service account credentials) in a context that requires OAuth client credentials.

To fix this issue, you need to ensure that you create and use the correct type of credentials in the Google Cloud Platform (GCP) Console. Here's how to do it:

### Steps to Create Correct OAuth Client Credentials:

1. **Go to the Google Cloud Console**: Visit the [Google Cloud Console](https://console.cloud.google.com/).

2. **Select Your Project**: Make sure you have selected the project where you enabled the Google Slides and Google Drive APIs.

3. **Navigate to Credentials Page**: Go to the "Credentials" page in the "APIs & Services" section.

4. **Create Credentials**: Click on the “Create Credentials” button at the top of the page and select “OAuth client ID”.

5. **Configure OAuth Consent Screen**:
   - If prompted, you'll first need to configure the OAuth consent screen. This includes setting the user type (usually "External") and entering the required information like application name, user support email, etc.
   - Once you've configured and saved the consent screen settings, return to creating the OAuth client ID.

6. **Application Type**:
   - Select the application type that fits your usage. For a standalone Python script or a desktop application, choose "Desktop app".
   - Enter a name for the OAuth client ID and click "Create".

7. **Download the JSON File**:
   - After creating the OAuth client ID, click the "Download" button (represented by a download icon) next to the created OAuth client ID to download the JSON file containing your credentials.

8. **Use the Downloaded JSON in Your Script**:
   - Replace the path in the `CREDENTIALS_FILE` variable in your Python script with the path to this downloaded JSON file.

### Retry Running Your Python Script

Once you have the correct OAuth client ID credentials in place and referenced in your script, try running your Python script again. It should prompt you to log in with your Google account and grant the necessary permissions. After granting the permissions, the script should work as intended without raising the "Client secrets must be for a web or installed app" error.