import 'package:dio/dio.dart';
import 'package:sit/init.dart';

import 'package:sit/session/ywb.dart';

import '../entity/meta.dart';

const String _serviceFunctionList = 'https://xgfy.sit.edu.cn/app/public/queryAppManageJson';
const String _serviceFunctionDetail = 'https://xgfy.sit.edu.cn/app/public/queryAppFormJson';

class YwbApplicationMetaService {
  YwbSession get session => Init.ywbSession;

  const YwbApplicationMetaService();

  Future<List<YwbApplicationMeta>> getApplicationMetas() async {
    final response = await session.request(
      _serviceFunctionList,
      data: '{"appObject":"student","appName":null}',
      options: Options(
        responseType: ResponseType.json,
        method: "POST",
      ),
    );

    final Map<String, dynamic> data = response.data;
    final List<YwbApplicationMeta> functionList = (data['value'] as List<dynamic>)
        .map((e) => YwbApplicationMeta.fromJson(e))
        .where((element) => element.status == 1) // Filter functions unavailable.
        .toList();

    return functionList;
  }

  Future<YwbApplicationMetaDetails> getMetaDetails(String functionId) async {
    final response = await session.request(
      _serviceFunctionDetail,
      data: '{"appID":"$functionId"}',
      options: Options(
        responseType: ResponseType.json,
        method: "POST",
      ),
    );
    final Map<String, dynamic> data = response.data;
    final List<YwbApplicationMetaDetailSection> sections =
        (data['value'] as List<dynamic>).map((e) => YwbApplicationMetaDetailSection.fromJson(e)).toList();

    return YwbApplicationMetaDetails(id: functionId, sections: sections);
  }
}
