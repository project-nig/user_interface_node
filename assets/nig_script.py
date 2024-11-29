#parameter management
action=action_raw
transaction_amount=transaction_amount_raw
receiver_public_key_hash=receiver_public_key_hash_raw
requester_public_key_hash=requester_public_key_hash_raw
requester_public_key_hex=requester_public_key_hex_raw
account_temp_input=account_temp_input_raw
account_temp_output=account_temp_output_raw
requested_amount=requested_amount_raw
utxo_json=utxo_json_raw
utxo_json_marketplace=utxo_json_marketplace_raw
timestamp_nig=timestamp_nig_raw
payment_ref=payment_ref_raw
requested_nig=requested_nig_raw
requested_currency=requested_currency_raw
requested_deposit=requested_deposit_raw
private_key=private_key_raw

smart_contract_account=smart_contract_account_raw
smart_contract_sender=smart_contract_sender_raw
smart_contract_new=smart_contract_new_raw
smart_contract_flag=smart_contract_flag_raw
smart_contract_gas=smart_contract_gas_raw
smart_contract_memory=smart_contract_memory_raw
smart_contract_memory_size=smart_contract_memory_size_raw
smart_contract_type=smart_contract_type_raw
smart_contract_payload=smart_contract_payload_raw
smart_contract_result=smart_contract_result_raw
smart_contract_previous_transaction=smart_contract_previous_transaction_raw
smart_contract_transaction_hash=smart_contract_transaction_hash_raw

seller_public_key_hash=seller_public_key_hash_raw

smart_contract_ref=smart_contract_ref_raw

NUMBER_OF_LEADING_ZEROS = NUMBER_OF_LEADING_ZEROS_raw
BLOCK_REWARD = BLOCK_REWARD_raw
NETWORK_DEFAULT = NETWORK_DEFAULT_raw
ROUND_VALUE_DIGIT = ROUND_VALUE_DIGIT_raw
DEFAULT_TRANSACTION_FEE_PERCENTAGE = DEFAULT_TRANSACTION_FEE_PERCENTAGE_raw
INTERFACE_TRANSACTION_FEE_SHARE = INTERFACE_TRANSACTION_FEE_SHARE_raw
NODE_TRANSACTION_FEE_SHARE = NODE_TRANSACTION_FEE_SHARE_raw
MINER_TRANSACTION_FEE_SHARE = MINER_TRANSACTION_FEE_SHARE_raw
INTERFACE_BLOCK_REWARD_PERCENTAGE = INTERFACE_BLOCK_REWARD_PERCENTAGE_raw
NODE_BLOCK_REWARD_PERCENTAGE = NODE_BLOCK_REWARD_PERCENTAGE_raw
MINER_BLOCK_REWARD_PERCENTAGE = MINER_BLOCK_REWARD_PERCENTAGE_raw
EUR_NIG_VALUE_START_TIMESTAMP = EUR_NIG_VALUE_START_TIMESTAMP_raw
EUR_NIG_VALUE_START_CONVERSION_RATE = EUR_NIG_VALUE_START_CONVERSION_RATE_raw
EUR_NIG_VALUE_START_INCREASE_DAILY_PERCENTAGE = EUR_NIG_VALUE_START_INCREASE_DAILY_PERCENTAGE_raw
EUR_NIG_VALUE_START_INCREASE_HALVING_DAYS = EUR_NIG_VALUE_START_INCREASE_HALVING_DAYS_raw

INTERFACE_PUBLIC_KEY_HASH = INTERFACE_PUBLIC_KEY_HASH_raw
NODE_PUBLIC_KEY_HASH = NODE_PUBLIC_KEY_HASH_raw


#from Crypto.Hash import RIPEMD160, SHA256
import Crypto as Crypto
import Crypto.PublicKey.RSA as RSA
#import Crypto.Hash.SHA256 as SHA256
import Crypto.Hash.RIPEMD160 as RIPEMD160
import Crypto.Signature.pkcs1_15 as pkcs1_15
import Crypto.Cipher.PKCS1_v1_5 as Cipher_PKCS1_v1_5
#from Crypto.PublicKey import RSA
import datetime
import binascii
import random
import binascii
import math
import logging
import json


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

def clean_request(d: dict) -> dict:
    #this function is replacing the following value in Flask request
    # true => True
    # false => False
    # none => None
    return dict_replace_value(d)

def dict_replace_value(d: dict) -> dict:
    x = {}
    for k, v in d.items():
        if v=="true":v=True
        elif v=="false":v=False
        elif v=="none":v=None
        elif isinstance(v, dict):
            v = dict_replace_value(v)
        elif isinstance(v, list):
            v = list_replace_value(v)
        x[k] = v
    return x

def list_replace_value(l: list) -> list:
    x = []
    for e in l:
        if e=="true":v=True
        elif e=="false":v=False
        elif e=="none":v=None
        elif isinstance(e, list):
            e = list_replace_value(e)
        elif isinstance(e, dict):
            e = dict_replace_value(e)
        x.append(e)
    return x

class TransactionInput:
    def __init__(self, transaction_hash: str, output_index: int, unlocking_script: str = "", unlocking_public_key_hash: str = "", *args, **kwargs):
        self.transaction_hash = transaction_hash
        self.output_index = output_index
        self.unlocking_script = unlocking_script
        self.unlocking_public_key_hash = unlocking_public_key_hash
        self.network=kwargs.get('network',NETWORK_DEFAULT)
        self.marketplace_flag=kwargs.get('marketplace_flag',False)

    def to_json(self, with_unlocking_script: bool = True) -> str:
        return json.dumps(self.to_dict(with_unlocking_script))

    def to_dict(self, with_unlocking_script: bool = True):
        if with_unlocking_script:
            return {
                "transaction_hash": self.transaction_hash,
                "output_index": self.output_index,
                "unlocking_script": self.unlocking_script,
                "unlocking_public_key_hash": self.unlocking_public_key_hash,
                "network": self.network
            }
        else:
            return {
                "transaction_hash": self.transaction_hash,
                "output_index": self.output_index,
                "unlocking_public_key_hash": self.unlocking_public_key_hash,
                "network": self.network
            }



