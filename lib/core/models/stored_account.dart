class StoredAccount {
  final String handle;
  final String did;
  final String? displayName;
  final String? avatar;
  final String service;

  StoredAccount({
    required this.handle,
    required this.did,
    this.displayName,
    this.avatar,
    required this.service,
  });

  Map<String, dynamic> toJson() => {
        'handle': handle,
        'did': did,
        'displayName': displayName,
        'avatar': avatar,
        'service': service,
      };

  factory StoredAccount.fromJson(Map<String, dynamic> json) => StoredAccount(
        handle: json['handle'],
        did: json['did'],
        displayName: json['displayName'],
        avatar: json['avatar'],
        service: json['service'],
      );
}
