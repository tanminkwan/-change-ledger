use std::fs::File;
use std::io::Write;
use std::path::Path;
use rsa::{pkcs1v15, RsaPrivateKey, RsaPublicKey};
use rsa::pkcs8::{EncodePrivateKey, EncodePublicKey, DecodePrivateKey, DecodePublicKey};
use sha2::{Sha256, Digest};
use aes_gcm::{Aes256Gcm, KeyInit, Nonce};
use aes_gcm::aead::{Aead, Error as AeadError};
use rand::rngs::OsRng;
use rand::RngCore;
use base64;
use serde::{Serialize, Deserialize};
use std::error::Error;
use flutter_rust_bridge::frb;

#[derive(Serialize, Deserialize)]
pub struct RsaKeyPair {
    pub private_key_pem: String,
    pub public_key_pem: String,
}

#[frb]
pub fn generate_rsa_key_pair() -> RsaKeyPair {
    let mut rng = OsRng;
    let private_key = RsaPrivateKey::new(&mut rng, 2048).expect("Failed to generate private key");
    let public_key = RsaPublicKey::from(&private_key);

    RsaKeyPair {
        private_key_pem: private_key.to_pkcs8_pem(rsa::pkcs8::LineEnding::LF).unwrap().to_string(),
        public_key_pem: public_key.to_public_key_pem(rsa::pkcs8::LineEnding::LF).unwrap().to_string(),
    }
}

#[frb]
pub fn write_pem_file(path: String, pem: String) -> Result<(), String> {
    let path = Path::new(&path);
    match File::create(path) {
        Ok(mut file) => match file.write_all(pem.as_bytes()) {
            Ok(_) => Ok(()),
            Err(err) => Err(format!("Failed to write to file: {}", err)),
        },
        Err(err) => Err(format!("Failed to create file: {}", err)),
    }
}

// Generate symmetric key (32 bytes)
#[frb]
pub fn generate_symmetric_key() -> Vec<u8> {
    let mut key = vec![0u8; 32];
    OsRng.fill_bytes(&mut key);
    key
}

// Encrypt data using AES-256 GCM
#[frb]
pub fn encrypt(plain_text: &str, key: Vec<u8>) -> Result<(Vec<u8>, Vec<u8>), String> {
    if key.len() != 32 {
        return Err("Key must be 32 bytes.".to_string());
    }

    let mut iv = vec![0u8; 12];
    OsRng.fill_bytes(&mut iv);
    let nonce = Nonce::from_slice(&iv);

    let cipher = Aes256Gcm::new_from_slice(&key).map_err(|e| e.to_string())?;

    let ciphertext = cipher.encrypt(nonce, plain_text.as_bytes())
        .map_err(|e| e.to_string())?;

    Ok((ciphertext, iv))
}

// Decrypt data using AES-256 GCM
#[frb]
pub fn decrypt(encrypted_data: Vec<u8>, key: Vec<u8>, iv: Vec<u8>) -> Result<String, String> {
    if key.len() != 32 {
        return Err("Key must be 32 bytes.".to_string());
    }
    if iv.len() != 12 {
        return Err("IV must be 12 bytes.".to_string());
    }

    let nonce = Nonce::from_slice(&iv);

    let cipher = Aes256Gcm::new_from_slice(&key).map_err(|e| e.to_string())?;

    let decrypted_data = cipher.decrypt(nonce, encrypted_data.as_ref())
        .map_err(|e| e.to_string())?;

    String::from_utf8(decrypted_data).map_err(|e| e.to_string())
}

// Sign a transaction using a private key
#[frb]
pub fn sign(orig_text: &str, private_key: &str) -> Result<String, String> {
    let private_key_pem = RsaPrivateKey::from_pkcs8_pem(private_key)
        .map_err(|e| e.to_string())?;

    let mut hasher = Sha256::new();
    hasher.update(orig_text.as_bytes());
    let hashed = hasher.finalize();

    let padding = pkcs1v15::Pkcs1v15Sign::new::<Sha256>();
    let signature = private_key_pem
        .sign(padding, &hashed)
        .map_err(|e| e.to_string())?;

    Ok(base64::encode(signature))
}

// Verify a signature using a public key
#[frb]
pub fn verify_signature(signature: &str, orig_text: &str, public_key_pem: &str) -> Result<bool, String> {
    let public_key = RsaPublicKey::from_public_key_pem(public_key_pem)
        .map_err(|e| e.to_string())?;

    let mut hasher = Sha256::new();
    hasher.update(orig_text.as_bytes());
    let hashed = hasher.finalize();

    let signature_bytes = base64::decode(signature).map_err(|e| e.to_string())?;
    let padding = pkcs1v15::Pkcs1v15Sign::new::<Sha256>();

    public_key.verify(padding, &hashed, &signature_bytes)
        .map(|_| true)
        .map_err(|e| e.to_string())
}

