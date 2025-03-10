class WatchingProfileResponse {
  bool status;
  List<WatchingProfileModel> data;
  String message;
  WatchingProfileModel newUserProfile;

  WatchingProfileResponse({
    this.status = false,
    this.data = const <WatchingProfileModel>[],
    this.message = "",
    required this.newUserProfile,
  });

  factory WatchingProfileResponse.fromJson(Map<String, dynamic> json) {
    return WatchingProfileResponse(
        status: json['status'] is bool ? json['status'] : false,
        data: json['data'] is List ? List<WatchingProfileModel>.from(json['data'].map((x) => WatchingProfileModel.fromJson(x))) : [],
        message: json['message'] is String ? json['message'] : "",
        newUserProfile: json['user_profile'] != null ? WatchingProfileModel.fromJson(json['user_profile']) : WatchingProfileModel());
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'data': data.map((e) => e.toJson()).toList(),
      'message': message,
    };
  }
}

class WatchingProfileModel {
  int id;
  int userId;
  String name;
  String avatar;

  WatchingProfileModel({
    this.id = -1,
    this.userId = -1,
    this.name = "",
    this.avatar = "",
  });

  factory WatchingProfileModel.fromJson(Map<String, dynamic> json) {
    return WatchingProfileModel(
      id: json['id'] is int ? json['id'] : -1,
      userId: json['user_id'] is int ? json['user_id'] : -1,
      name: json['name'] is String ? json['name'] : "",
      avatar: json['avatar'] is String ? json['avatar'] : "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'avatar': avatar,
    };
  }
}

class UserProfile {
  final bool status;
  final String message;

  UserProfile({
    required this.status,
    required this.message,
  });

  // Factory method to create a UserProfile instance from a JSON object
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      status: json['status'],
      message: json['message'],
    );
  }

  // Method to convert UserProfile instance to JSON format
  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
    };
  }
}

class SaveUserProfile {
  final bool status;
  final String message;

  SaveUserProfile({required this.status, required this.message});

  factory SaveUserProfile.fromJson(Map<String, dynamic> json) {
    return SaveUserProfile(
      status: json['status'],
      message: json['message'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
    };
  }
}
