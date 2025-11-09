// import 'package:flutter/material.dart';
// import 'package:shadcn_ui/shadcn_ui.dart';
// import '../../../devices/data/models/device_model.dart';
// import '../../../devices/presentation/screens/device_list_screen.dart';
// import '../../data/models/scenario_model.dart';
// import 'device_overview_item.dart';
//
// class DevicesOverviewCard extends StatelessWidget {
//   final Scenario scenario;
//
//   const DevicesOverviewCard({super.key, required this.scenario});
//
//   @override
//   Widget build(BuildContext context) {
//     final theme = ShadTheme.of(context);
//
//     return ShadCard(
//       width: double.infinity,
//       child: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Icon(Icons.devices, color: theme.colorScheme.primary, size: 24),
//                 const SizedBox(width: 8),
//                 Text(
//                   'Devices Overview',
//                   style: theme.textTheme.h4.copyWith(
//                     fontWeight: FontWeight.w600,
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 8),
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//               decoration: BoxDecoration(
//                 color: theme.colorScheme.primary,
//                 borderRadius: BorderRadius.circular(20),
//               ),
//               child: Text(
//                 '${scenario.devices.length} ${scenario.devices.length == 1 ? 'Device' : 'Devices'}',
//                 style: TextStyle(
//                   fontSize: 12,
//                   fontWeight: FontWeight.w600,
//                   color: theme.colorScheme.background,
//                 ),
//               ),
//             ),
//             const SizedBox(height: 16),
//             scenario.devices.isEmpty
//                 ? _buildEmptyState()
//                 : _buildDevicesList(scenario.devices),
//             const SizedBox(height: 16),
//             ShadButton(
//               width: double.infinity,
//               size: ShadButtonSize.lg,
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   const Icon(Icons.visibility, size: 20),
//                   const SizedBox(width: 8),
//                   const Text('View All Devices'),
//                 ],
//               ),
//               onPressed: () {
//                 Navigator.push(
//                   context,
//                   MaterialPageRoute(
//                     builder: (context) => DeviceListScreen(
//                       devices: scenario.devices,
//                       scenario: scenario,
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildEmptyState() {
//     return Center(
//       child: Padding(
//         padding: const EdgeInsets.all(20),
//         child: Column(
//           children: [
//             Icon(Icons.devices_other, size: 48, color: Colors.grey[400]),
//             const SizedBox(height: 8),
//             Text(
//               'No devices in this scenario',
//               style: TextStyle(color: Colors.grey[600], fontSize: 14),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildDevicesList(List<Device> devices) {
//     return Column(
//       children: [
//         ...devices.take(3).map((device) {
//           return Padding(
//             padding: const EdgeInsets.only(bottom: 8),
//             child: DeviceOverviewItem(device: device),
//           );
//         }),
//         if (devices.length > 3)
//           Padding(
//             padding: const EdgeInsets.only(top: 8),
//             child: Text(
//               '+ ${devices.length - 3} more devices',
//               style: TextStyle(
//                 color: Colors.grey[600],
//                 fontSize: 12,
//                 fontStyle: FontStyle.italic,
//               ),
//             ),
//           ),
//       ],
//     );
//   }
// }
