#!/bin/bash

# 중복 로드 방지 Guard
if [[ -n "${_LOGGER_SH_LOADED:-}" ]]; then
	return 0
fi
readonly _LOGGER_SH_LOADED=true

# ANSI 컬러 코드 정의
readonly COLOR_RESET="\033[0m"
readonly COLOR_INFO="\033[0;32m"
readonly COLOR_WARN="\033[0;33m"
readonly COLOR_ERROR="\033[0;31m"

# 표준 로깅 함수 정의
log_info() { printf "%b[INFO]  [%s]%b %s\n" "$COLOR_INFO" "$(date '+%Y-%m-%d %H:%M:%S')" "$COLOR_RESET" "$*"; }
log_warn() { printf "%b[WARN]  [%s]%b %s\n" "$COLOR_WARN" "$(date '+%Y-%m-%d %H:%M:%S')" "$COLOR_RESET" "$*"; }
log_error() { printf "%b[ERROR] [%s]%b %s\n" "$COLOR_ERROR" "$(date '+%Y-%m-%d %H:%M:%S')" "$COLOR_RESET" "$*" >&2; }
