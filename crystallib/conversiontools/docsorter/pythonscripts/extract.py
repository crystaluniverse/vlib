
from pathlib import Path
import pymupdf
import json

# Convert inputs to Path objects
pdf_path_obj: Path = Path("@pdf_path").expanduser().resolve()
output_folder_obj: Path = Path("@output_folder")

# Validate PDF exists
if not pdf_path_obj.exists():
    raise FileNotFoundError(f"PDF file not found: {pdf_path_obj}")

# Create output directory if it doesn't exist
output_folder_obj.mkdir(parents=True, exist_ok=True)

# Clean up existing files
if output_folder_obj.exists():
    for file in output_folder_obj.glob("*"):
        if file.suffix in [".png", ".txt", ".json"]:
            file.unlink()

try:
    # Open the PDF
    doc = pymupdf.open(str(pdf_path_obj))
except Exception as e:
    raise ValueError(f"Failed to open PDF: {e}")

extracted_images= []
page_names = []

try:
    # Iterate through pages
    for page_num in range(len(doc)):
        page = doc[page_num]
        page_name = "" 
        
        # Extract text from the page
        text = page.get_text("text")
        print(f"Extracted text from page {page_num}:", text)  # Debug print
        
        # Process text line by line
        for line in text.split('\n'):
            # Look for page label
            if 'page:' in line:
                parts = line.split('page:')
                if len(parts) > 1:
                    page_name = parts[1].strip()
                    page_names.append(page_name)
                    print(f"Page label found: {page_name}")
        
        if page_name:
            # Save text to file
            text_filename = output_folder_obj / f"{page_name}.txt"
            with open(text_filename, "w", encoding="utf-8") as text_file:
                text_file.write(text)
            print(f"Text saved to {text_filename}")
            
            # Render page as image
            zoom = 2  # Increase quality
            mat = pymupdf.Matrix(zoom, zoom)
            pix = page.get_pixmap(matrix=mat)
            
            # Save page as PNG
            image_filename = output_folder_obj / f"{page_name}.png"
            pix.save(str(image_filename))
            print(f"Page saved as {image_filename}")
            extracted_images.append(image_filename)
    
    # Write page names to JSON file
    names_json = {"pages": page_names}
    json_path = output_folder_obj / "pages.json"
    with open(json_path, "w") as f:
        json.dump(names_json, f, indent=2)
    
finally:
    doc.close()

if not extracted_images:
    print("No images were extracted from the PDF")
else:
    print(f"Successfully extracted {len(extracted_images)} images")
    print(f"Created pages.json with {len(page_names)} pages")

