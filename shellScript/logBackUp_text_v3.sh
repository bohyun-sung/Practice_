#!/bin/sh

# ==========================================
# 1. 환경 설정 (전역 변수)
# ==========================================
BACKUP_BASE="/centec/jobmind/bhs_test/backup" # 백업 최상위 디렉터리
DATE=$(date +%Y%m%d)                          # 오늘 날짜 (20260618)

# 3일 전 기준 날짜 계산 (오늘이 18일이면 15일 이하인 파일이 대상)
# POSIX sh 호환을 위해 익일/전일 계산은 쉘 내부 연산 처리
PURGE_TARGET_DATE=$(date +%Y%m%d -d "3 days ago" 2>/dev/null)
if [ -z "$PURGE_TARGET_DATE" ]; then
	# -d 옵션이 안 먹는 일부 UNIX 환경 방어 코드 (20260618 -> 20260615)
	PURGE_TARGET_DATE=$(expr "$DATE" - 3)
fi

TARGET_DIRS="
/centec/jobmind/bhs_test/log_test
/centec/jobmind/bhs_test/log_test2
"

# ==========================================
# 2. 백업 기능 함수 (파일명 날짜 매칭 방식)
# ==========================================
backup() {
	bo_src_dir="$1"

	[ ! -d "$bo_src_dir" ] && return
	bo_dir_name=$(basename "$bo_src_dir")

	bo_backup_dir="${BACKUP_BASE}/${bo_dir_name}"
	mkdir -p "$bo_backup_dir"

	bo_archive="${bo_backup_dir}/${bo_dir_name}_${DATE}.tar.gz"

	# 백업 대상 파일 목록을 임시 저장할 변수 초기화
	bo_file_list=""

	# 디렉터리 내의 모든 .log 파일을 하나씩 체크
	for file_path in "${bo_src_dir}"/*.log; do
		# 파일이 실제로 존재하지 않으면 스킵 (와일드카드 처리용)
		[ ! -f "$file_path" ] && continue

		# 파일명 추출 (예: test_2026-06-13.log -> test_2026-06-13.log)
		base_file=$(basename "$file_path")

		# 파일명에서 하이픈(-)을 제거하고 숫자 8자리 연속된 부분만 추출
		# test_2026-06-13.log -> test_20260613.log -> 20260613
		file_date=$(echo "$base_file" | tr -d '-' | tr -cd '0-9' | cut -c 1-8)

		# 추출한 날짜가 유효한 8자리 숫자이고, 3일 전 기준 날짜보다 작거나 같으면 백업 대상에 추가
		if [ -n "$file_date" ] && [ "$file_date" -le "$PURGE_TARGET_DATE" ]; then
			bo_file_list="${bo_file_list}${file_path}
"
		fi
	done

	# 백업 대상 파일이 존재할 때만 압축 진행
	if [ -n "$bo_file_list" ]; then
		# 파일 목록을 tar에 전달하여 압축 생성
		echo "$bo_file_list" | tar -czf "$bo_archive" -T - 2>/dev/null

		if [ $? -eq 0 ] && [ -f "$bo_archive" ]; then
			echo "[SUCCESS] ${bo_dir_name} -> 파일명 기준 3일 전 파일 백업 완료 (원본 유지)"
		else
			echo "[ERROR] ${bo_dir_name} -> 백업 압축 실패"
			rm -f "$bo_archive" 2>/dev/null
		fi
	else
		echo "[INFO] ${bo_dir_name} -> 파일명 기준 3일 전 백업 대상 파일이 없습니다. (기준일: ${PURGE_TARGET_DATE} 이하)"
	fi
}

# ==========================================
# 3. 메인 루프 실행
# ==========================================
for dir in $TARGET_DIRS; do
	backup "$dir"
done
