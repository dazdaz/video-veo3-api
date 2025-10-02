# Video Generation and Safety Analysis Tools

A collection of scripts for generating videos using Google's Gemini Veo 3.0 API and analyzing them for safety compliance using Google Cloud Vision API.

## Overview

This repository contains two main tools:

1. **`create-video-veo3-api.sh`** - Generate videos from text prompts using Gemini's Veo 3.0 model
2. **`safe-search-vision-api.py`** - Analyze video content for safety concerns using Google Cloud Vision API

## Prerequisites

- **Bash** (for video generation script)
- **Python 3.7+** (for safety analysis)
- **uv** package manager ([installation instructions](https://github.com/astral-sh/uv))
- **Google Cloud Project** with Vision API enabled
- **Gemini API Key** ([get one here](https://ai.google.dev/))
- **ffprobe** (optional, for video metadata inspection)

### System Dependencies

```bash
# Install jq for JSON parsing (required for video generation)
# macOS
brew install jq

# Ubuntu/Debian
sudo apt-get install jq

# Install OpenCV dependencies (for safety analysis)
# Ubuntu/Debian
sudo apt-get install python3-opencv
```

## Setup

### 1. Clone the Repository

```bash
git clone <repository-url>
cd <repository-directory>
```

### 2. Set Up Python Environment

```bash
# Create virtual environment
uv venv

# Activate virtual environment
source .venv/bin/activate  # On Windows: .venv\Scripts\activate

# Install dependencies for safety analysis
uv pip install -r requirements-safe-search.txt
```

### 3. Configure API Access

#### Gemini API Key

```bash
export GEMINI_API_KEY=your_api_key_here
```

#### Google Cloud Credentials

```bash
# Enable Vision API
gcloud services enable vision.googleapis.com --project=your-project-id

# Set credentials (one of the following methods)
# Method 1: Application Default Credentials
gcloud auth application-default login

# Method 2: Service Account
export GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account-key.json
```

## Usage

### Video Generation with Veo 3.0

The script supports two modes: **interactive** and **command-line**.

#### Interactive Mode (Multi-line Prompts)

```bash
./create-video-veo3-api.sh output_video.mp4
```

Then enter your prompt and press `Ctrl-D` when finished:

```
Enter your prompt (press Ctrl-D when finished):
A cinematic shot of a majestic lion in the savannah,
golden hour lighting, 4K quality, smooth camera movement
^D
```

#### Command-line Mode (Single-line Prompts)

```bash
./create-video-veo3-api.sh -p "A cinematic shot of a majestic lion in the savannah" lion_video.mp4
```

#### Features

- **Aspect Ratio**: 16:9 (hardcoded, can be modified in script)
- **Negative Prompt**: Automatically excludes "cartoon, drawing, low quality"
- **Progress Tracking**: Real-time polling with status updates
- **Timing**: Reports total generation time
- **Error Handling**: Validates responses and provides clear error messages

### Video Safety Analysis

Analyze generated videos (or any MP4 file) for inappropriate content:

#### Basic Usage

```bash
./safe-search-vision-api.py lion_video.mp4
```

#### Advanced Options

```bash
# Analyze with custom sampling interval and save flagged frames
./safe-search-vision-api.py video.mp4 \
  --interval 2.0 \
  --save-flagged \
  --output-dir flagged_frames \
  --json-output results.json \
  --report-output report.txt

# Use specific service account
./safe-search-vision-api.py video.mp4 \
  --credentials /path/to/service-account.json
```

#### Options

| Option | Description | Default |
|--------|-------------|---------|
| `--credentials` | Path to Google Cloud service account JSON | Uses application default |
| `--interval` | Seconds between frame analysis | 1.0 |
| `--save-flagged` | Save frames with detected issues | False |
| `--output-dir` | Directory for flagged frames | `flagged_frames` |
| `--json-output` | Save detailed JSON results | None |
| `--report-output` | Save text report | None |

#### Safety Categories Analyzed

- **Adult Content**: Inappropriate adult material
- **Violence**: Violent or gory imagery
- **Medical**: Medical/surgical content
- **Racy**: Suggestive content
- **Spoof**: Fake or manipulated content

#### Likelihood Levels

- `VERY_UNLIKELY`
- `UNLIKELY`
- `POSSIBLE` ⚠️ (triggers flag)
- `LIKELY` ⚠️ (triggers flag)
- `VERY_LIKELY` ⚠️ (triggers flag)

### Video Inspection (Optional)

Use `ffprobe` to inspect generated video metadata:

```bash
# Full video information
ffprobe -v error -show_format -show_streams lion_video.mp4

# Specific codec and dimension information
ffprobe -v error \
  -select_streams v:0 \
  -show_entries stream=codec_name,codec_long_name,coded_width,coded_height:format=filename,size,duration \
  -of default=nw=1:nokey=0 \
  lion_video.mp4
```

## Example Workflow

```bash
# 1. Generate a video
export GEMINI_API_KEY=your_api_key_here
./create-video-veo3-api.sh -p "A peaceful beach at sunset with waves crashing" beach.mp4

# 2. Analyze the generated video
./safe-search-vision-api.py beach.mp4 \
  --interval 1.0 \
  --save-flagged \
  --json-output beach_analysis.json \
  --report-output beach_report.txt

# 3. Inspect video metadata
ffprobe beach.mp4
```

## Output Examples

### Video Generation Output

```
create-video-veo3-api.sh -p "create a lion walking in the savannah, who turns his head towards the camera and roars" lion.mp4
Starting video generation...
Prompt: A cinematic shot of a majestic lion in the savannah
Output file: lion_video.mp4
Video generation started. Operation: projects/.../operations/...
Polling for completion...
..........
Video ready! Downloading from: https://...
==================================
Video successfully saved to: lion_video.mp4
Time taken: 125 seconds
==================================
```

### Safety Analysis Report

```
$ safe-search-vision-api.py lion.mp4
============================================================
VIDEO SAFE SEARCH ANALYSIS REPORT
============================================================
Video: lion_video.mp4
Analysis Date: 2024-01-15T10:30:45.123456
Frames Analyzed: 60
Sampling Interval: 1.0 seconds

SUMMARY
----------------------------------------
Maximum Adult Content: VERY_UNLIKELY
Maximum Violence: UNLIKELY
Maximum Medical: VERY_UNLIKELY
Maximum Racy Content: VERY_UNLIKELY
Maximum Spoof: VERY_UNLIKELY

✓ No concerning content detected
```

## Dependencies

### Video Generation Script (`requirements.txt`)

```
# System tools (must be installed separately)
jq
curl
```

## Troubleshooting

### Video Generation Issues

**Error: GEMINI_API_KEY environment variable is not set**
```bash
export GEMINI_API_KEY=your_actual_api_key
```

**Error: Failed to start video generation**
- Check API key validity
- Verify API quota limits
- Ensure prompt is properly formatted

**jq command not found**
```bash
# macOS
brew install jq

# Ubuntu/Debian
sudo apt-get install jq
```

### Safety Analysis Issues

**Error: Could not import google.cloud.vision**
```bash
source .venv/bin/activate
uv pip install -r requirements-safe-search.txt
```

**Authentication errors**
```bash
# Re-authenticate
gcloud auth application-default login

# Or set service account
export GOOGLE_APPLICATION_CREDENTIALS=/path/to/key.json
```

**Vision API not enabled**
```bash
gcloud services enable vision.googleapis.com --project=your-project-id
```

## Cost Considerations

- **Gemini Veo 3.0**: Check [Gemini pricing](https://ai.google.dev/pricing)
- **Vision API**: ~$1.50 per 1000 images analyzed ([pricing details](https://cloud.google.com/vision/pricing))

## Support

For issues and questions:
- Gemini API: https://ai.google.dev/gemini-api/docs
- Vision API: https://cloud.google.com/vision/docs
