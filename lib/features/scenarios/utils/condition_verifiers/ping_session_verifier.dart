import 'package:netsim_mobile/core/utils/app_logger.dart';
import 'package:netsim_mobile/features/simulation/domain/entities/packet.dart';
import 'package:netsim_mobile/features/simulation/domain/entities/ping_session.dart';
import 'package:netsim_mobile/features/scenarios/domain/entities/scenario_condition.dart';

/// Verifier for ping session-based conditions
class PingSessionVerifier {
  /// Find the latest matching ping session by source and destination IP
  /// Returns null if no matching session is found
  static PingSession? findLatestMatchingSession({
    required String sourceIp,
    required String destIp,
    required List<PingSession> sessions,
  }) {
    // Filter sessions matching the IP pair
    final matchingSessions = sessions.where((session) {
      return session.sourceIp == sourceIp && session.targetIp == destIp;
    }).toList();

    if (matchingSessions.isEmpty) {
      appLogger.d(
        '[PingSessionVerifier] No matching session found for $sourceIp -> $destIp',
      );
      return null;
    }

    // Sort by start time descending to get the latest
    matchingSessions.sort((a, b) => b.startTime.compareTo(a.startTime));

    final latestSession = matchingSessions.first;
    appLogger.d(
      '[PingSessionVerifier] Found latest session: ${latestSession.id} '
      '(status: ${latestSession.status.displayName})',
    );

    return latestSession;
  }

  /// Verify response time against threshold with operator
  static bool verifyResponseTime({
    required PingSession session,
    required ResponseTimeOperator operator,
    required int thresholdMs,
  }) {
    final responseTime = session.totalResponseTime;

    if (responseTime == null) {
      appLogger.d(
        '[PingSessionVerifier] Response time check failed: no response time recorded',
      );
      return false;
    }

    final responseMs = responseTime.inMilliseconds;

    bool result;
    switch (operator) {
      case ResponseTimeOperator.greaterThan:
        result = responseMs > thresholdMs;
        break;
      case ResponseTimeOperator.lessThan:
        result = responseMs < thresholdMs;
        break;
    }

    appLogger.d(
      '[PingSessionVerifier] Response time check: ${responseMs}ms ${operator.symbol} ${thresholdMs}ms = $result',
    );

    return result;
  }

  /// Verify if ping session timed out
  static bool verifyTimeout({required PingSession session}) {
    final result = session.status == PingSessionStatus.timeout;
    appLogger.d(
      '[PingSessionVerifier] Timeout check: status=${session.status.displayName}, result=$result',
    );
    return result;
  }

  /// Verify if ping session has ARP events
  static bool verifyHasArp({required PingSession session}) {
    final result = session.requiredArp;
    appLogger.d(
      '[PingSessionVerifier] Has ARP check: arpPacketCount=${session.arpPacketCount}, result=$result',
    );
    return result;
  }

  /// Verify if ping session has ICMP events
  static bool verifyHasIcmp({required PingSession session}) {
    final result = session.icmpPacketCount > 0;
    appLogger.d(
      '[PingSessionVerifier] Has ICMP check: icmpPacketCount=${session.icmpPacketCount}, result=$result',
    );
    return result;
  }

  /// Verify if ping was successful
  /// Success is determined by:
  /// 1. Session status is success, OR
  /// 2. Last event is an ICMP echo reply from destination IP to source IP
  static bool verifySuccess({required PingSession session}) {
    // First check session status
    if (session.status == PingSessionStatus.success) {
      appLogger.d(
        '[PingSessionVerifier] Success check: session status is success',
      );
      return true;
    }

    // Check if last event is ICMP echo reply from dest to source
    if (session.events.isEmpty) {
      appLogger.d(
        '[PingSessionVerifier] Success check failed: no events in session',
      );
      return false;
    }

    final lastEvent = session.events.last;

    // Check if it's an ICMP echo reply
    final isEchoReply = lastEvent.packetType == PacketType.icmpEchoReply;
    if (!isEchoReply) {
      appLogger.d(
        '[PingSessionVerifier] Success check failed: last event is ${lastEvent.packetType}, not ICMP echo reply',
      );
      return false;
    }

    // Check if reply is from destination IP to source IP
    // The reply should have: fromIp = original destIp, toIp = original sourceIp
    final isFromDest = lastEvent.fromIp == session.targetIp;
    final isToSource = lastEvent.toIp == session.sourceIp;

    final result = isFromDest && isToSource;
    appLogger.d(
      '[PingSessionVerifier] Success check: '
      'lastEvent.fromIp=${lastEvent.fromIp} == targetIp=${session.targetIp} ($isFromDest), '
      'lastEvent.toIp=${lastEvent.toIp} == sourceIp=${session.sourceIp} ($isToSource), '
      'result=$result',
    );

    return result;
  }

  /// Verify a ping session check based on check type
  static bool verify({
    required PingSession session,
    required PingSessionCheckType checkType,
    ResponseTimeOperator? responseTimeOperator,
    int? responseTimeThresholdMs,
  }) {
    switch (checkType) {
      case PingSessionCheckType.responseTime:
        if (responseTimeOperator == null || responseTimeThresholdMs == null) {
          appLogger.w(
            '[PingSessionVerifier] Response time check requires operator and threshold',
          );
          return false;
        }
        return verifyResponseTime(
          session: session,
          operator: responseTimeOperator,
          thresholdMs: responseTimeThresholdMs,
        );

      case PingSessionCheckType.timeout:
        return verifyTimeout(session: session);

      case PingSessionCheckType.hasArp:
        return verifyHasArp(session: session);

      case PingSessionCheckType.hasIcmp:
        return verifyHasIcmp(session: session);

      case PingSessionCheckType.success:
        return verifySuccess(session: session);
    }
  }
}
