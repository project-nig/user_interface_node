import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:web3dart/web3dart.dart';
import 'package:http/http.dart';

class EthereumService {
  late Web3Client ethClient;
  final String rpcUrl = "http://10.0.2.2:7545"; // Ganache URL pour Android
  final String contractAddress = "0x76681c2D87F7B05cad52d2B572b333093207bD59"; // Adresse du contrat

  EthereumService() {
    ethClient = Web3Client(rpcUrl, Client());
  }

  Future<DeployedContract> loadContract() async {
    String abi = await rootBundle.loadString("assets/contract_abi.json");
    final contract = DeployedContract(
      ContractAbi.fromJson(abi, "YourContractName"),
      EthereumAddress.fromHex(contractAddress),
    );
    return contract;
  }

  Future<List<dynamic>> query(String functionName, List<dynamic> args) async {
    final contract = await loadContract();
    final ethFunction = contract.function(functionName);
    final result = await ethClient.call(
      contract: contract,
      function: ethFunction,
      params: args,
    );
    return result;
  }
}
