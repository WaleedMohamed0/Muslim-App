import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:muslim/core/widgets/app_widgets.dart';
import 'package:muslim/features/zakat/domain/zakat_calculator.dart';

class ZakatCalculatorScreen extends StatefulWidget {
  const ZakatCalculatorScreen({super.key});
  @override
  State<ZakatCalculatorScreen> createState() => _ZakatCalculatorScreenState();
}

class _ZakatCalculatorScreenState extends State<ZakatCalculatorScreen> {
  static const _keys = ['cash','goldGrams','goldPrice','silverGrams','silverPrice','investments','receivables','liabilities'];
  late final List<TextEditingController> _controllers;
  final _formKey = GlobalKey<FormState>();
  NisabStandard _standard = NisabStandard.silver;
  bool _hawl = false;
  ZakatResult? _result;
  String _currency = 'جنيه مصري';

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(_keys.length, (_) => TextEditingController());
    for (final c in _controllers) { c.addListener(_saveDraft); }
    unawaited(_loadDraft());
  }

  Future<void> _loadDraft() async {
    final p = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      for (var i=0; i<_keys.length; i++) { _controllers[i].text = p.getString('zakat_${_keys[i]}') ?? ''; }
      _standard = NisabStandard.values[p.getInt('zakat_standard') ?? 1];
      _hawl = p.getBool('zakat_hawl') ?? false;
      _currency = p.getString('zakat_currency') ?? 'جنيه مصري';
    });
  }

  Future<void> _saveDraft() async {
    final p = await SharedPreferences.getInstance();
    for (var i=0; i<_keys.length; i++) { await p.setString('zakat_${_keys[i]}', _controllers[i].text); }
    await p.setInt('zakat_standard', _standard.index);
    await p.setBool('zakat_hawl', _hawl);
    await p.setString('zakat_currency', _currency);
  }

  double _value(int i) => double.tryParse(_controllers[i].text.trim().replaceAll(',', '.')) ?? 0;

  void _calculate() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _result = calculateZakat(ZakatInputs(
      cash:_value(0), goldGrams:_value(1), goldPrice:_value(2), silverGrams:_value(3), silverPrice:_value(4),
      investments:_value(5), receivables:_value(6), liabilities:_value(7), nisabStandard:_standard, hawlComplete:_hawl,
    )));
  }

  Future<void> _reset() async {
    for (final c in _controllers) { c.clear(); }
    setState(() { _hawl = false; _standard = NisabStandard.silver; _currency = 'جنيه مصري'; _result = null; });
    final p = await SharedPreferences.getInstance();
    for (final key in _keys) { await p.remove('zakat_$key'); }
    await p.remove('zakat_standard'); await p.remove('zakat_hawl'); await p.remove('zakat_currency');
  }

  @override
  void dispose() { for(final c in _controllers) { c.removeListener(_saveDraft); c.dispose(); } super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context); final scheme = t.colorScheme;
    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(
      appBar: defaultAppBar(context: context, text: 'حاسبة الزكاة'),
      body: Form(key: _formKey, child: ListView(padding: const EdgeInsetsDirectional.fromSTEB(18, 12, 18, 28), children: [
        _intro(context),
        const SizedBox(height: 14),
        _section(context, 'الأموال والأصول', Icons.account_balance_wallet_rounded, [
          _field(0,'النقدية','الأموال النقدية والحسابات البنكية'),
          _field(1,'وزن الذهب بالجرام','أدخل الوزن الذي تريد احتسابه'),
          _field(2,'سعر جرام الذهب','أدخل سعر السوق الحالي للجرام'),
          _field(3,'وزن الفضة بالجرام','أدخل الوزن الذي تريد احتسابه'),
          _field(4,'سعر جرام الفضة','أدخل سعر السوق الحالي للجرام'),
          _field(5,'الأسهم والاستثمارات','قيمة الأصول المحتفظ بها بغرض التجارة'),
          _field(6,'الديون المستحقة لك','ما تتوقع تحصيله من الديون'),
          _field(7,'الديون المستحقة عليك','الالتزامات المؤهلة المستحقة للسداد'),
        ]),
        const SizedBox(height: 14),
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('إعدادات الحساب', style:t.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(initialValue:_currency, decoration: const InputDecoration(labelText:'العملة'), items: const [DropdownMenuItem(value:'جنيه مصري',child:Text('جنيه مصري (EGP)')),DropdownMenuItem(value:'ريال سعودي',child:Text('ريال سعودي (SAR)')),DropdownMenuItem(value:'دولار أمريكي',child:Text('دولار أمريكي (USD)'))], onChanged:(v){if(v!=null)setState(()=>_currency=v); unawaited(_saveDraft());}),
          const SizedBox(height: 8),
          Text('معيار النصاب',style:t.textTheme.titleSmall),
          SegmentedButton<NisabStandard>(segments:const [ButtonSegment(value:NisabStandard.gold,label:Text('الذهب 85 جم'),icon:Icon(Icons.circle_outlined)),ButtonSegment(value:NisabStandard.silver,label:Text('الفضة 595 جم'),icon:Icon(Icons.circle_outlined))],selected:{_standard},showSelectedIcon:false,onSelectionChanged:(values){setState(()=>_standard=values.first);unawaited(_saveDraft());}),
          SwitchListTile(contentPadding:EdgeInsets.zero,title:const Text('مرور سنة هجرية كاملة (الحول)'),subtitle:const Text('فعّل الخيار إذا مر عام هجري على بلوغ المال النصاب'),value:_hawl,onChanged:(v){setState(()=>_hawl=v);unawaited(_saveDraft());}),
          Text('أدخل سعر الجرام الحالي يدويًا قبل الحساب. يُحسب نصاب الذهب بسعر الذهب المدخل، ونصاب الفضة بسعر الفضة المدخل.',style:t.textTheme.bodySmall?.copyWith(color:scheme.onSurfaceVariant)),
        ]))),
        const SizedBox(height: 14),
        FilledButton.icon(onPressed:_calculate,icon:const Icon(Icons.calculate_rounded),label:const Padding(padding:EdgeInsets.symmetric(vertical:13),child:Text('احسب الزكاة'))),
        if (_result != null) ...[const SizedBox(height:14),_resultCard(context,_result!)],
        const SizedBox(height:10),
        OutlinedButton.icon(onPressed:_reset,icon:const Icon(Icons.restart_alt_rounded),label:const Text('إعادة ضبط')),
        const SizedBox(height:16),
        Text('النصاب هو الحد الأدنى من المال الذي تجب عنده الزكاة. الحول هو مرور سنة هجرية كاملة على المال. مقدار زكاة المال 2.5% عند تحقق الشروط.',style:t.textTheme.bodySmall?.copyWith(color:scheme.onSurfaceVariant)),
        const SizedBox(height:8),
        Text('هذا الحساب تقديري، وتختلف أحكام بعض الأصول والديون بحسب تفاصيلها. راجع عالمًا مؤهلًا في الحالات المعقدة.',style:t.textTheme.bodySmall?.copyWith(color:scheme.onSurfaceVariant)),
      ])),
    ));
  }

  Widget _intro(BuildContext context) { final s=Theme.of(context).colorScheme; return Card(color:s.primaryContainer,child:Padding(padding:const EdgeInsets.all(16),child:Row(children:[Icon(Icons.savings_rounded,size:34,color:s.onPrimaryContainer),const SizedBox(width:12),Expanded(child:Text('احسب زكاة أموالك السنوية بعد إدخال الأصول والخصوم المؤهلة.',style:Theme.of(context).textTheme.bodyMedium?.copyWith(color:s.onPrimaryContainer,fontWeight:FontWeight.w600))) ]))); }

  Widget _section(BuildContext context,String title,IconData icon,List<Widget> children) => Card(child:Padding(padding:const EdgeInsets.all(16),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[Icon(icon,color:Theme.of(context).colorScheme.primary),const SizedBox(width:8),Text(title,style:Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight:FontWeight.bold))]),const SizedBox(height:12),...children])));

  Widget _field(int index,String label,String hint) => Padding(padding:const EdgeInsets.only(bottom:10),child:TextFormField(controller:_controllers[index],keyboardType:const TextInputType.numberWithOptions(decimal:true),textDirection:TextDirection.ltr,decoration:InputDecoration(labelText:label,hintText:hint,suffixText:_currency,helperText:(index==2||index==4)?'سعر يدوي — حدّثه وفق السوق الحالي':null),validator:(text){final raw=(text??'').trim();if(raw.isEmpty){final isRequiredPrice=(_standard==NisabStandard.gold&&index==2)||(_standard==NisabStandard.silver&&index==4);return isRequiredPrice?'أدخل سعر الجرام لحساب النصاب':null;}final value=double.tryParse(raw.replaceAll(',', '.'));if(value==null)return 'أدخل رقمًا صحيحًا غير سالب';if(value<0||!value.isFinite)return 'لا يمكن إدخال قيمة سالبة أو غير صالحة';if((index==2||index==4)&&value<=0)return 'يجب أن يكون سعر الجرام أكبر من صفر';return null;}));

  Widget _resultCard(BuildContext context,ZakatResult r) { final t=Theme.of(context); final s=t.colorScheme; final due=r.isDue; String money(double v)=>'${v.toStringAsFixed(2)} $_currency'; return Card(color:s.surfaceContainerHigh,child:Padding(padding:const EdgeInsets.all(18),child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Row(children:[Icon(due?Icons.verified_rounded:Icons.info_outline_rounded,color:due?s.primary:s.tertiary),const SizedBox(width:8),Expanded(child:Text(due?'الزكاة واجبة بحسب البيانات':'لا تجب الزكاة حاليًا بحسب البيانات',style:t.textTheme.titleMedium?.copyWith(fontWeight:FontWeight.bold)))]),const SizedBox(height:8),Text(!r.reachedNisab?'صافي المال أقل من النصاب المحدد.':!_hawl?'بلغ المال النصاب، لكن الحول لم يكتمل بعد.':'تحقق النصاب والحول؛ الزكاة المحسوبة 2.5% من صافي المال.'),const Divider(height:24),_row('إجمالي الأموال',money(r.totalAssets)),_row('إجمالي الخصوم المؤهلة',money(r.liabilities)),_row('صافي المال الخاضع للزكاة',money(r.netWealth)),_row('قيمة النصاب',money(r.nisabValue)),const Divider(height:20),_row('المبلغ الواجب إخراجه',money(r.zakatDue),strong:true)]))); }
  Widget _row(String label,String value,{bool strong=false}) => Padding(padding:const EdgeInsets.symmetric(vertical:5),child:Row(children:[Expanded(child:Text(label,style:strong?const TextStyle(fontWeight:FontWeight.bold):null)),Text(value,style:TextStyle(fontWeight:strong?FontWeight.bold:FontWeight.w600))]));
}