class TransactionOutput:
    def __init__(self, list_public_key_hash: bytes, amount: float, *args, **kwargs):
        '''Generate the output of the Transaction'''
        self.amount = normal_round(amount,ROUND_VALUE_DIGIT)
        account_temp=kwargs.get('account_temp',False)
        public_key_hash_str=list_public_key_hash[0]
        
        transfer_flag=kwargs.get('transfer_flag',False)
        marketplace_step=kwargs.get('marketplace_step',0)

        if account_temp is True or account_temp=="True" or account_temp=="true" or account_temp=="reputation_creation":
            #SmartContract transaction
            public_key_hash_str=''
            for public_key_hash in list_public_key_hash:
                public_key_hash_str+=" OP_SC "+public_key_hash
            self.locking_script = f"OP_DUP OP_HASH160 {marketplace_wallet.public_key_hash} OP_EQUAL_VERIFY OP_CHECKSIG{public_key_hash_str}"
            if account_temp=="reputation_creation":self.locking_script+=" OP_RE"

            if marketplace_step==15 or marketplace_step==2:
                #in marketplace_step 15 & 2, the marketplace contract needs to be deassociated from the SmartContract
                self.locking_script+=" OP_DEL_SC "+marketplace_wallet.public_key_hash

            if marketplace_step==99 or marketplace_step==98 or marketplace_step==66:
                #in marketplace_step 99, the marketplace request is cancelled so it needs to be archived
                #in marketplace_step 98, the marketplace request has expired so it needs to be archived
                #in marketplace_step 66, the marketplace request has a payment default so it needs to be archived
                self.locking_script+=" OP_DEL_SC "+marketplace_wallet.public_key_hash
                for public_key_hash in list_public_key_hash:
                    self.locking_script+=" OP_DEL_SC "+public_key_hash
        else:
            self.locking_script = f"OP_DUP OP_HASH160 {public_key_hash_str} OP_EQUAL_VERIFY OP_CHECKSIG"
        self.account=kwargs.get('encrypted_account',None)
        

        #if marketplace_step == 0 or marketplace_step == 1:self.network="marketplace"
        #else:self.network=kwargs.get('network',NETWORK_DEFAULT)
        self.network=kwargs.get('network',NETWORK_DEFAULT)

        #transaction fee management
        if marketplace_step==4 or marketplace_step==45 or transfer_flag is True:
            self.transaction_fee_percentage=DEFAULT_TRANSACTION_FEE_PERCENTAGE
        else:
            self.transaction_fee_percentage=0
        self.interface_public_key_hash=INTERFACE_PUBLIC_KEY_HASH
        self.node_public_key_hash=NODE_PUBLIC_KEY_HASH
        coinbase_transaction=kwargs.get('coinbase_transaction',False)
        remaing_transaction=kwargs.get('remaing_transaction',False)
        self.marketplace_transaction_flag=kwargs.get('marketplace_transaction_flag',False)
        self.smart_contract_transaction_flag=kwargs.get('smart_contract_transaction_flag',False)
        

        #smart contract management
        self.smart_contract_flag=kwargs.get('smart_contract_flag',None)
        if self.smart_contract_flag is not None:
            self.smart_contract_sender=kwargs.get('smart_contract_sender',None)
            self.smart_contract_new=kwargs.get('smart_contract_new',False)
            self.smart_contract_account=kwargs.get('smart_contract_account',None)
            self.smart_contract_gas=kwargs.get('smart_contract_gas',None)
            self.smart_contract_memory=kwargs.get('smart_contract_memory',None)
            self.smart_contract_memory_size=kwargs.get('smart_contract_memory_size',None)
            self.smart_contract_type=kwargs.get('smart_contract_type',None)
            self.smart_contract_payload=kwargs.get('smart_contract_payload',None)
            self.smart_contract_result=kwargs.get('smart_contract_result',None)
            self.smart_contract_previous_transaction=kwargs.get('smart_contract_previous_transaction',None)

        if marketplace_step==4 or transfer_flag is True and coinbase_transaction is False and remaing_transaction is False:
            self.fee_node = normal_round(amount*(float(self.transaction_fee_percentage)/100)*float(NODE_TRANSACTION_FEE_SHARE)/100,ROUND_VALUE_DIGIT)
            self.fee_interface = normal_round(amount*(float(self.transaction_fee_percentage)/100)*float(INTERFACE_TRANSACTION_FEE_SHARE)/100,ROUND_VALUE_DIGIT)
            self.fee_miner = normal_round(amount*(float(self.transaction_fee_percentage)/100)*float(MINER_TRANSACTION_FEE_SHARE)/100,ROUND_VALUE_DIGIT)
            self.amount=normal_round(amount-self.fee_node-self.fee_interface-self.fee_miner,ROUND_VALUE_DIGIT)
        else:
            #only marketplace_step from 0 to 3 included are free
            self.fee_node = 0
            self.fee_interface = 0
            self.fee_miner = 0
            self.amount=normal_round(amount,ROUND_VALUE_DIGIT)

        
    def to_json(self) -> str:
        return json.dumps(self.to_dict())

    def to_dict(self) -> dict:
        if self.smart_contract_flag is not None:
            return {
                "amount": self.amount,
                "locking_script": self.locking_script,
                "network": self.network,
                "account": self.account,
                "interface_public_key_hash": self.interface_public_key_hash,
                "node_public_key_hash": self.node_public_key_hash,
                "fee_interface": self.fee_interface,
                "marketplace_transaction_flag":self.marketplace_transaction_flag,
                "smart_contract_transaction_flag":self.smart_contract_transaction_flag,
                "fee_node": self.fee_node,
                "fee_miner": self.fee_miner,
                "smart_contract_sender": self.smart_contract_sender,
                "smart_contract_new": self.smart_contract_new,
                "smart_contract_account": self.smart_contract_account,
                "smart_contract_flag": self.smart_contract_flag,
                "smart_contract_gas": self.smart_contract_gas,
                "smart_contract_memory": self.smart_contract_memory,
                "smart_contract_memory_size": self.smart_contract_memory_size,
                "smart_contract_type": self.smart_contract_type,
                "smart_contract_payload": self.smart_contract_payload,
                "smart_contract_result": self.smart_contract_result,
                "smart_contract_previous_transaction": self.smart_contract_previous_transaction}
        else:
            return {
                "amount": self.amount,
                "locking_script": self.locking_script,
                "network": self.network,
                "account": self.account,
                "interface_public_key_hash": self.interface_public_key_hash,
                "node_public_key_hash": self.node_public_key_hash,
                "fee_interface": self.fee_interface,
                "fee_node": self.fee_node,
                "fee_miner": self.fee_miner
            }


class Owner:
    def __init__(self, private_key: str = ""):
        if private_key:
            self.private_key = RSA.importKey(private_key)
        else:
            self.private_key = RSA.generate(2048)
        public_key = self.private_key.publickey().export_key("DER")
        self.public_key_hex = binascii.hexlify(public_key).decode("utf-8")
        self.public_key_hash = calculate_hash(calculate_hash(self.public_key_hex, hash_function="sha256"),
                                              hash_function="ripemd160")
                

class Transaction:
    def __init__(self, inputs: [TransactionInput], outputs: [TransactionOutput]):
        self.timestamp = datetime.datetime.timestamp(datetime.datetime.utcnow())
        self.inputs = inputs
        self.outputs = outputs
        self.transaction_hash = self.get_transaction_hash()

    def get_transaction_hash(self) -> str:
        transaction_data = {
            "timestamp": self.timestamp,
            "inputs": [i.to_dict() for i in self.inputs],
            "outputs": [i.to_dict() for i in self.outputs]
        }
        transaction_bytes = json.dumps(transaction_data, indent=2)
        return calculate_hash(transaction_bytes)

    def sign_transaction_data(self, owner):
        transaction_dict = {"timestamp": self.timestamp,
                            "inputs": [tx_input.to_dict(with_unlocking_script=False) for tx_input in self.inputs],
                            "outputs": [tx_output.to_dict() for tx_output in self.outputs]}
        transaction_bytes = json.dumps(clean_request(transaction_dict), indent=2).encode('utf-8')
        hash_object = Crypto.Hash.SHA256.new(transaction_bytes)
        signature = pkcs1_15.new(owner.private_key).sign(hash_object)
        return signature

    def sign(self, owner):
        signature_hex = binascii.hexlify(self.sign_transaction_data(owner)).decode("utf-8")
        marketplace_signature_hex = binascii.hexlify(self.sign_transaction_data(marketplace_wallet)).decode("utf-8")
        for transaction_input in self.inputs:
            if transaction_input.marketplace_flag is False:transaction_input.unlocking_script = f"{signature_hex} {owner.public_key_hex}"
            else:transaction_input.unlocking_script = f"{marketplace_signature_hex} {marketplace_wallet.public_key_hex}"

    @property
    def transaction_data(self) -> dict:
        transaction_data = {
            "timestamp": self.timestamp,
            "inputs": [i.to_dict() for i in self.inputs],
            "outputs": [i.to_dict() for i in self.outputs],
            "transaction_hash": self.transaction_hash
        }
        return transaction_data