#[derive(Serialize, Deserialize)]
struct PayloadAndSignature {
    payload: String,
    signature: String,
}

#[derive(Serialize, Deserialize)]
pub struct EncryptedMessage {
    pub encrypted_payload: String, // Base64로 인코딩된 암호화된 JSON 문자열
    pub iv: String,                // Base64로 인코딩된 초기화 벡터
    pub symmetric_key: String,     // Base64로 인코딩된 RSA로 암호화된 대칭키
}

#[frb]
pub fn create_secure_payload(
    text: String,
    private_key_pem: String,
    public_key_pem: String
) -> Result<EncryptedMessage, String> {
    // Step 1: Sign the text with the private key using the existing sign function
    let signature_base64 = sign(&text, &private_key_pem)?;

    // Step 2: Create and serialize the JSON object
    let payload_and_signature = PayloadAndSignature {
        payload: text,
        signature: signature_base64,
    };

    let serialized = serde_json::to_string(&payload_and_signature)
        .map_err(|e| format!("Failed to serialize JSON: {}", e))?;

    // Step 3: Generate a symmetric key
    let symmetric_key = generate_symmetric_key();

    // Step 4: Encrypt the JSON string with the symmetric key
    let (encrypted_payload, iv) = encrypt(&serialized, symmetric_key.clone())
        .map_err(|e| format!("Failed to encrypt payload: {}", e))?;

    // Step 5: Encrypt the symmetric key with the recipient's public key
    let public_key = RsaPublicKey::from_public_key_pem(&public_key_pem)
        .map_err(|e| format!("Failed to parse public key: {}", e))?;

    let encrypted_symmetric_key = public_key
        .encrypt(&mut OsRng, pkcs1v15::Pkcs1v15Encrypt, &symmetric_key)
        .map_err(|e| format!("Failed to encrypt symmetric key: {}", e))?;

    // Step 6: Encode all binary data to Base64
    let encrypted_payload_base64 = base64::encode(encrypted_payload);
    let iv_base64 = base64::encode(iv);
    let symmetric_key_base64 = base64::encode(encrypted_symmetric_key);

    // Step 7: Return the final structure
    Ok(EncryptedMessage {
        encrypted_payload: encrypted_payload_base64, // Base64로 인코딩된 암호화된 데이터
        iv: iv_base64,                               // Base64로 인코딩된 IV
        symmetric_key: symmetric_key_base64,         // Base64로 인코딩된 대칭키
    })

}

#[frb]
pub fn verify_and_decrypt_payload(
    encrypted_message: EncryptedMessage,
    recipient_private_key_pem: String,
    sender_public_key_pem: String,
) -> Result<String, String> {
    // Step 1: Base64 디코딩
    let encrypted_payload = base64::decode(&encrypted_message.encrypted_payload)
        .map_err(|e| format!("Failed to decode encrypted payload: {}", e))?;
    let iv = base64::decode(&encrypted_message.iv)
        .map_err(|e| format!("Failed to decode IV: {}", e))?;
    let encrypted_symmetric_key = base64::decode(&encrypted_message.symmetric_key)
        .map_err(|e| format!("Failed to decode symmetric key: {}", e))?;

    // Step 2: 수신자의 비밀키로 대칭키 복호화
    let recipient_private_key = RsaPrivateKey::from_pkcs8_pem(&recipient_private_key_pem)
        .map_err(|e| format!("Failed to parse recipient private key: {}", e))?;
    let symmetric_key = recipient_private_key
        .decrypt(pkcs1v15::Pkcs1v15Encrypt, &encrypted_symmetric_key)
        .map_err(|e| format!("Failed to decrypt symmetric key: {}", e))?;

    // Step 3: 대칭키를 사용해 암호화된 payload 복호화
    let decrypted_payload = decrypt(encrypted_payload, symmetric_key, iv)
        .map_err(|e| format!("Failed to decrypt payload: {}", e))?;

    // Step 4: 복호화된 JSON에서 payload와 signature 추출
    let payload_and_signature: PayloadAndSignature = serde_json::from_str(&decrypted_payload)
        .map_err(|e| format!("Failed to parse decrypted JSON: {}", e))?;

    let payload = payload_and_signature.payload;
    let signature = payload_and_signature.signature;

    // Step 5: 보낸 사람의 공개키로 서명 검증
    let is_valid = verify_signature(&signature, &payload, &sender_public_key_pem)
        .map_err(|e| format!("Signature verification failed: {}", e))?;

    if !is_valid {
        return Err("Signature is invalid.".to_string());
    }

    // Step 6: 복호화된 payload 반환
    Ok(payload)
}
