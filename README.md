# Scrubbadubdub
Scrub Metadata from files using ExifTool!


Given one or more file paths, removes every metadata tag with ExifTool.
By default write a sibling copy whose name ends in *_clean*
Add *--overwrite* if you prefer to replace the originals in-place.

Usage
-----
    # Keep originals, write photo_clean.jpg and clip_clean.mp4
    python main.py photo.jpg clip.mp4

    # Overwrite the originals
    python main.py --overwrite *.jpg
-----