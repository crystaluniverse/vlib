module jwt

import crypto.hmac
import crypto.sha256
import encoding.base64
import json
import x.json2
import time
import crypto.rand
import os

// JWT code in this page is from
// https://github.com/vlang/v/blob/master/examples/vweb_orm_jwt/src/auth_services.v
// credit to https://github.com/enghitalo

pub struct JsonWebToken {
	JwtHeader
	JwtPayload
}

struct JwtHeader {
	alg string
	typ string
}

// TODO: refactor to use single JWT interface
// todo: we can name these better
pub struct JwtPayload {
pub:
	sub  string    // (subject)
	iss  string    // (issuer)
	exp  time.Time // (expiration)
	iat  time.Time // (issued at)
	aud  string    // (audience)
	data string
}

// creates jwt with encoded payload and header
// DOESN'T handle data encryption, sensitive data should be encrypted
pub fn create_token(payload_ JwtPayload) JsonWebToken {
	return JsonWebToken{
		JwtHeader: JwtHeader{'HS256', 'JWT'}
		JwtPayload: JwtPayload{
			...payload_
			iat: time.now()
		}
	}
}

pub fn create_secret() string {
	bytes := rand.bytes(64) or { panic('Creating JWT Secret: ${err}') }
	return bytes.bytestr()
}

pub fn (token JsonWebToken) sign(secret string) string {
	header := base64.url_encode(json.encode(token.JwtHeader).bytes())
	payload := base64.url_encode(json.encode(token.JwtPayload).bytes())
	signature := base64.url_encode(hmac.new(secret.bytes(), '${header}.${payload}'.bytes(),
		sha256.sum, sha256.block_size).bytestr().bytes())
	return '${header}.${payload}.${signature}'
}

pub fn (token JsonWebToken) is_expired() bool {
	return token.exp <= time.now()
}

pub type SignedJWT = string

pub fn (token SignedJWT) is_valid() bool {
	return token.count('.') == 2
}

pub fn (token SignedJWT) verify(secret string) !bool {
	if !token.is_valid() {
		return error('Token `${token}` is not valid')
	}
	signature_mirror := hmac.new(secret.bytes(), token.all_before_last('.').bytes(), sha256.sum,
		sha256.block_size).bytestr().bytes()
	signature_token := base64.url_decode(token.all_after_last('.'))
	return hmac.equal(signature_token, signature_mirror)
}

// gets cookie token, returns user obj
pub fn (token SignedJWT) decode() !JsonWebToken {
	if !token.is_valid() {
		return error('Token `${token}` is not valid')
	}
	header_urlencoded := token.split('.')[0]
	header_json := base64.url_decode(header_urlencoded).bytestr()
	header := json.decode(JwtHeader, header_json) or { panic('Decode header: ${err}') }
	payload_urlencoded := token.split('.')[1]
	payload_json := base64.url_decode(payload_urlencoded).bytestr()
	payload := json.decode(JwtPayload, payload_json) or { panic('Decoding payload: ${err}') }
	return JsonWebToken{
		JwtHeader: header
		JwtPayload: payload
	}
}

// gets cookie token, returns user obj
pub fn (token SignedJWT) get_field(field string) !string {
	if !token.is_valid() {
		return error('Token `${token}` is not valid')
	}
	header_urlencoded := token.split('.')[0]
	header_json := base64.url_decode(header_urlencoded).bytestr()
	header := json.decode(JwtHeader, header_json) or { panic('Decode header: ${err}') }
	payload_urlencoded := token.split('.')[1]
	payload_json := base64.url_decode(payload_urlencoded).bytestr()
	payload_raw := json2.raw_decode(payload_json) or { panic('Decoding payload: ${err}') }
	payload_map := payload_raw.as_map()
	return payload_map[field].str()
}

// gets cookie token, returns user obj
pub fn (token SignedJWT) decode_subject() !string {
	decoded := token.decode()!
	return decoded.sub
}

// verifies jwt cookie
pub fn verify_jwt(token string) bool {
	if token == '' {
		return false
	}
	secret := os.getenv('SECRET_KEY')
	token_split := token.split('.')

	signature_mirror := hmac.new(secret.bytes(), '${token_split[0]}.${token_split[1]}'.bytes(),
		sha256.sum, sha256.block_size).bytestr().bytes()

	signature_from_token := base64.url_decode(token_split[2])

	return hmac.equal(signature_from_token, signature_mirror)
}

// verifies jwt cookie
// todo: implement assymetric verification
pub fn verify_jwt_assymetric(token string, pk string) bool {
	return false
}

// gets cookie token, returns user obj
pub fn get_data(token string) !string {
	if token == '' {
		return error('Failed to decode token: token is empty')
	}
	payload := json.decode(JwtPayload, base64.url_decode(token.split('.')[1]).bytestr()) or {
		panic(err)
	}
	return payload.data
}

// gets cookie token, returns user obj
pub fn get_payload(token string) !JwtPayload {
	if token == '' {
		return error('Failed to decode token: token is empty')
	}
	encoded_payload := base64.url_decode(token.split('.')[1]).bytestr()
	return json.decode(JwtPayload, encoded_payload)!
}

// // gets cookie token, returns access obj
// pub fn get_access(token string, username string) ?Access {
// 	if token == '' {
// 		return error('Cookie token is empty')
// 	}
// 	payload := json.decode(AccessPayload, base64.url_decode(token.split('.')[1]).bytestr()) or {
// 		panic(err)
// 	}
// 	if payload.user != username {
// 		return error('Access cookie is for different user')
// 	}
// 	return payload.access
// }
