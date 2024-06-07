// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'smart_contract_creation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FormData _$FormDataFromJson(Map<String, dynamic> json) {
  return FormData(
    sc_type: json['sc_type'] as String?,
    sc_new: json['sc_new'] as String?,
    sc_account: json['sc_account'] as String?,
    sc_payload: json['sc_payload'] as String?,
  );
}

Map<String, dynamic> _$FormDataToJson(FormData instance) => <String, dynamic>{
  'sc_type': instance.sc_type,
  'sc_new': instance.sc_new,
  'sc_account': instance.sc_account,
  'sc_payload': instance.sc_payload,
    };
