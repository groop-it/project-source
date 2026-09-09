@echo off
chcp 65001 > nul
setlocal EnableExtensions

title OZ Scheduler Launcher

rem ============================================================
rem OZ Scheduler Launcher
rem - 최초 실행 시 JAVA_HOME / SCH_HOME 입력
rem - 설정 저장 여부 확인
rem - 저장 시 oz-scheduler-config.bat 생성
rem - 이후 실행 시 저장된 설정 사용
rem ============================================================

set "CONFIG_FILE=%~dp0oz-scheduler-config.bat"

:START
cls
echo ==========================================
echo        OZ Scheduler Launcher
echo ==========================================
echo.

rem ------------------------------------------------------------
rem 저장된 설정 파일 확인
rem ------------------------------------------------------------
if exist "%CONFIG_FILE%" (
    call "%CONFIG_FILE%"

    echo [저장된 설정]
    echo.
    echo JAVA_HOME = %JAVA_HOME%
    echo SCH_HOME  = %SCH_HOME%
    echo.
    echo ------------------------------------------
    echo [1] 저장된 설정으로 실행
    echo [2] 경로 다시 설정
    echo [3] 종료
    echo ------------------------------------------
    echo.

    set /p MENU=선택 ^> 

    if "%MENU%"=="1" goto VALIDATE
    if "%MENU%"=="2" goto INPUT_CONFIG
    if "%MENU%"=="3" goto END

    echo.
    echo [ERROR] 잘못된 선택입니다.
    pause
    goto START
)

rem 설정파일이 없으면 최초 설정
goto INPUT_CONFIG


:INPUT_CONFIG
cls
echo ==========================================
echo        OZ Scheduler Launcher
echo ==========================================
echo.
echo OZ Scheduler 실행 환경을 설정합니다.
echo.

rem 기존 값 초기화
set "JAVA_HOME="
set "SCH_HOME="

echo JAVA_HOME을 입력하세요:
set /p JAVA_HOME=^> 

echo.
echo SCH_HOME을 입력하세요:
set /p SCH_HOME=^> 

rem 혹시 사용자가 "C:\..." 형태로 입력했을 경우 따옴표 제거
set "JAVA_HOME=%JAVA_HOME:"=%"
set "SCH_HOME=%SCH_HOME:"=%"

echo.
echo ==========================================
echo        입력한 설정
echo ==========================================
echo.
echo JAVA_HOME = %JAVA_HOME%
echo SCH_HOME  = %SCH_HOME%
echo.

rem ------------------------------------------------------------
rem 입력값 Validation
rem ------------------------------------------------------------
if "%JAVA_HOME%"=="" (
    echo [ERROR] JAVA_HOME이 입력되지 않았습니다.
    pause
    goto INPUT_CONFIG
)

if "%SCH_HOME%"=="" (
    echo [ERROR] SCH_HOME이 입력되지 않았습니다.
    pause
    goto INPUT_CONFIG
)

if not exist "%JAVA_HOME%\bin\java.exe" (
    echo [ERROR] JAVA_HOME에서 java.exe를 찾을 수 없습니다.
    echo.
    echo 확인 경로:
    echo %JAVA_HOME%\bin\java.exe
    echo.
    pause
    goto INPUT_CONFIG
)

if not exist "%SCH_HOME%" (
    echo [ERROR] SCH_HOME 경로가 존재하지 않습니다.
    echo.
    echo 확인 경로:
    echo %SCH_HOME%
    echo.
    pause
    goto INPUT_CONFIG
)

echo.
set /p SAVE_CONFIG=설정을 저장하시겠습니까? (Y/N) ^> 

if /I "%SAVE_CONFIG%"=="Y" goto SAVE_CONFIG
if /I "%SAVE_CONFIG%"=="N" goto VALIDATE

echo.
echo [ERROR] Y 또는 N을 입력해주세요.
pause
goto INPUT_CONFIG


:SAVE_CONFIG
echo.
echo 설정을 저장합니다...

(
    echo @echo off
    echo rem ============================================================
    echo rem OZ Scheduler Local Configuration
    echo rem 개인 개발환경 설정파일
    echo rem ============================================================
    echo set "JAVA_HOME=%JAVA_HOME%"
    echo set "SCH_HOME=%SCH_HOME%"
) > "%CONFIG_FILE%"

if exist "%CONFIG_FILE%" (
    echo.
    echo [SUCCESS] 설정이 저장되었습니다.
    echo.
    echo 설정파일:
    echo %CONFIG_FILE%
) else (
    echo.
    echo [ERROR] 설정파일 저장에 실패했습니다.
)

echo.
pause


:VALIDATE
cls
echo ==========================================
echo        OZ Scheduler 환경 확인
echo ==========================================
echo.
echo JAVA_HOME = %JAVA_HOME%
echo SCH_HOME  = %SCH_HOME%
echo.

rem ------------------------------------------------------------
rem Java Validation
rem ------------------------------------------------------------
if not exist "%JAVA_HOME%\bin\java.exe" (
    echo [ERROR] java.exe를 찾을 수 없습니다.
    echo.
    echo JAVA_HOME:
    echo %JAVA_HOME%
    echo.
    pause
    goto INPUT_CONFIG
)

rem ------------------------------------------------------------
rem Scheduler Home Validation
rem ------------------------------------------------------------
if not exist "%SCH_HOME%" (
    echo [ERROR] OZ Scheduler Home을 찾을 수 없습니다.
    echo.
    echo SCH_HOME:
    echo %SCH_HOME%
    echo.
    pause
    goto INPUT_CONFIG
)

rem ------------------------------------------------------------
rem Scheduler BAT Validation
rem ------------------------------------------------------------
if not exist "%SCH_HOME%\scheduler.bat" (
    echo [ERROR] scheduler.bat 파일을 찾을 수 없습니다.
    echo.
    echo 예상 경로:
    echo %SCH_HOME%\scheduler.bat
    echo.
    echo SCH_HOME 경로를 다시 확인해주세요.
    echo.
    pause
    goto INPUT_CONFIG
)

echo [OK] Java 확인 완료
echo [OK] Scheduler Home 확인 완료
echo [OK] scheduler.bat 확인 완료
echo.

rem ------------------------------------------------------------
rem PATH 설정
rem ------------------------------------------------------------
set "PATH=%JAVA_HOME%\bin;%PATH%"

echo Java Version:
echo ------------------------------------------
"%JAVA_HOME%\bin\java.exe" -version
echo ------------------------------------------
echo.

set /p RUN_SCHEDULER=OZ Scheduler를 실행하시겠습니까? (Y/N) ^> 

if /I "%RUN_SCHEDULER%"=="Y" goto RUN
if /I "%RUN_SCHEDULER%"=="N" goto END

echo.
echo [ERROR] Y 또는 N을 입력해주세요.
pause
goto VALIDATE


:RUN
cls
echo ==========================================
echo        OZ Scheduler Starting...
echo ==========================================
echo.
echo JAVA_HOME = %JAVA_HOME%
echo SCH_HOME  = %SCH_HOME%
echo.

cd /d "%SCH_HOME%"

echo OZ Scheduler를 실행합니다.
echo.

call scheduler.bat

echo.
echo ==========================================
echo Scheduler 실행 명령이 종료되었습니다.
echo ==========================================
echo.

pause
goto END


:END
endlocal
exit /b 0