@echo off
:: =============================================
:: Local CI script for Windows
:: Runs: mkdir build → cd build → cmake .. → build → ctest
:: Usage: .\ci.bat
:: =============================================

setlocal

echo.
echo [CI] Creating build directory...
if not exist build mkdir build
cd build

echo.
echo [CI] Configuring project with CMake...
cmake ..
if errorlevel 1 (
    echo [ERROR] CMake configuration failed
    cd ..
    exit /b 1
)

echo.
echo [CI] Building project (Debug)...
cmake --build . --config Debug
if errorlevel 1 (
    echo [ERROR] Build failed
    cd ..
    exit /b 1
)

echo.
echo [CI] Running unit tests with CTest...
ctest --output-on-failure -C Debug
if errorlevel 1 (
    echo [ERROR] Tests failed!
    cd ..
    exit /b 1
)

cd ..
echo.
echo [SUCCESS] Build and tests completed successfully!
echo Executable: build\Debug\hello.exe
echo.

endlocal
exit /b 0
