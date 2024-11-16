# rust_n_flutter

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Flutter Rust Bridge
[online documentation](https://cjycode.com/flutter_rust_bridge/quickstart)

# Run Application

```bash
flutter run --dart-entrypoint-args user_id
```

### Communication Flow between Offerer and Answerer

#### 1. Contract
- Offerer: Offerer가 DHT에서 특정 Answerer의 SDP를 Get한다.
- Offerer: SDP로부터 Answerer정보, 공개키, 서명를 읽어 서명 검증 후 각각 Answerer table과 Keystore에 저장한다.
- Offerer: Answerer가 Listening으로 찾을 수 있는 방법으로 DHT에 자신의 공개키+서명을 포함한 SDP를 저장한다.
- Answerer : DHT에서 contract를 원하는 Offerer의 SDP를 Get한다.
- Answerer : SDP로부터 Offerer정보, 공개키, 서명를 읽어 서명 검증 후 각각 Transaction table(type=contract, amount=0)과 Keystore에 저장한다.

#### 2. Sending Transaction
- Offerer: Answerer가 Listening으로 찾을 수 있는 방법으로 DHT에 transaction SDP를 저장
- Answerer: DHT에서 Offerer의 SDP를 Get한다.
- Answerer: Offerer의 transaction 허용에 해당하는 SDP를 생성
- Offerer: DHT에서 Answerer의 SDP를 Get한다.
- Offerer: WebRTC Data chennal 생성
- Offerer: Transaction 생성
    - transaction id 생성
    - transaction_id+sender_id+recipient_id+amount+timestamp 를 json 직렬화하여 Offerer의 비밀키로 서명
    - transaction 암호화용 대칭키 생성
    - 대칭키로 transaction_id+sender_id+recipient_id+amount+timestamp+signature json 직렬화 string을 암호화
    - Answerer의 공개키로 대칭키 암호화
- Offerer: 암호화된 transaction + 암호화된 대칭키 데이터를 Data chennal을 통해 Answerer에게 전송

#### 3. Receiving Transaction
- Answerer: 자신의 비밀키와 Offerer의 공개키를 읽음.
- Answerer: 자신의 비밀키로 암호화된 대칭키를 복호화.
- Answerer: 복호화된 대칭키로 암호화된 transaction을 복호화
- Answerer: transaction을 역직렬화
- Answerer: Offerer의 공개키로 Offerer의 서명이 유효한지 검증(hash비교)
- Answerer: 직렬화된 상태의 transaction을 자신의 비밀키로 서명
- Answerer: Data chennal을 통해 Offerer에게 자신의 서명 전송(transaction 접수 했다는 증명)
- Offerer: transaction과 Answerer의 서명을 Table에 저장
- Answerer: Ledger 등록
    - Ledger db의 바로 이전 발생한 transaction의 current_hash 조회
    - `transaction_id+sender_id+recipient_id+amount+timestamp+Offerer signature+바로 이전 발생한 transaction의 current_hash` 로 hash 생성
    - 아래 기준으로 Ledger 등록 : 각각의 data, prev_hash = `이전 발생한 transaction의 current_hash`, current_hash = `위에서 생성한 hash`
