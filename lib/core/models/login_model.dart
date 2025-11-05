class LoginResponseModel {
  int? status;
  String? message;
  String? token;
  String? username;
  LoginData? data;
  bool? hasWallet;
  String? role;
  bool? paymentSettingExists;

  LoginResponseModel({
    this.status,
    this.message,
    this.token,
    this.data,
    this.hasWallet,
    this.username,
    this.role,
    this.paymentSettingExists,
  });

  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    print('🎯 ========== DEBUGGING LOGIN RESPONSE ==========');
    print('🔑 ROOT JSON KEYS: ${json.keys.toList()}');

    // Check for the nested structure
    bool hasState = json.containsKey('state');
    bool hasPayload = json.containsKey('payload');
    bool hasPaymentSetting = json.containsKey('payment_setting_exists');

    print('🏛️ state exists: $hasState');
    print('📦 payload exists: $hasPayload');
    print('💰 payment_setting_exists exists: $hasPaymentSetting');
    print('💰 payment_setting_exists value: ${json['payment_setting_exists']}');
    print('💰 payment_setting_exists type: ${json['payment_setting_exists']?.runtimeType}');

    // Handle the nested structure
    Map<String, dynamic> payloadData = {};
    bool finalPaymentSetting = true;

    if (hasState && hasPayload) {
      print('✅ Detected nested structure with state + payload');

      // Get payment_setting_exists from ROOT level - FIXED LOGIC
      finalPaymentSetting = json['payment_setting_exists'] == true;
      print('✅ payment_setting_exists from root: $finalPaymentSetting');

      // Get user data from payload
      if (json['payload'] is Map<String, dynamic>) {
        payloadData = json['payload'] as Map<String, dynamic>;
        print('🔑 PAYLOAD KEYS: ${payloadData.keys.toList()}');

        // Debug payload content
        print('📋 Payload content:');
        payloadData.forEach((key, value) {
          print('   - $key: $value (${value.runtimeType})');
        });
      }
    } else {
      print('ℹ️ Using direct structure');
      payloadData = json;
      finalPaymentSetting = json['payment_setting_exists'] == true;
    }

    // Extract user data from payload
    final data = payloadData['data'] != null && payloadData['data'] is Map<String, dynamic>
        ? LoginData.fromJson(payloadData['data'])
        : null;

    // Debug username extraction
    print('👤 Username extraction debug:');
    print('   - payloadData contains username: ${payloadData.containsKey('username')}');
    print('   - payloadData username value: ${payloadData['username']}');
    print('   - data?.username: ${data?.username}');

    final model = LoginResponseModel(
      status: _parseInt(payloadData['status']),
      message: payloadData['message']?.toString(),
      token: payloadData['token']?.toString(),
      // ✅ FIXED: Get username from payload, not from data
      username: payloadData['username']?.toString() ?? data?.username,
      data: data,
      hasWallet: payloadData['has_wallet'] == true,
      role: payloadData['role']?.toString(),
      // ✅ FIXED: Use the correctly extracted payment setting
      paymentSettingExists: finalPaymentSetting,
    );

    print('🎯 ========== PARSED MODEL ==========');
    print('✅ Status: ${model.status}');
    print('✅ Message: ${model.message}');
    print('✅ Token: ${model.token != null ? "Present" : "Null"}');
    print('✅ Role: ${model.role}');
    print('✅ Has Wallet: ${model.hasWallet}');
    print('✅ Payment Setting Exists: ${model.paymentSettingExists}');
    print('✅ Username: ${model.username}');
    print('✅ Data: ${model.data != null ? "Present" : "Null"}');
    if (model.data != null) {
      print('✅ Data username: ${model.data!.username}');
      print('✅ Data firstname: ${model.data!.firstname}');
      print('✅ Data lastname: ${model.data!.lastname}');
    }
    print('🎯 ========== END DEBUG ==========');

    return model;
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> map = <String, dynamic>{};
    map['status'] = status;
    map['message'] = message;
    map['username'] = username;
    map['token'] = token;
    if (data != null) {
      map['data'] = data!.toJson();
    }
    map['has_wallet'] = hasWallet;
    map['role'] = role;
    map['payment_setting_exists'] = paymentSettingExists;
    return map;
  }
}

class LoginData {
  String? id;
  String? classarmId;
  String? classId;
  String? dob;
  String? adno;
  String? fpicture;
  String? firstname;
  String? username;
  String? othername;
  String? lastname;
  String? gender;
  String? rPin;
  String? status;
  String? classarmName;
  String? className;
  String? role;

  LoginData({
    this.id,
    this.classarmId,
    this.classId,
    this.dob,
    this.adno,
    this.fpicture,
    this.firstname,
    this.othername,
    this.lastname,
    this.username,
    this.gender,
    this.rPin,
    this.status,
    this.classarmName,
    this.className,
    this.role,
  });

  LoginData.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    classarmId = json['classarm_id'];
    classId = json['class_id'];
    dob = json['dob']?.toString();
    adno = json['adno'];
    fpicture = json['fpicture'];
    firstname = json['firstname'];
    othername = json['othername']?.toString();
    lastname = json['lastname'];
    username = json['username'];
    gender = json['gender'];
    rPin = json['r_pin'];
    status = json['status'];
    classarmName = json['classarm_name'];
    className = json['class_name'];
    role = json['role'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> map = <String, dynamic>{};
    map['id'] = id;
    map['classarm_id'] = classarmId;
    map['class_id'] = classId;
    map['dob'] = dob;
    map['adno'] = adno;
    map['fpicture'] = fpicture;
    map['firstname'] = firstname;
    map['username'] = username;
    map['othername'] = othername;
    map['lastname'] = lastname;
    map['gender'] = gender;
    map['r_pin'] = rPin;
    map['status'] = status;
    map['classarm_name'] = classarmName;
    map['class_name'] = className;
    map['role'] = role;
    return map;
  }
}