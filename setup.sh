#!/bin/bash

# AI Demo App Setup Script
# This script helps you set up the Flutter AI Demo App quickly

echo "🤖 AI Demo App Setup Script"
echo "=============================="

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter is not installed. Please install Flutter first:"
    echo "   https://docs.flutter.dev/get-started/install"
    exit 1
fi

echo "✅ Flutter found: $(flutter --version | head -n 1)"

# Check Flutter version
FLUTTER_VERSION=$(flutter --version | head -n 1 | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+' | head -n 1)
echo "📱 Flutter version: $FLUTTER_VERSION"

# Install dependencies
echo "📦 Installing dependencies..."
flutter pub get

if [ $? -eq 0 ]; then
    echo "✅ Dependencies installed successfully"
else
    echo "❌ Failed to install dependencies"
    exit 1
fi

# Check for API key configuration
if grep -q "YOUR_GROQ_API_KEY_HERE" lib/services/groq_service.dart; then
    echo ""
    echo "⚠️  IMPORTANT: Configure your Groq API key"
    echo "   1. Visit https://console.groq.com"
    echo "   2. Create a free account and generate an API key"
    echo "   3. Edit lib/services/groq_service.dart"
    echo "   4. Replace 'YOUR_GROQ_API_KEY_HERE' with your actual key"
    echo ""
fi

# Run Flutter doctor
echo "🔍 Running Flutter doctor..."
flutter doctor

echo ""
echo "🎉 Setup complete!"
echo ""
echo "To run the app:"
echo "   flutter run -d web-server --web-port=9090"
echo ""
echo "Then open: http://localhost:9090"
echo ""
echo "📚 For more information, see README.md"