class TransactionOutput_readiness:
    def __init__(self, *args, **kwargs):
        self.list_public_key_hash=kwargs.get('list_public_key_hash',None) 
        self.network=kwargs.get('network',None)
        self.account_temp=kwargs.get('account_temp',None)
        self.marketplace_step=kwargs.get('marketplace_step',0)
        self.transfer_flag=kwargs.get('transfer_flag',False)
        self.requester_public_key_hash=kwargs.get('requester_public_key_hash',None)
        self.requested_amount=kwargs.get('requested_amount',None)
        self.requested_currency=kwargs.get('requested_currency',None)
        self.requested_nig=kwargs.get('requested_nig',None)
        self.timestamp_nig=kwargs.get('timestamp_nig',None)
        self.requester_public_key_hex=kwargs.get('requester_public_key_hex',None)
        self.payment_ref=kwargs.get('payment_ref',None)
        self.encrypted_account=kwargs.get('encrypted_account',None)
        self.marketplace_transaction_flag=kwargs.get('marketplace_transaction_flag',False)
        #Smart Contract
        self.smart_contract_account=kwargs.get('smart_contract_account',None)
        self.smart_contract_sender=kwargs.get('smart_contract_sender',None)
        self.smart_contract_new=kwargs.get('smart_contract_new',False)
        self.smart_contract_flag=kwargs.get('smart_contract_flag',None)
        self.smart_contract_gas=kwargs.get('smart_contract_gas',None)
        self.smart_contract_memory=kwargs.get('smart_contract_memory',None)
        self.smart_contract_memory_size=kwargs.get('smart_contract_memory_size',None)
        self.smart_contract_type=kwargs.get('smart_contract_type',None)
        self.smart_contract_payload=kwargs.get('smart_contract_payload',None)
        self.smart_contract_result=kwargs.get('smart_contract_result',None)
        self.smart_contract_previous_transaction=kwargs.get('smart_contract_previous_transaction',None)
        self.smart_contract_transaction_flag=kwargs.get('smart_contract_transaction_flag',None)
        

    def generate(self,amount):
        return TransactionOutput(list_public_key_hash=self.list_public_key_hash,
                                 amount=amount,
                                 network=self.network,
                                 account_temp=self.account_temp,
                                 transfer_flag=self.transfer_flag,
                                 marketplace_step=self.marketplace_step,
                                 requester_public_key_hash=self.requester_public_key_hash,
                                 requested_amount=self.requested_amount,
                                 requested_currency=self.requested_currency,
                                 requested_nig=self.requested_nig,
                                 timestamp_nig=self.timestamp_nig,
                                 requester_public_key_hex=self.requester_public_key_hex,
                                 payment_ref=self.payment_ref,
                                 encrypted_account=self.encrypted_account,
                                 marketplace_transaction_flag=self.marketplace_transaction_flag,
                                 smart_contract_account=self.smart_contract_account,
                                 smart_contract_sender=self.smart_contract_sender,
                                 smart_contract_new=self.smart_contract_new,
                                 smart_contract_flag=self.smart_contract_flag,
                                 smart_contract_gas=self.smart_contract_gas,
                                 smart_contract_memory=self.smart_contract_memory,
                                 smart_contract_memory_size=self.smart_contract_memory_size,
                                 smart_contract_type=self.smart_contract_type,
                                 smart_contract_payload=self.smart_contract_payload,
                                 smart_contract_result=self.smart_contract_result,
                                 smart_contract_previous_transaction=self.smart_contract_previous_transaction,
                                 smart_contract_transaction_flag=self.smart_contract_transaction_flag)

