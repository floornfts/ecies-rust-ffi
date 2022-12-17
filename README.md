# ecies-rust-ffi
A Rust Foreign Function Interface (FFI) crypto framework to C-based libraries e.g `.a`, `.dylib`, `.xcframework` etc

This module uses the Elliptic Curve Integrated Encryption Scheme (ECIES)

## Summary
### Generate a private key
```
// Rust ffi
#[no_mangle]
pub unsafe extern "C" fn ecies_generate_secret_key() -> *const c_char

// C-header
const char *ecies_generate_secret_key(void);
```
### Generate a public key from a secret key
```
// Rust ffi
#[no_mangle]
pub unsafe extern "C" fn ecies_public_key_from(secret_key_ptr: *const c_char) -> *const c_char 

// C-header
const char *ecies_public_key_from(const char *secret_key_ptr);
```
### Encrypt a message using a public key
```
// Rust ffi
#[no_mangle]
pub unsafe extern "C" fn ecies_encrypt(public_key_ptr: *const c_char, message_ptr: *const c_char) -> *const c_char  

// C-header
const char *ecies_encrypt(const char *public_key_ptr, const char *message_ptr);
```

### Decrypt a message using a secret key
```
// Rust ffi
#[no_mangle]
pub unsafe extern "C" fn ecies_decrypt(secret_key_ptr: *const c_char, message_ptr: *const c_char) -> *const c_char

// C-header
const char *ecies_decrypt(const char *secret_key_ptr, const char *message_ptr);
```

### Swift Example
```
enum CryptoError: Error {
    case encryptionFailure
    case decryptionFailure
}

func generatePrivateKey() -> String {
    String(cString: ecies_generate_secret_key())
}

func publicKey(from privateKey: String) -> String {
    let privateKey: NSString = privateKey as NSString
    let privateKeyBytes = UnsafeMutablePointer(mutating: privateKey.utf8String)
    
    return String(cString: ecies_public_key_from(privateKeyBytes))
}

func encrypt(_ message: String, publicKey: String) throws -> String {
    let message: NSString = message as NSString
    let publicKey: NSString = publicKey as NSString
    let messageBytes = UnsafeMutablePointer(mutating: message.utf8String)
    let publicKeyBytes = UnsafeMutablePointer(mutating: publicKey.utf8String)

    guard let encryptedText = ecies_encrypt(publicKeyBytes, messageBytes) else {
        throw CryptoError.encryptionFailure
    }
    
    return String(cString: encryptedText)
}

func decrypt(_ message: String, privateKey: String) throws -> String {
    let message: NSString = message as NSString
    let privateKey: NSString = privateKey as NSString
    let messageBytes = UnsafeMutablePointer(mutating: message.utf8String)
    let privateKeyBytes = UnsafeMutablePointer(mutating: privateKey.utf8String)
    
    guard let decryptedText = ecies_decrypt(privateKeyBytes, messageBytes) else {
        throw CryptoError.decryptionFailure
    }
    
    return String(cString: decryptedText)
}
