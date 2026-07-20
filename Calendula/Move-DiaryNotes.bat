@echo off
title Move Diary Notes — Calendula
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Move-DiaryNotes.ps1" -Year 2026
echo.
echo === DONE ===
pause
