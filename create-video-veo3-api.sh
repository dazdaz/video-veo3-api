#!/bin/bash

# https://ai.google.dev/gemini-api/docs/video?example=dialogue

# Function to display usage
usage() {
    echo "Usage:"
    echo "  Interactive mode (multi-line prompt):"
    echo "    $0 <output_filename>"
    echo "    Then enter your prompt (can be multiple lines) and press Ctrl-D when done"
    echo ""
    echo "  Command-line mode:"
    echo "    $0 -p \"<prompt>\" <output_filename>"
    echo ""
    echo "Examples:"
    echo "  $0 lion_video.mp4"
    echo "  $0 -p \"A cinematic shot of a majestic lion in the savannah\" lion_video.mp4"
    exit 1
}

# Check if required arguments are provided
if [ $# -lt 1 ]; then
    usage
fi

# Parse arguments
if [ "$1" = "-p" ]; then
    # Command-line mode
    if [ $# -lt 3 ]; then
        echo "Error: Missing prompt or output filename"
        usage
    fi
    PROMPT="$2"
    OUTPUT_FILE="$3"
else
    # Interactive mode
    if [ $# -ne 1 ]; then
        echo "Error: Please provide only the output filename for interactive mode"
        usage
    fi
    OUTPUT_FILE="$1"
    
    echo "Enter your prompt (press Ctrl-D when finished):"
    PROMPT=$(cat)
    
    # Check if prompt is empty
    if [ -z "$PROMPT" ]; then
        echo "Error: Empty prompt provided"
        exit 1
    fi
    
    echo ""
    echo "Prompt received."
fi

# Note: This script uses jq to parse the JSON response.
# GEMINI API Base URL
BASE_URL="https://generativelanguage.googleapis.com/v1beta"

# Check if API key is set
if [ -z "$GEMINI_API_KEY" ]; then
    echo "Error: GEMINI_API_KEY environment variable is not set"
    exit 1
fi

echo "Starting video generation..."
echo "Prompt: ${PROMPT}"
echo "Output file: ${OUTPUT_FILE}"

# Escape the prompt for JSON (handle quotes and newlines)
ESCAPED_PROMPT=$(echo "$PROMPT" | jq -Rs .)

# Send request to generate video and capture the operation name into a variable.
operation_name=$(curl -s "${BASE_URL}/models/veo-3.0-generate-001:predictLongRunning" \
  -H "x-goog-api-key: $GEMINI_API_KEY" \
  -H "Content-Type: application/json" \
  -X "POST" \
  -d "{
    \"instances\": [{
        \"prompt\": ${ESCAPED_PROMPT}
      }
    ],
    \"parameters\": {
      \"aspectRatio\": \"16:9\",
      \"negativePrompt\": \"cartoon, drawing, low quality\"
    }
  }" | jq -r .name)

# Check if we got a valid operation name
if [ -z "$operation_name" ] || [ "$operation_name" = "null" ]; then
    echo "Error: Failed to start video generation"
    exit 1
fi

echo "Video generation started. Operation: ${operation_name}"
echo "Polling for completion..."

# Poll the operation status until the video is ready
while true; do
  # Get the full JSON status and store it in a variable.
  status_response=$(curl -s -H "x-goog-api-key: $GEMINI_API_KEY" "${BASE_URL}/${operation_name}")

  # Check the "done" field from the JSON stored in the variable.
  is_done=$(echo "${status_response}" | jq .done)

  if [ "${is_done}" = "true" ]; then
    # Extract the download URI from the final response.
    video_uri=$(echo "${status_response}" | jq -r '.response.generateVideoResponse.generatedSamples[0].video.uri')

    if [ -z "$video_uri" ] || [ "$video_uri" = "null" ]; then
        echo "Error: Failed to get video URI from response"
        exit 1
    fi

    echo "Video ready! Downloading from: ${video_uri}"

    # Download the video using the URI and API key and follow redirects.
    curl -L -o "${OUTPUT_FILE}" -H "x-goog-api-key: $GEMINI_API_KEY" "${video_uri}"

    if [ $? -eq 0 ]; then
        echo "Video successfully saved to: ${OUTPUT_FILE}"
    else
        echo "Error: Failed to download video"
        exit 1
    fi
    break
  fi

  echo -n "."
  # Wait for 10 seconds before checking again.
  sleep 10
done
