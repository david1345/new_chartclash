# 롤백 방법

## 백업 위치
- 백업 디렉토리: `src_backup_YYYYMMDD_HHMMSS/`
- 백업 시간: 자동으로 폴더명에 포함됨

## 롤백 명령어

### 전체 롤백
```bash
cd ~/.gemini/antigravity/scratch/vibe-forecast
rm -rf src
cp -r src_backup_YYYYMMDD_HHMMSS src
npm run dev
```

### 특정 파일만 롤백
```bash
cd ~/.gemini/antigravity/scratch/vibe-forecast
cp src_backup_YYYYMMDD_HHMMSS/app/page.tsx src/app/page.tsx
```

## 백업 파일 목록 확인
```bash
ls -la src_backup_*/
```

## 변경 사항 비교
```bash
diff -r src_backup_YYYYMMDD_HHMMSS/app/page.tsx src/app/page.tsx
```
