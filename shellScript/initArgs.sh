#!/bin/bash

COLOR_INFO="\033[0;32m"
COLOR_WARN="\033[0;33m"

log_info() { printf "%b[INFO]  [%s]%b %s\n" "$COLOR_INFO" "$(date '+%Y-%m-%d %H:%M:%S')" "$COLOR_RESET" "$*"; }
log_warn() { printf "%b[WARN]  [%s]%b %s\n" "$COLOR_WARN" "$(date '+%Y-%m-%d %H:%M:%S')" "$COLOR_RESET" "$*"; }

process_arguments() {
	local index=1

	if [[ $# -eq 0 ]]; then
		log_warn "전달된 매개변수가 없습니다."
		return 0
	fi

	log_info "총 $# 개의 매개변수 처리를 시작합니다."
	echo "--------------------------------------------------"

	for arg in "$@"; do
		local processed_val="$arg"

		# '%%' 로 시작하는 경우 빈값으로 변환
		if [[ "$arg" == %*% ]]; then
			# % 로 시작하는 모든 항목 패턴 검사 (% 두 개 포함)
			if [[ "$arg" =~ ^%%.* ]]; then
				processed_val=""
			fi
		fi

		# 결과 출력 (빈값일 경우 시각적 표기 처리)
		if [[ -z "$processed_val" ]]; then
			printf "  - Argument #%-2d: (Original: '%s') -> [EMPTY STRING]\n" "$index" "$arg"
		else
			printf "  - Argument #%-2d: '%s'\n" "$index" "$processed_val"
		fi

		((index++))
	done

	echo "--------------------------------------------------"
	log_info "모든 매개변수 처리가 성공적으로 완료되었습니다."
}

main() {
	process_arguments "$@"
}

main "$@"
