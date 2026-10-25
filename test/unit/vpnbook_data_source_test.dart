import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:galaxy_vpn/data/datasources/remote/relay_probe.dart';
import 'package:galaxy_vpn/data/datasources/remote/vpnbook_data_source.dart';

/// Trimmed copy of the structure of https://www.vpnbook.com/freevpn.
const _page = '''
<html><head><script>var x = "Password: notThis";</script></head><body>
<h2>VPN Server Locations</h2>
<div>US Server 1 <code>us16.vpnbook.com</code> <span>Online</span> OpenVPN WireGuard</div>
<div>UK Server 2 <code>uk68.vpnbook.com</code> <span>Online</span> OpenVPN WireGuard</div>
<div>Germany Server 1 <code>de20.vpnbook.com</code> <span>Online</span> OpenVPN WireGuard</div>
<div>Canada Server 3 <code>ca225.vpnbook.com</code> Canada PPTP, Outline</div>
<h2>Frequently asked questions</h2>
<p>What is the VPNBook username and password? Username: <strong>vpnbook</strong>.
Password: <strong>sample123</strong>. The same login works on every server.</p>
</body></html>
''';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('VpnBookDataSource.parsePage', () {
    test('reads the published login, ignoring scripts', () {
      final page = VpnBookDataSource.parsePage(_page)!;
      expect(page.username, 'vpnbook');
      expect(page.password, 'sample123');
    });

    test('keeps only servers that offer OpenVPN', () {
      final page = VpnBookDataSource.parsePage(_page)!;
      expect(page.hostnames, [
        'de20.vpnbook.com',
        'uk68.vpnbook.com',
        'us16.vpnbook.com',
      ]);
    });

    test('returns null when the page has no login', () {
      expect(VpnBookDataSource.parsePage('<p>Maintenance</p>'), isNull);
    });

    test('falls back to the known servers when none are listed', () {
      final page = VpnBookDataSource.parsePage(
        '<p>Username: vpnbook. Password: abc123.</p>',
      )!;
      expect(page.hostnames, VpnBookDataSource.knownHostnames);
    });
  });

  group('VpnBookDataSource.buildServers', () {
    final servers = VpnBookDataSource.buildServers(
      VpnBookDataSource.parsePage(_page)!,
      'nobind\n<ca>\nCA\n</ca>\n',
      now: DateTime(2026),
    );

    test('maps each server to its country with the live login', () {
      expect(servers.map((s) => s.countryCode), ['DE', 'GB', 'US']);
      final uk = servers[1];
      expect(uk.id, 'vpnbook_uk68.vpnbook.com');
      expect(uk.country, 'United Kingdom');
      expect(uk.username, 'vpnbook');
      expect(uk.password, 'sample123');
      expect(uk.supportsSstp, isFalse);
      expect(VpnBookDataSource.isVpnBook(uk), isTrue);
    });

    test('tries UDP 53 before TCP 443', () {
      expect(OpenVpnRemote.parseAll(servers.first.ovpnConfig), const [
        OpenVpnRemote(host: 'de20.vpnbook.com', port: 53, udp: true),
        OpenVpnRemote(host: 'de20.vpnbook.com', port: 443, udp: false),
      ]);
      expect(servers.first.ovpnConfig, contains('<ca>\nCA\n</ca>'));
    });
  });

  test('bundled template carries the shared certificates', () async {
    final template = await rootBundle.loadString(
      VpnBookDataSource.templateAsset,
    );
    expect(template, contains('auth-user-pass'));
    for (final block in ['ca', 'cert', 'key']) {
      expect(template, contains('<$block>'));
    }
    expect(template, isNot(contains('remote ')));
  });
}
