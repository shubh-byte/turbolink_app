/// Data model representing a discovered peer device on the network.
///
/// Each peer has a unique ID, a display name, and a signal strength
/// indicator (0.0 to 1.0) used to position it on the radar visualization.
class Peer {
  final String id;
  final String name;
  final String deviceType; // 'phone', 'tablet', 'laptop'
  final double signalStrength; // 0.0 to 1.0
  final bool isConnected;

  const Peer({
    required this.id,
    required this.name,
    this.deviceType = 'phone',
    this.signalStrength = 0.5,
    this.isConnected = false,
  });

  Peer copyWith({
    String? id,
    String? name,
    String? deviceType,
    double? signalStrength,
    bool? isConnected,
  }) {
    return Peer(
      id: id ?? this.id,
      name: name ?? this.name,
      deviceType: deviceType ?? this.deviceType,
      signalStrength: signalStrength ?? this.signalStrength,
      isConnected: isConnected ?? this.isConnected,
    );
  }
}
