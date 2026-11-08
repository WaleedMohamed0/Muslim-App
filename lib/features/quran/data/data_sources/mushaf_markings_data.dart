import '../../domain/entities/mushaf_marking.dart';

/// Offline descriptions for common marks in the Madani Mushaf (Hafs).
/// Some marks and their placement differ between editions and narrations.
const mushafMarkings = <MushafMarking>[
  MushafMarking(
    symbol: 'مـ', name: 'الوقف اللازم', category: MushafMarkingCategory.waqf,
    meaning: 'يُوقف هنا؛ لأن وصل الكلام بما بعده قد يوهم معنى غير المراد.',
    example: '﴿وَلَا يَحْزُنكَ قَوْلُهُمْۘ إِنَّ الْعِزَّةَ لِلَّهِ جَمِيعًا﴾ — يونس: ٦٥',
  ),
  MushafMarking(
    symbol: 'لا', name: 'علامة لا تقف', category: MushafMarkingCategory.waqf,
    meaning: 'لا يُختار الوقف على الكلمة؛ لتعلّقها بما بعدها. إن اضطررت للوقف، فابدأ بما يصحّ به المعنى. مواضعها وظهورها تختلف باختلاف الطبعات.',
    example: '﴿الَّذِينَ تَتَوَفَّاهُمُ الْمَلَائِكَةُ طَيِّبِينَۙ يَقُولُونَ سَلَامٌ عَلَيْكُمُ﴾ — النحل: ٣٢',
  ),
  MushafMarking(
    symbol: 'ج', name: 'الوقف الجائز', category: MushafMarkingCategory.waqf,
    meaning: 'يجوز الوقف والوصل، ولا أولوية ظاهرة لأحدهما.',
    example: '﴿نَحْنُ نَقُصُّ عَلَيْكَ نَبَأَهُم بِالْحَقِّۚ إِنَّهُمْ فِتْيَةٌ﴾ — الكهف: ١٣',
  ),
  MushafMarking(
    symbol: 'صلى', name: 'الوصل أولى', category: MushafMarkingCategory.waqf,
    meaning: 'يجوز الوقف، لكن وصل القراءة بما بعدها أولى.',
    example: '﴿أُولَٰئِكَ عَلَىٰ هُدًى مِّن رَّبِّهِمْۖ وَأُولَٰئِكَ هُمُ الْمُفْلِحُونَ﴾ — البقرة: ٥',
  ),
  MushafMarking(
    symbol: 'قلى', name: 'الوقف أولى', category: MushafMarkingCategory.waqf,
    meaning: 'يجوز الوصل، لكن الوقف هنا أولى لاكتمال المعنى.',
    example: '﴿ذُرِّيَّةً بَعْضُهَا مِن بَعْضٍۗ وَاللَّهُ سَمِيعٌ عَلِيمٌ﴾ — آل عمران: ٣٤',
  ),
  MushafMarking(
    symbol: '∴  ∴', name: 'تعانق الوقف (المعانقة)', category: MushafMarkingCategory.waqf,
    meaning: 'علامتان متقابلتان؛ تقف عند واحدة منهما فقط، ولا تقف عند الموضعين معًا.',
    example: '﴿لَا رَيْبَۛ فِيهِۛ هُدًى لِّلْمُتَّقِينَ﴾ — البقرة: ٢',
  ),
  MushafMarking(
    symbol: 'س', name: 'السكتة اللطيفة', category: MushafMarkingCategory.waqf,
    meaning: 'سكتة قصيرة بلا تنفّس ثم متابعة القراءة. في رواية حفص من طريق الشاطبية لها مواضع مشهورة، منها هذه الكلمة.',
    example: '﴿عِوَجًاۜ قَيِّمًا﴾ — الكهف: ١–٢',
  ),
  MushafMarking(
    symbol: '۩', name: 'موضع سجدة التلاوة', category: MushafMarkingCategory.recitation,
    meaning: 'تشير إلى موضع آيَة سجدة. حكم سجود التلاوة عند قراءتها أو سماعها له تفصيل فقهي، والعلامة نفسها تحدد الموضع.',
    example: '﴿وَخَرَّ رَاكِعًا وَأَنَابَ۩﴾ — ص: ٢٤',
  ),
  MushafMarking(
    symbol: '۝', name: 'نهاية الْآيَة ورقمها', category: MushafMarkingCategory.recitation,
    meaning: 'تفصل بين الآيات، ويُكتب داخل العلامة رقم الْآيَة. الوقف على رؤوس الآي له أحكامه، وقد يتصل المعنى بما بعدها.',
    example: '﴿بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ ۝١﴾ — الفاتحة: ١',
  ),
  MushafMarking(
    symbol: 'ٓ', name: 'علامة المد', category: MushafMarkingCategory.recitation,
    meaning: 'تدل على مدّ الحرف، ومقدار المد ونوعه يُعرفان من سبب المد والرواية؛ لا تعني أن كل موضع يُمدّ بالمقدار نفسه.',
    example: '﴿وَلَا الضَّآلِّينَ﴾ — الفاتحة: ٧',
  ),
  MushafMarking(
    symbol: 'ۜ', name: 'علامة السكت', category: MushafMarkingCategory.recitation,
    meaning: 'تدل في مواضع مخصوصة في رواية حفص على سكت يسير بلا تنفّس. مواضع السكت وعددها مرتبطان بالطريق والرواية.',
    example: '﴿عِوَجًاۜ قَيِّمًا﴾ — الكهف: ١–٢',
  ),
  MushafMarking(
    symbol: 'مّ', name: 'الميم الصغيرة (الإقلاب)', category: MushafMarkingCategory.notation,
    meaning: 'إذا جاءت فوق النون الساكنة أو التنوين قبل الباء، تُقلب النون ميمًا مخفاة مع الغنة عند التلاوة.',
    example: '﴿مِنۢ بَعْدِ﴾ — البقرة: ٢٧',
  ),
  MushafMarking(
    symbol: 'ۨ', name: 'النون الصغيرة', category: MushafMarkingCategory.notation,
    meaning: 'تدل في كلمات مخصوصة على نون منطوقة لم تُكتب نونًا كاملة في الرسم.',
    example: '﴿نُـۨجِي الْمُؤْمِنِينَ﴾ — الْأَنْبِيَاء: ٨٨',
  ),
  MushafMarking(
    symbol: 'صۜ', name: 'السين الصغيرة فوق الصاد', category: MushafMarkingCategory.notation,
    meaning: 'علامة قراءة خاصة في كلمات معدودة في رواية حفص؛ تُقرأ سينًا في هذا الموضع.',
    example: '﴿وَاللَّهُ يَقْبِضُ وَيَبْصُۜطُ وَإِلَيْهِ تُرْجَعُونَ﴾ — البقرة: ٢٤٥ (تُقرأ: وَيَبْسُطُ)',
  ),
  MushafMarking(
    symbol: 'ْ', name: 'السكون', category: MushafMarkingCategory.notation,
    meaning: 'يدل على أن الحرف ساكن، أي لا حركة قصيرة عليه. وتُعرف أحكام النون أو الميم الساكنتين من الحرف التالي أيضًا.',
    example: '﴿أَنْعَمْتَ﴾ — الفاتحة: ٧',
  ),
  MushafMarking(
    symbol: 'ّ', name: 'الشدة', category: MushafMarkingCategory.notation,
    meaning: 'تعني أن الحرف مشدد، وأصله حرفان: الأول ساكن والثاني متحرك.',
    example: '﴿إِيَّاكَ نَعْبُدُ﴾ — الفاتحة: ٥',
  ),
  MushafMarking(
    symbol: 'ً ٍ ٌ', name: 'التنوين', category: MushafMarkingCategory.notation,
    meaning: 'فتحتان أو كسرتان أو ضمتان في آخر الاسم، وتُنطق نونًا ساكنة عند الوصل. وللتنوين أحكام تجويد بحسب الحرف التالي.',
    example: '﴿هُدًى لِّلْمُتَّقِينَ﴾ — البقرة: ٢',
  ),
  MushafMarking(
    symbol: 'ٱ', name: 'همزة الوصل', category: MushafMarkingCategory.notation,
    meaning: 'تُنطق عند البدء بالكلمة، وتسقط عند وصلها بما قبلها.',
    example: '﴿ٱلْحَمْدُ لِلَّهِ﴾ — الفاتحة: ٢',
  ),
];
