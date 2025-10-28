class LoginResponseModel {
  int? status;
  String? message;
  String? token;
  String? username;
  LoginData? data;
  bool? hasWallet;
  String? role;

  LoginResponseModel({
    this.status,
    this.message,
    this.token,
    this.data,
    this.hasWallet,
    this.username,
    this.role,
  });

  LoginResponseModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    username = json['username'];
    token = json['token'];
    data = json['data'] != null ? LoginData.fromJson(json['data']) : null;
    hasWallet = json['has_wallet'];
    role = json['role']; // This is correctly reading from JSON

    // Add debug logging
    print('🔍 LOGIN MODEL - FROM JSON:');
    print('   - Role from API: $role');
    print('   - Data role: ${data?.role}');
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
    map['role'] = role; // ✅ FIXED: Now including role!

    // Add debug logging
    print('🔍 LOGIN MODEL - TO JSON:');
    print('   - Role being saved: $role');
    print('   - Full JSON being saved: $map');

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
