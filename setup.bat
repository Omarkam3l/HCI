@echo off
REM AI Demo App Setup Script for Windows
REM This script helps you set up the Flutter AI Demo App quickly

echo 🤖 AI Demo App Setup Script
echo ==============================

REM Check if Flutter is installed
flutter --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Flutter is not installed. Please install Flutter first:
    echo    https://docs.flutter.dev/get-started/install
    pause
    exit /b 1
)

echo ✅ Flutter found
flutter --version | findstr /C:"Flutter"

REM Install dependencies
echo 📦 Installing dependencies...
flutter pub get

if %errorlevel% equ 0 (
    echo ✅ Dependencies installed successfully
) else (
    echo ❌ Failed to install dependencies
    pause
    exit /b 1
)

REM Check for API key configuration
findstr /C:"YOUR_GROQ_API_KEY_HERE" lib\services\groq_service.dart >nul 2>&1
if %errorlevel% equ 0 (
    echo.
    echo ⚠️  IMPORTANT: Configure your Groq API key
    echo    1. Visit https://console.groq.com
    echo    2. Create a free account and generate an API key
    echo    3. Edit lib\services\groq_service.dart
    echo    4. Replace 'YOUR_GROQ_API_KEY_HERE' with your actual key
    echo.
)

REM Run Flutter doctor
echo 🔍 Running Flutter doctor...
flutter doctor

echo.
echo 🎉 Setup complete!
echo.
echo To run the app:
echo    flutter run -d web-server --web-port=9090
echo.
echo Then open: http://localhost:9090
echo.
echo 📚 For more information, see README.md
pause