# -change-ledger

### 1. Rustup 설치 파일 다운로드 및 실행

1. **PowerShell**을 열고 아래 명령어를 입력해 `rustup-init.exe` 파일을 다운로드합니다:

   ```powershell
   Invoke-WebRequest -Uri https://win.rustup.rs -OutFile rustup-init.exe
   ```

2. 다운로드한 **rustup-init.exe** 파일을 실행하여 설치를 시작합니다:

   ```powershell
   .\rustup-init.exe
   ```

3. 설치 중간에 **기본 설치 옵션**을 선택하면 Rust와 Cargo가 함께 설치됩니다.

### 2. 환경 변수 적용

설치가 완료되면 PowerShell을 닫았다가 다시 열어 **환경 변수를 새로 적용**한 후 아래 명령어로 설치가 잘 되었는지 확인합니다:

   ```powershell
   rustc --version
   cargo --version
   ```

이렇게 하면 Windows에서 Rust가 정상적으로 설치된 것입니다!
