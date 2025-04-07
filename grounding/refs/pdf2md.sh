#!/bin/bash

# Activate the virtual environment
source ~/workspace/university/bap/marker/bin/activate

# Find all PDF files in the pdf directory
for pdf_file in pdf/*.pdf; do
    # Extract the base name without extension
    base_name=$(basename "$pdf_file" .pdf)
    
    # Check if the corresponding directory exists in md folder
    if [ ! -d "md/$base_name" ] && [ -f "$pdf_file" ]; then
        echo "Processing $pdf_file..."
        # Apply marker_single command to the PDF file
        marker_single "$pdf_file" --output_dir md
    
        touch bib/$base_name.bib
    fi
done
