import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../theme/app_theme.dart';
import '../../data/portal_ai_text.dart';
import '../../domain/models/academic_document_model.dart';
import '../providers/academic_portal_provider.dart';
import '../widgets/portal_ai_assist.dart';
import '../widgets/portal_state_views.dart';

class AcademicDocumentsScreen extends StatefulWidget {
  const AcademicDocumentsScreen({super.key});

  @override
  State<AcademicDocumentsScreen> createState() => _AcademicDocumentsScreenState();
}

class _AcademicDocumentsScreenState extends State<AcademicDocumentsScreen> {
  String _selectedCategory = 'all';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<AcademicPortalProvider>();
      if (!p.documents.hasData) p.fetchDocuments();
      if (!p.documentCategories.hasData) p.fetchDocumentCategories();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() => Future.wait([
        context.read<AcademicPortalProvider>().fetchDocuments(forceRefresh: true),
        context.read<AcademicPortalProvider>().fetchDocumentCategories(forceRefresh: true),
      ]);

  Future<void> _openDocument(AcademicDocumentItem doc) async {
    final uri = Uri.tryParse(doc.url);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tautan dokumen tidak valid.')),
      );
      return;
    }

    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal membuka berkas dokumen.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengunduh dokumen: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AcademicPortalProvider>();
    final docsResource = provider.documents;
    final catsResource = provider.documentCategories;
    final allDocs = docsResource.data;
    final categories = catsResource.data ?? const [];

    final filteredDocs = (allDocs ?? const []).where((doc) {
      if (_selectedCategory != 'all' && doc.idDokumenKategori != _selectedCategory) {
        return false;
      }
      if (_searchQuery.isNotEmpty &&
          !doc.namaDokumen.toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();

    return PortalPageScaffold(
      title: 'Dokumen Akademik',
      isLoading: docsResource.isLoading && !docsResource.hasData,
      onRefresh: _refresh,
      aiContext: PortalAiContext(
        pageTitle: 'Dokumen',
        label: 'Dokumen Akademik',
        buildPageText: () => PortalAiText.documents(allDocs),
      ),
      body: Builder(
        builder: (context) {
          if (allDocs == null) {
            if (docsResource.isLoading) {
              return const PortalLoadingView(message: 'Memuat berkas dokumen...');
            }
            return PortalErrorView(
              icon: Icons.folder_shared_rounded,
              title: 'Gagal Memuat Dokumen',
              message: docsResource.error,
              onRetry: _refresh,
            );
          }

          if (allDocs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppTheme.accentGold.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.folder_shared_rounded,
                        size: 48,
                        color: AppTheme.accentGold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Belum Ada Dokumen',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Daftar dokumen akademik kampus belum tersedia.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13.5, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              if (docsResource.error != null)
                PortalSyncBanner(message: docsResource.error!, onRetry: _refresh),
              _buildSearchBar(),
              const SizedBox(height: 14),
              _buildCategoryChips(categories),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Daftar Berkas & Panduan',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  Text(
                    '${filteredDocs.length} Berkas',
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: AppTheme.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (filteredDocs.isEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 16),
                  alignment: Alignment.center,
                  child: const Column(
                    children: [
                      Icon(Icons.search_off_rounded, size: 40, color: AppTheme.textMuted),
                      SizedBox(height: 8),
                      Text(
                        'Tidak ada dokumen yang sesuai pencarian',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                      ),
                    ],
                  ),
                )
              else
                ...filteredDocs.map((doc) => _buildDocTile(doc, categories)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (val) => setState(() => _searchQuery = val.trim()),
        decoration: InputDecoration(
          hintText: 'Cari panduan, formulir, SK...',
          hintStyle: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
          prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textMuted, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildCategoryChips(List<AcademicDocumentCategory> categories) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildChip('Semua', 'all'),
          ...categories.map((c) => _buildChip(c.namaKategori, c.idKategori)),
        ],
      ),
    );
  }

  Widget _buildChip(String label, String value) {
    final isSelected = _selectedCategory == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => setState(() => _selectedCategory = value),
        selectedColor: AppTheme.primaryBlue,
        backgroundColor: Colors.white,
        side: BorderSide(
          color: isSelected ? AppTheme.primaryBlue : AppTheme.cardBorder,
        ),
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : AppTheme.textDark,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildDocTile(AcademicDocumentItem doc, List<AcademicDocumentCategory> categories) {
    final categoryName = categories
        .cast<AcademicDocumentCategory?>()
        .firstWhere((c) => c?.idKategori == doc.idDokumenKategori, orElse: () => null)
        ?.namaKategori;

    final IconData fileIcon = doc.isPdf
        ? Icons.picture_as_pdf_rounded
        : Icons.description_rounded;
    final Color fileColor = doc.isPdf ? AppTheme.dangerRed : AppTheme.primaryBlue;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: fileColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(fileIcon, color: fileColor, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doc.namaDokumen,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.bgGrey,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: AppTheme.cardBorder),
                      ),
                      child: Text(
                        doc.fileExtension.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ),
                    if (categoryName != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryBlue.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          categoryName,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.download_rounded, color: AppTheme.primaryBlue),
            tooltip: 'Unduh / Buka Dokumen',
            onPressed: () => _openDocument(doc),
          ),
        ],
      ),
    );
  }
}
