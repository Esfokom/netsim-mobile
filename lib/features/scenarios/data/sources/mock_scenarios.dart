// import '../../../devices/data/models/device_model.dart';
// import '../../../devices/data/models/device_parameters.dart';
// import '../../../devices/data/models/device_position.dart';
// import '../../../devices/data/models/device_status.dart';
// import '../models/scenario_model.dart';
// import '../models/scenario_metadata.dart';
//
// class MockScenarios {
//   static List<Scenario> scenarios = [
//     Scenario(
//       name: "Basic Networking",
//       difficulty: "easy",
//       timeLimit: 600,
//       score: 200,
//       devices: [
//         Device(
//           id: "1",
//           type: "Router",
//           position: Position(x: 0, y: 0),
//           parameters: Parameters(
//             pingInterval: 30,
//             latencyThreshold: 100,
//             failureProbability: 0.1,
//             trafficLoad: 10,
//           ),
//           status: Status(
//             online: true,
//             latency: 20,
//             lastChecked: DateTime.now(),
//           ),
//         ),
//         Device(
//           id: "2",
//           type: "Sever",
//           position: Position(x: 5, y: 5),
//           parameters: Parameters(
//             pingInterval: 20,
//             latencyThreshold: 100,
//             failureProbability: 0.1,
//             trafficLoad: 10,
//           ),
//           status: Status(
//             online: true,
//             latency: 20,
//             lastChecked: DateTime.now(),
//           ),
//         ),
//       ],
//       metadata: Metadata(
//         createdBy: "admin",
//         createdAt: DateTime.now(),
//         description: "Introductory networking scenario.",
//       ),
//     ),
//     Scenario(
//       name: "Advanced Routing",
//       difficulty: "hard",
//       timeLimit: 1200,
//       score: 250,
//       devices: [
//         Device(
//           id: "3",
//           type: "Switch",
//           position: Position(x: 10, y: 20),
//           parameters: Parameters(
//             pingInterval: 15,
//             latencyThreshold: 50,
//             failureProbability: 0.2,
//             trafficLoad: 70,
//           ),
//           status: Status(
//             online: false,
//             latency: 200,
//             lastChecked: DateTime.now(),
//           ),
//         ),
//         Device(
//           id: "4",
//           type: "Firewall",
//           position: Position(x: 5, y: 15),
//           parameters: Parameters(
//             pingInterval: 20,
//             latencyThreshold: 80,
//             failureProbability: 0.05,
//             trafficLoad: 30,
//           ),
//           status: Status(
//             online: true,
//             latency: 40,
//             lastChecked: DateTime.now(),
//           ),
//         ),
//         Device(
//           id: "5",
//           type: "PC",
//           position: Position(x: 0, y: 0),
//           parameters: Parameters(
//             pingInterval: 30,
//             latencyThreshold: 100,
//             failureProbability: 0.1,
//             trafficLoad: 8,
//           ),
//           status: Status(
//             online: true,
//             latency: 20,
//             lastChecked: DateTime.now(),
//           ),
//         ),
//       ],
//       metadata: Metadata(
//         createdBy: "trainer",
//         createdAt: DateTime.now(),
//         description: "Challenging routing exercise with failures.",
//       ),
//     ),
//     Scenario(
//       name: "Campus Wireless Network",
//       difficulty: "medium",
//       timeLimit: 900,
//       score: 150,
//       devices: [
//         Device(
//           id: "6",
//           type: "PC",
//           position: Position(x: 8, y: 10),
//           parameters: Parameters(
//             pingInterval: 25,
//             latencyThreshold: 90,
//             failureProbability: 0.08,
//             trafficLoad: 40,
//           ),
//           status: Status(
//             online: true,
//             latency: 25,
//             lastChecked: DateTime.now(),
//           ),
//         ),
//         Device(
//           id: "7",
//           type: "Firewall",
//           position: Position(x: 12, y: 18),
//           parameters: Parameters(
//             pingInterval: 20,
//             latencyThreshold: 70,
//             failureProbability: 0.12,
//             trafficLoad: 55,
//           ),
//           status: Status(
//             online: true,
//             latency: 30,
//             lastChecked: DateTime.now(),
//           ),
//         ),
//         Device(
//           id: "8",
//           type: "Switch",
//           position: Position(x: 0, y: 0),
//           parameters: Parameters(
//             pingInterval: 30,
//             latencyThreshold: 100,
//             failureProbability: 0.1,
//             trafficLoad: 10,
//           ),
//           status: Status(
//             online: true,
//             latency: 20,
//             lastChecked: DateTime.now(),
//           ),
//         ),
//       ],
//       metadata: Metadata(
//         createdBy: "network_admin",
//         createdAt: DateTime.now(),
//         description:
//             "Scenario simulating a wireless network environment across campus buildings.",
//       ),
//     ),
//     Scenario(
//       name: "Data Center Outage",
//       difficulty: "hard",
//       timeLimit: 1500,
//       score: 300,
//       devices: [
//         Device(
//           id: "8",
//           type: "Router",
//           position: Position(x: 0, y: 0),
//           parameters: Parameters(
//             pingInterval: 30,
//             latencyThreshold: 100,
//             failureProbability: 0.1,
//             trafficLoad: 10,
//           ),
//           status: Status(
//             online: true,
//             latency: 20,
//             lastChecked: DateTime.now(),
//           ),
//         ),
//         Device(
//           id: "9",
//           type: "Sever",
//           position: Position(x: 5, y: 5),
//           parameters: Parameters(
//             pingInterval: 20,
//             latencyThreshold: 100,
//             failureProbability: 0.1,
//             trafficLoad: 10,
//           ),
//           status: Status(
//             online: true,
//             latency: 20,
//             lastChecked: DateTime.now(),
//           ),
//         ),
//       ],
//       metadata: Metadata(
//         createdBy: "admin",
//         createdAt: DateTime.now(),
//         description: "Scenario simulating a data center outage.",
//       ),
//     ),
//     Scenario(
//       name: "Small Office Setup",
//       difficulty: "easy",
//       timeLimit: 400,
//       score: 80,
//       devices: [
//         Device(
//           id: "10",
//           type: "Router",
//           position: Position(x: 0, y: 0),
//           parameters: Parameters(
//             pingInterval: 30,
//             latencyThreshold: 100,
//             failureProbability: 0.1,
//             trafficLoad: 10,
//           ),
//           status: Status(
//             online: true,
//             latency: 20,
//             lastChecked: DateTime.now(),
//           ),
//         ),
//         Device(
//           id: "11",
//           type: "Sever",
//           position: Position(x: 5, y: 5),
//           parameters: Parameters(
//             pingInterval: 20,
//             latencyThreshold: 100,
//             failureProbability: 0.1,
//             trafficLoad: 10,
//           ),
//           status: Status(
//             online: true,
//             latency: 20,
//             lastChecked: DateTime.now(),
//           ),
//         ),
//       ],
//       metadata: Metadata(
//         createdBy: "trainer",
//         createdAt: DateTime.now(),
//         description: "Setup for a small office network.",
//       ),
//     ),
//   ];
// }
