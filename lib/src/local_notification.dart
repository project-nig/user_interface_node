import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'parameters.dart';
import 'dart:convert';
import 'account_getactive.dart';
import 'account_file.dart';
import 'package:flutter/material.dart';
import 'purchase_intro.dart';
import 'purchase_request.dart';
import 'sell_intro.dart';
import 'purchase_followup.dart';
import 'sell_followup.dart';
import 'balance.dart';



class LocalNotificationService {

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  
  Future<void> init(prefs,context) async {
    // Initialize native android notification
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('notification_favicon');

    // Initialize native Ios Notifications
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    void onDidReceiveNotificationResponse(NotificationResponse notificationResponse) async {
    //final String? payload = notificationResponse.payload;
    if (notificationResponse.payload == "purchase") {
      await Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (context) => PurchaseIntro(
                prefs: prefs,
              ),
            ),
      );
    }
    if (notificationResponse.payload == "sell") {
      await Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (context) => SellIntro(
                prefs: prefs,
              ),
            ),
      );
    }
    if (notificationResponse.payload == "purchase_followup") {
      await Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (context) => Purchase_followupHome(
                prefs: prefs,
              ),
            ),
      );
    }
    if (notificationResponse.payload == "sell_followup") {
      await Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (context) => Sell_followupHome(
                prefs: prefs,
              ),
            ),
      );
    }
    if (notificationResponse.payload == "balance") {
      await Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (context) => BalanceDemo(
              ),
            ),
      );
    }
    
}

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings, onDidReceiveNotificationResponse: onDidReceiveNotificationResponse
    );
  }


  void showNotificationAndroid(String title, String value, String payload) async {
    print("===>check notification2");
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails('channel_id', 'Channel Name',
            channelDescription: 'Channel Description',
            importance: Importance.max,
            priority: Priority.high);

    int notification_id = 1;
    
    const NotificationDetails notificationDetails =
        NotificationDetails(android: androidNotificationDetails);
    print(title);
    await flutterLocalNotificationsPlugin.show(notification_id, title, value, notificationDetails, payload: payload);
  }


  void CheckNotification(context) async {
    try{
      var public_key_data = await ActiveAccount();
      var requester_public_key_hash=public_key_data["public_key_hash"];
      var notification_timestamp_dict = await readNotificationList(requester_public_key_hash);
      var notification_timestamp_user_dict=notification_timestamp_dict[requester_public_key_hash];
      //final notification_timestamp = '1';
      var response_check_notification = await http.get(Uri.parse(nig_hostname+'/check_notification/'+requester_public_key_hash+'/'+json.encode(notification_timestamp_user_dict)));
      var check_notification_data=jsonDecode(response_check_notification.body);
      print("==>check1");
      print(check_notification_data);
      var timestamp_reset_flag=false;
      DateTime now = DateTime.timestamp();
      var now_str=(now.millisecondsSinceEpoch/1000-notification_time_offset).toString();
      print("===>now_str");
      print(now_str);
      if (check_notification_data['1']!=0){
        var notification_data=check_notification_data['1'];
        timestamp_reset_flag=true;
        notification_timestamp_dict[requester_public_key_hash]['1']=now_str;
        showNotificationAndroid("Vendez vos NIG", "Il y a $notification_data nouvelle(s) demande(s) d'achat","sell");}
      if (check_notification_data['2']!=0){
        var notification_data=check_notification_data['2'];
        timestamp_reset_flag=true;
        notification_timestamp_dict[requester_public_key_hash]['2']=now_str;
        showNotificationAndroid("Suivi d'achat à confirmer !", "Merci de confirmer $notification_data suivi(s) d'achat !","purchase_followup");}
      if (check_notification_data['3']!=0){
        var notification_data=check_notification_data['3'];
        timestamp_reset_flag=true;
        notification_timestamp_dict[requester_public_key_hash]['3']=now_str;
        showNotificationAndroid("Suivi de vente à confirmer !", "Merci de confirmer $notification_data suivi(s) de vente !","sell_followup");}
      if (check_notification_data['4']!=0){
        var notification_data=check_notification_data['4'];
        timestamp_reset_flag=true;
        notification_timestamp_dict[requester_public_key_hash]['4']=now_str;
        if (notification_data==1){
          showNotificationAndroid("Votre achat est confirmé !", "Vérifier le solde de votre compte.","balance");
        }
        else{
          showNotificationAndroid("Vos $notification_data achats sont confirmés !", "Vérifier le solde de votre compte.","balance");
        }}
      if (check_notification_data['45']!=0){
        var notification_data=check_notification_data['45'];
        timestamp_reset_flag=true;
        notification_timestamp_dict[requester_public_key_hash]['45']=now_str;
        if (notification_data==1){
          showNotificationAndroid("Votre achat est confirmé !", "Attention votre réputation est degradée !","balance");
        }
        else{
          showNotificationAndroid("Vos $notification_data achats sont confirmés !", "Attention votre réputation est degradée !","balance");
        }}
      if (check_notification_data['66']!=0){
        var notification_data=check_notification_data['66'];
        timestamp_reset_flag=true;
        notification_timestamp_dict[requester_public_key_hash]['66']=now_str;
        if (notification_data==1){
          showNotificationAndroid("Votre achat est rejeté !", "Votre réputation est sévèrement degradée !","purchase");
        }
        else{
          showNotificationAndroid("Vos $notification_data achats sont rejetés !", "Votre réputation est sévèrement degradée !","purchase");
        }}
      if (check_notification_data['98']!=0){
        var notification_data=check_notification_data['98'];
        timestamp_reset_flag=true;
        notification_timestamp_dict[requester_public_key_hash]['98']=now_str;
        if (notification_data==1){
          showNotificationAndroid("Demande d'achat expirée !", "Votre demande d'achat a expiré!","purchase");
        }
        else{
          showNotificationAndroid("$notification_data Demandes d'achats expirées !", "Les $notification_data demandes d'achats ont expiré !","purchase");
        }}
      if (check_notification_data['99']!=0){
        var notification_data=check_notification_data['99'];
        timestamp_reset_flag=true;
        notification_timestamp_dict[requester_public_key_hash]['99']=now_str;
        if (notification_data==1){
          showNotificationAndroid("Demande d'achat annulée !", "Votre demande d'achat a été annulé !","purchase");
        }
        else{
          showNotificationAndroid("$notification_data Demandes d'achats annulées !", "Les $notification_data demandes d'achats ont été annulé","purchase");
        }}
      if (timestamp_reset_flag == true){UpdateNotificationTimeStamp(notification_timestamp_dict);}
      //UpdateNotificationTimeStamp(notification_timestamp_dict);
    }
    catch(e) {
      print("erreur CheckNotification");
      print(e);
    }
    
}
  
}




 




