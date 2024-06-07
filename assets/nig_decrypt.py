#parameter management
action=action_raw
account=account_raw
pin_encrypted=pin_encrypted_raw
account_private_key=account_private_key_raw
requester_public_key_hex=requester_public_key_hex_raw
mp_details=mp_details_raw


from Crypto.Hash import RIPEMD160, SHA256
import Crypto as Crypto
import Crypto.PublicKey.RSA as RSA
#import Crypto.Hash.SHA256 as SHA256
import Crypto.Hash.RIPEMD160 as RIPEMD160
import Crypto.Signature.pkcs1_15 as pkcs1_15
import Crypto.Cipher.PKCS1_v1_5 as Cipher_PKCS1_v1_5
#from Crypto.PublicKey import RSA
import datetime
import binascii
import json
import random
import binascii
import math

def calculate_hash(data, hash_function: str = "sha256") -> str:
    data = bytearray(data, "utf-8")
    if hash_function == "sha256":
        h = Crypto.Hash.SHA256.new()
        h.update(data)
        return h.hexdigest()
    if hash_function == "ripemd160":
        h = RIPEMD160.new()
        h.update(data)
        return h.hexdigest()

class Owner:
    def __init__(self, private_key: str = ""):
        if private_key:
            self.private_key = RSA.importKey(private_key)
        else:
            self.private_key = RSA.generate(2048)
        public_key = self.private_key.publickey().export_key("DER")
        #self.private_key_str = self.private_key.publickey().export_key()
        self.private_key_str = self.private_key.export_key()
        self.public_key_hex = binascii.hexlify(public_key).decode("utf-8")
        self.public_key_hash = calculate_hash(calculate_hash(self.public_key_hex, hash_function="sha256"),
                                              hash_function="ripemd160")

class TransactionAccount:
    def __init__(self, name: str, iban: str, bic: str, email: str, phone: str, country: str, public_key_hash: str, *args, **kwargs):
        self.name = name
        self.iban = iban
        self.bic = bic
        self.email = email
        self.phone = phone
        self.country = country
        self.public_key_hash = public_key_hash
        self.pin=kwargs.get('pin',random.randint(1000, 9999))

    def to_json(self) -> str:
        return json.dumps(self.to_dict())
    def to_json_part1(self) -> str:
        return json.dumps(self.to_dict_part1())
    def to_json_part2(self) -> str:
        return json.dumps(self.to_dict_part2())

    def to_dict(self) -> dict:
        return {
            "name": self.name,
            "iban": self.iban,
            "bic": self.bic,
            "email": self.email,
            "phone": self.phone,
            "country": self.country,
            "public_key_hash": self.public_key_hash,
            "pin": self.pin
        }

    def to_dict_part1(self) -> dict:
        return {
            "iban": self.iban,
            "bic": self.bic,
            "email": self.email,
            "public_key_hash": self.public_key_hash,
        }
    def to_dict_part2(self) -> dict:
        return {
            "name": self.name,
            "phone": self.phone,
            "country": self.country,
            "pin": self.pin
        }

    def encrypt(self,requester_public_key_hex,sender_private_key):
        #Step 1 encryption of account with requester_public_key_hex
        key1 = RSA.importKey(binascii.unhexlify(requester_public_key_hex))
        cipher1 = Cipher_PKCS1_v1_5.new(key1)
        account_data_part1 = self.to_json_part1()
        account_data_part2 = self.to_json_part2()
        #Step 2 encryption of pin with sender_public_key_hex
        #key2 = RSA.importKey(binascii.unhexlify(sender_private_key))
        key2 = sender_private_key
        pin_data = self.pin
        cipher2 = Cipher_PKCS1_v1_5.new(key2)
        return cipher1.encrypt(account_data_part1.encode()).hex()+" "+cipher1.encrypt(account_data_part2.encode()).hex()+" "+cipher2.encrypt(str(pin_data).encode()).hex()


def decrypt_account(account_encrypted_part1,account_encrypted_part2,private_key):
    key = RSA.importKey(private_key)
    decipher = Cipher_PKCS1_v1_5.new(key)
    account_decrypted_part1=decipher.decrypt(bytes.fromhex(account_encrypted_part1), None).decode()
    account_decrypted_data_part1 = json.loads(account_decrypted_part1.strip())
    account_decrypted_part2=decipher.decrypt(bytes.fromhex(account_encrypted_part2), None).decode()
    account_decrypted_data_part2 = json.loads(account_decrypted_part2.strip())
    return TransactionAccount(account_decrypted_data_part2['name'],
                              account_decrypted_data_part1['iban'],
                              account_decrypted_data_part1['bic'],
                              account_decrypted_data_part1['email'],
                              account_decrypted_data_part2['phone'],
                              account_decrypted_data_part2['country'],
                              account_decrypted_data_part1['public_key_hash'],
                              pin=account_decrypted_data_part2['pin']).to_dict()

def decrypt_pin(pin_encrypted,private_key):
    key = RSA.importKey(private_key)
    decipher = Cipher_PKCS1_v1_5.new(key)
    pin_decrypted=decipher.decrypt(bytes.fromhex(pin_encrypted), None).decode()
    return pin_decrypted


decrypted_account=None
sender_wallet=Owner(private_key=account_private_key)

content_dict={}