sender_wallet=Owner(private_key=private_key)
#marketplace_wallet=Owner(private_key=b'0\x82\x04\xa3\x02\x01\x00\x02\x82\x01\x01\x00\xe3\xd38\xc7\xa4g\x85QL7)9q\xed:WW\xfc^\x9e0B\xbc\x9c\xbauPK\xde^\xeeW\xc9\xccx\x85\x06\x04$%f*E\xd3 \xca#\xe5\xaa\xeb\x98\x9e\x17\x19\xf0d\xe6\xfe"\x8d\x9f\n1j\x06\xac\xd7\x08\xa5Sk\xb5\xcc\x1e\x0b\x83\x07\xee\x98H\xe0\x07)\xd5\xa1q\xf0\x0e*C^q\x9b\xe1\xda\x99\xd7\x03\x9d\x8c3\x1b\xf8i\'\nS{\x10K"\x8a\x91\x06\x1a\xda\x0b\xe7\x91\x8e\x8d\x88\xc8\xad\xad\xb0\xbe(#\x02ku\x1d\xb6=\x0b\x10\x1dqF\xf5\xb5\nF1a\x87z\xa3\x13\x0ei\xbe5\xd5\xf4\xebq\x07:@\xbd\x17f\xc4D\x07\t\xea\xe3\xc9\xf0\xbf\xbe\xedo\xa2\x83X3G!\xd4\x97\xb9\xf3\xd6\xc3\x1b\x9a%\x8f\xe1\xd8\x9f\xe3\xeb\xf5\xbf\xfa\xfc6\xe9\xfc\x8c\xbd\x82\xa5{\x9b\xec\x0eL\xea9\r\xf3z\x87\xd6\rX^\x80\x85Y\xab\xd8=\x81\xa2\xf2s~#\\\xe2\xfc\x0c\xde\xe6\x87p\xd9\x17\xbf\t=\n\xd5dV\x10\xb4\xf4#\x02\x03\x01\x00\x01\x02\x82\x01\x00\x17\x131\xde\x8dS\xcb\x88\x80E\x86\xaa\xe1\xfeJ\xeeEyHd\xbcHH\xcd\xeaX\x19\xd1\xbda\x9f\x16\xb6\xd7\xe6\r\xb9\xc8\xc4\x97\xccviK\xbe7\xf5\xbf\xd1zz\xf8>\xd3\x15?\xf0b%l\xc9\x02\xcc\x1e!\x89H_\x00\xa3\xbc\xe1?\xc8{\xeb\xack~\xf2\xc3\xf7e\xc6)\xf6s\x7f\xc9\x1f\x0e\xb0\x9c\xbf\x18\xed\x83\xa8\xc2\xeb!}j\x96w\xeaOT\x99\x17`k\x14$\xea\xa6R\xc0\xaf\x18\xf6\xfe\x8c\xd8\xd9"\x9c"r\x9e86[P\x0c\xde3\x0f\xef6\xf4nG\xa7\x81\xda\x87;Bu\xa4R\xba\xc3\xac\x14\x9a.\xff\xe6e\xd1\x00\xf2\xb0\xb6\x93\x87;\x94\xd3\rm\xbc\x18r\x85\xa9\'s\xb1\xa5\x7f\xb6\x8d\xa0\x81\xa3\xd3\xddM\xba\x94\xbfi\x93\xb5;w[\x8503\x82\xc25,\xa83\xfe\xd09\xe3\x16\xb6\x1b\xac~\x11\xa2QH\x1c\xd1\n!\x01p_\xe2\xae\xc8\xb7#\x10Nn\xf0%\x08&v\xcf\xa6\xcb~\xe8b\x1e\x1ek\xfc:\x95Ni\x02\x81\x81\x00\xe8\xb7\x9co6\xa3\xc7z\x90\xc7g\x11\nP&`P\xe9p\x19\'f%@\x1d\xdf\xd1\x08\x87XO\xb6Z\xc2$E-\x93b\x9c1\x0e\xc7\xf5\xb62$\xf9y\x16\x15q\n?\xa3\xa4d\x89\xbe\xa0\x13\xa3\xd7?\xcaj.\xebg\x15g&iK|\xad\x1e\xf7E\xcf"\xcd\xbe\xa3Q\x84O\xdc/3\x18\x8c\x18\x81\xf0\xe1\xd8\xec\xd6h\x98B,\x8c\xc0\x86\xcd_g\xb7;\x9b\xc8\xdb\xcc\xc9&\x02\x91\xad\xd6\xb7\x91\xfa\xf491\xc9\x02\x81\x81\x00\xfa\x9eO\xf67\xc3\x8d\x0f\xaf\xde\x04\x08\x06\x9c\xfb{\xbb\xf8\x7f\x07\xe48\x91\xce\xad\r\xd2]V(:\xf7\xbbY5\xab\xb5\x9c<\xd1\xe11\x96\xaf7}\r\xba\xbc`\xf9\x10=\xe7\x91\xfd/\xec\xd9\xe5|\x185~>y`\x14\x8e\xdb\xc2\xb0\xb9k\x88$6s\xefTD\x9f\x17w5Z\x90\x8f9\x19\xf4\x02\x10\x90;\x9b\x0c\xe4M\xfc\xda\x0c\xd1Wz7\x9amT#\xc9?\x89(Z\xe2UW\n\x7fw\xde\xd3CI\x85\x8c\x8b\x02\x81\x80e%\x08t\xbd\xc6\xc98X\x1c\x92\x8b1tLy\xa81\rk\xa1X\x1f\xf0\x92\x0bi\n\xcf\xe8n\x1c\xcf\xady\x9e\'\x84\xdbc\x0f_aAF\x02\xddW m\x9c\xbc\x18\xbc8\x1f\x87"\xe7\x1b#\xee\x1d\xeb\xb7\xca\x16\xc2qw7\xf1\xd5\xe9\xdd2Q7\x1f\xbc;`8\xef:\xca\xca\xfa\xe3\xf8\xcd>v\x98c]\x85\xae\xca1\x83\x9b\x9fI=\x94YF\x92\tmz\xf3\xfd\xb4/\xe8\xb9M\x1f\xc5&\xdb\xe7\xba\xa5\xf1!\x02\x81\x80\x01\x93U5[\x0cc\xaa\xa1\x94g\xba\x150\x8ft+\xaeX>\x18u2\x95v\t\x0c5\x82\x01&\xbd\xbf\xf3\xc3\x9e\x9c\xb9\xaa\xb87\x0e4\xc0M=\x00\x05\x18\x82\x13\x8e\xc2\x94\xde\x1a\x15_\x0b\xcf\xa1\x84\x15r\x01\xba\x89\x9c\x17y\xd23\x826\xe6\xd83oo%\xbcx\xb3\x91\x10H\xcdw\xd9\x08\x0c\xbc\xa6\x96\x01\x89\xeb\xfe\xd3n\xaf\x80= \xab\xa8\x05\xd4\x82\x1e\xe7x\xfa\xc7\xc2*\x82\x16\xd5\xfe\x0f&\xdbu$\xd5.\x19\x02\x81\x81\x00\xb4\x11z\xc7\x80\x0c\xc0\x04\t\xb7\xcc\tl<|\x02\xf0Rj\xd8\x19\xa8/\xdb\x04\xd9\xb4\xe2\xd9\x9aXXS\xe9hHm\x88\x83{\x9c\xc8\xf8+C\x15\xf2\xe6\xac\xf4\x96i\xcb<\xf7s\x17\x18\xcd0A\xb1E\xdb\x1e1U\xe6u\xeb\xca\xbb\x1e\xc60Y8\xb2\xf6_Do\x1b\x0c\xe8\xbf\xa4M\x19\xe1x\xe0o\x1b.\x00_>\x91\xfb\x9f\xaa3\xbc\x92HB\xa2@\x97G,\\h\xeecU\xc5\xe8}\xdb\x04\xd6\xe3\xb0\xc2\xe6\xfe')
marketplace_wallet=Owner(private_key='-----BEGIN RSA PRIVATE KEY-----\nMIIEowIBAAKCAQEA49M4x6RnhVFMNyk5ce06V1f8Xp4wQrycunVQS95e7lfJzHiF\nBgQkJWYqRdMgyiPlquuYnhcZ8GTm/iKNnwoxagas1wilU2u1zB4LgwfumEjgBynV\noXHwDipDXnGb4dqZ1wOdjDMb+GknClN7EEsiipEGGtoL55GOjYjIra2wvigjAmt1\nHbY9CxAdcUb1tQpGMWGHeqMTDmm+NdX063EHOkC9F2bERAcJ6uPJ8L++7W+ig1gz\nRyHUl7nz1sMbmiWP4dif4+v1v/r8Nun8jL2CpXub7A5M6jkN83qH1g1YXoCFWavY\nPYGi8nN+I1zi/Aze5odw2Re/CT0K1WRWELT0IwIDAQABAoIBABcTMd6NU8uIgEWG\nquH+Su5FeUhkvEhIzepYGdG9YZ8WttfmDbnIxJfMdmlLvjf1v9F6evg+0xU/8GIl\nbMkCzB4hiUhfAKO84T/Ie+usa37yw/dlxin2c3/JHw6wnL8Y7YOowushfWqWd+pP\nVJkXYGsUJOqmUsCvGPb+jNjZIpwicp44NltQDN4zD+829G5Hp4HahztCdaRSusOs\nFJou/+Zl0QDysLaThzuU0w1tvBhyhaknc7Glf7aNoIGj091NupS/aZO1O3dbhTAz\ngsI1LKgz/tA54xa2G6x+EaJRSBzRCiEBcF/irsi3IxBObvAlCCZ2z6bLfuhiHh5r\n/DqVTmkCgYEA6Lecbzajx3qQx2cRClAmYFDpcBknZiVAHd/RCIdYT7ZawiRFLZNi\nnDEOx/W2MiT5eRYVcQo/o6Rkib6gE6PXP8pqLutnFWcmaUt8rR73Rc8izb6jUYRP\n3C8zGIwYgfDh2OzWaJhCLIzAhs1fZ7c7m8jbzMkmApGt1reR+vQ5MckCgYEA+p5P\n9jfDjQ+v3gQIBpz7e7v4fwfkOJHOrQ3SXVYoOve7WTWrtZw80eExlq83fQ26vGD5\nED3nkf0v7NnlfBg1fj55YBSO28KwuWuIJDZz71REnxd3NVqQjzkZ9AIQkDubDORN\n/NoM0Vd6N5ptVCPJP4koWuJVVwp/d97TQ0mFjIsCgYBlJQh0vcbJOFgckosxdEx5\nqDENa6FYH/CSC2kKz+huHM+teZ4nhNtjD19hQUYC3VcgbZy8GLw4H4ci5xsj7h3r\nt8oWwnF3N/HV6d0yUTcfvDtgOO86ysr64/jNPnaYY12Frsoxg5ufST2UWUaSCW16\n8/20L+i5TR/FJtvnuqXxIQKBgAGTVTVbDGOqoZRnuhUwj3Qrrlg+GHUylXYJDDWC\nASa9v/PDnpy5qrg3DjTATT0ABRiCE47ClN4aFV8Lz6GEFXIBuomcF3nSM4I25tgz\nb28lvHizkRBIzXfZCAy8ppYBiev+026vgD0gq6gF1IIe53j6x8IqghbV/g8m23Uk\n1S4ZAoGBALQReseADMAECbfMCWw8fALwUmrYGagv2wTZtOLZmlhYU+loSG2Ig3uc\nyPgrQxXy5qz0lmnLPPdzFxjNMEGxRdseMVXmdevKux7GMFk4svZfRG8bDOi/pE0Z\n4XjgbxsuAF8+kfufqjO8kkhCokCXRyxcaO5jVcXofdsE1uOwwub+\n-----END RSA PRIVATE KEY-----')



