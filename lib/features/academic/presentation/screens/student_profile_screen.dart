import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../domain/models/student_biodata_model.dart';
import '../providers/academic_portal_provider.dart';
import '../../../../theme/app_theme.dart';
import '../../data/portal_ai_text.dart';
import '../widgets/portal_state_views.dart';
import '../widgets/portal_ai_assist.dart';

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AcademicPortalProvider>();
      if (!provider.biodata.hasData) {
        provider.fetchBiodata();
      }
    });
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label berhasil disalin'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AcademicPortalProvider>();
    final resource = provider.biodata;

    return PortalPageScaffold(
      title: 'Profil Mahasiswa',
      isLoading: resource.isLoading,
      onRefresh: () => provider.fetchBiodata(forceRefresh: true),
      body: _buildBody(provider, resource),
      aiContext: PortalAiContext(
        pageTitle: 'Profil Mahasiswa',
        label: 'Biodata',
        buildPageText: () => PortalAiText.biodata(provider.biodata.data),
      ),
    );
  }

  Widget _buildBody(AcademicPortalProvider provider, PortalResource<StudentBiodata> resource) {
    final biodata = resource.data;
    Future<void> retry() => provider.fetchBiodata(forceRefresh: true);

    if (biodata == null) {
      if (resource.isLoading) {
        return const PortalLoadingView(message: 'Memuat biodata mahasiswa...');
      }
      return PortalErrorView(
        icon: Icons.person_off_rounded,
        title: 'Gagal Memuat Profil',
        message: resource.error,
        onRetry: retry,
      );
    }


    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      children: [
        if (resource.error != null)
          PortalSyncBanner(message: resource.error!, onRetry: retry),
        _buildHeroProfileCard(biodata),
        const SizedBox(height: 14),
        _buildQuickMetricsRow(biodata),
        const SizedBox(height: 16),
        _buildSectionHeader('Informasi Akademik', Icons.school_rounded),
        const SizedBox(height: 8),
        _buildAcademicCard(biodata),
        const SizedBox(height: 16),
        _buildSectionHeader('Data Pribadi', Icons.person_rounded),
        const SizedBox(height: 8),
        _buildPersonalCard(biodata),
        const SizedBox(height: 16),
        _buildSectionHeader('Data Orang Tua / Wali', Icons.family_restroom_rounded),
        const SizedBox(height: 8),
        _buildParentsCard(biodata),
        const SizedBox(height: 16),
        _buildSectionHeader('Pendidikan Asal', Icons.account_balance_rounded),
        const SizedBox(height: 8),
        _buildHighSchoolCard(biodata),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildHeroProfileCard(StudentBiodata biodata) {
    final initials = biodata.namaMahasiswa.isNotEmpty
        ? biodata.namaMahasiswa
            .split(' ')
            .take(2)
            .map((e) => e.isNotEmpty ? e[0] : '')
            .join('')
        : 'M';

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryDark, AppTheme.primaryBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryBlue.withOpacity(0.28),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: Colors.white,
                child: CircleAvatar(
                  radius: 31,
                  backgroundColor: AppTheme.primaryLight.withOpacity(0.2),
                  child: Text(
                    initials,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryBlue,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      biodata.namaMahasiswa,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    InkWell(
                      onTap: () => _copyToClipboard(biodata.nim, 'NIM'),
                      borderRadius: BorderRadius.circular(4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'NIM: ${biodata.nim}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 13,
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.copy_rounded,
                              size: 13, color: Colors.white.withOpacity(0.8)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      biodata.programStudi?.namaProdi ?? 'Program Studi',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.85),
                        fontSize: 12.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildHeroTag(
                  'Kelas',
                  biodata.idKelas ?? '-',
                  Icons.meeting_room_rounded,
                ),
                Container(
                  height: 24,
                  width: 1,
                  color: Colors.white.withOpacity(0.2),
                ),
                _buildHeroTag(
                  'Shift',
                  biodata.shift?.namaShift ?? 'Reguler',
                  Icons.schedule_rounded,
                ),
                Container(
                  height: 24,
                  width: 1,
                  color: Colors.white.withOpacity(0.2),
                ),
                _buildHeroTag(
                  'Status',
                  biodata.statusMahasiswa?.namaStatusMahasiswa ?? 'Aktif',
                  Icons.verified_user_rounded,
                  isStatus: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroTag(String label, String value, IconData icon, {bool isStatus = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: isStatus ? Colors.greenAccent : Colors.white70),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.7)),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isStatus ? Colors.greenAccent : Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickMetricsRow(StudentBiodata biodata) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricTile(
            'IPK Berjalan',
            biodata.ipkSemesterBerjalan ?? '0.00',
            Icons.stars_rounded,
            AppTheme.accentGold,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMetricTile(
            'Total SKS',
            '${biodata.sksSemesterBerjalan ?? '0'} SKS',
            Icons.school_rounded,
            AppTheme.primaryBlue,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildMetricTile(
            'Semester',
            'Ke-${biodata.semester ?? '1'}',
            Icons.calendar_month_rounded,
            AppTheme.accentGold,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricTile(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 10.5, color: AppTheme.textMuted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.primaryBlue),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildAcademicCard(StudentBiodata biodata) {
    final prodi = biodata.programStudi;
    return _buildCardContainer([
      _buildInfoRow('Program Studi', prodi?.namaProdi ?? '-'),
      _buildInfoRow('Fakultas', prodi?.fakultas?.namaFakultas ?? '-'),
      _buildInfoRow('Jenjang', prodi?.jenjangPendidikan?.namaJenjangPendidikan ?? '-'),
      _buildInfoRow('Gelar Kelulusan', prodi?.jenjangPendidikan?.gelarJenjangPendidikan ?? '-'),
      _buildInfoRow('Ketua Program Studi', prodi?.pejabat?.namaPejabat ?? '-'),
      _buildInfoRow('Dekan Fakultas', prodi?.fakultas?.pejabat?.namaPejabat ?? '-'),
      _buildInfoRow('Tanggal Diterima', biodata.formattedAcceptedDate),
      _buildInfoRow('Kelas', biodata.idKelas ?? '-'),
      _buildInfoRow('Shift Perkuliahan', biodata.shift?.namaShift ?? '-'),
      _buildInfoRow('Email Resmi Prodi', prodi?.emailProdi ?? '-', isEmail: true),
    ]);
  }

  Widget _buildPersonalCard(StudentBiodata biodata) {
    return _buildCardContainer([
      _buildInfoRow('Nama Lengkap', biodata.namaMahasiswa),
      _buildInfoRow('Tempat, Tanggal Lahir', biodata.formattedBirthPlaceAndDate),
      _buildInfoRow('NIK (KTP)', biodata.noIdentitas ?? '-', isCopyable: true),
      _buildInfoRow('Email Pribadi', biodata.alamatEmail ?? '-', isCopyable: true, isEmail: true),
      _buildInfoRow('No. WhatsApp / HP', biodata.noHpMahasiswa ?? '-', isCopyable: true),
      _buildInfoRow('Pekerjaan Saat Ini', biodata.pekerjaan?.isNotEmpty == true ? biodata.pekerjaan! : '-'),
      _buildInfoRow('Alamat Domisili', biodata.alamatMahasiswa ?? '-'),
    ]);
  }

  Widget _buildParentsCard(StudentBiodata biodata) {
    return _buildCardContainer([
      _buildInfoRow('Nama Ayah / Wali', biodata.namaOrangTua ?? '-'),
      _buildInfoRow('Nama Ibu Kandung', biodata.namaIbuKandung ?? '-'),
      _buildInfoRow('Pekerjaan Orang Tua', biodata.pekerjaanOrangTua ?? '-'),
      _buildInfoRow('No. HP Orang Tua', biodata.noHpOrangTua ?? '-', isCopyable: true),
      _buildInfoRow('Alamat Orang Tua', biodata.alamatOrangTua ?? '-'),
    ]);
  }

  Widget _buildHighSchoolCard(StudentBiodata biodata) {
    return _buildCardContainer([
      _buildInfoRow('Asal Sekolah', biodata.asalSekolah ?? '-'),
      _buildInfoRow('Alamat Sekolah Asal', biodata.alamatSekolahAsal ?? '-'),
      _buildInfoRow('Nomor STTB / Ijazah', biodata.nomorSttb ?? '-', isCopyable: true),
      _buildInfoRow('Tanggal Kelulusan / STTB', biodata.tanggalSttb ?? '-'),
    ]);
  }

  Widget _buildCardContainer(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Column(children: children),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value, {
    bool isCopyable = false,
    bool isEmail = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppTheme.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const Text(':', style: TextStyle(color: AppTheme.textMuted, fontSize: 12.5)),
          const SizedBox(width: 8),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isEmail ? AppTheme.primaryBlue : AppTheme.textDark,
                    ),
                  ),
                ),
                if (isCopyable && value != '-') ...[
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: () => _copyToClipboard(value, label),
                    borderRadius: BorderRadius.circular(4),
                    child: const Padding(
                      padding: EdgeInsets.all(2),
                      child: Icon(
                        Icons.copy_rounded,
                        size: 14,
                        color: AppTheme.primaryBlue,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
