class AsmaaAllahElHosna
{
  static List<String> name=[];
  static List<String> meaning=[];
  AsmaaAllahElHosna.fromJson(Map<String,dynamic>json)
  {
    json['data'].forEach((el){
      name.add(el['name']);
      meaning.add(el['text']);
    });
  }
}