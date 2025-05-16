####3번 라인####
#!/bin/bash

CONF_PATH="./postgresql.conf"
BACKUP_PATH="./postgresql.conf.bak"
LOG_PATH="./postgresql_conf_changes.log"

GREEN="\e[32m"
YELLOW="\e[33m"
RESET="\e[0m"

if [ ! -f "$CONF_PATH" ]; then
    echo "Error: $CONF_PATH 파일이 존재하지 않습니다."
    exit 1
fi

cp "$CONF_PATH" "$BACKUP_PATH"
echo -e "[+] 기존 설정 백업: ${GREEN}$BACKUP_PATH${RESET}"
echo -e "[+] 설정 변경 로그 파일: ${GREEN}$LOG_PATH${RESET}" > "$LOG_PATH"

total_mem_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
total_mem_gb=$((total_mem_kb / 1024 / 1024))

declare -A PARAM_DESCRIPTIONS
PARAM_DESCRIPTIONS["listen_addresses"]="PostgreSQL이 어떤 IP에서 연결을 받을지 지정 (* = 전체 허용)"
PARAM_DESCRIPTIONS["max_connections"]="최대 동시 접속 수 (메모리 기준 64GB: 1000, 32GB: 400, 16GB: 300)"
PARAM_DESCRIPTIONS["shared_buffers"]="PostgreSQL 메모리 캐시, 시스템 메모리의 1/4 권장"
PARAM_DESCRIPTIONS["work_mem"]="정렬/해시 작업 시 세션당 메모리"
PARAM_DESCRIPTIONS["maintenance_work_mem"]="유지보수 작업용 메모리 (VACUUM, INDEX 등)"
PARAM_DESCRIPTIONS["checkpoint_timeout"]="체크포인트 주기 (기본 10min)"
PARAM_DESCRIPTIONS["max_wal_size"]="WAL 파일 최대 크기 (권장 20G 이상)"
PARAM_DESCRIPTIONS["checkpoint_completion_target"]="체크포인트 분산 실행 비율 (기본 0.9)"
PARAM_DESCRIPTIONS["effective_cache_size"]="디스크 캐시 추정값, 시스템 메모리의 3/4 권장"
PARAM_DESCRIPTIONS["autovacuum"]="자동 vacuum 활성화 여부"
PARAM_DESCRIPTIONS["autovacuum_max_workers"]="동시 autovacuum 워커 수 (기본 6)"
PARAM_DESCRIPTIONS["log_filename"]="로그 파일 이름 형식 (예: postgresql-%Y-%m-%d.log)"
PARAM_DESCRIPTIONS["default_statistics_target"]="통계 수집 정도 (기본 300, 범위 1-10000)"
PARAM_DESCRIPTIONS["jit"]="JIT 컴파일 사용 여부 (기본 off)"
PARAM_DESCRIPTIONS["log_checkpoints"]="체크포인트 발생 시 로그 기록"
PARAM_DESCRIPTIONS["log_line_prefix"]="로그 라인 포맷 (예: [%t [PG-%e] %u %r %d (%p)])"
PARAM_DESCRIPTIONS["log_lock_waits"]="Deadlock 대기 시 로그 출력"
PARAM_DESCRIPTIONS["log_statement"]="로그 남길 SQL 유형 ('ddl', 'all' 등)"
PARAM_DESCRIPTIONS["track_functions"]="함수 호출 추적 여부 (기본 all)"
PARAM_DESCRIPTIONS["track_activity_query_size"]="activity view에서 보이는 쿼리 길이 (기본 65000)"
PARAM_DESCRIPTIONS["log_autovacuum_min_duration"]="autovacuum 로그 남기기 위한 최소 시간 (0 = 모두)"
PARAM_DESCRIPTIONS["log_destination"]="로그 출력 위치 ('stderr', 주석 해제 필요)"
PARAM_DESCRIPTIONS["logging_collector"]="로그 수집 여부 (기본 on)"
PARAM_DESCRIPTIONS["pg_stat_statements.max"]="pg_stat_statements의 최대 추적 SQL 수 (예: 10000)"
PARAM_DESCRIPTIONS["pg_stat_statements.track"]="pg_stat_statements 추적 대상 ('all' 등)"
PARAM_DESCRIPTIONS["password_encryption"]="사용자 비밀번호 암호화 방식 ('scram-sha-256', 'md5')"

