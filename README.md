# PostgreSQL Conf Editor (Bash 기반 자동화 스크립트)

🛠️ PostgreSQL의 `postgresql.conf` 설정을 사용자 입력 기반으로 자동 수정하는 CLI 도구입니다.  
운영 환경에서도 수동 편집 없이, 주요 항목을 안전하게 관리할 수 있도록 설계되었습니다.

---

## 🧱 디렉토리 구조

```bash
postgresql-conf-editor/
├── PostgreSQL_conf_Editor.sh     # 핵심 스크립트
├── postgresql.conf.sample    # 테스트용 샘플 설정파일
└── READE.me                  # 설명서
```

## ✨ 주요 기능

- 주요 설정 항목(26개) 자동 수정
- 기존 설정값 확인 및 설명 출력
- 설정이 존재하지 않을 경우 자동 추가
- `postgresql.conf.bak` 백업 파일 자동 생성
- `diff` 결과 출력으로 변경사항 확인 가능

---

## ⚙️ 사용 방법

1. 수정 대상 `postgresql.conf` 파일이 있는 디렉토리로 이동
2. 스크립트 실행

```bash
chmod +x PoostgreSQL_conf_Editor.sh
./PoostgreSQL_conf_Editor.sh
```

---

### 🛠️ 수정 가능한 항목
```
1. listen_addresses =  
2. max_connections = 
3. shared_buffers = 
4. work_mem = 
5. maintenance_work_mem = 
6. checkpoint_timeout = 
7. max_wal_size = 
8. checkpoint_completion_target = 
9. effective_cache_size = 
10. autovacuum = 
11. autovacuum_max_workers = 
12. log_filename = 
13. default_statistics_target = 
14. jit = 
15. log_checkpoints = 
16. log_line_prefix = 
17. log_lock_waits = 
18. log_statement = 
19. track_functions = 
20. track_activity_query_size = 
21. log_autovacuum_min_duration = 
22. log_destination = 
23. logging_collector = 
24. pg_stat_statements.max = 
25. pg_stat_statements.track = 
26. password_encryption =
```
