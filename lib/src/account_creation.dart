// Copyright 2020, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:chaquopy/chaquopy.dart';
import 'package:flutter/services.dart';
import 'account_file.dart';
import 'parameters.dart';


// Demonstrates how to use autofill hints. The full list of hints is here:
// https://github.com/flutter/engine/blob/master/lib/web_ui/lib/src/engine/text_editing/autofill_hint.dart



class AccountCreationHome extends StatefulWidget {
  const AccountCreationHome({super.key});

  @override
  State<AccountCreationHome> createState() => _AccountCreationHomeState();
}

class _AccountCreationHomeState extends State<AccountCreationHome> {
  late Future<AccountList> futurereadAccountList;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    futurereadAccountList = readAccountList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Création d'un nouveau compte"),
      ),
      body: FutureBuilder<AccountList>(
            future: futurereadAccountList,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Form(
                key: _formKey,
                child: Scrollbar(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: AutofillGroup(
                      child: Column(
                        children: [
                          ...[
                            Text("Cette page vous permet de créer un nouveau compte dans la limite de $nb_account_max compte(s) maximum."),
                            TextButton(
                            child: const Text('Créer un nouveau compte'),
                              onPressed: () async {
                                print("contenu du compte");
                                print(snapshot.data!.account_list);

                                if (snapshot.data!.account_list.length>=nb_account_max){
                                  _showDialog("$nb_account_max compte(s) maximun autorisé(s)");
                                }else {

                                  //Step 1 creating of a new account
                                  final String controller = await rootBundle.loadString('assets/nig_decrypt.py');

                                  final param = "action_raw="""+json.encode("account_creation")+"""\r"""+
                                  "account_raw="""+json.encode("")+"""\r"""+
                                  "pin_encrypted_raw="""+json.encode("")+"""\r"""+
                                  "account_private_key_raw="""+json.encode("")+"""\r"""+
                                  "requester_public_key_hex_raw="""+json.encode("")+"""\r"""+
                                  "mp_details_raw="""+json.encode("")+"""\r""";


                                  print('====param=====');
                                  var param1=param.replaceAll('false', "'false'");
                                  var param2=param1.replaceAll('null', "'null'");
                                  var param3=param2.replaceAll('true', "'true'");
                                  print(param3);
                                  final transaction_data = await Chaquopy.executeCode(param3+controller);
                                  print('====transaction_data=====');
                                  debugPrint(transaction_data['textOutputOrError']);

                                  //var account = transaction_data['textOutputOrError'];
                                  Map account = jsonDecode(transaction_data['textOutputOrError']);

                                  print('====result account_creation=====');
                                  var private_key_str=account['private_key_str'];
                                  print("private_key_str");
                                  print(private_key_str);
                                  var public_key_hex=account['public_key_hex'];
                                  print("public_key_hex");
                                  print(public_key_hex);
                                  var public_key_hash=account['public_key_hash'];
                                  print("public_key_hash");
                                  print(public_key_hash);
                                  
                                  //camille account setup
                                  //account["private_key_str"]="-----BEGIN RSA PRIVATE KEY-----\nMIIEowIBAAKCAQEAsVZk/dA8PDovQm9bhsc5HqSiz88rShgkHRzDjLe2IFUVA3Rm\ndX0T+Xx7cRl6XogfhXeD44AOl1/3DUO3MvsOybLAqdYqUrUzOzkxoLb7b7CNkaxg\n+rBSfG5OvcmReq9rUeQJ6DfcS8ITNpvdp7Hk8gphXlhwYQD1YtzrchU9j+wFK91w\n4cU0Bu8BPTjGicMg/jPczdoLvi/4ikO0yrS39oG89Yvsr3AIeW1KQNPBZwfXxjmh\nmBUg8UhQskcalVVikaP2b4qNleiqq/KtASusLB/+/bbQZY7SjZpN9X7pG3lncEkh\nlKLtF4UVUcnc9Qoo+5Mhxt0P/SG3c3jKlvbmuQIDAQABAoIBAAZUmrNS0SunOhOp\njP9hMkFNSECZ2SZCeVuOsM5fqoE5+E+Qwq2UAvgHgRKXAb7JJjLqAsvGwP6XXuba\n0Xng63S4zFbjvcwJCuSk1IgzsAMbLtqR6D5at/8YIvh0bxyNkYuxU8c140fTDEOJ\nSd7YI1+ejj5DcvOLiLb4QvFmH7X4/ClhUFCLM5daR66yhyax8mEAlKHHDWfuA9lI\ncq9fFguo2S1CII4EsF2jGLK+NfXpVVUISFq14is3XmG7tUyZHn2+ILO1EMfnxBVF\n2EmQ13wt637Kyydnt6c8jt9N2TXhcEWFrhCbjl5ujBylmg70SZXNEi/TFGDMCgv+\n33lwHH8CgYEAwk4rbmvx9jIXxj/HJAu/HESdzCc7S5NKprBOk5ERMRF+M/Dm99ei\n+jQyvjy2rirMSqyM5AIYkqKmMUiX3fUW1RlUBHS+21COUeoeh3Aa9/4pU8/oFzw9\naaqxBTbBzjae/42OZI9tS5B8KTa8TBgcnPuqR8MlZUnqGh8bFXQkJPMCgYEA6aUE\nDp89pIVbhYLPX7fyEIxl5z+9iKLjl9nQzdztEdZqy7N47usIfHsD6Dlp3oiiRlEk\nBrzAcKRdHpS7wy9vnrg0GkQizM9HMtZMj/4J2/QIimIGwTyzSLhuY0u1cZaZD/eG\niHb/k9nE9urh8ACCCEv/ZP7tpVoLeodP7FyXIKMCgYEAswlaJYXbTrH7jBXKReF4\n9/AVwj5H+aw/dfYwgPKDd8YZlnycJbSRHKCqPPYuka8nzIrPy2xO/hZWskSkgsVJ\ng5OyAeUc03KXoMzr0nour2GG7Q4+WeKM5+d680XwMDXOLcVedjReTelVLpibyjXR\nb6jIzxT2SS1hQy50Q0Ff6JcCgYBN4CaeCQ2uzJRYx+T+7nzMbz93+JLf/AsIDh2+\nwCh0jZdDFir013oYo5gFyz0yYzBTZ7AuXrN12BMBommDAUifCp6zMoq24U/F7g/O\n3snCenBuT4YY2naXgoGorw9nMN8Lp2E8Ew3U5fz0oA12xXSR92LE8wOa3Yx95qQJ\nEEN/KQKBgBxM7Om+D16JZI+jpUYIaUzZN3UP1OCyepRnVjGP+dpB07k4swRDOR/Y\n7/b/DQy+S67iKuGxTZs+2gL79MdhjYRYvAQ5sxf0hSzeDSQsG2wPDYp5SE55Urgm\n5SbivHvRe9VdT3ehO9FgTktAyLnFsdNtlqos1O+mnBvRkP9hZky9\n-----END RSA PRIVATE KEY-----";
                                  //account["public_key_hex"]= "30820122300d06092a864886f70d01010105000382010f003082010a0282010100b15664fdd03c3c3a2f426f5b86c7391ea4a2cfcf2b4a18241d1cc38cb7b6205515037466757d13f97c7b71197a5e881f857783e3800e975ff70d43b732fb0ec9b2c0a9d62a52b5333b3931a0b6fb6fb08d91ac60fab0527c6e4ebdc9917aaf6b51e409e837dc4bc213369bdda7b1e4f20a615e58706100f562dceb72153d8fec052bdd70e1c53406ef013d38c689c320fe33dccdda0bbe2ff88a43b4cab4b7f681bcf58becaf7008796d4a40d3c16707d7c639a1981520f14850b2471a95556291a3f66f8a8d95e8aaabf2ad012bac2c1ffefdb6d0658ed28d9a4df57ee91b796770492194a2ed17851551c9dcf50a28fb9321c6dd0ffd21b77378ca96f6e6b90203010001";
                                  //account["public_key_hash"]="84d7eee902bf978d379aa988da0068d71e0037a7";

                                  //interface account setup
                                  //account["private_key_str"]="-----BEGIN RSA PRIVATE KEY-----\nMIIEpAIBAAKCAQEA6Zma3zRYvWbUplrkEn4qOxfHY1xBACkF2I2s1ItFqO9k1ywV\noO8Tse/tlq5QkjSAo3YgRvNKl/Z1YL1dxnYHIGZgdOujZfirs9CQgUpslMBE3vSd\n1KdGRL5f0k7dn3DZFm4Im0VNDq19Y0wytIA86WRrv5mVYr2hiX+qSzHdA//JiW6S\n2do3LL4Qrbhr2pMA0UKc5AghRCJ6JET++MmFOGziw76fdJoWhjoRqrP2bgTC/V1q\np1NeoMqfaSPF6YvEdbLZmUMhVPbWBeK4UYHJLVJFElYYXO9s/kFXgdmq49DGHX/Q\nBgHIilWYY2bHK6r6InQyib9bB1vCHGditlU2hwIDAQABAoIBAAEL0I8+V0Vl3/7s\nukfA6+R+20Q9Jgdfp6iMHeGHzCSRCeUSy/gAChkKZ4h8uFynQoo43bUjospibq0j\nu/dHEQoam0T6xy0OO4qfHP6PPERARi6vbsOEikKFjb1N4B02Lqq0jHJRkaJGsaCP\nt0xqpJsw+XCOugYKrl4Exdj3XLOHYAkfJJIZoXpt6V2KUXFfePmItrALPjorgf57\nYPP6UOhBkFoAtbqY5o4YD3qPB7uVS1iUF5CUry/HYoIWy1pnC+UZwgkLW57/fOit\n8x5IAmi8TV553knt3AeAK1YnyOzUIyrJeWtus8lDPZrwIaG4EiLO+nW/RdDI6ks6\n2f7QJE0CgYEA7EiS1JMV7h1+1uBsyuO3forJhBCI8l0jU4sFphBKApZseX5Oq3XP\nZ1aXbZlAe5GCC7tB7TSmDt5WqVfwDJ9D4B1B+TYPYk3V65/Lv7o8yqqwCcndy7Ra\n6N84U5iCvyvd2D0q/HPTOYq3oHkiUjIBVUlktH3weTha1yd7e1YNGlUCgYEA/Re1\nMoHnGzcHlP369ka9jLx/AlwPvLdBTB0QvVcJbFP2SWBsQxm3zGkaErzWOVhYCcuJ\ns8/J3Kg5RXaNnTT/rGT0dwUYIGhJjjt5RgSfikowwA5CbRuV3FavUUHD4ScanpG1\nBx0ySv64r8zXXf3Y3vTfSRRT17pOCqqnrFtdYWsCgYEAq/XlZm/ldfZhaWDLzJ0N\n3jqDjmm6QSknnJWA9urD8j4nlAQonQCQgVSzwD/YfhXX31HZGRlIAWovB+/H9Ge0\nrlacvRJq/9BF78XMMy0HMTgoBfe0Q5xuzSwngi9seFUkj0t1DWX+Q9KA8Xk3UTqz\nXa6ca/98E7y/3/YMGCb4QkECgYAOYKlnfB+v2RlyKld2ZCBifVbNwIMYWmS4OTJ5\nPxeG8uIb2wFrcmuRjirwA5A747vkmo5xC43RHjFas9hppNgdaALHPB/Zv3LmRJSo\nGJ0jkwFf969oWVfTE42UFSNWiA0oEujwxYTU49GEEyPs7/3A9LI2iZQVvjyuuHEc\nBniwjwKBgQCR1VJ3uoX/NdeyPDycRb8qTI0tIV9LDQX3IGxZmrOKR1E0gBUD24X6\ntAuBF6kFF5xqchSgtcomk7U5iRYSCHdQfsFNsBBUvSMFJwQ6fG595BptGF5mS1oP\ndsHZIBc4C0QYWjMEqgYcPExDHP2boknTMn21L6PqtUdbU+VRVwI7eQ==\n-----END RSA PRIVATE KEY-----";
                                  //account["public_key_hex"]= "30820122300d06092a864886f70d01010105000382010f003082010a0282010100e9999adf3458bd66d4a65ae4127e2a3b17c7635c41002905d88dacd48b45a8ef64d72c15a0ef13b1efed96ae50923480a3762046f34a97f67560bd5dc6760720666074eba365f8abb3d090814a6c94c044def49dd4a74644be5fd24edd9f70d9166e089b454d0ead7d634c32b4803ce9646bbf999562bda1897faa4b31dd03ffc9896e92d9da372cbe10adb86bda9300d1429ce4082144227a2444fef8c985386ce2c3be9f749a16863a11aab3f66e04c2fd5d6aa7535ea0ca9f6923c5e98bc475b2d999432154f6d605e2b85181c92d52451256185cef6cfe415781d9aae3d0c61d7fd00601c88a55986366c72baafa22743289bf5b075bc21c6762b65536870203010001";
                                  //account["public_key_hash"]="1f8da1bae39c78bf4d8f9f3b8727e50001eed5ae";

                                  //marketplace account setup
                                  //account["private_key_str"]="-----BEGIN RSA PRIVATE KEY-----\nMIIEowIBAAKCAQEA49M4x6RnhVFMNyk5ce06V1f8Xp4wQrycunVQS95e7lfJzHiF\nBgQkJWYqRdMgyiPlquuYnhcZ8GTm/iKNnwoxagas1wilU2u1zB4LgwfumEjgBynV\noXHwDipDXnGb4dqZ1wOdjDMb+GknClN7EEsiipEGGtoL55GOjYjIra2wvigjAmt1\nHbY9CxAdcUb1tQpGMWGHeqMTDmm+NdX063EHOkC9F2bERAcJ6uPJ8L++7W+ig1gz\nRyHUl7nz1sMbmiWP4dif4+v1v/r8Nun8jL2CpXub7A5M6jkN83qH1g1YXoCFWavY\nPYGi8nN+I1zi/Aze5odw2Re/CT0K1WRWELT0IwIDAQABAoIBABcTMd6NU8uIgEWG\nquH+Su5FeUhkvEhIzepYGdG9YZ8WttfmDbnIxJfMdmlLvjf1v9F6evg+0xU/8GIl\nbMkCzB4hiUhfAKO84T/Ie+usa37yw/dlxin2c3/JHw6wnL8Y7YOowushfWqWd+pP\nVJkXYGsUJOqmUsCvGPb+jNjZIpwicp44NltQDN4zD+829G5Hp4HahztCdaRSusOs\nFJou/+Zl0QDysLaThzuU0w1tvBhyhaknc7Glf7aNoIGj091NupS/aZO1O3dbhTAz\ngsI1LKgz/tA54xa2G6x+EaJRSBzRCiEBcF/irsi3IxBObvAlCCZ2z6bLfuhiHh5r\n/DqVTmkCgYEA6Lecbzajx3qQx2cRClAmYFDpcBknZiVAHd/RCIdYT7ZawiRFLZNi\nnDEOx/W2MiT5eRYVcQo/o6Rkib6gE6PXP8pqLutnFWcmaUt8rR73Rc8izb6jUYRP\n3C8zGIwYgfDh2OzWaJhCLIzAhs1fZ7c7m8jbzMkmApGt1reR+vQ5MckCgYEA+p5P\n9jfDjQ+v3gQIBpz7e7v4fwfkOJHOrQ3SXVYoOve7WTWrtZw80eExlq83fQ26vGD5\nED3nkf0v7NnlfBg1fj55YBSO28KwuWuIJDZz71REnxd3NVqQjzkZ9AIQkDubDORN\n/NoM0Vd6N5ptVCPJP4koWuJVVwp/d97TQ0mFjIsCgYBlJQh0vcbJOFgckosxdEx5\nqDENa6FYH/CSC2kKz+huHM+teZ4nhNtjD19hQUYC3VcgbZy8GLw4H4ci5xsj7h3r\nt8oWwnF3N/HV6d0yUTcfvDtgOO86ysr64/jNPnaYY12Frsoxg5ufST2UWUaSCW16\n8/20L+i5TR/FJtvnuqXxIQKBgAGTVTVbDGOqoZRnuhUwj3Qrrlg+GHUylXYJDDWC\nASa9v/PDnpy5qrg3DjTATT0ABRiCE47ClN4aFV8Lz6GEFXIBuomcF3nSM4I25tgz\nb28lvHizkRBIzXfZCAy8ppYBiev+026vgD0gq6gF1IIe53j6x8IqghbV/g8m23Uk\n1S4ZAoGBALQReseADMAECbfMCWw8fALwUmrYGagv2wTZtOLZmlhYU+loSG2Ig3uc\nyPgrQxXy5qz0lmnLPPdzFxjNMEGxRdseMVXmdevKux7GMFk4svZfRG8bDOi/pE0Z\n4XjgbxsuAF8+kfufqjO8kkhCokCXRyxcaO5jVcXofdsE1uOwwub+\n-----END RSA PRIVATE KEY-----";
                                  //account["public_key_hex"]= "30820122300d06092a864886f70d01010105000382010f003082010a0282010100e3d338c7a46785514c37293971ed3a5757fc5e9e3042bc9cba75504bde5eee57c9cc788506042425662a45d320ca23e5aaeb989e1719f064e6fe228d9f0a316a06acd708a5536bb5cc1e0b8307ee9848e00729d5a171f00e2a435e719be1da99d7039d8c331bf869270a537b104b228a91061ada0be7918e8d88c8adadb0be2823026b751db63d0b101d7146f5b50a463161877aa3130e69be35d5f4eb71073a40bd1766c4440709eae3c9f0bfbeed6fa28358334721d497b9f3d6c31b9a258fe1d89fe3ebf5bffafc36e9fc8cbd82a57b9bec0e4cea390df37a87d60d585e808559abd83d81a2f2737e235ce2fc0cdee68770d917bf093d0ad5645610b4f4230203010001";
                                  //account["public_key_hash"]= "31f2ac8088005412c7b031a6e342b17a65a48d01";
                                  

                                  //Step 2 set all the other account as inactive
                                  for (var other_account in snapshot.data!.account_list) {
                                    other_account['active']=false;
                                  };

                                  //Step 3 add the name and step the account as active
                                  account['name']="test";
                                  account['active']=true;
                                  snapshot.data!.account_list.add(account);
                                  print("===>result");
                                  print(snapshot.data!.account_list);

                                  //Step 4 save the account
                                  var account_2_save = new Map();
                                  account_2_save['account_list']=snapshot.data!.account_list;
                                  var account_2_save_json=json.encode(account_2_save);
                                  print("===>account_2_save");
                                  print(account_2_save_json);
                                  writeAccount(account_2_save_json);
                                  _showDialog("Nouveau compte créé");


                                }






                              },
                            ),

                          
            
                          ].expand(
                            (widget) => [
                              widget,
                              const SizedBox(
                                height: 24,
                              )
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              );
              } else if (snapshot.hasError) {
                return Text('${snapshot.error}');
              }
              return const CircularProgressIndicator();
            }  
      ),
      
    );
  }

  void _showDialog(String message) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(message),
        actions: [
          TextButton(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

}
