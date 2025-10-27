cmake_minimum_required(VERSION 3.10)
project(HelloWorld VERSION 1.0 LANGUAGES CXX)

# Require C++17
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Create executable from main.cpp
add_executable(hello main.cpp)

# Optional: enable useful warnings for supported compilers
if(MSVC)
  target_compile_options(hello PRIVATE /W4 /permissive-)
else()
  target_compile_options(hello PRIVATE -Wall -Wextra -pedantic)
endif()

