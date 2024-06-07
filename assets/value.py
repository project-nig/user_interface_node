#from Crypto.Hash import RIPEMD160, SHA256
import Crypto as Crypto


def calculate_hash(data, hash_function: str = "sha256") -> str:
    data = bytearray(data, "utf-8")
    if hash_function == "sha256":
        h = Crypto.Hash.SHA256.new()
        h.update(data)
        return h.hexdigest()
    if hash_function == "ripemd160":
        h = Crypto.Hash.RIPEMD160.new()
        h.update(data)
        return h.hexdigest()

#data="khkhkhkhkhkmsmdpzdlzdlsdsqmdsxq"
print(calculate_hash(data))
#print(TEST_VALUE,TEST_VALUE2)