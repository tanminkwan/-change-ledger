`#[frb]` 어트리뷰트를 사용하여 Flutter와 Rust를 통합하는 방법을 처음부터 단계별로 알려드리겠습니다.

---

### 1. 프로젝트 준비

#### 1.1. Rust 라이브러리 생성
터미널에서 Rust 라이브러리를 생성합니다:
```bash
cargo new my_rust_lib --lib
cd my_rust_lib
```

#### 1.2. `flutter_rust_bridge` 설치
Rust 프로젝트에서 `flutter_rust_bridge`를 사용하기 위해 `Cargo.toml`에 다음을 추가합니다:
```toml
[dependencies]
flutter_rust_bridge = "1.75"
rsa = "0.8"
rand = "0.8"
aes-gcm = "0.10"
serde = { version = "1.0", features = ["derive"] }
serde_json = "1.0"
uuid = { version = "1.2", features = ["v4"] }
sha2 = "0.10"
base64 = "0.21"
chrono = "0.4"

[build-dependencies]
flutter_rust_bridge_codegen = "1.75"
```

---

### 2. Rust 코드 작성

`src/lib.rs`에 Flutter에서 호출할 함수와 로직을 작성합니다.

#### 2.1. RSA 함수 작성
주어진 RSA 코드를 `src/lib.rs`에 작성하고, `#[frb]` 어트리뷰트를 사용합니다:
```rust
use rsa::{RsaPrivateKey, RsaPublicKey};
use rand::rngs::OsRng;
use flutter_rust_bridge::StreamSink;

#[frb]
pub fn generate_keys() -> Result<(String, String), String> {
    let mut rng = OsRng;
    let private_key = RsaPrivateKey::new(&mut rng, 2048)
        .map_err(|e| e.to_string())?;
    let public_key = RsaPublicKey::from(&private_key);

    let private_pem = private_key.to_pkcs8_pem()
        .map_err(|e| e.to_string())?;
    let public_pem = public_key.to_pem()
        .map_err(|e| e.to_string())?;

    Ok((private_pem, public_pem))
}
```

#### 2.2. AES 암호화 함수 작성
추가로 AES 관련 함수도 작성합니다:
```rust
use aes_gcm::{Aes256Gcm, KeyInit, Nonce};
use aes_gcm::aead::{Aead, NewAead};

#[frb]
pub fn encrypt_aes_gcm(plain_text: String, key: Vec<u8>) -> Result<(Vec<u8>, Vec<u8>), String> {
    let cipher = Aes256Gcm::new_from_slice(&key)
        .map_err(|e| e.to_string())?;

    let mut nonce = vec![0u8; 12];
    rand::thread_rng().fill_bytes(&mut nonce);

    let encrypted_data = cipher.encrypt(Nonce::from_slice(&nonce), plain_text.as_bytes())
        .map_err(|e| e.to_string())?;

    Ok((encrypted_data, nonce))
}
```

---

### 3. 브릿지 코드 생성

#### 3.1. Flutter Rust Bridge 코드 생성
`flutter_rust_bridge_codegen`을 설치합니다:
```bash
cargo install flutter_rust_bridge_codegen
```

`flutter_rust_bridge_codegen`을 실행하여 Dart 브릿지 코드를 생성합니다:
```bash
flutter_rust_bridge_codegen \
    -r src/lib.rs \
    -d ../flutter_project/lib/bridge_generated.dart \
    -c ios/Classes/bridge_generated.h
```

- `-r`: Rust 코드의 경로 (여기서는 `src/lib.rs`).
- `-d`: 생성된 Dart 브릿지 코드의 경로.
- `-c`: 생성된 헤더 파일의 경로 (iOS에서 사용).

---

### 4. Flutter 프로젝트 설정

#### 4.1. Flutter 프로젝트 생성
Flutter 프로젝트를 생성하거나 기존 프로젝트를 사용합니다:
```bash
flutter create flutter_project
cd flutter_project
```

#### 4.2. `flutter_rust_bridge` 플러그인 추가
`pubspec.yaml`에 다음을 추가합니다:
```yaml
dependencies:
  flutter_rust_bridge: ^1.75.0
  ffi: ^2.0.1
```

#### 4.3. Rust 라이브러리 연결
Rust 라이브러리를 Android와 iOS에서 빌드하도록 설정합니다.

- **Android**: `android/app/build.gradle` 수정
  ```gradle
  externalNativeBuild {
      cmake {
          path "CMakeLists.txt"
      }
  }
  ```

- **iOS**: `ios/Classes/` 디렉토리에 생성된 헤더 파일 (`bridge_generated.h`)을 추가합니다.

---

### 5. Flutter에서 Rust 함수 호출

`lib/main.dart`에 Rust 브릿지 함수를 호출하는 Flutter 코드를 작성합니다:

```dart
import 'dart:ffi';
import 'package:flutter/material.dart';
import 'bridge_generated.dart';

final rustApi = RustImpl(
  loadLibForBindings(), // Rust 라이브러리를 로드
);

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: Text("Flutter-Rust Bridge Example")),
        body: Center(
          child: ElevatedButton(
            onPressed: () async {
              try {
                final keys = await rustApi.generateKeys();
                print("Private Key: ${keys.first}");
                print("Public Key: ${keys.second}");
              } catch (e) {
                print("Error: $e");
              }
            },
            child: Text("Generate RSA Keys"),
          ),
        ),
      ),
    );
  }
}
```

---

### 6. 빌드 및 실행

1. **Rust 라이브러리 빌드**:
   - iOS:
     ```bash
     cargo lipo --release
     ```
   - Android:
     ```bash
     cargo ndk --target aarch64-linux-android build
     ```

2. **Flutter 실행**:
   ```bash
   flutter run
   ```

---

### 결과
이제 Flutter에서 Rust로 작성된 `generate_keys` 및 `encrypt_aes_gcm`와 같은 함수를 호출할 수 있습니다. 필요에 따라 추가적인 Rust 함수에 `#[frb]`를 붙여 통합하세요!