import 'dart:collection';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:mimir/network/session.dart';

import '../entity/local.dart';
import '../entity/remote.dart';
import 'anaylze.dart';

class ExpenseGetService {
  String al2(int v) => v < 10 ? "0$v" : "$v";

  String format(DateTime d) => "${d.year}${al2(d.month)}${al2(d.day)}${al2(d.hour)}${al2(d.minute)}${al2(d.second)}";

  static const String magicNumber = "adc4ac6822fd462780f878b86cb94688";
  static const urlPath = "https://xgfy.sit.edu.cn/yktapi/services/querytransservice/querytrans";
  final ISession session;

  ExpenseGetService(this.session);

  Future<List<Transaction>> fetch({
    required String studentID,
    required DateTime from,
    required DateTime to,
  }) async {
    String curTs = format(DateTime.now());
    String fromTs = format(from);
    String toTs = format(to);
    String auth = composeAuth(studentID, fromTs, toTs, curTs);

    final res = await session.request(
      urlPath,
      ReqMethod.post,
      para: {
        'timestamp': curTs,
        'starttime': fromTs,
        'endtime': toTs,
        'sign': auth,
        'sign_method': 'HMAC',
        'stuempno': studentID,
      },
      options: SessionOptions(contentType: 'text/plain'),
    );
    final raw = anaylzeJson(res.data);
    return raw.retdata.map(analyzeFull).toList();
  }

  DatapackRaw anaylzeJson(dynamic data) {
    var res = HashMap<String, dynamic>.of(data);
    var retdataRaw = res["retdata"];
    var retdata = json.decode(retdataRaw);
    res["retdata"] = retdata;
    return DatapackRaw.fromJson(res);
  }

  String composeAuth(String studentId, String from, String to, String cur) {
    String full = studentId + from + to + cur;
    var msg = utf8.encode(full);
    var key = utf8.encode(magicNumber);
    var hmac = Hmac(sha1, key);
    return hmac.convert(msg).toString();
  }
}
