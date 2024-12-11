from googleapiclient.discovery import build
from google_auth_oauthlib.flow import InstalledAppFlow
from google.auth.transport.requests import Request
import os
import io
from googleapiclient.http import MediaIoBaseDownload
import IPython

# Scopes required by the app
SCOPES = ['https://www.googleapis.com/auth/presentations.readonly',
          'https://www.googleapis.com/auth/drive.readonly']

# Path to your credentials JSON file
CREDENTIALS_FILE = '${drive.key_path.path}'

# The ID of your presentation, which can be extracted from the presentation URL
PRESENTATION_ID = '${args.presentation_id}'

# Authenticate and build the service
flow = InstalledAppFlow.from_client_secrets_file(CREDENTIALS_FILE, SCOPES)
creds = flow.run_local_server(port=0)
service = build('slides', 'v1', credentials=creds)
drive_service = build('drive', 'v3', credentials=creds)

# Retrieve the slides from the presentation
presentation = service.presentations().get(presentationId=PRESENTATION_ID).execute()
slides = presentation.get('slides')



# Create a directory for PNG files
os.makedirs('${args.dest_path}', exist_ok=True)

IPython.embed()

# # Download each slide as PNG
# for i, slide in enumerate(slides):
#     page_id = slide.get('objectId')
#     request = drive_service.files().export_media(fileId=PRESENTATION_ID,mimeType='image/png')
#     fh = io.BytesIO()
#     downloader = MediaIoBaseDownload(fh, request)
#     done = False
#     while not done:
#         status, done = downloader.next_chunk()
    
#     # Write the PNG to a file
#     with open(f'${args.dest_path}/slide_{i + 1}.png', 'wb') as f:
#         f.write(fh.getvalue())
#         print(f'Slide {i + 1} downloaded.')
    
print('All slides have been downloaded as PNG.')
