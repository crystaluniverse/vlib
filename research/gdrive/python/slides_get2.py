from google.oauth2 import service_account
from googleapiclient.discovery import build
import fitz  # PyMuPDF
import io
from googleapiclient.http import MediaIoBaseDownload
import os


SERVICE_ACCOUNT_FILE = '${drive.key_path.path}'
PRESENTATION_ID = '${args.presentation_id}'
SCOPES = ['https://www.googleapis.com/auth/drive']


# Authenticate and build the service
credentials = service_account.Credentials.from_service_account_file(
        SERVICE_ACCOUNT_FILE, scopes=SCOPES)
service = build('drive', 'v3', credentials=credentials)

# Export the presentation as a PDF
request = service.files().export_media(fileId=PRESENTATION_ID, mimeType='application/pdf')
fh = io.BytesIO()
downloader = MediaIoBaseDownload(fh, request)
done = False
while not done:
    status, done = downloader.next_chunk()

# Save the PDF to a file
pdf_path = 'presentation.pdf'
with open(pdf_path, 'wb') as f:
    f.write(fh.getvalue())

# Open the PDF and convert each page to PNG
os.makedirs('presentation_slides', exist_ok=True)
doc = fitz.open(pdf_path)
for page_num in range(len(doc)):
    page = doc.load_page(page_num)
    pix = page.get_pixmap()
    output = f"presentation_slides/slide_{page_num + 1}.png"
    pix.save(output)

print('All slides have been downloaded as PNG.')
