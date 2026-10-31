class AzkarAndTsabeeh
{
 static List<String> azkarElSabah = [];
 static List<String> azkarElMasa2 = [];
 static List<String> azkarElNoom = [];
 static List<String> tsabee7 = [];
 static List<String> ad3ya = [];

  AzkarAndTsabeeh();
  AzkarAndTsabeeh.fromJson(Map<String,dynamic> json)
  {
    json['أذكار الصباح'].forEach((el)
    {
      azkarElSabah.add(el['content']);
    });

    json['أذكار المساء'].forEach((el)
    {
      azkarElMasa2.add(el['content']);
    });

    json['تسابيح'].forEach((el)
    {
      tsabee7.add(el['content']);
    });

    json['أذكار النوم'].forEach((el)
    {
      azkarElNoom.add(el['content']);
    });

    json['أدعية قرآنية'].forEach((el)
    {
      ad3ya.add(el['content']);
    });
  }
}