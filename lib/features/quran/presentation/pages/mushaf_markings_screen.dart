import 'package:flutter/material.dart';
import 'package:muslim/core/widgets/app_widgets.dart';
import 'package:muslim/core/widgets/info_hint_card.dart';
import 'package:muslim/core/widgets/external_link_button.dart';
import '../../data/data_sources/mushaf_markings_data.dart';
import '../../domain/entities/mushaf_marking.dart';
import '../widgets/mushaf_marking_widgets.dart';
import '../widgets/quran_search_field.dart';

class MushafMarkingsScreen extends StatefulWidget {
  const MushafMarkingsScreen({super.key});

  @override
  State<MushafMarkingsScreen> createState() => _MushafMarkingsScreenState();
}

class _MushafMarkingsScreenState extends State<MushafMarkingsScreen> {
  MushafMarkingCategory? _category;
  String _query = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = mushafMarkings.where((item) =>
      (_category == null || item.category == _category) &&
      ('${item.symbol} ${item.name} ${item.meaning} ${item.example ?? ''}'.contains(_query.trim()))
    ).toList();
    return Scaffold(
      appBar: defaultAppBar(context: context, text: 'علامات المصحف'),
      body: SafeArea(child: CustomScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(18, 14, 18, 12),
            child: const InfoHintCard(
              text: 'علامات ضبط المصحف',
            ),
          )),
          SliverToBoxAdapter(child: SizedBox(height: 50, child: ListView(
            padding: const EdgeInsetsDirectional.symmetric(horizontal: 18),
            scrollDirection: Axis.horizontal,
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 8),
                child: ChoiceChip(label: const Text('الكل'), selected: _category == null, side: const BorderSide(color: Colors.grey, width: 1), onSelected: (_) => setState(() => _category = null)),
              ),
              ...MushafMarkingCategory.values.map((category) => MushafCategoryChip(
                category: category, selected: _category == category, onTap: () => setState(() => _category = category))),
            ],
          ))),
          SliverToBoxAdapter(child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(18, 10, 18, 14),
            child: QuranSearchField(
              controller: _searchController,
              query: _query,
              hintText: 'ابحث عن علامة أو معناها',
              onChanged: (value) => setState(() => _query = value),
              onClear: () {
                _searchController.clear();
                setState(() => _query = '');
              },
            ),
          )),
          if (filtered.isEmpty)
            const SliverFillRemaining(hasScrollBody: false, child: Center(child: Text('لا توجد علامات مطابقة')))
          else
            SliverPadding(
              padding: const EdgeInsetsDirectional.fromSTEB(18, 0, 18, 20),
              sliver: SliverList.separated(
                itemCount: filtered.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) => MushafMarkingCard(marking: filtered[index]),
              ),
            ),
          const SliverToBoxAdapter(child: Padding(
            padding: EdgeInsetsDirectional.fromSTEB(18, 0, 18, 28),
            child: ExternalLinkButton(
              url: 'https://alitkaan.com/%D8%A3%D8%A8%D8%B1%D8%B2-%D8%B9%D9%84%D8%A7%D9%85%D8%A7%D8%AA-%D8%A7%D9%84%D8%B6%D8%A8%D8%B7/',
              label: 'المصدر: دليل الإتقان — أبرز علامات الضبط',
            ),
          )),
        ],
      )),
    );
  }
}
