import '../../entities/vpn_live_metrics.dart';
import '../../repositories/vpn_repository.dart';

class GetVpnMetricsStreamUseCase {
  final VpnRepository repository;

  GetVpnMetricsStreamUseCase(this.repository);

  Stream<VpnLiveMetrics> call() => repository.metricsStream;
}
