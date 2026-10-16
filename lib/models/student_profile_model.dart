class StudentProfile {
  final String name;
  final String nim;
  final String prodi;
  final String fakultas;
  final String kelas;
  final String shift;
  final String semester;
  final String email;
  final String phone;
  final String status;
  final String bio;

  const StudentProfile({
    this.name = '',
    this.nim = '',
    this.prodi = '',
    this.fakultas = '',
    this.kelas = '',
    this.shift = '',
    this.semester = '',
    this.email = '',
    this.phone = '',
    this.status = 'Mahasiswa Aktif',
    this.bio = '',
  });

  bool get isFilled => name.trim().isNotEmpty && nim.trim().isNotEmpty;

  StudentProfile copyWith({
    String? name,
    String? nim,
    String? prodi,
    String? fakultas,
    String? kelas,
    String? shift,
    String? semester,
    String? email,
    String? phone,
    String? status,
    String? bio,
  }) {
    return StudentProfile(
      name: name ?? this.name,
      nim: nim ?? this.nim,
      prodi: prodi ?? this.prodi,
      fakultas: fakultas ?? this.fakultas,
      kelas: kelas ?? this.kelas,
      shift: shift ?? this.shift,
      semester: semester ?? this.semester,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      status: status ?? this.status,
      bio: bio ?? this.bio,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'nim': nim,
        'prodi': prodi,
        'fakultas': fakultas,
        'kelas': kelas,
        'shift': shift,
        'semester': semester,
        'email': email,
        'phone': phone,
        'status': status,
        'bio': bio,
      };

  factory StudentProfile.fromJson(Map<String, dynamic> json) {
    return StudentProfile(
      name: (json['name'] as String?)?.trim() ?? '',
      nim: (json['nim'] as String?)?.trim() ?? '',
      prodi: (json['prodi'] as String?)?.trim() ?? '',
      fakultas: (json['fakultas'] as String?)?.trim() ?? '',
      kelas: (json['kelas'] as String?)?.trim() ?? '',
      shift: (json['shift'] as String?)?.trim() ?? '',
      semester: (json['semester'] as String?)?.trim() ?? '',
      email: (json['email'] as String?)?.trim() ?? '',
      phone: (json['phone'] as String?)?.trim() ?? '',
      status: (json['status'] as String?)?.trim() ?? 'Mahasiswa Aktif',
      bio: (json['bio'] as String?)?.trim() ?? '',
    );
  }

  bool get isValidName => name.trim().length >= 2;
  bool get isValidNim => RegExp(r'^\d{8,14}$').hasMatch(nim.trim());
  bool get isValidEmail => RegExp(r'^[\w\.\-]+@[\w\.\-]+\.[a-zA-Z]{2,}$').hasMatch(email.trim());
  bool get isValidPhone => RegExp(r'^\+?[0-9]{10,15}$').hasMatch(phone.trim().replaceAll(' ', ''));
}
