class Hadeeth
{
  static List<String> ids = [];
  static List<String> hadeeths = [];
  static List<String> explanation = [];
  Hadeeth.getIds(Map<String, dynamic> json)
  {
    // to avoid duplicate ids
    ids.clear();
    json['data'].forEach((element) {
      ids.add(element['id']);
    });
  }
  Hadeeth.getHadeethInfo(Map<String, dynamic> json)
  {
    hadeeths.add(json['hadeeth']);
    explanation.add(json['explanation']);
  }
}