// src/lib.rs

use rsa::{RsaPrivateKey, RsaPublicKey};
use rsa::pkcs8::{DecodePrivateKey, DecodePublicKey};
use rsa::pkcs1v15;
use rand::{RngCore, rngs::OsRng};
use std::fs::File;
use std::io::{Read, Write};
use std::path::Path;
use serde::{Serialize, Deserialize};
use serde_json;
use std::error::Error;
use std::time::{SystemTime, UNIX_EPOCH};
use uuid::Uuid;
use sha2::{Sha256, Digest};
use base64;
//use signature::{Signer, Verifier};
use aes_gcm::{Aes256Gcm, KeyInit, Nonce}; // AES-GCM 구조체 및 타입
use aes_gcm::aead::Aead;
//use cipher::{KeyIvInit, StreamCipher, generic_array::GenericArray};

/// RSA 키 쌍을 생성하는 함수.
pub fn generate_rsa_key_pair() -> Result<(RsaPrivateKey, RsaPublicKey), Box<dyn std::error::Error>> {
    let mut rng = OsRng;
    let private_key = RsaPrivateKey::new(&mut rng, 2048)?;
    let public_key = RsaPublicKey::from(&private_key);
    Ok((private_key, public_key))
}

/// PEM 파일로 키를 저장하는 함수.
pub fn write_pem_file<P: AsRef<Path>>(path: P, pem: &str) -> Result<(), Box<dyn std::error::Error>> {
    let mut file = File::create(path)?;
    file.write_all(pem.as_bytes())?;
    Ok(())
}

/// PEM 파일에서 비밀키를 읽는 함수.
pub fn read_private_key_from_pem<P: AsRef<Path>>(path: P) -> Result<RsaPrivateKey, Box<dyn std::error::Error>> {
    let mut file = File::open(path)?;
    let mut pem = String::new();
    file.read_to_string(&mut pem)?;
    let private_key = RsaPrivateKey::from_pkcs8_pem(&pem)?;
    Ok(private_key)
}

/// PEM 파일에서 공개키를 읽는 함수.
pub fn read_public_key_from_pem<P: AsRef<Path>>(path: P) -> Result<RsaPublicKey, Box<dyn std::error::Error>> {
    let mut file = File::open(path)?;
    let mut pem = String::new();
    file.read_to_string(&mut pem)?;
    let public_key = RsaPublicKey::from_public_key_pem(&pem)?;
    Ok(public_key)
}

// Transaction 구조체 정의
#[derive(Serialize, Deserialize, Debug)]
pub struct Transaction {
    transaction_id: String,
    sender_id: String,
    recipient_id: String,
    amount: f64,
    timestamp: u64,
    signature: Option<String>, // 서명 필드
}

impl Transaction {
    // 생성자 함수
    pub fn new(sender_id: String, recipient_id: String, amount: f64) -> Self {
        let transaction_id = Uuid::new_v4()
            .to_string()
            .chars()
            .take(16)
            .collect();

        let timestamp = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .expect("Time went backwards")
            .as_secs();

        Transaction {
            transaction_id,
            sender_id,
            recipient_id,
            amount,
            timestamp,
            signature: None, // 초기 서명 값은 None
        }
    }

    // JSON 문자열로 직렬화 (signature 포함)
    pub fn serialize(&self) -> Result<String, Box<dyn Error>> {
        let json = serde_json::to_string(&self)?;
        Ok(json)
    }

    // JSON 문자열에서 역직렬화
    pub fn deserialize(json_str: &str) -> Result<Self, Box<dyn Error>> {
        let transaction: Transaction = serde_json::from_str(json_str)?;
        Ok(transaction)
    }

    // JSON 문자열로 직렬화 (signature 필드 제외)
    fn serialize_without_signature(&self) -> Result<String, Box<dyn Error>> {
        // 임시로 `Transaction`의 사본을 만들어 `signature` 필드를 제거하고 직렬화
        let mut temp_transaction = self.clone();
        temp_transaction.signature = None;
        let json = serde_json::to_string(&temp_transaction)?;
        Ok(json)
    }

