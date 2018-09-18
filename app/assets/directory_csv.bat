@ECHO OFF

:: https://ss64.com/nt/color.html

:start
SET /P DIRECTORY=Enter full path to directory (eg. C:\Users\julie.allinson\Desktop): 

IF EXIST "%DIRECTORY%" (
	goto :agree 
) ELSE (
  echo "%DIRECTORY% doesn't exist"
  goto :start
)

:agree
CHOICE /M "Create CSV of %DIRECTORY%"

IF %ERRORLEVEL% EQU 1 (
 goto :checksum
) ELSE (
  goto :end
)

:checksum
ECHO NOTE ABOUT CHECKSUMS
ECHO   Checksums require CertUtil be installed - modern versions (Windows 7 and up) should have it
ECHO   You can check it's installed in a cmd prompt with CertUtil -?.
ECHO   Checksums are optional and can take a long time to run on large or many files.
CHOICE /M "Create Checksums"

IF %ERRORLEVEL% EQU 1 (
SET CHK=yes & goto :loop
) ELSE (
SET CHK=no & goto :loop
)

:loop
PUSHD "%DIRECTORY%"
type NUL > "%DIRECTORY%/FILES.csv"
ECHO path,filename,file_size,checksum >> "%DIRECTORY%/FILES.csv"
FOR /R %%G IN (*) DO CALL :sub "%%G" >> "%DIRECTORY%/FILES.csv"
ECHO File written to "%DIRECTORY%\FILES.csv"
goto :end

:sub

CALL :strlen result %1

SET _full_path=%1
SET _remove_path=%DIRECTORY%\

IF NOT %1=="%DIRECTORY%\FILES.csv" (

	ECHO |set /p="%%_full_path:%_remove_path%=%%"
	ECHO |set /p=,"%~nx1"
	
	IF %result% LEQ 260  (ECHO |set /p=,%~z1)
	IF %result% GTR 260 (ECHO |set /p=,path_too_long)

	IF %CHK%==no ( 
		ECHO ,not_created 
	) ELSE (
		IF %result% LEQ 260 (
			CALL :make_md5 %1
		) ELSE (
			ECHO ,path_too_long
		)
	)
)
goto :eof

:make_md5
setlocal enabledelayedexpansion
SET "md5="
FOR /f "skip=1 tokens=* delims=" %%# in ('certutil -hashfile "%~f1" MD5') do (
	IF NOT DEFINED md5 (
		for %%Z in (%%#) do set "md5=!md5!%%Z"
	)
)
echo ,%md5%
endlocal
goto :eof

:strlen <resultVar> <stringVar>
(   
    setlocal EnableDelayedExpansion
    set "s=!%~2!#"
    set "len=0"
    for %%P in (4096 2048 1024 512 256 128 64 32 16 8 4 2 1) do (
        if "!s:~%%P,1!" NEQ "" ( 
            set /a "len+=%%P"
            set "s=!s:~%%P!"
        )
    )
)
( 
    endlocal
    set "%~1=%len%"
    exit /b
)

:end
CHOICE /M "Create another (Y) or exit (N)"
IF %ERRORLEVEL% EQU 1 (
 goto :start
) 
ELSE (
  exit
)

:eof




