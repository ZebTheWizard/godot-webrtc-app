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
	var hashStr = hashContext.finish()

	return hashStr.hex_encode()

func GenerateUUID() -> String:
	var crypto = Crypto.new()
	var bytes = crypto.generate_random_bytes(16)

	bytes[6] = (bytes[6] & 0x0f) | 0x40
	bytes[8] = (bytes[8] & 0x3f) | 0x80

	var hex = bytes.hex_encode()

	return "%s-%s-%s-%s-%s" % [
		hex.substr(0, 8),
		hex.substr(8, 4),
		hex.substr(12, 4),
		hex.substr(16, 4),
		hex.substr(20, 12)
	]
