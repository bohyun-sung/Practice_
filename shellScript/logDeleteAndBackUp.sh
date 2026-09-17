#!/bin/sh

# ==========================================
# 1. 환경 설정 (전역 변수)
# ==========================================
BACKUP_BASE="/hli_app/backup" # 백업 최상위 디렉터리
DATE=$(date +%Y%m%d)          # 오늘 날짜 (YYYYMMDD)

TARGET_DIRS="
/hli_app/log/was/jobmind/jobmind_logs
/hli_app/sw/was/jobmind/jobmind_server/sysout
/hli_app/log/was/jobmind/jobmind_agent
"

backup_and_purge() {
	local src_dir="$1"

	[ ! -d "$src_dir" ] && return

	local dir_name=$(basename "$src_dir")

	local backup_dir="${BACKUP_BASE}/${dir_name}"
	mkdir -p "$backup_dir"

	local archive="${backup_dir}/${dir_name}_${DATE}.tar.gz"

	find "$src_dir" -type f -ctime +3 2>/dev/null | tar -czf "$archive" -T - 2>/dev/null

	if [ $? -eq 0 ] && [ -f "$archive" ]; then
		find "$src_dir" -type f -ctime +3 -exec rm -f {} \;
		echo "[SUCCESS] ${dir_name} -> 3일 지난 파일 백업 및 원본 삭제 완료"
	else
		rm -f "$archive" 2>/dev/null
	fi
}

for dir in $TARGET_DIRS; do
	backup_and_purge "$dir"
done
