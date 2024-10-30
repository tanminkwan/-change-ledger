// src/main.rs

use crypto_test::{
    generate_rsa_key_pair, 
    write_pem_file, 
    read_private_key_from_pem, 
    read_public_key_from_pem, 
    Transaction,
    generate_symmetric_key,
    encrypt,
    decrypt,
}; 
use rsa::pkcs8::{EncodePrivateKey, EncodePublicKey};
use hex; // hex 크레이트 임포트

fn main() -> Result<(), Box<dyn std::error::Error>> {
    let (private_key, public_key) = generate_rsa_key_pair()?;

    let private_pem = private_key.to_pkcs8_pem(Default::default())?;
    let public_pem = public_key.to_public_key_pem(Default::default())?;
    println!("Private Key (PEM):\n{}", &*private_pem);
    println!("Public Key (PEM):\n{}", &*public_pem);

    // PEM 파일로 저장
    write_pem_file("private_key.pem", &private_pem)?;
    write_pem_file("public_key.pem", &public_pem)?;
    println!("PEM 파일을 저장했습니다: private_key.pem, public_key.pem");

    // 저장한 PEM 파일에서 키 읽기
    let read_private_key = read_private_key_from_pem("private_key.pem")?;
    let read_public_key = read_public_key_from_pem("public_key.pem")?;
    println!("PEM 파일에서 키를 성공적으로 읽었습니다.");

    // 읽어온 키를 다시 PEM 형식으로 출력
    println!("읽어온 Private Key (PEM):\n{}", &*read_private_key.to_pkcs8_pem(Default::default())?);
    println!("읽어온 Public Key (PEM):\n{}", &*read_public_key.to_public_key_pem(Default::default())?);

    // Transaction 인스턴스 생성
    let mut transaction = Transaction::new(
        "sender123".to_string(),
        "recipient456".to_string(),
        100.0,
    );
    
    // 트랜잭션에 서명 생성
    transaction.sign(&private_key)?;
    println!("Signed Transaction: {:?}", transaction);
    
    // 서명 검증
    let is_valid = transaction.verify_signature(&public_key)?;
    println!("Signature valid: {}", is_valid);
    
    // 직렬화
    let serialized = transaction.serialize()?;
    println!("Serialized JSON: {}", serialized);

    // 1. 대칭키 생성
    let symmetric_key = generate_symmetric_key();
    println!("생성된 대칭키: {:?}", symmetric_key);
    
    // 2. 대칭키로 직렬화된 트랜잭션 암호화
    let (encrypted_data_vec, iv) = encrypt(&serialized, &symmetric_key)?;
    let encrypted_data_hex = hex::encode(encrypted_data_vec);
    let iv_hex = hex::encode(iv);
    println!("암호화된 데이터 (Hex): {}", encrypted_data_hex);
    println!("IV (Hex): {}", iv_hex);

    // 3. 대칭키로 암호화된 트랜잭션 복호화
    let encrypted_data_vec = hex::decode(encrypted_data_hex)?;
    let iv_vec = hex::decode(iv_hex)?;
    let mut iv_array = [0u8; 12];
    iv_array.copy_from_slice(&iv_vec);
    let decrypted_serialized = decrypt(&encrypted_data_vec, &symmetric_key, &iv_array)?;
    println!("복호화된 직렬화 데이터: {}", decrypted_serialized);

    // 역직렬화
    let deserialized = Transaction::deserialize(&decrypted_serialized)?;
    println!("Deserialized Transaction: {:?}", deserialized);

    Ok(())

}
