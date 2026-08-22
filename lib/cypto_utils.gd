extends RefCounted
class_name  CryptoUtils

func GenerateSalt(length = 32):
	var crypto = Crypto.new()
	return crypto.generate_random_bytes(length).hex_encode()
	
func HashPassword(password):
	var passwordData = password.to_utf8_buffer()
	var salt = DotEnv.get_env('APP_KEY')
	var saltData = salt.to_utf8_buffer()
	
	var combinedData = passwordData + saltData
	var hashContext = HashingContext.new()
	hashContext.start(HashingContext.HASH_SHA256)
	hashContext.update(combinedData)
	var hash = hashContext.finish()
	
	return hash.hex_encode() 
	