def calculate_nig_rate(*args, **kwargs):
    timestamp=kwargs.get('timestamp',None)
    currency=kwargs.get('currency','eur').upper()
    NIG_VALUE_START_TIMESTAMP=EUR_NIG_VALUE_START_TIMESTAMP
    NIG_VALUE_START_CONVERSION_RATE=EUR_NIG_VALUE_START_CONVERSION_RATE
    NIG_VALUE_START_INCREASE_DAILY_PERCENTAGE=EUR_NIG_VALUE_START_INCREASE_DAILY_PERCENTAGE
    NIG_VALUE_START_INCREASE_HALVING_DAYS=EUR_NIG_VALUE_START_INCREASE_HALVING_DAYS
    if timestamp is not None:date_now=datetime.datetime.fromtimestamp(timestamp)
    else:date_now=datetime.datetime.utcnow()

    delta=date_now-datetime.datetime.fromtimestamp(float(NIG_VALUE_START_TIMESTAMP))
    delta_days=delta.days
    flag=True
    nig_rate_initial=float(NIG_VALUE_START_CONVERSION_RATE)
    nig_increase=1
    INCREASE_DAILY_PERCENTAGE=float(NIG_VALUE_START_INCREASE_DAILY_PERCENTAGE)
    HALVING_DAYS=float(NIG_VALUE_START_INCREASE_HALVING_DAYS)
    while flag is True:
        if delta_days<HALVING_DAYS:
            nig_increase=nig_increase*math.pow((float(INCREASE_DAILY_PERCENTAGE)/100)+1,delta_days)
            nig_rate=nig_rate_initial*nig_increase
            flag=False
        else:
            nig_increase=nig_increase*math.pow((float(INCREASE_DAILY_PERCENTAGE)/100)+1,HALVING_DAYS)
            delta_days-=HALVING_DAYS
            INCREASE_DAILY_PERCENTAGE=INCREASE_DAILY_PERCENTAGE/2    
    return nig_rate

def normal_round(num, ndigits=0):
    """
    Rounds a float to the specified number of decimal places.
    num: the value to round
    ndigits: the number of digits to round to
    """
    if ndigits == 0:
        return int(num + 0.5)
    else:
        digit_value = 10 ** ndigits
        return int(num * digit_value + 0.5) / digit_value

transaction_amount=normal_round(transaction_amount,ROUND_VALUE_DIGIT)
transaction_amount_init=transaction_amount

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
        import logging
        logging.info(f"============ PIN CODE: {self.pin}")
        return cipher1.encrypt(account_data_part1.encode()).hex()+" "+cipher1.encrypt(account_data_part2.encode()).hex()+" "+cipher2.encrypt(str(pin_data).encode()).hex()
    
