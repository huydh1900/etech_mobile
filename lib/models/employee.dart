// Odoo trả `false` cho field rỗng (char/m2o/date) -> coerce về ''/0,
// tránh render "false" và crash cast khi backend thiếu dữ liệu.
int _iv(Object? v) => v is num ? v.toInt() : 0;
String _sv(Object? v) => (v == null || v == false) ? '' : v.toString();

class Employee {
  final int id;
  final String name;
  final String email;
  final String department;
  final String departmentManager;
  final String manager;
  final String company;
  final String dateStart;
  final String birthday;
  final String phone;
  final String address;
  final String jobPosition;
  final String employeeCode;
  final String avatarUrl;
  final bool hasAvatar;
  final String writeDate;

  Employee({
    required this.id,
    required this.name,
    required this.email,
    required this.department,
    required this.departmentManager,
    required this.manager,
    required this.company,
    required this.dateStart,
    required this.birthday,
    required this.phone,
    required this.address,
    required this.jobPosition,
    required this.employeeCode,
    this.avatarUrl = '',
    this.hasAvatar = false,
    this.writeDate = '',
  });

  factory Employee.fromJson(Map<String, dynamic> json) => Employee(
    id: _iv(json['id']),
    name: _sv(json['name']),
    email: _sv(json['email']),
    department: _sv(json['department']),
    departmentManager: _sv(json['department_manager']),
    manager: _sv(json['parent_id']),
    company: _sv(json['company']),
    dateStart: _sv(json['date_start']),
    birthday: _sv(json['birthday']),
    phone: _sv(json['phone']),
    address: _sv(json['address']),
    jobPosition: _sv(json['job_position']),
    employeeCode: _sv(json['employee_code']),
    avatarUrl: _sv(json['avatar_url']),
    hasAvatar: json['has_avatar'] == true,
    writeDate: _sv(json['write_date']),
  );

  Employee copyWith({
    String? name,
    String? email,
    String? birthday,
    String? phone,
    String? address,
    bool? hasAvatar,
    String? writeDate,
  }) => Employee(
    id: id,
    name: name ?? this.name,
    email: email ?? this.email,
    department: department,
    departmentManager: departmentManager,
    manager: manager,
    company: company,
    dateStart: dateStart,
    birthday: birthday ?? this.birthday,
    phone: phone ?? this.phone,
    address: address ?? this.address,
    jobPosition: jobPosition,
    employeeCode: employeeCode,
    avatarUrl: avatarUrl,
    hasAvatar: hasAvatar ?? this.hasAvatar,
    writeDate: writeDate ?? this.writeDate,
  );
}
