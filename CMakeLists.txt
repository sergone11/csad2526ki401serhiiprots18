cmake_minimum_required(VERSION 3.14)
project(main VERSION 0.1 LANGUAGES CXX)

# Встановлюємо стандарт C++
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Встановлюємо динамічну бібліотеку дебаґу (/MDd) для MSVC
set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreadedDebugDLL")

# Основний виконуваний файл
add_executable(main main.cpp)
target_link_libraries(main PRIVATE math_operations)

# Додаємо підтримку тестів
include(CTest)
enable_testing()

# Уникаємо pthread на Windows
if(NOT WIN32)
    find_package(Threads REQUIRED)
    target_link_libraries(main PRIVATE Threads::Threads)
endif()

# Автоматично завантажуємо і конфігуруємо Google Test
include(FetchContent)
FetchContent_Declare(
  googletest
  GIT_REPOSITORY https://github.com/google/googletest.git
  GIT_TAG v1.14.0
)
set(gtest_force_shared_crt ON CACHE BOOL "" FORCE) # Використовуємо /MDd
FetchContent_MakeAvailable(googletest)
# Створюємо виконуваний файл для тестів
add_executable(unit_tests tests/unit_tests.cpp)
target_link_libraries(unit_tests PRIVATE math_operations gtest gtest_main)
if(NOT WIN32)
    target_link_libraries(unit_tests PRIVATE Threads::Threads)
endif()
add_test(NAME unit_tests COMMAND unit_tests)
