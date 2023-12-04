project(ShittyPerfMon-Natives)

cmake_minimum_required(VERSION 3.0)
set(CXX_STANDARD 17)

include_directories(Inc)
add_library(WMIFucker SHARED WMIFucker.cpp)
message(STATUS "${LIBRARY_OUTPUT_DIRECTORY}")

add_library(DriveUsageInfo SHARED DriveUsageInfo.cpp)

set(WMIFucker_DLL "${CMAKE_BINARY_DIR}/Debug/WMIFucker.dll")
set(DriveUsageInfo_DLL "${CMAKE_BINARY_DIR}/Debug/DriveUsageInfo.dll")

add_custom_command(
    TARGET WMIFucker
    POST_BUILD
    USES_TERMINAL
    COMMAND ${CMAKE_COMMAND} -E copy_if_different ${WMIFucker_DLL} ${CMAKE_CURRENT_SOURCE_DIR}/../dll/
)
add_custom_command(
    TARGET DriveUsageInfo
    POST_BUILD
    USES_TERMINAL
    COMMAND ${CMAKE_COMMAND} -E copy_if_different ${DriveUsageInfo_DLL} ${CMAKE_CURRENT_SOURCE_DIR}/../dll/
)