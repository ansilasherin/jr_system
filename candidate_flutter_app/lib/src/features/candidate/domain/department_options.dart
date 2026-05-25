const candidateDepartments = <String>[
  'Flutter',
  'Python',
  'UI/UX',
  'Data Science',
  'Marketing',
  'Human Resources',
];

String? normalizeDepartment(String? value) {
  final raw = value?.trim() ?? '';
  if (raw.isEmpty) return null;
  final lowered = raw.toLowerCase();
  const aliases = <String, String>{
    'flutter': 'Flutter',
    'flutter development': 'Flutter',
    'mobile development': 'Flutter',
    'python': 'Python',
    'python development': 'Python',
    'backend': 'Python',
    'django': 'Python',
    'ui/ux': 'UI/UX',
    'ui ux': 'UI/UX',
    'ux': 'UI/UX',
    'ui': 'UI/UX',
    'design': 'UI/UX',
    'data science': 'Data Science',
    'data analytics': 'Data Science',
    'machine learning': 'Data Science',
    'marketing': 'Marketing',
    'digital marketing': 'Marketing',
    'human resources': 'Human Resources',
    'hr': 'Human Resources',
    'recruitment': 'Human Resources',
  };
  if (aliases.containsKey(lowered)) return aliases[lowered];
  for (final department in candidateDepartments) {
    if (department.toLowerCase() == lowered) return department;
  }
  for (final entry in aliases.entries) {
    if (lowered.contains(entry.key)) return entry.value;
  }
  return raw;
}

bool departmentMatchesJob(String? department, String? jobDepartment) {
  final canonical = normalizeDepartment(department);
  if (canonical == null || canonical.isEmpty) return false;
  return (jobDepartment ?? '').trim().toLowerCase() == canonical.toLowerCase();
}
