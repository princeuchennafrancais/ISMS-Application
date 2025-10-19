class ProfileResponseModel {
  int? status;
  String? message;
  ProfileData? data;

  ProfileResponseModel({this.status, this.message, this.data});

  ProfileResponseModel.fromJson(Map<String, dynamic> json) {
    status = json['status'];
    message = json['message'];
    data = json['data'] != null ? ProfileData.fromJson(json['data']) : null;
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> map = <String, dynamic>{};
    map['status'] = status;
    map['message'] = message;
    if (data != null) {
      map['data'] = data!.toJson();
    }
    return map;
  }
}

class ProfileData {
  String? id;
  String? classarmId;
  String? classId;
  String? dob;
  String? adno;
  String? fpicture;
  String? firstname;
  String? othername;
  String? lastname;
  String? gender;
  String? rPin;
  String? status;
  String? classarmName;
  String? className;

  ProfileData({
    this.id,
    this.classarmId,
    this.classId,
    this.dob,
    this.adno,
    this.fpicture,
    this.firstname,
    this.othername,
    this.lastname,
    this.gender,
    this.rPin,
    this.status,
    this.classarmName,
    this.className,
  });

  ProfileData.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    classarmId = json['classarm_id'];
    classId = json['class_id'];
    dob = json['dob']?.toString();
    adno = json['adno'];
    fpicture = json['fpicture'];
    firstname = json['firstname'];
    othername = json['othername']?.toString();
    lastname = json['lastname'];
    gender = json['gender'];
    rPin = json['r_pin'];
    status = json['status'];
    classarmName = json['classarm_name'];
    className = json['class_name'];
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
    map['othername'] = othername;
    map['lastname'] = lastname;
    map['gender'] = gender;
    map['r_pin'] = rPin;
    map['status'] = status;
    map['classarm_name'] = classarmName;
    map['class_name'] = className;
    return map;
  }
}
