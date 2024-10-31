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
    establish_connection,
    save_transaction_to_db,
    get_prev_hash,
    encrypt_symmetric_key,
    decrypt_symmetric_key,
}; 
use rsa::pkcs8::{EncodePrivateKey, EncodePublicKey};
use hex; // hex 크레이트 임포트

fn main() -> Result<(), Box<dyn std::error::Error>> {

    //1. Offerer: 공개키/비밀키 생성
    let ( mut private_key, mut public_key) = generate_rsa_key_pair()?;

    let mut private_pem = private_key.to_pkcs8_pem(Default::default())?;
    let mut public_pem = public_key.to_public_key_pem(Default::default())?;
    //println!("Private Key (PEM):\n{}", &*private_pem);
    //println!("Public Key (PEM):\n{}", &*public_pem);

    // PEM 파일로 저장
    write_pem_file("private_key_offerer.pem", &private_pem)?;
    write_pem_file("public_key_offerer.pem", &public_pem)?;
    println!("1. Offerer: 공개키/비밀키 PEM 파일 저장: private_key_offerer.pem, public_key_offerer.pem");

    //2. Answerer: 공개키/비밀키 생성
    (private_key, public_key) = generate_rsa_key_pair()?;

    private_pem = private_key.to_pkcs8_pem(Default::default())?;
    public_pem = public_key.to_public_key_pem(Default::default())?;
    
    // PEM 파일로 저장
    write_pem_file("private_key_answerer.pem", &private_pem)?;
    write_pem_file("public_key_answerer.pem", &public_pem)?;
    println!("2. Answerer: 공개키/비밀키 PEM 파일 저장: private_key_answerer.pem, public_key_answerer.pem");
    
    //3. Offerer와 Answerer간 공개키 공유
    println!("3. Offerer, Answerer: 서로의 공개키를 공유.");
    
    //4. Offerer: 자신의 비밀키와 Answerer의 공개키 읽기
    let private_key_offerer = read_private_key_from_pem("private_key_offerer.pem")?;
    let public_key_answerer = read_public_key_from_pem("public_key_answerer.pem")?;
    println!("4. Offerer: 자신의 비밀키와 Answerer의 공개키를 읽음.");

    // 읽어온 키를 다시 PEM 형식으로 출력
    println!("- 읽어온 Private Key (PEM):\n{}", &*private_key_offerer.to_pkcs8_pem(Default::default())?);
    println!("- 읽어온 Public Key (PEM):\n{}", &*public_key_answerer.to_public_key_pem(Default::default())?);

    //5. Offerer: 트랜잭션 생성
    let mut transaction = Transaction::new(
        "sender123".to_string(),
        "recipient456".to_string(),
        100.0,
    );
    println!("5. Offerer: Transaction을 생성.");
    println!("- Transaction: {:?}", transaction);    

    //6. Offerer: 자신의 비밀키로 트랜잭션에 서명
    transaction.sign(&private_key_offerer)?;
    println!("6. Offerer: 자신의 비밀키로 트랜잭션에 서명.");
    println!("- Signed Transaction: {:?}", transaction);
    
    //7. Offerer: 트랜잭션을 직렬화
    let serialized = transaction.serialize()?;
    println!("7. Offerer: 트랜잭션을 직렬화.");
    println!("- Serialized JSON: {}", serialized);

    //8. Offerer: 대칭키 생성
    let symmetric_key = generate_symmetric_key();
    println!("8. Offerer: 대칭키 생성.");
    println!("- 생성된 대칭키: {:?}", symmetric_key);
    
    //9. Offerer: 대칭키로 직렬화된 트랜잭션 암호화
    let (encrypted_data_vec, iv) = encrypt(&serialized, &symmetric_key)?;
    let encrypted_data_hex = hex::encode(encrypted_data_vec);
    let iv_hex = hex::encode(iv);
    println!("9. Offerer: 대칭키로 직렬화된 트랜잭션 암호화.");
    println!("- 암호화된 데이터 (Hex): {}", encrypted_data_hex);
    println!("- IV (Hex): {}", iv_hex);

    //10. Offerer: Answerer의 공개키로 대칭키를 암호화
    let encrypted_symmetric_key = encrypt_symmetric_key(&symmetric_key, &public_key_answerer)?;
    let encrypted_symmetric_key_hex = hex::encode(&encrypted_symmetric_key);
    println!("10. Offerer: Answerer의 공개키로 대칭키를 암호화");
    println!("- 암호화된 대칭키 (Hex): {}", encrypted_symmetric_key_hex);

    //11. Offerer: Answerer에게 트랜잭션+비밀키 전문 송신
    // Simulate sending data (in a real application, this would be sent over a network)
    println!("11. Offerer: Sent encrypted transaction data and encrypted symmetric key to Answerer.");

    //12. Answerer: 자신의 비밀키와 Offerer의 공개키 읽기
    let private_key_answerer = read_private_key_from_pem("private_key_answerer.pem")?;
    let public_key_offerer = read_public_key_from_pem("public_key_offerer.pem")?;
    println!("12. Answerer: 자신의 비밀키와 Offerer의 공개키를 읽음.");

    //13. Answerer: 자신의 비밀키로 대칭키 복호화
    let encrypted_symmetric_key = hex::decode(encrypted_symmetric_key_hex)?;
    let decrypted_symmetric_key = decrypt_symmetric_key(&encrypted_symmetric_key, &private_key_answerer)?;
    println!("13. Answerer: 자신의 비밀키로 대칭키를 복호화.");
    println!("- 복호화된 대칭키: {:?}", decrypted_symmetric_key);

    //14. Answerer: 대칭키로 암호화된 트랜잭션 복호화
    let encrypted_data_vec = hex::decode(encrypted_data_hex)?;
    let iv_vec = hex::decode(iv_hex)?;
    let mut iv_array = [0u8; 12];
    iv_array.copy_from_slice(&iv_vec);
    let decrypted_serialized = decrypt(&encrypted_data_vec, &symmetric_key, &iv_array)?;
    println!("14. Answerer: 대칭키로 암호화된 트랜잭션 복호화.");
    println!("- 복호화된 직렬화 데이터: {}", decrypted_serialized);

    //15. Answerer: 트랜잭션 역직렬화
    let mut received_transaction = Transaction::deserialize(&decrypted_serialized)?;
    println!("15. Answerer: 트랜잭션 역직렬화.");
    println!("- Deserialized Transaction: {:?}", received_transaction);

    //16. Answerer: Offerer의 공개키로 Offerer의 서명 검증
    let is_valid = received_transaction.verify_signature(&public_key_offerer)?;
    println!("16. Answerer: Offerer의 공개키로 Offerer의 서명 검증.");
    println!("- Signature valid: {}", is_valid);
    
    //17. Answerer: 원장에서 바로 이전 트랜잭션의 current_hash를 가져와 prev_hash로 설정
    let conn = &mut establish_connection();

    // Get the previous hash using the new function
    let prev_hash = get_prev_hash(conn)?;
    received_transaction.prev_hash = Some(prev_hash);
    println!("17. Answerer: 원장에서 바로 이전 트랜잭션의 current_hash를 가져와 prev_hash로 설정.");
    println!("- prev_hash-added Transaction: {:?}", received_transaction);

    //18. Answerer: prev_hash를 포함한 트랜잭션 정보를 이용해서 current_hash 생성.
    let current_hash = received_transaction.calculate_current_hash()?;
    received_transaction.current_hash = Some(current_hash);
    println!("18. Answerer: prev_hash를 포함한 트랜잭션 정보를 이용해서 current_hash 생성.");
    println!("- Completed Transaction: {:?}", received_transaction);

    //19. Answerer: SQLite 데이터베이스에 트랜잭션 저장
    save_transaction_to_db(&received_transaction, conn)?;
    println!("19. Answerer: SQLite 데이터베이스에 트랜잭션 저장.");

    Ok(())

}
