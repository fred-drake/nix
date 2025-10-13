# Scanimage Command Reference for Web Application

This document provides comprehensive information about `scanimage` options for the Epson ES-400 scanner. Use this as a reference for building a web application that calls `scanimage`.

## Table of Contents
- [Device Identification](#device-identification)
- [Output Formats](#output-formats)
- [Resolution Settings](#resolution-settings)
- [Scan Modes](#scan-modes)
- [Scan Areas](#scan-areas)
- [Scanner Source](#scanner-source)
- [Duplex Scanning](#duplex-scanning)
- [Batch Scanning](#batch-scanning)
- [Image Adjustments](#image-adjustments)
- [Advanced Options](#advanced-options)
- [Command Examples](#command-examples)
- [Exit Codes](#exit-codes)

---

## Device Identification

### Device String
The Epson ES-400 has two available backends:

**epsonscan2 (Recommended):**
```
epsonscan2:ES-400:583248383231303773:esci2:usb:ES0128:342
```
- Most feature-complete
- Supports all scanner capabilities
- Uses device serial number (stable across reconnects)

**epsonds (Alternative):**
```
epsonds:libusb:003:XXX
```
- Simpler backend
- Device number (XXX) changes on reconnect
- Fewer features

### List Available Scanners
```bash
scanimage -L
# or
scanimage --list-devices
```

### Show Device Capabilities
```bash
scanimage -d "DEVICE_STRING" -A
# or
scanimage --device="DEVICE_STRING" --all-options
```

---

## Output Formats

### Supported Formats
- **PDF** - Best for documents
- **PNG** - Lossless compression
- **JPEG** - Smaller file sizes, lossy
- **TIFF** - Professional archival format
- **PNM** - Uncompressed (default if not specified)

### Format Option
```bash
--format=<format>
```

**Examples:**
```bash
--format=pdf
--format=png
--format=jpeg
--format=tiff
```

**File Extension Recommendations:**
- PDF → `.pdf`
- PNG → `.png`
- JPEG → `.jpg` or `.jpeg`
- TIFF → `.tif` or `.tiff`
- PNM → `.pnm`

---

## Resolution Settings

### Optical Resolution
- **Native sensor**: 600 DPI
- **Interpolated max**: 1200 DPI

### Resolution Option
```bash
--resolution=<dpi>
```

**Valid range:** 50-1200 DPI (in steps of 1)

**Recommended Settings by Use Case:**

| Use Case | DPI | File Size | Quality |
|----------|-----|-----------|---------|
| Quick preview | 150 | Small | Low |
| Standard documents | 200-300 | Medium | Good |
| High-quality documents | 600 | Large | Excellent |
| Archival/OCR | 600 | Large | Best |
| Photo scanning | 600 | Very Large | Best |

**Examples:**
```bash
--resolution=150  # Fast preview
--resolution=300  # Balanced quality/size
--resolution=600  # Maximum optical quality
```

**Note:** Resolutions above 600 DPI use interpolation and don't improve actual quality.

---

## Scan Modes

### Mode Option
```bash
--mode=<mode>
```

### Available Modes
1. **Color** - Full color scanning (24-bit)
2. **Grayscale** - Black and white with shades of gray (8-bit)
3. **Monochrome** - Pure black and white (1-bit, also called Lineart)

**Examples:**
```bash
--mode=Color       # Most common for documents with color
--mode=Grayscale   # Good for text documents, smaller files
--mode=Monochrome  # Smallest files, text only
```

**File Size Comparison (A4 page at 300 DPI):**
- Color: ~2-5 MB
- Grayscale: ~1-2 MB
- Monochrome: ~50-200 KB

---

## Scan Areas

### Predefined Scan Areas
```bash
--scan-area=<area>
```

**Available Presets:**
- `Auto Detect` - Automatically detect document size
- `Auto Detect (long paper)` - For extra-long documents
- `Letter` - 8.5" × 11" (US Letter)
- `Legal` - 8.5" × 14" (US Legal)
- `A4` - 210mm × 297mm (International standard)
- `A5` - 148mm × 210mm
- `A5 (Landscape)` - A5 rotated
- `A6` - 105mm × 148mm
- `A6 (Landscape)` - A6 rotated
- `A8` - 52mm × 74mm
- `A8 (Landscape)` - A8 rotated
- `B5 [JIS]` - 182mm × 257mm (Japanese standard)
- `Postcard` - 100mm × 148mm
- `Postcard (Landscape)` - Postcard rotated
- `PlasticCard` - Credit card size (54mm × 86mm)
- `Maximum` - Full scanner bed
- `Manual` - Use custom dimensions (see below)

### Custom Scan Area (Manual)
When using `--scan-area=Manual`, specify dimensions:

```bash
-l <x>    # Left edge (0-215.9mm)
-t <y>    # Top edge (0-393.7mm)
-x <width>   # Width (0-215.9mm)
-y <height>  # Height (0-393.7mm)
```

**Example (4" × 6" photo):**
```bash
--scan-area=Manual -l 0 -t 0 -x 101.6 -y 152.4
```

---

## Scanner Source

### Source Option
```bash
--source=<source>
```

### Available Sources
- `ADF` or `ADF Front` - Document feeder (single-sided)
- `ADF Duplex` - Document feeder (NOT SUPPORTED ON ES-400)

**Note:** The ES-400 uses automatic duplex detection. Use `--duplex=yes` for two-sided scanning (see below).

---

## Duplex Scanning

### Duplex Option
```bash
--duplex=yes    # Scan both sides
--duplex=no     # Scan front only (default)
```

**Requirements:**
- Must use ADF (Auto Document Feeder)
- Document must be placed in the feeder tray
- Works best with batch mode for multiple pages

**Example:**
```bash
scanimage -d "DEVICE" \
  --source="ADF Front" \
  --duplex=yes \
  --format=pdf \
  --batch="page-%04d.pdf"
```

---

## Batch Scanning

Batch mode scans multiple pages sequentially.

### Batch Options
```bash
--batch[=FORMAT]           # Enable batch mode
--batch-start=<n>          # Start numbering at n (default: 1)
--batch-count=<n>          # Scan exactly n pages
--batch-increment=<n>      # Increment page number by n (default: 1)
--batch-double             # Same as --batch-increment=2
--batch-print              # Print filenames to stdout
--batch-prompt             # Prompt before each page
```

### Batch Format String
Use `%d` for page numbers (with optional width formatting):
- `%d` - 1, 2, 3, ...
- `%02d` - 01, 02, 03, ...
- `%04d` - 0001, 0002, 0003, ...

**Default formats by output format:**
- PDF: `out%d.pdf`
- PNG: `out%d.png`
- JPEG: `out%d.jpg`
- TIFF: `out%d.tif`

### Batch Examples

**Scan all pages in ADF:**
```bash
scanimage -d "DEVICE" \
  --format=pdf \
  --batch="/path/to/page-%04d.pdf"
```

**Scan exactly 5 pages:**
```bash
scanimage -d "DEVICE" \
  --batch="page-%d.pdf" \
  --batch-count=5
```

**Scan with manual prompting:**
```bash
scanimage -d "DEVICE" \
  --batch="page-%d.pdf" \
  --batch-prompt
```

**Merging batch PDFs:**
After scanning, merge with `pdfunite` (requires poppler-utils):
```bash
pdfunite page-*.pdf output.pdf
rm page-*.pdf
```

---

## Image Adjustments

### Brightness
```bash
--brightness=<value>   # Range: -100 to 100 (default: 0)
```
- Negative values darken
- Positive values lighten

### Contrast
```bash
--contrast=<value>     # Range: -100 to 100 (default: 0)
```
- Negative values decrease contrast
- Positive values increase contrast

### Gamma Correction
```bash
--gamma-correction=<value>   # Range: 0.5 to 3.0 (default: 2.2)
```
- Lower values darken
- Higher values lighten
- 2.2 is standard sRGB gamma

### Threshold (Monochrome Only)
```bash
--threshold=<value>    # Range: 0-255 (default: 128)
```
- Determines black/white cutoff
- Lower values = more black
- Higher values = more white

### Color Dropout
```bash
--dropout=<color>
```
Options: `None`, `Red`, `Blue`, `Green`
- Removes specified color channel
- Useful for scanning forms with colored backgrounds

### Text Enhancement
```bash
--text-enhance=<level>
```
Options: `None`, `Normal`, `High`
- Sharpens text for better OCR
- May increase file size

---

## Advanced Options

### Deskew
```bash
--deskew=yes    # Auto-correct document rotation (default)
--deskew=no     # Disable auto-rotation
```

### Rotation
```bash
--rotate=<degrees>
```
Options: `0 degrees`, `90 degrees`, `180 degrees`, `270 degrees`, `Auto`

### Skip Blank Pages
```bash
--skip-blankpages=<threshold>   # Range: 0-30
```
- 0 = disabled (default)
- Higher values = more aggressive blank detection
- Useful for batch scanning mixed documents

### Double Feed Detection
```bash
--double-feed-detection=<mode>
```
Options: `None`, `Thin` (requires hardware support)
- Detects when multiple pages feed at once

### Long Paper Mode
```bash
--long-paper-mode=yes    # Enable scanning of extra-long documents
--long-paper-mode=no     # Standard mode (default)
```
- Only supports automatic height detection
- No manual height specification in long paper mode

### Image Count
```bash
--image-count=<n>   # Range: 1-999 (default: 0 for continuous)
```
- Maximum number of images to scan in ADF mode
- 0 = scan until feeder is empty

---

## Command Examples

### 1. Simple Single-Page Scan
```bash
scanimage \
  -d "epsonscan2:ES-400:583248383231303773:esci2:usb:ES0128:342" \
  --format=pdf \
  --resolution=300 \
  --mode=Color \
  --scan-area=A4 \
  > document.pdf
```

### 2. High-Quality Scan
```bash
scanimage \
  -d "epsonscan2:ES-400:583248383231303773:esci2:usb:ES0128:342" \
  --format=pdf \
  --resolution=600 \
  --mode=Color \
  --scan-area=A4 \
  --brightness=10 \
  --contrast=10 \
  > document-hq.pdf
```

### 3. Fast Grayscale Document
```bash
scanimage \
  -d "epsonscan2:ES-400:583248383231303773:esci2:usb:ES0128:342" \
  --format=pdf \
  --resolution=200 \
  --mode=Grayscale \
  --scan-area=Letter \
  > document-gray.pdf
```

### 4. Batch Scan from ADF
```bash
scanimage \
  -d "epsonscan2:ES-400:583248383231303773:esci2:usb:ES0128:342" \
  --format=pdf \
  --resolution=300 \
  --mode=Color \
  --scan-area=A4 \
  --batch="/tmp/page-%04d.pdf" \
  --batch-start=1

# Merge into single PDF
pdfunite /tmp/page-*.pdf output.pdf
rm /tmp/page-*.pdf
```

### 5. Duplex Scan (Both Sides)
```bash
scanimage \
  -d "epsonscan2:ES-400:583248383231303773:esci2:usb:ES0128:342" \
  --format=pdf \
  --resolution=300 \
  --mode=Color \
  --scan-area=A4 \
  --source="ADF Front" \
  --duplex=yes \
  --batch="/tmp/page-%04d.pdf"

# Merge pages
pdfunite /tmp/page-*.pdf output-duplex.pdf
rm /tmp/page-*.pdf
```

### 6. Scan with Text Enhancement
```bash
scanimage \
  -d "epsonscan2:ES-400:583248383231303773:esci2:usb:ES0128:342" \
  --format=pdf \
  --resolution=300 \
  --mode=Grayscale \
  --scan-area=A4 \
  --text-enhance=High \
  --brightness=5 \
  > document-ocr.pdf
```

### 7. Scan Receipt (Small Document)
```bash
scanimage \
  -d "epsonscan2:ES-400:583248383231303773:esci2:usb:ES0128:342" \
  --format=pdf \
  --resolution=300 \
  --mode=Color \
  --scan-area="Auto Detect" \
  > receipt.pdf
```

### 8. Scan Business Card
```bash
scanimage \
  -d "epsonscan2:ES-400:583248383231303773:esci2:usb:ES0128:342" \
  --format=png \
  --resolution=600 \
  --mode=Color \
  --scan-area=PlasticCard \
  > business-card.png
```

---

## Exit Codes

### Standard Exit Codes
- **0** - Success
- **1** - General error
- **7** - Out of memory
- **Other** - Various SANE backend errors

### Common Error Messages

**"Document feeder out of documents"**
- No paper in ADF
- Place document in feeder tray

**"Error during device I/O"**
- USB connection issue
- Scanner powered off
- Permission problem
- Try: power cycle scanner, check permissions

**"open of device failed"**
- Scanner not detected
- Wrong device string
- Another process using scanner

**"Invalid argument"**
- Incorrect option value
- Unsupported combination of options
- Check option ranges and compatibility

---

## Web Application Considerations

### Recommended Presets for Web UI

**Quick Scan (Fast):**
- Resolution: 150 DPI
- Mode: Grayscale
- Format: PDF
- Est. time: ~3-5 seconds

**Standard Scan (Balanced):**
- Resolution: 300 DPI
- Mode: Color
- Format: PDF
- Est. time: ~8-12 seconds

**High Quality (Archival):**
- Resolution: 600 DPI
- Mode: Color
- Format: PDF
- Est. time: ~20-30 seconds

### Performance Metrics

| Resolution | Mode | A4 Scan Time | File Size (Color) |
|------------|------|--------------|-------------------|
| 150 DPI | Color | ~5 sec | 300-800 KB |
| 200 DPI | Color | ~6 sec | 500 KB - 1.5 MB |
| 300 DPI | Color | ~10 sec | 1-3 MB |
| 600 DPI | Color | ~25 sec | 2-6 MB |

### Error Handling Best Practices

1. **Timeout Handling**
   - Set reasonable timeouts (2-3 minutes for single page)
   - Longer for batch scans
   - Provide progress feedback to user

2. **Validation**
   - Check scanner availability before starting
   - Verify paper in ADF for batch scans
   - Validate output file was created and has content

3. **Cleanup**
   - Remove empty/failed scan files
   - Clean up temporary files after merging
   - Handle interrupted scans gracefully

4. **User Feedback**
   - Show scanning progress
   - Report estimated time remaining
   - Display clear error messages

### Security Considerations

1. **Input Validation**
   - Sanitize filenames
   - Validate resolution/mode values
   - Limit batch page counts

2. **File Storage**
   - Use temporary directories
   - Set appropriate permissions (640 or 600)
   - Clean up old scans automatically

3. **Resource Limits**
   - Limit concurrent scans (1 at a time)
   - Set disk space quotas
   - Implement rate limiting

### API Design Recommendations

**Minimal Required Parameters:**
```json
{
  "format": "pdf",
  "resolution": 300,
  "mode": "Color"
}
```

**Full Options:**
```json
{
  "format": "pdf|png|jpeg|tiff",
  "resolution": 50-1200,
  "mode": "Color|Grayscale|Monochrome",
  "scan_area": "A4|Letter|Auto Detect|...",
  "duplex": true|false,
  "batch": true|false,
  "brightness": -100 to 100,
  "contrast": -100 to 100,
  "text_enhance": "None|Normal|High",
  "deskew": true|false,
  "skip_blank": 0-30
}
```

---

## Additional Resources

**SANE Project:**
- Homepage: http://www.sane-project.org/
- Man Pages: http://www.sane-project.org/man/
- Supported Devices: http://www.sane-project.org/sane-backends.html

**Epson ES-400 Specifications:**
- Optical Resolution: 600 DPI
- Interpolated Resolution: 1200 DPI
- ADF Capacity: 50 sheets
- Color Depth: 24-bit input / 24-bit output
- Max Document Size: 8.5" × 14" (216mm × 356mm)
- Long Paper Mode: Up to 236" (5994mm)

**Useful Commands:**
```bash
# List all options
scanimage -A

# Test scan (no output)
scanimage --test

# Batch scan all pages
scanimage --batch

# Get version
scanimage --version

# Help
scanimage --help
```
