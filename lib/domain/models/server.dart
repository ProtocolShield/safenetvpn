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
    List<SubServer> subServers = [];
    
    // Parse sub_servers if they exist
    if (json['sub_servers'] != null && (json['sub_servers'] as List).isNotEmpty) {
      subServers = (json['sub_servers'] as List)
          .map((e) => SubServer.fromJson(e))
          .toList();
    } else {
      // If no sub_servers, create a default one from the server data
      // Try to extract IP/domain from the server object itself
      String ip = '';
      String domain = '';
      
      // Check if server has IP/domain fields directly
      if (json['ip_address'] != null) {
        ip = json['ip_address'].toString();
      } else if (json['ipAddress'] != null) {
        ip = json['ipAddress'].toString();
      } else if (json['ip'] != null) {
        ip = json['ip'].toString();
      }
      
      if (json['domain'] != null) {
        domain = json['domain'].toString();
      } else if (json['host'] != null) {
        domain = json['host'].toString();
      }
      
      // Temporary fallback: use server ID as identifier if no IP/domain
      // This is used when sub_servers are empty; VPS servers are handled separately via fetchVpsServers()
      if (ip.isEmpty && domain.isEmpty) {
        // Try to use server ID or name - this is temporary until backend provides real IPs
        int serverId = json['id'] ?? 0;
        domain = 'vps-$serverId.psvpn.local'; // placeholder domain
        // Note: This warning is suppressed because VPS servers are now handled by fetchVpsServers()
        // print("⚠️  WARNING: No IP/domain in server response. Using placeholder: $domain");
      }
      
      // Create a default SubServer with the server as VPS
      subServers = [
        SubServer(
          id: json['id'] ?? 0,
          serverId: json['id'] ?? 0,
          name: json['name'] ?? 'Default',
          status: json['status'] ?? 1,
          vpsServer: VpsServer(
            id: json['id'] ?? 0,
            name: json['name'] ?? 'Default',
            ipAddress: ip,
            domain: domain,
          ),
        )
      ];
    }
    
    return Server(
      id: json['id'],
      image: json['image'],
      name: json['name'],
      platforms: Platforms.fromJson(json['platforms']),
      type: json['type'],
      status: json['status'],
      createdAt: json['created_at'],
      subServers: subServers,
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
  final String? username;
  final String? password;
  final int? port;
  final String? privateKey;
  int? latency;

  VpsServer({
    required this.id,
    required this.name,
    required this.ipAddress,
    required this.domain,
    this.username,
    this.password,
    this.port,
    this.privateKey,
    this.latency,
  });

  factory VpsServer.fromJson(Map<String, dynamic> json) {
    // Try multiple possible field names for IP address
    String ip = '';
    if (json['ip_address'] != null) {
      ip = json['ip_address'].toString();
    } else if (json['ipAddress'] != null) {
      ip = json['ipAddress'].toString();
    } else if (json['ip'] != null) {
      ip = json['ip'].toString();
    }
    
    // Try multiple possible field names for domain
    String domain = '';
    if (json['domain'] != null) {
      domain = json['domain'].toString();
    } else if (json['host'] != null) {
      domain = json['host'].toString();
    }
    
    return VpsServer(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      ipAddress: ip,
      domain: domain,
      username: json['username'],
      password: json['password'],
      port: json['port'],
      privateKey: json['private_key'],
      latency: json['latency'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'ip_address': ipAddress,
      'domain': domain,
      'username': username,
      'password': password,
      'port': port,
      'private_key': privateKey,
      'latency': latency,
    };
  }
}
