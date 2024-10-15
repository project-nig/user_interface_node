// Copyright 2020, the Flutter project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//test 2
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_size/window_size.dart';


import 'src/autofill.dart';
import 'src/balance.dart';
import 'src/form_widgets.dart';
import 'src/http/mock_client.dart';
import 'src/transfer.dart';
import 'src/validation.dart';
import 'src/transaction_list.dart';
import 'src/purchase_intro.dart';
import 'src/purchase_followup.dart';
import 'src/sell_intro.dart';
import 'src/sell_followup.dart';
import 'src/account_creation.dart';
import 'src/account_selection.dart';
import 'src/contest.dart';
import 'src/contest_result.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'src/parameters.dart';
import 'src/application_update.dart';
import 'src/application_issue.dart';
import 'src/maintenance.dart';
import 'src/connectivity.dart';
import 'src/smart_contract_creation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'src/local_notification.dart';
import 'package:cron/cron.dart';
import 'src/tutorial.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences prefs = await SharedPreferences.getInstance();
  setupWindow();
  var demos=await setupdemos(prefs);
  runApp(FormApp(prefs: prefs,demos: demos));
}

const double windowWidth = 480;
const double windowHeight = 854;

void setupWindow() {
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
    WidgetsFlutterBinding.ensureInitialized();
    setWindowTitle('Form Samples');
    setWindowMinSize(const Size(windowWidth, windowHeight));
    setWindowMaxSize(const Size(windowWidth, windowHeight));
    getCurrentScreen().then((screen) {
      setWindowFrame(Rect.fromCenter(
        center: screen!.frame.center,
        width: windowWidth,
        height: windowHeight,
      ));
    });
  }
}

fetchApplicationVersion() async {
  var application_version_flag = false;
  var appplication_issue_flag = false;
  var application_url = null;
  var payload="""\r
memory_obj_2_load=['application']
application.get_version_data()
""";

  var body = {
      'smart_contract_type': 'api',
      'smart_contract_public_key_hash': APPLICATION_VERSION_PUBLIC_KEY_HASH,
      'sender_public_key_hash': 'sender_public_key_hash',
      'payload':payload,
    };
  var jsonString = json.encode(body);
  var application_version_url=nig_hostname+'/smart_contract';
  var application_version_response = await http.post(Uri.parse(application_version_url),headers: {"Content-Type": "application/json"}, body: jsonString);
  if (application_version_response.statusCode == 503 || application_version_response.statusCode == 302) {
    //the server is on maintenance
    maintenance_flag=true;
  }
  else{
    maintenance_flag=false;
    try{
      var application_version_json=jsonDecode(application_version_response.body)['smart_contract_result'];
      print("====>application_version_json");
      print(application_version_json);
      var version=application_version_json['version'];
      application_url=application_version_json['url'];
      if (version==application_version){
        application_version_flag=true;
      }
    }
    catch(e) {
      print("===>probleme:");
      print(e);
      appplication_issue_flag=true;};
  }
  return [application_version_flag,application_url,appplication_issue_flag];
}

