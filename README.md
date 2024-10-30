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

---

Visual Studio Code(VS Code)에서 Rust를 실행하려면 Rust의 개발 도구를 설정하고 확장 기능을 설치해야 합니다. 아래는 Windows에서 VS Code를 통해 Rust 코드를 작성하고 실행하는 방법입니다.

### 1. VS Code 설치 및 Rust 확장 설치

1. **VS Code**를 설치합니다. [VS Code 다운로드](https://code.visualstudio.com/Download) 페이지에서 설치 파일을 받습니다.
2. VS Code에서 **Rust 확장**을 설치합니다. 다음 두 가지 확장을 설치하는 것이 좋습니다:
   - **Rust** (rust-lang.rust): Rust의 기본 확장으로, 코드 완성, 오류 검사, 문법 강조와 같은 기능을 제공합니다.
   - **CodeLLDB** (vadimcn.vscode-lldb): Rust 코드를 디버깅할 수 있게 해줍니다.

이 두 확장을 설치하면 Rust 개발 환경이 구축됩니다.

### 2. Rust 프로젝트 생성

1. **터미널**을 열어 새 프로젝트를 생성합니다. VS Code에서 `Ctrl + ~`로 터미널을 열고, 아래 명령어를 실행해 새 Rust 프로젝트를 생성합니다:

   ```bash
   cargo new project_name
   ```

   예를 들어, 프로젝트 이름을 `hello_rust`로 하려면 `cargo new hello_rust` 명령을 실행합니다.

2. 생성된 프로젝트 폴더로 이동합니다.

   ```bash
   cd hello_rust
   ```

3. VS Code에서 프로젝트 폴더를 열어 Rust 소스 코드 파일을 볼 수 있습니다.

### 3. Rust 코드 작성 및 실행

1. `src/main.rs` 파일을 열어 코드 작성을 시작합니다. 기본 코드 예시는 다음과 같습니다:

   ```rust
   fn main() {
       println!("Hello, Rust with VS Code!");
   }
   ```

2. **빌드 및 실행**:
   - **빌드**: 터미널에서 `cargo build` 명령어를 입력하면 프로젝트가 빌드됩니다.
   - **실행**: 빌드된 프로젝트를 실행하려면 `cargo run` 명령어를 사용합니다.

   ```bash
   cargo run
   ```

3. 프로그램이 제대로 실행되면 `"Hello, Rust with VS Code!"`가 출력됩니다.

### 4. 디버깅

1. **Run and Debug** 탭(또는 `Ctrl+Shift+D`)을 열고 **Add Configuration...** 버튼을 눌러 **Cargo.toml** 파일이 있는 프로젝트를 선택합니다.
2. **Cargo: Run**을 선택하여 디버깅 설정을 추가합니다. `launch.json` 파일이 자동으로 생성되며, 이를 통해 Rust 프로그램을 디버깅할 수 있습니다.

VS Code에서 설정이 완료되었으니, 이제 Rust 코드 작성, 실행, 디버깅까지 한 곳에서 할 수 있습니다!

---

네, Rust에는 SQLAlchemy와 같은 ORM(Object-Relational Mapping) 도구가 있습니다. 가장 널리 사용되는 ORM 중 하나는 **Diesel**입니다. Diesel을 사용하면 데이터베이스와의 상호 작용을 더욱 편리하고 안전하게 처리할 수 있습니다.

아래에서는 Diesel을 사용하여 트랜잭션을 SQLite 데이터베이스에 저장하는 방법을 설명하겠습니다.

---

### 1. Diesel 및 필요한 크레이트 추가

**`Cargo.toml`** 파일에 Diesel과 관련된 종속성을 추가합니다:

```toml
[dependencies]
diesel = { version = "2.0.0", features = ["sqlite", "serde_json"] }
dotenvy = "0.15.6"
serde = { version = "1.0", features = ["derive"] }
serde_json = "1.0"
uuid = { version = "1.3", features = ["serde", "v4"] }
```

- `diesel`: ORM 기능을 제공합니다.
- `dotenvy`: 환경 변수를 관리합니다.
- `serde` 및 `serde_json`: 직렬화 및 역직렬화를 위해 사용합니다.
- `uuid`: UUID를 생성하고 직렬화하기 위해 사용합니다.

### 2. Diesel CLI 설치 및 데이터베이스 설정

Diesel CLI를 설치해야 합니다:

```bash
cargo install diesel_cli --no-default-features --features sqlite-bundled
```

**참고:** `sqlite-bundled` 기능을 사용하여 SQLite를 번들로 포함합니다.

프로젝트 루트 디렉토리에 **`.env`** 파일을 생성하고 데이터베이스 URL을 설정합니다:

```
DATABASE_URL=transactions.db
```

### 3. 데이터베이스 마이그레이션 설정

Diesel은 마이그레이션을 통해 데이터베이스 스키마를 관리합니다.

```bash
diesel setup
```

마이그레이션을 생성합니다:

```bash
diesel migration generate create_transactions
```

생성된 마이그레이션 디렉토리의 **`up.sql`** 파일에 테이블 생성 쿼리를 작성합니다:

```sql
CREATE TABLE transactions (
    id          TEXT PRIMARY KEY,
    sender_id   TEXT NOT NULL,
    recipient_id TEXT NOT NULL,
    amount      REAL NOT NULL,
    timestamp   BIGINT NOT NULL,
    signature   TEXT
);
```

**`down.sql`** 파일에는 해당 테이블을 삭제하는 쿼리를 작성합니다:

```sql
DROP TABLE transactions;
```

마이그레이션을 실행합니다:

```bash
diesel migration run
```

### 4. Rust 코드 수정

**`src/schema.rs`** 파일 생성:

```rust
// src/schema.rs

diesel::table! {
    transactions (id) {
        id -> Text,
        sender_id -> Text,
        recipient_id -> Text,
        amount -> Double,
        timestamp -> BigInt,
        signature -> Nullable<Text>,
    }
}
```

**`src/lib.rs`** 파일 수정:

```rust
// src/lib.rs

#[macro_use]
extern crate diesel;

pub mod schema;

use diesel::prelude::*;
use diesel::sqlite::SqliteConnection;
use dotenvy::dotenv;
use std::env;

use self::schema::transactions;
use self::schema::transactions::dsl::*;

use serde::{Serialize, Deserialize};
use uuid::Uuid;

// 기존 코드...

// Transaction 구조체 수정
#[derive(Serialize, Deserialize, Debug, Clone, Queryable, Insertable)]
#[table_name = "transactions"]
pub struct Transaction {
    pub id: String,
    pub sender_id: String,
    pub recipient_id: String,
    pub amount: f64,
    pub timestamp: i64,
    pub signature: Option<String>,
}

impl Transaction {
    // 생성자 함수 수정
    pub fn new(sender_id: String, recipient_id: String, amount: f64) -> Self {
        let id = Uuid::new_v4().to_string();

        let timestamp = chrono::Utc::now().timestamp();

        Transaction {
            id,
            sender_id,
            recipient_id,
            amount,
            timestamp,
            signature: None,
        }
    }

    // 기타 메서드 수정 필요 없음
}

// 데이터베이스 연결 함수 추가
pub fn establish_connection() -> SqliteConnection {
    dotenv().ok();

    let database_url = env::var("DATABASE_URL").expect("DATABASE_URL must be set");
    SqliteConnection::establish(&database_url)
        .unwrap_or_else(|_| panic!("Error connecting to {}", database_url))
}

// 트랜잭션 저장 함수 추가
pub fn save_transaction_to_db(transaction: &Transaction) -> Result<(), Box<dyn std::error::Error>> {
    let conn = &mut establish_connection();

    diesel::insert_into(transactions::table)
        .values(transaction)
        .execute(conn)?;

    println!("트랜잭션이 데이터베이스에 저장되었습니다.");

    Ok(())
}
```

- `Transaction` 구조체에 `Queryable` 및 `Insertable` 트레이트를 추가했습니다.
- `id` 필드명을 `transaction_id`에서 `id`로 변경하여 데이터베이스 스키마와 일치시켰습니다.
- `timestamp`의 타입을 `i64`로 변경했습니다.
- `establish_connection` 함수와 `save_transaction_to_db` 함수를 추가했습니다.

**`src/main.rs`** 파일 수정:

```rust
// src/main.rs

use crypto_tran::{
    generate_rsa_key_pair, 
    write_pem_file, 
    read_private_key_from_pem, 
    read_public_key_from_pem, 
    Transaction,
    generate_symmetric_key,
    encrypt,
    decrypt,
    save_transaction_to_db, // 추가
}; 
use rsa::pkcs8::{EncodePrivateKey, EncodePublicKey};
use hex;

fn main() -> Result<(), Box<dyn std::error::Error>> {
    // 기존 코드 유지...

    // 역직렬화
    let deserialized = Transaction::deserialize(&decrypted_serialized)?;
    println!("Deserialized Transaction: {:?}", deserialized);

    // SQLite 데이터베이스에 트랜잭션 저장
    save_transaction_to_db(&deserialized)?;

    Ok(())
}
```

### 5. 코드 실행

프로그램을 실행하면 트랜잭션이 SQLite 데이터베이스에 ORM 방식으로 저장됩니다.

```bash
cargo run
```

---

### 설명

- **Diesel ORM 사용**: Diesel을 사용하여 데이터베이스와 상호 작용합니다. Diesel은 Rust의 타입 시스템을 활용하여 컴파일 타임에 SQL 쿼리의 정확성을 검사합니다.
- **마이그레이션**: 데이터베이스 스키마를 버전 관리하고 일관성을 유지하기 위해 마이그레이션을 사용합니다.
- **환경 변수 관리**: `dotenvy` 크레이트를 사용하여 `.env` 파일에서 환경 변수를 로드합니다.
- **구조체 수정**: Diesel과 호환되도록 `Transaction` 구조체를 수정하고 필요한 트레이트를 구현했습니다.
- **데이터베이스 연결 및 저장 함수**: 데이터베이스 연결을 관리하는 `establish_connection` 함수와 트랜잭션을 저장하는 `save_transaction_to_db` 함수를 추가했습니다.

### 추가 참고 사항

- **에러 처리**: 모든 데이터베이스 작업에서 발생할 수 있는 에러를 적절하게 처리하고 전파합니다.
- **데이터베이스 파일 위치**: `.env` 파일에서 데이터베이스 파일의 위치를 지정할 수 있습니다.
- **타임스탬프 처리**: `chrono` 크레이트를 사용하여 UTC 타임스탬프를 가져오고 `i64`로 저장합니다.

### 전체 코드 구조

프로젝트의 전체 디렉토리 구조는 다음과 같습니다:

```
├── Cargo.toml
├── .env
├── migrations
│   └── {timestamp}_create_transactions
│       ├── up.sql
│       └── down.sql
├── src
│   ├── lib.rs
│   ├── main.rs
│   └── schema.rs
```

### 결론

이렇게 하면 Rust에서 Diesel ORM을 사용하여 SQLAlchemy와 유사한 방식으로 SQLite 데이터베이스에 트랜잭션을 저장할 수 있습니다. Diesel은 강력한 타입 시스템과 컴파일 타임 검사를 제공하여 데이터베이스 작업을 안전하고 효율적으로 수행할 수 있도록 도와줍니다.

추가적인 기능이나 최적화가 필요하다면 Diesel의 공식 문서를 참고하시기 바랍니다: [Diesel 공식 문서](https://diesel.rs/guides/getting-started)