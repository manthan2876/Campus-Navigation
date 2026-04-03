import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import '../models/navigation_models.dart';

class NavigationEngine {
  final Map<int, Node> nodes = {};
  final Map<String, int> endpointLocations = {};
  bool isInitialized = false;

  Future<void> initialize() async {
    if (isInitialized) return;
    await _loadGraph();
    await _loadEndpoints();
    isInitialized = true;
  }

  Future<void> _loadGraph() async {
    try {
      String contents = await rootBundle.loadString('assets/graph.json');
      var graphD = jsonDecode(contents);

      if (graphD is Map<String, dynamic>) {
        if (graphD['nodes'] is List) {
          for (var node in graphD['nodes']) {
            if (node is Map<String, dynamic>) {
              int? nodeId = node['id'];
              double? latitude = node['latitude'];
              double? longitude = node['longitude'];
              bool indoors = node.containsKey('indoors') ? node['indoors'] : false;
              bool vertical = indoors && node.containsKey('vertical') ? node['vertical'] : false;
              int level = indoors && !vertical && node.containsKey('level') ? node['level'] : 0;
              
              if (nodeId != null && latitude != null && longitude != null) {
                nodes[nodeId] = Node(latitude, longitude, indoors, level, vertical);
              }
            }
          }
        }

        if (graphD['edges'] is List) {
          for (var edge in graphD['edges']) {
            if (edge is Map<String, dynamic>) {
              int? node1Id = edge['node_1'];
              int? node2Id = edge['node_2'];
              double? distance = (edge['distance'] as num?)?.toDouble();
              bool? ada = edge['ada'];

              if (node1Id != null && node2Id != null && distance != null && ada != null) {
                Node? node1 = nodes[node1Id];
                Node? node2 = nodes[node2Id];

                if (node1 != null && node2 != null) {
                  Node.connect(node1, node2, Edge(distance, ada));
                }
              }
            }
          }
        }
      }
    } catch (e) {
      print("Error loading graph: \$e");
    }
  }

  Future<void> _loadEndpoints() async {
    try {
      String endpointContents = await rootBundle.loadString('assets/endpoints.json');
      var endpointsJson = jsonDecode(endpointContents);

      if (endpointsJson is Map<String, dynamic> && endpointsJson['endpoints'] is List) {
        for (var endpoint in endpointsJson['endpoints']) {
          if (endpoint is Map<String, dynamic>) {
            String? location = endpoint['location'];
            int? nodeId = endpoint['node_id'];

            if (location != null && nodeId != null) {
              endpointLocations[location] = nodeId;
            }
          }
        }
      }
    } catch (e) {
      print("Error loading endpoints: \$e");
    }
  }

  double _heuristic(Node node, Node goal) {
    const distCalc = DistanceVincenty(roundResult: false);
    return distCalc.as(LengthUnit.Meter, node.coords, goal.coords);
  }

  List<Node>? calculateRoute(int startID, int goalID, {bool adaOnly = false}) {
    if (!nodes.containsKey(startID) || !nodes.containsKey(goalID)) return null;

    Node start = nodes[startID]!;
    Node goal = nodes[goalID]!;
    
    // Reset costs from previous runs
    for (var node in nodes.values) {
      node.gCost = double.infinity;
      node.hCost = double.infinity;
      node.fCost = double.infinity;
      node.parent = null;
    }

    var openSet = <Node>{start};
    var closedSet = <Node>{};

    start.gCost = 0;
    start.hCost = _heuristic(start, goal);
    start.fCost = start.hCost;

    while (openSet.isNotEmpty) {
      var current = openSet.reduce((a, b) => a.fCost < b.fCost ? a : b);

      if (current == goal) {
        return _reconstructPath(current, start);
      }

      openSet.remove(current);
      closedSet.add(current);

      for (var neighbor in current.getNeighbors(adaOnly: adaOnly)) {
        if (closedSet.contains(neighbor)) continue;

        var tentativeGScore = current.gCost + current.connections[neighbor]!.weight;

        if (!openSet.contains(neighbor)) {
          openSet.add(neighbor);
        } else if (tentativeGScore >= neighbor.gCost) {
          continue;
        }

        neighbor.parent = current;
        neighbor.gCost = tentativeGScore;
        neighbor.hCost = _heuristic(neighbor, goal);
        neighbor.fCost = neighbor.gCost + neighbor.hCost;
      }
    }

    return null;
  }

  List<Node> _reconstructPath(Node current, Node start) {
    var path = <Node>[current];
    while (current.parent != null && current != start) {
      current = current.parent!;
      path.add(current);
    }
    return path.reversed.toList();
  }

  Map<int?, List<Node>> segmentPath(List<Node> path) {
    Map<int?, List<Node>> segmentedPaths = {};
    List<Node> currentSegment = [];
    int? currentFloor = path.first.level;

    for (var node in path) {
      var nodeFloor = node.level;
      var isVertical = node.vertical;
      if (nodeFloor != currentFloor && !isVertical) {
        var lastSegment = List.from(currentSegment);
        if (currentFloor != null) {
          segmentedPaths[currentFloor] = List.from(lastSegment);
        }
        currentSegment.clear();
        currentSegment.add(lastSegment.last);
        currentFloor = nodeFloor;
      }
      currentSegment.add(node);
    }
    if (currentSegment.isNotEmpty) {
      segmentedPaths[currentFloor] = currentSegment;
    }
    return segmentedPaths;
  }
}