    // 트랜잭션에 서명 생성
    pub fn sign(&mut self, private_key: &RsaPrivateKey) -> Result<(), Box<dyn Error>> {
        let serialized = self.serialize_without_signature()?;

        // SHA-256 해시 계산
        let mut hasher = Sha256::new();
        hasher.update(serialized.as_bytes());
        let hashed = hasher.finalize();

        // 개인 키로 PKCS1 v1.5 방식으로 서명 생성
        let padding = pkcs1v15::Pkcs1v15Sign::new::<Sha256>();
        let signature = private_key.sign(padding, &hashed)?;

        // 서명을 Base64로 인코딩하여 저장
        self.signature = Some(base64::encode(signature));
        Ok(())
    }

    // 서명 검증
    pub fn verify_signature(&self, public_key: &RsaPublicKey) -> Result<bool, Box<dyn Error>> {
        if let Some(signature_base64) = &self.signature {
            let serialized = self.serialize_without_signature()?;

            // SHA-256 해시 계산
            let mut hasher = Sha256::new();
            hasher.update(serialized.as_bytes());
            let hashed = hasher.finalize();

            // 서명을 디코딩하고 검증
            let signature = base64::decode(signature_base64)?;
            let padding = pkcs1v15::Pkcs1v15Sign::new::<Sha256>();
            public_key.verify(padding, &hashed, &signature).map(|_| true).map_err(|e| e.into())
        } else {
            Ok(false)
        }
    }

}

// 트랜잭션 구조체의 `Clone` 트레이트를 구현
impl Clone for Transaction {
    fn clone(&self) -> Self {
        Transaction {
            transaction_id: self.transaction_id.clone(),
            sender_id: self.sender_id.clone(),
            recipient_id: self.recipient_id.clone(),
            amount: self.amount,
            timestamp: self.timestamp,
            signature: self.signature.clone(),
        }
    }
}

// 대칭키 생성 함수 (AES-256 키, 32바이트)
pub fn generate_symmetric_key() -> [u8; 32] {
    let mut key = [0u8; 32];
    OsRng.fill_bytes(&mut key);
    key
}

// AES-256 GCM 방식으로 직렬화된 트랜잭션 암호화
pub fn encrypt(plain_text: &str, key: &[u8; 32]) -> Result<(Vec<u8>, [u8; 12]), Box<dyn Error>> {
    // IV (Initial Vector, 12바이트) 생성
    let mut iv = [0u8; 12];
    OsRng.fill_bytes(&mut iv);
    let nonce = Nonce::from_slice(&iv);

    // AES-256 GCM 암호화기 초기화
    let cipher = Aes256Gcm::new_from_slice(key)?;

    // 직렬화된 트랜잭션을 암호화
    let ciphertext = cipher.encrypt(nonce, plain_text.as_bytes())
        .map_err(|e| Box::<dyn Error>::from(e.to_string()))?; // 오류 변환 추가

    Ok((ciphertext, iv)) // 암호화된 데이터와 IV 반환
}

// AES-256 GCM 방식으로 암호화된 트랜잭션 복호화
pub fn decrypt(encrypted_data: &[u8], key: &[u8; 32], iv: &[u8; 12]) -> Result<String, Box<dyn Error>> {
    // AES-256 GCM 복호화기 초기화
    let cipher = Aes256Gcm::new_from_slice(key)?;
    let nonce = Nonce::from_slice(iv);

    // 암호화된 데이터를 복호화
    let decrypted_data = cipher.decrypt(nonce, encrypted_data)
        .map_err(|e| Box::<dyn Error>::from(e.to_string()))?; // 오류 변환 추가

    // 복호화된 데이터를 문자열로 변환
    let decrypted_str = String::from_utf8(decrypted_data)?;

    Ok(decrypted_str)
}