if action=="account":
    account_encrypted_part1=account.split(" ")[0]
    account_encrypted_part2=account.split(" ")[1]
    if account_encrypted_part1 is not None and account_encrypted_part2 is not None:
        #decrypted_account=decrypt_account(account_encrypted_part1,account_encrypted_part2,sender_wallet.private_key)
        decrypted_account=decrypt_account(account_encrypted_part1,account_encrypted_part2,account_private_key)
        
    content_dict['decrypted_account']=decrypted_account
    

if action=="pin":
    decrypted_pin=decrypt_pin(pin_encrypted,account_private_key)  
    
    content_dict['decrypted_pin']=decrypted_pin

if action=="account_creation":
    account=Owner(None)
    content_dict["private_key_str"]=account.private_key_str.decode('utf8').replace("'", '"')
    content_dict["public_key_hex"]=account.public_key_hex
    content_dict["public_key_hash"]=account.public_key_hash


if action=="account_encryption":
    transaction_account=TransactionAccount("Banque Postale","FR03 2145 1212 1806 5635 9G45 723","ZSGTRGRPPGRF","james@bond.com","0612653689","France",sender_wallet.public_key_hash)
    content_dict["encrypted_account"]=transaction_account.encrypt(requester_public_key_hex,sender_wallet.private_key)
    

if action=="signature_generation":
    transaction_bytes = json.dumps(mp_details, indent=2).encode('utf-8')
    #transaction_bytes = str(mp_details).encode('utf-8')
    #transaction_bytes = json.dumps({'timestamp': 1683697950.437976, 'buyer_public_key_hash': '94bcf3579ad18be0e5fda58d0b17be524081bedf', 'requested_amount': 10.0, 'mp_request_id': 59857608, 'seller_public_key_hex': '30820122300d06092a864886f70d01010105000382010f003082010a0282010100afdd79279f6cedb4c491b81b9fde41f4ef69de9f40db289ab603e7dcff5e19662842de940c0d89eb74aa53c8d47db9a6c814746c71826eb4086f09dff2b365b3c99d1ebf15297a9933aec92d1c87a7daef9514e721e192c3eaf167a8c9854a675e39b78b9fafc1d1530f53a7061c2f6b4d51978ea7aa69ed62c602bfcbd803ad8cd3267b4d5bc6afe3833c83bb7f6c7ca5dbde165101166c83ee85bab466f9f254da39a643f40b18b1606b1f8139fcd24fa85a504a48e47d614af8c9bde160594ddfd2cee7299c30879cfe7b660c29a177dee24c33fcd2601a80b70723838d33a4543671075d8f7742c5f4eb363b7d7886be54f3d3de3731955793ee1cad85230203010001'}, indent=2).encode('utf-8')
    #transaction_bytes = json.dumps({'buyer_public_key_hash':'cf30719302f7759aec406fca0874512e267ce3d6','mp_request_id':38093854,'requested_amount':10.0,'timestamp':1683729508.456698,'seller_public_key_hex':'30820122300d06092a864886f70d01010105000382010f003082010a0282010100afdd79279f6cedb4c491b81b9fde41f4ef69de9f40db289ab603e7dcff5e19662842de940c0d89eb74aa53c8d47db9a6c814746c71826eb4086f09dff2b365b3c99d1ebf15297a9933aec92d1c87a7daef9514e721e192c3eaf167a8c9854a675e39b78b9fafc1d1530f53a7061c2f6b4d51978ea7aa69ed62c602bfcbd803ad8cd3267b4d5bc6afe3833c83bb7f6c7ca5dbde165101166c83ee85bab466f9f254da39a643f40b18b1606b1f8139fcd24fa85a504a48e47d614af8c9bde160594ddfd2cee7299c30879cfe7b660c29a177dee24c33fcd2601a80b70723838d33a4543671075d8f7742c5f4eb363b7d7886be54f3d3de3731955793ee1cad85230203010001'}, indent=2).encode('utf-8')
    #transaction_bytes = json.dumps({'timestamp': 1683729508.456698, 'buyer_public_key_hash': 'cf30719302f7759aec406fca0874512e267ce3d6', 'requested_amount': 10.0, 'mp_request_id': 38093854, 'seller_public_key_hex': '30820122300d06092a864886f70d01010105000382010f003082010a0282010100afdd79279f6cedb4c491b81b9fde41f4ef69de9f40db289ab603e7dcff5e19662842de940c0d89eb74aa53c8d47db9a6c814746c71826eb4086f09dff2b365b3c99d1ebf15297a9933aec92d1c87a7daef9514e721e192c3eaf167a8c9854a675e39b78b9fafc1d1530f53a7061c2f6b4d51978ea7aa69ed62c602bfcbd803ad8cd3267b4d5bc6afe3833c83bb7f6c7ca5dbde165101166c83ee85bab466f9f254da39a643f40b18b1606b1f8139fcd24fa85a504a48e47d614af8c9bde160594ddfd2cee7299c30879cfe7b660c29a177dee24c33fcd2601a80b70723838d33a4543671075d8f7742c5f4eb363b7d7886be54f3d3de3731955793ee1cad85230203010001'}, indent=2).encode('utf-8')
    hash_object = SHA256.new(transaction_bytes)
    signature = pkcs1_15.new(sender_wallet.private_key).sign(hash_object)
    content_dict['mp_details']=str(mp_details)
    #content_dict["mp_details"]=str(mp_details)
    content_dict['mp_request_signature']=binascii.hexlify(signature).decode("utf-8")

print(json.dumps(content_dict))