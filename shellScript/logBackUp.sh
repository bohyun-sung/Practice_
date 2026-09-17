#!/bin/sh

# ==========================================
# 1. 환경 설정 (전역 변수)
# ==========================================
BACKUP_BASE="/hli_app/backup"                # 백업 최상위 디렉터리
DATE=$(date +%Y%m%d)                         # 오늘 날짜 (YYYYMMDD)

TARGET_DIRS="
/hli_app/log/was/jobmind/jobmind_logs
/hli_app/sw/was/jobmind/jobmind_server/sysout
/hli_app/log/was/jobmind/jobmind_agent
"

# ==========================================
# 2. 백업 기능 함수 (POSIX sh 규격 준수)
# ==========================================
backup() {
    # SC3043 방지: POSIX sh 호환을 위해 변수명에 접두사를 붙여 전역 충돌 방지
    bo_src_dir="$1"
 
    # 대상 디렉터리가 존재하지 않으면 스킵
    [ ! -d "$bo_src_dir" ] && return
    
    # 디렉터리 명 추출
    bo_dir_name=$(basename "$bo_src_dir")
    
    # 백업 경로 생성 및 디렉터리 준비
    bo_backup_dir="${BACKUP_BASE}/${bo_dir_name}"
    mkdir -p "$bo_backup_dir"
    
    # 백업 파일명 정의
    bo_archive="${bo_backup_dir}/${bo_dir_name}_${DATE}.tar.gz"

    # SC2155 방지: 타겟 파일 목록 추출과 tar 실행 분리 유도 및 에러 마스킹 방지
    # 3일 지난 파일이 존재할 때만 tar 압축 실행
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