declare -A PARAM_EXAMPLES
PARAM_EXAMPLES["listen_addresses"]="'*'"
PARAM_EXAMPLES["max_connections"]="1000 (64GB), 400 (32GB)"
PARAM_EXAMPLES["shared_buffers"]="16GB (전체 메모리의 1/4)"
PARAM_EXAMPLES["work_mem"]="13MB (64GB 기준)"
PARAM_EXAMPLES["maintenance_work_mem"]="2GB"
PARAM_EXAMPLES["checkpoint_timeout"]="10min"
PARAM_EXAMPLES["max_wal_size"]="20GB"
PARAM_EXAMPLES["checkpoint_completion_target"]="0.9"
PARAM_EXAMPLES["effective_cache_size"]="48GB (64GB 기준)"
PARAM_EXAMPLES["autovacuum"]="on"
PARAM_EXAMPLES["autovacuum_max_workers"]="6"
PARAM_EXAMPLES["log_filename"]="'postgresql-%Y-%m-%d.log'"
PARAM_EXAMPLES["default_statistics_target"]="300"
PARAM_EXAMPLES["jit"]="off"
PARAM_EXAMPLES["log_checkpoints"]="on"
PARAM_EXAMPLES["log_line_prefix"]="'[%t [PG-%e] %u %r %d (%p)]'"
PARAM_EXAMPLES["log_lock_waits"]="on"
PARAM_EXAMPLES["log_statement"]="'ddl'"
PARAM_EXAMPLES["track_functions"]="all"
PARAM_EXAMPLES["track_activity_query_size"]="65000"
PARAM_EXAMPLES["log_autovacuum_min_duration"]="0"
PARAM_EXAMPLES["log_destination"]="'stderr'"
PARAM_EXAMPLES["logging_collector"]="on"
PARAM_EXAMPLES["pg_stat_statements.max"]="10000"
PARAM_EXAMPLES["pg_stat_statements.track"]="all"
PARAM_EXAMPLES["password_encryption"]="'scram-sha-256'"

MODE=""
echo -e "\n${GREEN}PostgreSQL 설정 관리 도구${RESET}"
echo "[1] 최초 설정 (전체 항목 순회)"
echo "[2] 특정 항목 수정"
read -p "모드를 선택하세요 [1/2]: " MODE

declare -a PARAMS=(
  listen_addresses max_connections shared_buffers work_mem maintenance_work_mem
  checkpoint_timeout max_wal_size checkpoint_completion_target effective_cache_size
  autovacuum autovacuum_max_workers log_filename default_statistics_target jit
  log_checkpoints log_line_prefix log_lock_waits log_statement track_functions
  track_activity_query_size log_autovacuum_min_duration log_destination logging_collector
  pg_stat_statements.max pg_stat_statements.track password_encryption
)

