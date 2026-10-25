import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:galaxy_vpn/core/constants/app_constants.dart';
import 'package:galaxy_vpn/data/datasources/remote/server_remote_data_source.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('merges and deduplicates the official VPN Gate catalogs', () async {
    final calls = <Uri>[];
    final profile = base64.encode(
      utf8.encode('client\ndev tun\nproto tcp-client\nremote relay 443\n'),
    );
    String row({
      required String name,
      required String ip,
      required String country,
      required String code,
    }) =>
        '$name,$ip,100,20,5000000,$country,$code,1,1,1,1,1,operator,,$profile';

    final primaryResponse = [
      '*vpn_servers',
      row(
        name: 'uk-relay',
        ip: '192.0.2.10',
        country: 'United Kingdom',
        code: 'GB',
      ),
    ].join('\n');
    final mirrorResponse = [
      '*vpn_servers',
      row(
        name: 'uk-relay',
        ip: '192.0.2.10',
        country: 'United Kingdom',
        code: 'GB',
      ),
      row(
        name: 'croatia-relay',
        ip: '192.0.2.20',
        country: 'Croatia',
        code: 'HR',
      ),
    ].join('\n');

    final client = MockClient((request) async {
      calls.add(request.url);
      return http.Response(
        request.url.toString() == AppConstants.vpnGateApiUrl
            ? primaryResponse
            : mirrorResponse,
        200,
      );
    });
    final dataSource = ServerRemoteDataSource(client);

    final servers = await dataSource.fetchRelays();

    expect(calls, contains(Uri.parse(AppConstants.vpnGateApiUrl)));
    expect(calls, contains(Uri.parse(AppConstants.vpnGateApiMirrorUrl)));
    expect(servers, hasLength(2));
    expect(servers.map((server) => server.countryCode).toSet(), {'GB', 'HR'});
    expect(
      servers.every((server) => server.ovpnConfig.contains('remote ')),
      isTrue,
    );

    dataSource.dispose();
  });
}