def purchase_step_robot(sender_wallet,receiver_public_key_hash,transaction_amount,account_temp_input,account_temp_output, *args, **kwargs):
    #input_list pararemeter
    transaction_hash=kwargs.get('transaction_hash',None)
    output_index=kwargs.get('output_index',None)
    network=kwargs.get('network',NETWORK_DEFAULT)
    #output_list pararemeter
    amount=kwargs.get('amount',None)
    transfer_flag=kwargs.get('transfer_flag',False) 
    marketplace_step=kwargs.get('marketplace_step',0) 
    requester_public_key_hash=kwargs.get('requester_public_key_hash',None) 
    requested_amount=kwargs.get('requested_amount',None)
    requested_currency=kwargs.get('requested_currency',None)
    requested_nig=kwargs.get('requested_nig',None)
    timestamp_nig=kwargs.get('timestamp_nig',None)
    requester_public_key_hex=kwargs.get('requester_public_key_hex',None)
    payment_ref=kwargs.get('payment_ref',None)
    encrypted_account=kwargs.get('encrypted_account',None)
    #Smart Contract output_list pararemeter
    smart_contract_account=kwargs.get('smart_contract_account',None)
    smart_contract_sender=kwargs.get('smart_contract_sender',None)
    smart_contract_new=kwargs.get('smart_contract_new',False)
    smart_contract_flag=kwargs.get('smart_contract_flag',None)
    smart_contract_gas=kwargs.get('smart_contract_gas',None)
    smart_contract_memory=kwargs.get('smart_contract_memory',None)
    smart_contract_memory_size=kwargs.get('smart_contract_memory_size',None)
    smart_contract_type=kwargs.get('smart_contract_type',None)
    smart_contract_payload=kwargs.get('smart_contract_payload',None)
    smart_contract_result=kwargs.get('smart_contract_result',None)
    smart_contract_previous_transaction=kwargs.get('smart_contract_previous_transaction',None)
    smart_contract_transaction_hash=kwargs.get('smart_contract_transaction_hash',None)

    smart_contract_ref=kwargs.get('smart_contract_ref',"None")

    marketplace_transaction_flag=kwargs.get('marketplace_transaction_flag',False)
    utxo_json=kwargs.get('utxo_json',None)

    smart_contract_transaction_flag=False

    requested_deposit=kwargs.get('requested_deposit',None)


    

    #launch of the transaction
    input_list=[]
    output_list=[]
    if action=="smart_contract_creation" or action=="reputation_creation":utxo_json=[{'amount':0}]
    marketplace_step2_flag=False
    utxo_total=0
    for utxo in utxo_json:
        if marketplace_step==0 or marketplace_step==-1 or marketplace_step==1 or marketplace_step==15 or marketplace_step>=2 and utxo['amount']>0 or action=="transfer" or action=="smart_contract_creation" or action=="smart_contract_update" or action=="reputation_creation":
            if marketplace_step==1 or marketplace_step==15 or marketplace_step==2:
                if marketplace_step==15 and utxo_json_marketplace is None:
                    #in case of buyer without reputation, there is no utxo for the buyer 
                    #utxo is the utxo of the SmartContract so utxo_json_marketplace is None
                    unlocking_public_key_hash_value=marketplace_wallet.public_key_hash+" SC "+smart_contract_ref
                    marketplace_flag_value=True
                else:
                    unlocking_public_key_hash_value=sender_wallet.public_key_hash
                    marketplace_flag_value=False
                input_list.append(TransactionInput(transaction_hash=utxo['transaction_hash'],
                    output_index=utxo['output_index'],
                    unlocking_public_key_hash=unlocking_public_key_hash_value,
                    marketplace_flag=marketplace_flag_value,
                    network=network))
                
                if marketplace_step==15 and marketplace_step2_flag is False or marketplace_step==2 and marketplace_step2_flag is False:
                    if utxo_json_marketplace is not None:
                        input_list.append(TransactionInput(transaction_hash=utxo_json_marketplace['utxos'][0]['transaction_hash'],
                            output_index=utxo_json_marketplace['utxos'][0]['output_index'],
                            unlocking_public_key_hash=marketplace_wallet.public_key_hash+" SC "+smart_contract_ref,
                            network=network,
                            marketplace_flag=True))
                        marketplace_step2_flag=True
            else:
                #unlocking_public_key_hash=marketplace_wallet.public_key_hash,
                #smart_contract_ref 
                if action!="smart_contract_creation" and action!="reputation_creation":
                    if transfer_flag is True:unlocking_public_key_hash=sender_wallet.public_key_hash
                    else:unlocking_public_key_hash=marketplace_wallet.public_key_hash+" SC "+smart_contract_ref
                    input_list.append(TransactionInput(transaction_hash=utxo['transaction_hash'],
                                                       output_index=utxo['output_index'],
                                                       unlocking_public_key_hash=unlocking_public_key_hash,
                                                       network=network))
                if action=="smart_contract_creation" or action=="smart_contract_update" or action=="reputation_creation":
                    smart_contract_transaction_flag=True
            
            transactionoutput_obj=TransactionOutput_readiness(list_public_key_hash=[receiver_public_key_hash],
                                                                    network=network,
                                                                    account_temp=account_temp_output,
                                                                    transfer_flag=transfer_flag,
                                                                    marketplace_step=marketplace_step,
                                                                    requester_public_key_hash=requester_public_key_hash,
                                                                    requested_amount=requested_amount,
                                                                    requested_currency=requested_currency,
                                                                    requested_nig=requested_nig,
                                                                    timestamp_nig=timestamp_nig,
                                                                    requester_public_key_hex=requester_public_key_hex,
                                                                    payment_ref=payment_ref,
                                                                    encrypted_account=encrypted_account,
                                                                    smart_contract_account=smart_contract_account,
                                                                    smart_contract_sender=smart_contract_sender,
                                                                    smart_contract_new=smart_contract_new,
                                                                    smart_contract_flag=smart_contract_flag,
                                                                    smart_contract_gas=smart_contract_gas,
                                                                    smart_contract_memory=smart_contract_memory,
                                                                    smart_contract_memory_size=smart_contract_memory_size,
                                                                    smart_contract_type=smart_contract_type,
                                                                    smart_contract_payload=smart_contract_payload,
                                                                    smart_contract_result=smart_contract_result,
                                                                    smart_contract_previous_transaction=smart_contract_previous_transaction,
                                                                    marketplace_transaction_flag=marketplace_transaction_flag,
                                                                    smart_contract_transaction_flag=smart_contract_transaction_flag)

            if float(utxo['amount'])>=float(transaction_amount):
                #only one utxo is sufficient
                utxo_total+=utxo['amount']
                if marketplace_step==4:
                    #for marketplace_step 4, the SmartContract is sent only to the smart_contract_ref with a zero amount
                    transactionoutput_obj.list_public_key_hash=[smart_contract_ref]
                    #output_list.append(transactionoutput_obj.generate(utxo['amount']-transaction_amount))
                    output_list.append(transactionoutput_obj.generate(0))
                    #for marketplace_step 4, a transaction without SmartContract is sent to the buyer for requested_nig + requested_deposit
                    transactionoutput_obj_step4_buyer=TransactionOutput_readiness(list_public_key_hash=[receiver_public_key_hash],
                                                                    network=network,
                                                                    account_temp=account_temp_output,
                                                                    transfer_flag=transfer_flag,
                                                                    marketplace_step=marketplace_step,
                                                                    requester_public_key_hash=requester_public_key_hash,
                                                                    requested_amount=requested_amount,
                                                                    requested_currency=requested_currency,
                                                                    requested_nig=requested_nig,
                                                                    timestamp_nig=timestamp_nig,
                                                                    requester_public_key_hex=requester_public_key_hex,
                                                                    payment_ref=payment_ref,
                                                                    encrypted_account=encrypted_account,
                                                                    marketplace_transaction_flag=marketplace_transaction_flag)
                    output_list.append(transactionoutput_obj_step4_buyer.generate(requested_nig+requested_deposit))
                    #for marketplace_step 4, a transaction without SmartContract is sent to seller_public_key_hash for transaction_amount - requested_nig
                    # marketplace_step = 0 to avoid transaction fee
                    transactionoutput_obj_step4_seller=TransactionOutput_readiness(list_public_key_hash=[seller_public_key_hash],
                                                                    network=network,
                                                                    account_temp=account_temp_output,
                                                                    transfer_flag=transfer_flag,
                                                                    marketplace_step=0,
                                                                    requester_public_key_hash=requester_public_key_hash,
                                                                    requested_amount=requested_amount,
                                                                    requested_currency=requested_currency,
                                                                    requested_nig=requested_nig,
                                                                    timestamp_nig=timestamp_nig,
                                                                    requester_public_key_hex=requester_public_key_hex,
                                                                    payment_ref=payment_ref,
                                                                    encrypted_account=encrypted_account)
                    #output_list.append(transactionoutput_obj_step4_requester.generate(transaction_amount-requested_nig))
                    #output_list.append(transactionoutput_obj_step4_seller.generate(utxo['amount']-requested_nig))
                    output_list.append(transactionoutput_obj_step4_seller.generate(transaction_amount-requested_nig))
                else:

                    if marketplace_step==15 or marketplace_step==2:
                        #requester and current wallet are public_key_hash to ensure that MasterState will have the SmartContract
                        transactionoutput_obj.list_public_key_hash.extend([requester_public_key_hash,sender_wallet.public_key_hash])
                        #the amount of the transaction is updated after by transaction_amount_init
                        output_list.append(transactionoutput_obj.generate(88888))
                        
                    elif transfer_flag is True:
                        output_list.append(transactionoutput_obj.generate(transaction_amount))  
                    else:
                        if marketplace_step==0 or marketplace_step==-1:
                            transactionoutput_obj.list_public_key_hash.extend([sender_wallet.public_key_hash,marketplace_wallet.public_key_hash])
                            output_list.append(transactionoutput_obj.generate(utxo['amount']))
                        elif marketplace_step==1:
                            transactionoutput_obj.list_public_key_hash.extend([sender_wallet.public_key_hash,marketplace_wallet.public_key_hash])
                            output_list.append(transactionoutput_obj.generate(transaction_amount))
                        elif action=="reputation_creation":
                            #transactionoutput_obj.list_public_key_hash.extend([sender_wallet.public_key_hash])
                            transactionoutput_obj.list_public_key_hash.extend([sender_wallet.public_key_hash,marketplace_wallet.public_key_hash])
                            output_list.append(transactionoutput_obj.generate(0))
                        else:
                            output_list.append(transactionoutput_obj.generate(utxo['amount']))
                        
                
                if marketplace_step!=3 and marketplace_step!=4 and action!="smart_contract_creation" and action!="smart_contract_update" and action!="reputation_creation":
                    #no needed in marketplace_step 3 and 4
                    if marketplace_step==15:
                        transaction_amount=transaction_amount_init
                        if float(utxo_total)-float(transaction_amount_init)>0:
                            output_list.append(TransactionOutput(list_public_key_hash=[sender_wallet.public_key_hash],
                                                                    transfer_flag=transfer_flag,
                                                                    amount=utxo_total-transaction_amount_init,
                                                                    remaing_transaction=True))

                    else:
                        if float(utxo['amount'])-float(transaction_amount)>0:
                            output_list.append(TransactionOutput(list_public_key_hash=[sender_wallet.public_key_hash],
                                                                transfer_flag=transfer_flag,
                                                                amount=utxo['amount']-transaction_amount,
                                                                remaing_transaction=True))
                #sender_wallet.process_transaction(inputs=input_list, outputs=output_list)
                transaction = Transaction(input_list, output_list)
                transaction.sign(sender_wallet)
                transaction_amount=0
                break
                

            else:
                #more than one utxo will be needed
                if marketplace_step==4 or transfer_flag is True:
                    #for marketplace_step 4, a transaction without SmartContract is sent to receiver_public_key_hash
                    transactionoutput_obj=TransactionOutput_readiness(list_public_key_hash=[receiver_public_key_hash],
                                                                    network=network,
                                                                    account_temp=account_temp_output,
                                                                    transfer_flag=transfer_flag,
                                                                    marketplace_step=marketplace_step,
                                                                    requester_public_key_hash=requester_public_key_hash,
                                                                    requested_amount=requested_amount,
                                                                    requested_currency=requested_currency,
                                                                    requested_nig=requested_nig,
                                                                    timestamp_nig=timestamp_nig,
                                                                    requester_public_key_hex=requester_public_key_hex,
                                                                    payment_ref=payment_ref,
                                                                    encrypted_account=encrypted_account,
                                                                    marketplace_transaction_flag=marketplace_transaction_flag)
                if transfer_flag is True:
                    if float(utxo['amount'])-float(transaction_amount)>=0:
                            output_list.append(TransactionOutput(list_public_key_hash=[sender_wallet.public_key_hash], 
                                                                 transfer_flag=transfer_flag,
                                                                 amount=(utxo['amount']-transaction_amount)))
                if marketplace_step==15:
                    utxo_total+=utxo['amount']
                
                transaction_amount-=float(utxo['amount'])


    if marketplace_step==1 or marketplace_step==15 or marketplace_step==2 or action=="transfer":
        output_list_checked=[]
        smart_contract_account_list=[]
        locking_script_list=[]
        locking_script_dict={}
        for transaction_output in output_list:
            if transaction_output.smart_contract_flag is not None:
                #this is a SmartContract
                #only one instance of SmartContract is keept
                if transaction_output.smart_contract_account not in smart_contract_account_list:
                    if marketplace_step==2:transaction_output.amount=normal_round(transaction_amount_init+utxo_json_marketplace['total'],ROUND_VALUE_DIGIT)
                    else:transaction_output.amount=normal_round(transaction_amount_init,ROUND_VALUE_DIGIT)
                    output_list_checked.append(transaction_output)
                    smart_contract_account_list.append(transaction_output.smart_contract_account)
            else:
                #this is not a SmartContract
                if transaction_output.locking_script not in locking_script_list:
                    locking_script_dict[transaction_output.locking_script]=transaction_output
                    locking_script_list.append(transaction_output.locking_script)
                    output_list_checked.append(transaction_output)
                else:
                    #only one instance of the transaction is kept with the sum of all the amount
                    transaction_output_temp=locking_script_dict[transaction_output.locking_script]
                    transaction_output_temp.amount+=normal_round(transaction_output.amount,ROUND_VALUE_DIGIT)

        output_list=output_list_checked


    transaction = Transaction(input_list, output_list)
    transaction.sign(sender_wallet)
    return transaction,transaction_amount

