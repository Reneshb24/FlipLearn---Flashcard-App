# FlipLearn – Flashcard Learning App

FlipLearn is a simple flashcard-based learning application designed to help learners study and retain information more effectively. The app allows users to create flashcards, organize them into topics and categories, track their learning progress, and test themselves with an integrated quiz feature. Whether you are preparing for school exams, learning a new language, or practicing professional skills, FlipLearn provides a structured and engaging way to study.

# Key Features

* Flashcards: Create, edit, and organize flashcards with questions and answers.
* Topics and Categories: Group flashcards into topics and categories for structured learning.
* Progress Tracking: Mark flashcards as "learned" to track progress over time.
* Built-in Quiz: Take multiple-choice quizzes automatically generated from your flashcards.
* Image Support: Add images to flashcards using either a network URL or from the local gallery.

# Technology Stack

* Framework: Flutter (Dart)
* Supported Platforms: Android and iOS
* Local Storage: SharedPreferences and SQLite
* IDE: Android Studio
* Version Control: Git and GitHub
* Libraries and Plugins:
  
    flutter_plugin_android_lifecycle – Android lifecycle support
  
    shared_preferences – lightweight local persistence
  
    provider – state management
  
    google_fonts – UI styling and typography
  

# Project Structure

* android/ and ios/ – Platform-specific code and configurations.
* lib/ – Application source code, with main.dart as the entry point.
* test/ – Unit and widget tests.
  
# Setup and Installation Guide

To run FlipLearn locally, you need to set up a Flutter development environment. Follow these steps carefully:

1. Prerequisites

Before starting, make sure the following are installed on your system:

* Git (for cloning the repository)
  
    Download: https://git-scm.com/downloads
  
* Flutter SDK (latest stable release)
  
    Download: https://docs.flutter.dev/get-started/install
  
* Android Studio (for building and running Android apps)
  
    Download: https://developer.android.com/studio
  
    Install the following components via Android Studio:

    *  Android SDK Platform 35 (or higher)
    * Android SDK Build-Tools
    * Android Emulator (optional, for testing without a physical device)
      
* Java Development Kit (JDK 17)
  
    Recommended: Eclipse Temurin JDK 17

After installation, confirm everything is set up by running:

flutter doctor

This will check if Flutter, Android SDK, Java, and connected devices are properly configured.

2. Clone the Repository

git clone https://github.com/Reneshb24/FlipLearn---Flashcard-App.git

cd FlipLearn---Flashcard-App

3. Install Dependencies

    Inside the project folder, fetch all required packages:

    flutter pub get

4. Run the Application

* Using a Physical Device:
  
    Connect your Android phone via USB.
  
    Enable USB debugging from Developer Options.
  
    Run:
  
    flutter run

* Using an Emulator:
  
    Open Android Studio.
  
    Start an Android Virtual Device (AVD).
  
    Run the app with:
  
    flutter run
  
# Screenshots:

* Home Screen:
  
      https://github.com/Reneshb24/FlipLearn---Flashcard-App/blob/main/screenshots/home.jpg

* Flashcard Screen:
  
      https://github.com/Reneshb24/FlipLearn---Flashcard-App/blob/main/screenshots/flashcard.jpg
  
* Add Flashcard Screen:
  
      https://github.com/Reneshb24/FlipLearn---Flashcard-App/blob/main/screenshots/addflashcard.jpg
  
* Quiz Screen:
  
      https://github.com/Reneshb24/FlipLearn---Flashcard-App/blob/main/screenshots/quiz.jpg

* Settings Screen:
  
      https://github.com/Reneshb24/FlipLearn---Flashcard-App/blob/main/screenshots/Settings.jpg

# Future Improvements:

* Cloud storage to allow synchronization across multiple devices.
* User authentication for secure access and personalized data.
* Shared topics and categories for collaborative learning.
* Advanced quiz modes, including true/false and fill-in-the-blank.

# Author
  RENESH B