if [[ "$MODE" == "1" ]]; then
    i=0
  while [ $i -lt ${#PARAMS[@]} ]; do
    param="${PARAMS[$i]}"
    echo -e "\n=================================================="
    echo -e "${GREEN}🔧 설정 항목: $param${RESET}"
        if [ "$param" == "max_connections" ]; then
  total_mem=$(free -h | awk '/^Mem:/ {print $2}')
  echo -e "설명: ${PARAM_DESCRIPTIONS[$param]}"
  echo -e "    현재 시스템 메모리: Total=$total_mem"
else
  echo -e "설명: ${PARAM_DESCRIPTIONS[$param]}"
fi

    current=$(grep -E "^#?\s*$param\s*=" "$CONF_PATH" | head -n 1)
    if [ -z "$current" ]; then
      echo -e "현재 설정: (설정 없음)"
    else
      echo -e "현재 설정: ${current}"
    fi

    echo -e "예시 입력값: ${PARAM_EXAMPLES[$param]}"
    read -p "새로운 값 입력 (Enter 시 건너뜀): " new_value

    if [ -z "$new_value" ]; then
      read -p "입력이 비어있습니다. 정말 건너뛰시겠습니까? (y/N): " confirm
      if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        read -p "다시 입력: " new_value
      fi
    fi

    if [ -z "$new_value" ]; then
      echo -e "${YELLOW}[-] $param 항목 건너뜀${RESET}"
      echo "[SKIP] $param 항목: 변경 없음" >> "$LOG_PATH"
      ((i++))
      continue
    fi

    read -p "설정을 '${new_value}' 로 적용합니다. 계속하시겠습니까? (Y/n/b = 이전): " confirm
    if [[ "$confirm" =~ ^[Bb]$ ]]; then
      echo "[⏪] 이전 항목으로 돌아갑니다."
      if [ $i -gt 0 ]; then ((i--)); fi
      continue
    elif [[ "$confirm" =~ ^[Nn]$ ]]; then
      echo "[⏭️] 설정 건너뜀."
      ((i++))
      continue
    fi

    if grep -qE "^#?\s*$param\s*=" "$CONF_PATH"; then
      sed -i -E "s|^#?\s*($param\s*=).*|\1 $new_value|" "$CONF_PATH"
      echo -e "[=] $param 항목 수정 완료."
      echo "[MODIFIED] $param = $new_value" >> "$LOG_PATH"
    else
      echo "$param = $new_value" >> "$CONF_PATH"
      echo -e "[+] $param 항목 추가 완료."
      echo "[ADDED] $param = $new_value" >> "$LOG_PATH"
    fi
    ((i++))
  done

elif [[ "$MODE" == "2" ]]; then
  echo -e "\n${GREEN}수정 가능한 항목 목록:${RESET}"
  for i in "${!PARAMS[@]}"; do
    idx=$((i+1))
    echo "[$idx] ${PARAMS[$i]}"
  done

  read -p "수정할 항목 번호를 입력하세요 (예: 3): " sel
  selected_param="${PARAMS[$((sel-1))]}"

  echo -e "\n${GREEN}🔧 선택된 항목: $selected_param${RESET}"
  echo -e "설명: ${PARAM_DESCRIPTIONS[$selected_param]}"

  current=$(grep -E "^#?\s*$selected_param\s*=" "$CONF_PATH" | head -n 1)
  if [ -z "$current" ]; then
    echo -e "현재 설정: (설정 없음)"
  else
    echo -e "현재 설정: ${current}"
  fi

  echo -e "예시 입력값: ${PARAM_EXAMPLES[$selected_param]}"
  read -p "새로운 값 입력: " new_value

  echo -e "설정을 '${YELLOW}$new_value${RESET}' 로 변경합니다. 이전 값으로 되돌리시겠습니까? (y/N): "
  read -p "확인 후 계속하려면 Enter, 취소하려면 'y': " undo
  if [[ "$undo" =~ ^[Yy]$ ]]; then
    echo "[⏪] 변경 취소됨. 원래 설정 유지."
    echo "[CANCELLED] $selected_param 항목 변경 취소됨" >> "$LOG_PATH"
    exit 0
  fi

  if grep -qE "^#?\s*$selected_param\s*=" "$CONF_PATH"; then
    sed -i -E "s|^#?\s*($selected_param\s*=).*|\1 $new_value|" "$CONF_PATH"
    echo -e "[=] $selected_param 항목 수정 완료."
    echo "[MODIFIED] $selected_param = $new_value" >> "$LOG_PATH"
  else
    echo "$selected_param = $new_value" >> "$CONF_PATH"
    echo -e "[+] $selected_param 항목 추가 완료."
    echo "[ADDED] $selected_param = $new_value" >> "$LOG_PATH"
  fi

else
  echo "잘못된 입력입니다. 스크립트를 종료합니다."
  exit 1
fi

echo -e "\n${GREEN}[✔] 설정 변경 완료. 변경 내용 비교:${RESET}"
diff "$BACKUP_PATH" "$CONF_PATH" || echo "변경 없음."
echo -e "\n변경 로그 파일: $LOG_PATH"