if action=="transfer":transaction,transaction_amount=purchase_step_robot(sender_wallet,receiver_public_key_hash,transaction_amount,account_temp_input,account_temp_output,transfer_flag=True,utxo_json=utxo_json)


if action=="purchase_step1_sell":
    #timestamp_nig=datetime.datetime.timestamp(datetime.datetime.utcnow())
    nig_rate=calculate_nig_rate(timestamp=timestamp_nig,currency="eur")
    #requested_nig=normal_round(requested_amount/nig_rate,ROUND_VALUE_DIGIT)

    receiver_public_key_hash=smart_contract_ref
    
    transaction,transaction_amount=purchase_step_robot(sender_wallet,receiver_public_key_hash,transaction_amount,account_temp_input,account_temp_output,
    marketplace_step=-1,requested_amount=requested_amount,timestamp_nig=timestamp_nig,nig_rate=nig_rate,requested_nig=requested_nig,requester_public_key_hash=requester_public_key_hash,requested_currency="eur",requester_public_key_hex=sender_wallet.public_key_hex,
    smart_contract_account=smart_contract_account,smart_contract_sender=smart_contract_sender,smart_contract_new=smart_contract_new,smart_contract_flag=smart_contract_flag,smart_contract_gas=smart_contract_gas,smart_contract_memory=smart_contract_memory,smart_contract_memory_size=smart_contract_memory_size
    ,smart_contract_type=smart_contract_type,smart_contract_payload=smart_contract_payload,smart_contract_result=smart_contract_result,smart_contract_previous_transaction=smart_contract_previous_transaction,smart_contract_transaction_hash=smart_contract_transaction_hash,smart_contract_ref=smart_contract_ref,marketplace_transaction_flag=True,utxo_json=utxo_json)

if action=="purchase_step1_buy":
    #timestamp_nig=datetime.datetime.timestamp(datetime.datetime.utcnow())
    nig_rate=calculate_nig_rate(timestamp=timestamp_nig,currency="eur")
    #requested_nig=normal_round(requested_amount/nig_rate,ROUND_VALUE_DIGIT)

    receiver_public_key_hash=smart_contract_ref
    
    transaction,transaction_amount=purchase_step_robot(sender_wallet,receiver_public_key_hash,transaction_amount,account_temp_input,account_temp_output,
    marketplace_step=1,requested_amount=requested_amount,timestamp_nig=timestamp_nig,nig_rate=nig_rate,requested_nig=requested_nig,requester_public_key_hash=requester_public_key_hash,requested_currency="eur",requester_public_key_hex=sender_wallet.public_key_hex,
    smart_contract_account=smart_contract_account,smart_contract_sender=smart_contract_sender,smart_contract_new=smart_contract_new,smart_contract_flag=smart_contract_flag,smart_contract_gas=smart_contract_gas,smart_contract_memory=smart_contract_memory,smart_contract_memory_size=smart_contract_memory_size
    ,smart_contract_type=smart_contract_type,smart_contract_payload=smart_contract_payload,smart_contract_result=smart_contract_result,smart_contract_previous_transaction=smart_contract_previous_transaction,smart_contract_transaction_hash=smart_contract_transaction_hash,smart_contract_ref=smart_contract_ref,marketplace_transaction_flag=True,utxo_json=utxo_json)

if action=="purchase_step15":
    #timestamp_nig=datetime.datetime.timestamp(datetime.datetime.utcnow())
    nig_rate=calculate_nig_rate(timestamp=timestamp_nig,currency="eur")
    #requested_nig=normal_round(requested_amount/nig_rate,ROUND_VALUE_DIGIT)

    receiver_public_key_hash=smart_contract_ref
    
    transaction,transaction_amount=purchase_step_robot(sender_wallet,receiver_public_key_hash,transaction_amount,account_temp_input,account_temp_output,
    marketplace_step=15,requested_amount=requested_amount,timestamp_nig=timestamp_nig,nig_rate=nig_rate,requested_nig=requested_nig,requester_public_key_hash=requester_public_key_hash,requested_currency="eur",requester_public_key_hex=sender_wallet.public_key_hex,
    smart_contract_account=smart_contract_account,smart_contract_sender=smart_contract_sender,smart_contract_new=smart_contract_new,smart_contract_flag=smart_contract_flag,smart_contract_gas=smart_contract_gas,smart_contract_memory=smart_contract_memory,smart_contract_memory_size=smart_contract_memory_size
    ,smart_contract_type=smart_contract_type,smart_contract_payload=smart_contract_payload,smart_contract_result=smart_contract_result,smart_contract_previous_transaction=smart_contract_previous_transaction,smart_contract_transaction_hash=smart_contract_transaction_hash,smart_contract_ref=smart_contract_ref,marketplace_transaction_flag=True,utxo_json=utxo_json)

