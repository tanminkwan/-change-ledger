use rsa::{RsaPrivateKey, RsaPublicKey, pkcs1v15, Pkcs1v15Encrypt};
use rsa::pkcs8::{DecodePrivateKey, DecodePublicKey};
use rand::{RngCore, rngs::OsRng};
use std::fs::File;
use std::io::{Read, Write};
use std::path::Path;
use serde::{Serialize, Deserialize};
use serde_json;
use std::error::Error;
//use std::time::{SystemTime, UNIX_EPOCH};
use uuid::Uuid;
use sha2::{Sha256, Digest};
use base64;
//use signature::{Signer, Verifier};
use aes_gcm::{Aes256Gcm, KeyInit, Nonce}; // AES-GCM 구조체 및 타입
use aes_gcm::aead::Aead;
use flutter_rust_bridge::frb;

#[frb]
pub fn encrypt_symmetric_key(
    symmetric_key: &[u8],
    public_key: &RsaPublicKey,
) -> Result<Vec<u8>, Box<dyn std::error::Error>> {
    let mut rng = rand::thread_rng();
    let encrypted_key = public_key.encrypt(
        &mut rng,
        Pkcs1v15Encrypt,
        symmetric_key,
    )?;
    Ok(encrypted_key)
}

#[frb]
pub fn decrypt_symmetric_key(
    encrypted_key: &[u8],
    private_key: &RsaPrivateKey,
) -> Result<Vec<u8>, Box<dyn std::error::Error>> {
    let decrypted_key = private_key.decrypt(
        Pkcs1v15Encrypt,
        encrypted_key,
    )?;
    Ok(decrypted_key)
}

/// RSA 키 쌍을 생성하는 함수.
#[frb]
pub fn generate_rsa_key_pair() -> Result<(RsaPrivateKey, RsaPublicKey), Box<dyn std::error::Error>> {
    let mut rng = OsRng;
    let private_key = RsaPrivateKey::new(&mut rng, 2048)?;
    let public_key = RsaPublicKey::from(&private_key);
    Ok((private_key, public_key))
}

/// PEM 파일로 키를 저장하는 함수.
#[frb]
pub fn write_pem_file<P: AsRef<Path>>(path: P, pem: &str) -> Result<(), Box<dyn std::error::Error>> {
    let mut file = File::create(path)?;
    file.write_all(pem.as_bytes())?;
    Ok(())
}

/// PEM 파일에서 비밀키를 읽는 함수.
#[frb]
pub fn read_private_key_from_pem<P: AsRef<Path>>(path: P) -> Result<RsaPrivateKey, Box<dyn std::error::Error>> {
    let mut file = File::open(path)?;
    let mut pem = String::new();
    file.read_to_string(&mut pem)?;
    let private_key = RsaPrivateKey::from_pkcs8_pem(&pem)?;
    Ok(private_key)
}

/// PEM 파일에서 공개키를 읽는 함수.
#[frb]
pub fn read_public_key_from_pem<P: AsRef<Path>>(path: P) -> Result<RsaPublicKey, Box<dyn std::error::Error>> {
    let mut file = File::open(path)?;
    let mut pem = String::new();
    file.read_to_string(&mut pem)?;
    let public_key = RsaPublicKey::from_public_key_pem(&pem)?;
    Ok(public_key)
}

#[derive(Serialize, Deserialize, Debug)]
pub struct SecuTransaction {
    pub id: String,
    pub sender_id: String,
    pub recipient_id: String,
    pub amount: f64,
    pub timestamp: i64,
    pub signature: Option<String>,
    pub prev_hash: Option<String>,
    pub current_hash: Option<String>,
}

impl SecuTransaction {
    // 생성자 함수
    pub fn new(
        sender_id_: String,
        recipient_id_: String,
        amount_: f64,
    ) -> Self {
        let id_ = Uuid::new_v4().to_string();
        let timestamp_ = chrono::Utc::now().timestamp();

        SecuTransaction {
            id: id_,
            sender_id: sender_id_,
            recipient_id: recipient_id_,
            amount: amount_,
            timestamp: timestamp_,
            signature: None, // 초기 서명 값은 None
            prev_hash: None,
            current_hash: None,
        }
    }

    // JSON 문자열로 직렬화 (signature 포함)
    pub fn serialize(&self) -> Result<String, Box<dyn Error>> {
        let json = serde_json::to_string(&self)?;
        Ok(json)
    }

    // JSON 문자열에서 역직렬화
    pub fn deserialize(json_str: &str) -> Result<Self, Box<dyn Error>> {
        let transaction: SecuTransaction = serde_json::from_str(json_str)?;
        Ok(transaction)
    }

    // JSON 문자열로 직렬화 (signature 필드 제외)
    fn serialize_without_signature(&self) -> Result<String, Box<dyn Error>> {
        // 임시로 `Transaction`의 사본을 만들어 `signature` 필드를 제거하고 직렬화
        let mut temp_transaction = self.clone();
        temp_transaction.signature = None;
        temp_transaction.prev_hash = None;
        temp_transaction.current_hash = None;
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
        let signature_ = private_key.sign(padding, &hashed)?;

        // 서명을 Base64로 인코딩하여 저장
        self.signature = Some(base64::encode(signature_));
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
            let signature_ = base64::decode(signature_base64)?;
            let padding = pkcs1v15::Pkcs1v15Sign::new::<Sha256>();
            public_key.verify(padding, &hashed, &signature_).map(|_| true).map_err(|e| e.into())
        } else {
            Ok(false)
        }
    }

    // current_hash 계산을 위한 메서드 추가
    pub fn calculate_current_hash(&self) -> Result<String, Box<dyn Error>> {
        // signature와 current_hash를 제외하고 직렬화 (prev_hash는 포함)
        let mut temp_transaction = self.clone();
        temp_transaction.signature = None;
        temp_transaction.current_hash = None;
        let serialized = serde_json::to_string(&temp_transaction)?;
    
        // SHA-256 해시 계산
        let mut hasher = Sha256::new();
        hasher.update(serialized.as_bytes());
        let hashed = hasher.finalize();
    
        Ok(format!("{:x}", hashed))
    }

}

// 트랜잭션 구조체의 `Clone` 트레이트를 구현
impl Clone for SecuTransaction {
    fn clone(&self) -> Self {
        SecuTransaction {
            id: self.id.clone(),
            sender_id: self.sender_id.clone(),
            recipient_id: self.recipient_id.clone(),
            amount: self.amount,
            timestamp: self.timestamp,
            signature: self.signature.clone(),
            prev_hash: self.prev_hash.clone(),
            current_hash: self.current_hash.clone(),
        }
    }
}


// 대칭키 생성 함수 (AES-256 키, 32바이트)
#[frb]
pub fn generate_symmetric_key() -> [u8; 32] {
    let mut key = [0u8; 32];
    OsRng.fill_bytes(&mut key);
    key
}

// AES-256 GCM 방식으로 직렬화된 트랜잭션 암호화
#[frb]
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
#[frb]
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
