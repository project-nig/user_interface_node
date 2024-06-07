// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transfer.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FormData _$FormDataFromJson(Map<String, dynamic> json) {
  return FormData(
    amount: json['amount'] as String?,
    receiver_public_key_hash: json['receiver_public_key_hash'] as String?,
  );
}

Map<String, dynamic> _$FormDataToJson(FormData instance) => <String, dynamic>{
      'amount': instance.amount,
      'receiver_public_key_hash': instance.receiver_public_key_hash,
    };
