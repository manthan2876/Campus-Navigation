import 'package:latlong2/latlong.dart';

class Node {
  final LatLng coords;
  final bool indoors;
  final bool vertical;
  final int level;
  
  // Map of neighbors and their corresponding edge data
  final Map<Node, Edge> connections = {};

  // For A* search
  double gCost = double.infinity;
  double hCost = double.infinity;
  double fCost = double.infinity;
  Node? parent;

  Node(double lat, double lng, this.indoors, this.level, this.vertical)
      : coords = LatLng(lat, lng);

  void addNeighbor(Node other, Edge edge) {
    connections[other] = edge;
  }

  Iterable<Node> getNeighbors({bool adaOnly = false}) {
    return connections.keys
        .where((neighbor) => !adaOnly || connections[neighbor]!.ada);
  }

  static void connect(Node a, Node b, Edge edge) {
    a.addNeighbor(b, edge);
    b.addNeighbor(a, edge);
  }
}

class Edge {
  final double weight;
  final bool ada;

  Edge(this.weight, this.ada);
}