if action=="purchase_step2":
    nig_rate=calculate_nig_rate(timestamp=timestamp_nig,currency="eur")
    #requested_nig=normal_round(requested_amount/nig_rate,ROUND_VALUE_DIGIT)
    
    receiver_public_key_hash=smart_contract_ref

    transaction,transaction_amount=purchase_step_robot(sender_wallet,receiver_public_key_hash,transaction_amount,account_temp_input,account_temp_output,
    marketplace_step=2,requested_amount=requested_amount,timestamp_nig=timestamp_nig,nig_rate=nig_rate,requested_nig=requested_nig,requester_public_key_hash=requester_public_key_hash,requested_currency="eur",requester_public_key_hex=sender_wallet.public_key_hex,
    smart_contract_account=smart_contract_account,smart_contract_sender=smart_contract_sender,smart_contract_new=smart_contract_new,smart_contract_flag=smart_contract_flag,smart_contract_gas=smart_contract_gas,smart_contract_memory=smart_contract_memory,smart_contract_memory_size=smart_contract_memory_size
    ,smart_contract_type=smart_contract_type,smart_contract_payload=smart_contract_payload,smart_contract_result=smart_contract_result,smart_contract_previous_transaction=smart_contract_previous_transaction,smart_contract_transaction_hash=smart_contract_transaction_hash,smart_contract_ref=smart_contract_ref,marketplace_transaction_flag=True,utxo_json=utxo_json)

if action=="purchase_step3":
    receiver_public_key_hash=smart_contract_ref
    transaction,transaction_amount=purchase_step_robot(marketplace_wallet,receiver_public_key_hash,transaction_amount,account_temp_input,account_temp_output,
    marketplace_step=3,requested_amount=requested_amount,timestamp_nig=timestamp_nig,requested_nig=requested_nig,requester_public_key_hash=requester_public_key_hash,requested_currency="eur",requester_public_key_hex=sender_wallet.public_key_hex,
    smart_contract_account=smart_contract_account,smart_contract_sender=smart_contract_sender,smart_contract_new=smart_contract_new,smart_contract_flag=smart_contract_flag,smart_contract_gas=smart_contract_gas,smart_contract_memory=smart_contract_memory,smart_contract_memory_size=smart_contract_memory_size
    ,smart_contract_type=smart_contract_type,smart_contract_payload=smart_contract_payload,smart_contract_result=smart_contract_result,smart_contract_previous_transaction=smart_contract_previous_transaction,smart_contract_transaction_hash=smart_contract_transaction_hash,smart_contract_ref=smart_contract_ref,marketplace_transaction_flag=True,utxo_json=utxo_json)

if action=="purchase_step4" or action=="purchase_step45":
    transaction,transaction_amount=purchase_step_robot(marketplace_wallet,receiver_public_key_hash,transaction_amount,account_temp_input,account_temp_output,
    marketplace_step=4,requested_amount=requested_amount,timestamp_nig=timestamp_nig,requested_nig=requested_nig,requested_deposit=requested_deposit,requester_public_key_hash=requester_public_key_hash,requested_currency="eur",requester_public_key_hex=sender_wallet.public_key_hex,
    smart_contract_account=smart_contract_account,smart_contract_sender=smart_contract_sender,smart_contract_new=smart_contract_new,smart_contract_flag=smart_contract_flag,smart_contract_gas=smart_contract_gas,smart_contract_memory=smart_contract_memory,smart_contract_memory_size=smart_contract_memory_size
    ,smart_contract_type=smart_contract_type,smart_contract_payload=smart_contract_payload,smart_contract_result=smart_contract_result,smart_contract_previous_transaction=smart_contract_previous_transaction,smart_contract_transaction_hash=smart_contract_transaction_hash,smart_contract_ref=smart_contract_ref,marketplace_transaction_flag=True,utxo_json=utxo_json)

if action=="smart_contract_creation":
    receiver_public_key_hash=smart_contract_ref
    
    transaction,transaction_amount=purchase_step_robot(sender_wallet,receiver_public_key_hash,transaction_amount,account_temp_input,account_temp_output,
    marketplace_step=0,requested_amount=requested_amount,timestamp_nig=timestamp_nig,requested_nig=requested_nig,requester_public_key_hash=requester_public_key_hash,requested_currency="eur",requester_public_key_hex=sender_wallet.public_key_hex,
    smart_contract_account=smart_contract_account,smart_contract_sender=smart_contract_sender,smart_contract_new=smart_contract_new,smart_contract_flag=smart_contract_flag,smart_contract_gas=smart_contract_gas,smart_contract_memory=smart_contract_memory,smart_contract_memory_size=smart_contract_memory_size
    ,smart_contract_type=smart_contract_type,smart_contract_payload=smart_contract_payload,smart_contract_result=smart_contract_result,smart_contract_previous_transaction=smart_contract_previous_transaction,smart_contract_transaction_hash=smart_contract_transaction_hash,smart_contract_ref=smart_contract_ref,marketplace_transaction_flag=False,utxo_json=utxo_json)

if action=="smart_contract_update":
    receiver_public_key_hash=smart_contract_ref
    
    transaction,transaction_amount=purchase_step_robot(marketplace_wallet,receiver_public_key_hash,transaction_amount,account_temp_input,account_temp_output,
    marketplace_step=0,requested_amount=requested_amount,timestamp_nig=timestamp_nig,requested_nig=requested_nig,requester_public_key_hash=requester_public_key_hash,requested_currency="eur",requester_public_key_hex=sender_wallet.public_key_hex,
    smart_contract_account=smart_contract_account,smart_contract_sender=smart_contract_sender,smart_contract_new=smart_contract_new,smart_contract_flag=smart_contract_flag,smart_contract_gas=smart_contract_gas,smart_contract_memory=smart_contract_memory,smart_contract_memory_size=smart_contract_memory_size
    ,smart_contract_type=smart_contract_type,smart_contract_payload=smart_contract_payload,smart_contract_result=smart_contract_result,smart_contract_previous_transaction=smart_contract_previous_transaction,smart_contract_transaction_hash=smart_contract_transaction_hash,smart_contract_ref=smart_contract_ref,marketplace_transaction_flag=False,utxo_json=utxo_json)

if action=="reputation_creation":
    receiver_public_key_hash=smart_contract_ref
    
    transaction,transaction_amount=purchase_step_robot(sender_wallet,receiver_public_key_hash,transaction_amount,account_temp_input,account_temp_output,
    marketplace_step=999,requested_amount=requested_amount,timestamp_nig=timestamp_nig,requested_nig=requested_nig,requester_public_key_hash=requester_public_key_hash,requested_currency="eur",requester_public_key_hex=sender_wallet.public_key_hex,
    smart_contract_account=smart_contract_account,smart_contract_sender=smart_contract_sender,smart_contract_new=smart_contract_new,smart_contract_flag=smart_contract_flag,smart_contract_gas=smart_contract_gas,smart_contract_memory=smart_contract_memory,smart_contract_memory_size=smart_contract_memory_size
    ,smart_contract_type=smart_contract_type,smart_contract_payload=smart_contract_payload,smart_contract_result=smart_contract_result,smart_contract_previous_transaction=smart_contract_previous_transaction,smart_contract_transaction_hash=smart_contract_transaction_hash,smart_contract_ref=smart_contract_ref,marketplace_transaction_flag=False,utxo_json=utxo_json)


    
def func_test(func):
    return func




content_dict={}
content_dict['transaction']=transaction.transaction_data
content_dict['transaction_amount']=transaction_amount
print(json.dumps(content_dict))