setupdemos(prefs) async {
  var  demos=null;
  var connectivity_flag=true;
  final connectivityResult = await (Connectivity().checkConnectivity());
  if (connectivityResult == ConnectivityResult.none){connectivity_flag=false;}
  if (connectivity_flag==false){
    demos = [
          Demo(
            name: "Aucune connexion internet. Cliquez pour plus de détails.",
            route: '/connectivity',
            builder: (context) => const ConnectivityHome(),
          )];
  }else{
    var application_url=null;
    var application_data= await fetchApplicationVersion();
    var check_application_version_flag=false;
    var check_appplication_issue_flag =false;
    if (maintenance_flag == false){
      check_application_version_flag=application_data[0];
      application_url=application_data[1];
      check_appplication_issue_flag=application_data[2];
    }
    if (maintenance_flag==true){
      demos = [
          Demo(
            name: "Le réseau NIG est en cours de maintenance. Cliquez pour plus de détails.",
            route: '/maintenance',
            builder: (context) => const MaintenanceHome(),
          )];
    }
    else{
      if (check_appplication_issue_flag==true){
      print("================>>>>>>>> Problème avec l'application");
      demos = [
            Demo(
              name: "Problème avec l'application. Cliquez pour plus de détails.",
              route: '/application_issue',
              builder: (context) => const ApplicationIssueHome(),
            )];
      }else{
        if (check_application_version_flag==true){
          if (smart_contract_creation_flag==true){
            demos = [
              Demo(
                name: "00_Mode d'emploi",
                route: '/tutorial',
                builder: (context) => const TutorialHome(),
              ),
              Demo(
                name: '10_Creation de Compte',
                route: '/account_creation',
                builder: (context) => const AccountCreationHome(),
              ),
              Demo(
                name: '20_Achat de NIG',
                route: '/purchase',
                builder: (context) => PurchaseIntro(
                  // This sample uses a mock HTTP client.
                  httpClient: mockClient,
                  prefs: prefs,
                ),
              ),
              Demo(
                name: '25_Suivi des Achats de NIG',
                route: '/purchase_followup',
                builder: (context) => Purchase_followupHome(
                  prefs: prefs,
                ),
              ),
              Demo(
                name: '30_Balance',
                route: '/balance',
                builder: (context) => const BalanceDemo(),
              ),
              Demo(
                name: '40_Compte Bancaire',
                route: '/autofill',
                builder: (context) => const AutofillDemo(),
              ),
              Demo(
                name: '50_Vente de NIG',
                route: '/sell',
                builder: (context) => SellIntro(
                  prefs: prefs,
                ),
              ),
              Demo(
                name: '55_Suivi des Ventes de NIG',
                route: '/sell_followup',
                builder: (context) => Sell_followupHome(
                  prefs: prefs,
                ),
              ),
              Demo(
                name: '60_Transfert de NIG',
                route: '/transfer',
                builder: (context) => TransferHome(
                  // This sample uses a mock HTTP client.
                  httpClient: mockClient,
                  prefs: prefs,
                ),
              ),
              Demo(
                name: '70_Transaction List',
                route: '/transaction_list',
                builder: (context) => const BalanceDemo2Home(),
              ),
              Demo(
                name: '80_Sélection de Compte',
                route: '/account_selection',
                builder: (context) => const AccountSelectionHome(),
              ),
              Demo(
                name: '90_Inscription Concours',
                route: '/contest',
                builder: (context) => Contest(
                  // This sample uses a mock HTTP client.
                  httpClient: mockClient,
                  prefs: prefs,
                ),
              ),
              Demo(
                name: '95_Classement',
                route: '/contest_result',
                builder: (context) => const ContestResultHome(),
              ),
              Demo(
                name: '95_Creation SmartContract',
                route: '/smart_contract_creation',
                builder: (context) => Form_SC_Creation(prefs: prefs),
              ),
              Demo(
                name: 'Validation',
                route: '/validation',
                builder: (context) => const FormValidationDemo(),
              ),
            ];
          }
          else{
            demos = [
            Demo(
              name: "00_Mode d'emploi",
              route: '/tutorial',
              builder: (context) => const TutorialHome(),
            ),
            Demo(
              name: '10_Creation de Compte',
              route: '/account_creation',
              builder: (context) => const AccountCreationHome(),
            ),
            Demo(
              name: '20_Achat de NIG',
              route: '/purchase',
              builder: (context) => PurchaseIntro(
                // This sample uses a mock HTTP client.
                httpClient: mockClient,
                prefs: prefs,
              ),
            ),
            Demo(
              name: '25_Suivi des Achats de NIG',
              route: '/purchase_followup',
              builder: (context) => Purchase_followupHome(
                prefs: prefs,
              ),
            ),
            Demo(
              name: '30_Balance',
              route: '/balance',
              builder: (context) => const BalanceDemo(),
            ),
            Demo(
              name: '40_Compte Bancaire',
              route: '/autofill',
              builder: (context) => const AutofillDemo(),
            ),
            Demo(
              name: '50_Vente de NIG',
              route: '/sell',
              builder: (context) => SellIntro(
                prefs: prefs,
              ),
            ),
            Demo(
              name: '55_Suivi des Ventes de NIG',
              route: '/sell_followup',
              builder: (context) => Sell_followupHome(
                prefs: prefs,
              ),
            ),
            Demo(
              name: '60_Transfert de NIG',
              route: '/transfer',
              builder: (context) => TransferHome(
                // This sample uses a mock HTTP client.
                httpClient: mockClient,
                prefs: prefs,
              ),
            ),
            Demo(
              name: '70_Transaction List',
              route: '/transaction_list',
              builder: (context) => const BalanceDemo2Home(),
            ),
            Demo(
              name: '80_Sélection de Compte',
              route: '/account_selection',
              builder: (context) => const AccountSelectionHome(),
            ),
            Demo(
              name: '90_Inscription Concours',
              route: '/contest',
              builder: (context) => Contest(
                // This sample uses a mock HTTP client.
                httpClient: mockClient,
                prefs: prefs,
              ),
            ),
            Demo(
              name: '95_Classement',
              route: '/contest_result',
              builder: (context) => const ContestResultHome(),
            ),
          ];
          }
        }
        else{
          demos = [
            Demo(
              name: "Cliquez pour mettre à jour votre application",
              route: '/application_update',
              builder: (context) => ApplicationUpdateHome(application_url:application_url),
            )];
        }
      }
    }
  
  }
return demos;
}
class FormApp extends StatelessWidget {
  final SharedPreferences prefs;
  final Iterable demos;
  
  FormApp({required this.prefs, required this.demos});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Form Samples',
      theme: ThemeData(primarySwatch: Colors.teal),
      routes: Map.fromEntries(demos.map((d) => MapEntry(d.route, d.builder))),
      home:  HomePage(prefs: prefs,demos:demos),
    );
  }
}



class HomePage extends StatelessWidget {
  final SharedPreferences prefs;
  final Iterable demos;


  HomePage({required this.prefs, required this.demos});
  @override
  Widget build(BuildContext context)  {
    LocalNotificationService().init(prefs,context);
    var cron = new Cron();
      cron.schedule(new Schedule.parse('*/2 * * * *'), () async {
      try {
        LocalNotificationService().CheckNotification(context);
        print('Check Notification');
      }
      catch(e) {
        print("erreur CRON");
        print(e);
      }
    });

 


    return Scaffold(
      appBar: AppBar(
        title: const Text('NIG Interface'),
      ),
      body: ListView(
        children: [...demos.map((d) => DemoTile(demo: d))],
      ),
    );
  }
}

class DemoTile extends StatelessWidget {
  final Demo? demo;

  const DemoTile({this.demo, super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(demo!.name),
      onTap: () {
        Navigator.pushNamed(context, demo!.route);
      },
    );
  }
}

class Demo {
  final String name;
  final String route;
  final WidgetBuilder builder;

  const Demo({required this.name, required this.route, required this.builder});
}



