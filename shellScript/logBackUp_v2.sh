#!/bin/sh

# ==========================================
# 1. 환경 설정 (전역 변수)
# ==========================================
BACKUP_BASE="/centec/jobmind/bhs_test/backup" # 백업 최상위 디렉터리
DATE=$(date +%Y%m%d)                          # 오늘 날짜 (YYYYMMDD)

TARGET_DIRS="
/centec/jobmind/bhs_test/log_test
/centec/jobmind/bhs_test/log_test2
"

# ==========================================
# 2. 백업 기능 함수
# ==========================================
backup() {
	bo_src_dir="$1"

	[ ! -d "$bo_src_dir" ] && return

	bo_dir_name=$(basename "$bo_src_dir")

	bo_backup_dir="${BACKUP_BASE}/${bo_dir_name}"
	mkdir -p "$bo_backup_dir"

	bo_archive="${bo_backup_dir}/${bo_dir_name}_${DATE}.tar.gz"

	if [ -n "$(find "$bo_src_dir" -type f -ctime +3 -print -quit 2>/dev/null)" ]; then
		find "$bo_src_dir" -type f -ctime +3 2>/dev/null | tar -czf "$bo_archive" -T - 2>/dev/null

		# 압축 정상 완료 검증
		if [ $? -eq 0 ] && [ -f "$bo_archive" ]; then
			echo "[SUCCESS] ${bo_dir_name} -> 3일 지난 파일 백업 완료 (원본 유지)"
		else
			echo "[ERROR] ${bo_dir_name} -> 백업 압축 실패"
			rm -f "$bo_archive" 2>/dev/null
		fi
	else
		echo "[INFO] ${bo_dir_name} -> 3일 지난 백업 대상 파일이 없습니다."
	fi
}

# ==========================================
# 3. 메인 루프 실행
# ==========================================
for dir in $TARGET_DIRS; do
	backup "$dir"
done
