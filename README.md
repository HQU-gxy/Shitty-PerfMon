# Shitty-PerfMon

A Shitty Performance Monitor for OS Course Project.
### This project has the following features:
- Running Processes
- CPU Usage
- Memory Usage
- Disk Drive Space Usage

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://flutter.dev/docs/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://flutter.dev/docs/cookbook)

For help getting started with Flutter, view our
[online documentation](https://flutter.dev/docs), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## How to Use
This project uses Windows native APIs to get the performance data, so it can only run on Windows.

## To Build The Native Library
The dll files are already included in the project, so you don't need to build them yourself.  
But if you want to build it yourself anyway, follow the steps below:

1. Enter the directory *./native/*
2. Create a build output directory e.g. *build*: `mkdir build`
3. Enter the build directory: `cd build`
4. Run `cmake ..` to generate the build files
5. Run `cmake --build . --config Debug` to build the library and copy it to the *../dll/* directory
