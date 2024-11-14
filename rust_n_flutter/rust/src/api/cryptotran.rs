use std::fs::File;
use std::io::Write;
use std::path::Path;
use rsa::{pkcs1v15, RsaPrivateKey, RsaPublicKey};
use rsa::pkcs8::{EncodePrivateKey, EncodePublicKey};
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
pub fn sign(orig_text: &str, private_key_pem: &str) -> Result<String, String> {
    let private_key = RsaPrivateKey::from_pkcs8_pem(private_key_pem)
        .map_err(|e| e.to_string())?;

    let mut hasher = Sha256::new();
    hasher.update(orig_text.as_bytes());
    let hashed = hasher.finalize();

    let padding = pkcs1v15::Pkcs1v15Sign::new::<Sha256>();
    let signature = private_key
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