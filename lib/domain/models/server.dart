// Top-level response
class ServerResponse {
  final bool status;
  final List<Server> servers;

  ServerResponse({
    required this.status,
    required this.servers,
  });

  factory ServerResponse.fromJson(Map<String, dynamic> json) {
    return ServerResponse(
      status: json['status'],
      servers: (json['servers'] as List)
          .map((e) => Server.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'servers': servers.map((e) => e.toJson()).toList(),
    };
  }
}

// Server model
class Server {
  final int id;
  final String image;
  final String name;
  final Platforms platforms;
  final String type;
  final int status;
  final String createdAt;
  final List<SubServer> subServers;

  Server({
    required this.id,
    required this.image,
    required this.name,
    required this.platforms,
    required this.type,
    required this.status,
    required this.createdAt,
    required this.subServers,
  });

  factory Server.fromJson(Map<String, dynamic> json) {
    return Server(
      id: json['id'],
      image: json['image'],
      name: json['name'],
      platforms: Platforms.fromJson(json['platforms']),
      type: json['type'],
      status: json['status'],
      createdAt: json['created_at'],
      subServers: (json['sub_servers'] as List)
          .map((e) => SubServer.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'image': image,
      'name': name,
      'platforms': platforms.toJson(),
      'type': type,
      'status': status,
      'created_at': createdAt,
      'sub_servers': subServers.map((e) => e.toJson()).toList(),
    };
  }
}

// Platforms model
class Platforms {
  final bool android;
  final bool ios;
  final bool macos;
  final bool windows;

  Platforms({
    required this.android,
    required this.ios,
    required this.macos,
    required this.windows,
  });

  factory Platforms.fromJson(Map<String, dynamic> json) {
    return Platforms(
      android: json['android'],
      ios: json['ios'],
      macos: json['macos'],
      windows: json['windows'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'android': android,
      'ios': ios,
      'macos': macos,
      'windows': windows,
    };
  }
}

// SubServer model
class SubServer {
  final int id;
  final int serverId;
  final String name;
  final int status;
  final VpsServer vpsServer;

  SubServer({
    required this.id,
    required this.serverId,
    required this.name,
    required this.status,
    required this.vpsServer,
  });

  factory SubServer.fromJson(Map<String, dynamic> json) {
    return SubServer(
      id: json['id'],
      serverId: json['server_id'],
      name: json['name'],
      status: json['status'],
      vpsServer: VpsServer.fromJson(json['vps_server']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'server_id': serverId,
      'name': name,
      'status': status,
      'vps_server': vpsServer.toJson(),
    };
  }
}

// VPS Server model
class VpsServer {
  final int id;
  final String name;
  final String ipAddress;
  final String domain;
  int? latency;

  VpsServer({
    required this.id,
    required this.name,
    required this.ipAddress,
    required this.domain,
    this.latency,
  });

  factory VpsServer.fromJson(Map<String, dynamic> json) {
    return VpsServer(
      id: json['id'],
      name: json['name'],
      ipAddress: json['ip_address'],
      domain: json['domain'],
      latency: json['latency'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'ip_address': ipAddress,
      'domain': domain,
      'latency': latency,
    };
  }
}
