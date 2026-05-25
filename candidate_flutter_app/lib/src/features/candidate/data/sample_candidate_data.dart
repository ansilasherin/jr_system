import '../domain/department_options.dart';
import '../domain/models/application_model.dart';
import '../domain/models/candidate_user.dart';
import '../domain/models/dashboard_bundle.dart';
import '../domain/models/job_model.dart';
import '../domain/models/jobs_page.dart';
import '../domain/models/mcq_question.dart';

class SampleCandidateData {
  static const skills = ['Flutter', 'Dart', 'Firebase', 'REST API'];

  static List<String> skillsForCv(String fileName) {
    final normalized = fileName.toLowerCase();
    if (normalized.contains('python') ||
        normalized.contains('data') ||
        normalized.contains('django')) {
      return const ['Python', 'Django', 'REST API', 'SQL'];
    }
    if (normalized.contains('ui') ||
        normalized.contains('ux') ||
        normalized.contains('design')) {
      return const ['UI/UX', 'Figma', 'Wireframing', 'Prototyping'];
    }
    if (normalized.contains('hr') || normalized.contains('recruit')) {
      return const ['Recruitment', 'Communication', 'MS Excel'];
    }
    return skills;
  }

  static const profile = CandidateUser(
    id: 1,
    fullName: 'Demo Candidate',
    email: 'candidate@example.com',
    role: 'user',
    phone: '9876543210',
    course: 'Flutter',
    cvUrl: '/media/demo_resume.pdf',
    cvName: 'demo_resume.pdf',
    profileUrl: null,
    skills: skills,
  );

  static const hrProfile = CandidateUser(
    id: 2,
    fullName: 'Demo HR',
    email: 'hr@example.com',
    role: 'hr',
    phone: '9876500000',
    course: null,
    cvUrl: null,
    cvName: null,
    profileUrl: null,
    skills: [],
  );

  static final jobs = [
    JobModel(
      id: 101,
      title: 'Flutter Developer Intern',
      company: 'Nexa Digital',
      location: 'Kochi',
      salary: '12000/month',
      experience: '0-1 years',
      skills: const ['Flutter', 'Dart', 'REST API'],
      department: 'Flutter',
      description: 'Build production mobile screens and integrate APIs.',
      matchScore: 92,
      applied: false,
      saved: true,
      postedDate: DateTime(2026, 5, 12),
      deadline: DateTime(2026, 6, 15),
    ),
    JobModel(
      id: 102,
      title: 'Junior Python Developer',
      company: 'Cloudmint Labs',
      location: 'Calicut',
      salary: '18000/month',
      experience: '0-2 years',
      skills: const ['Python', 'Django', 'REST API'],
      department: 'Python',
      description: 'Work on backend APIs for recruitment automation.',
      matchScore: 78,
      applied: false,
      saved: false,
      postedDate: DateTime(2026, 5, 10),
      deadline: DateTime(2026, 6, 10),
    ),
    JobModel(
      id: 103,
      title: 'Mobile UI Engineer',
      company: 'PixelWorks Studio',
      location: 'Remote',
      salary: '15000/month',
      experience: 'Fresher',
      skills: const ['Flutter', 'UI/UX', 'Firebase'],
      department: 'UI/UX',
      description: 'Create polished candidate-facing mobile experiences.',
      matchScore: 88,
      applied: false,
      saved: false,
      postedDate: DateTime(2026, 5, 8),
      deadline: DateTime(2026, 6, 5),
    ),
    JobModel(
      id: 107,
      title: 'Flutter App Developer',
      company: 'AppNest',
      location: 'Remote',
      salary: '20000/month',
      experience: '0-2 years',
      skills: const ['Flutter', 'Dart', 'Firebase'],
      department: 'Flutter',
      description: 'Develop mobile app features and connect Firebase modules.',
      matchScore: 86,
      applied: false,
      saved: false,
      postedDate: DateTime(2026, 5, 4),
      deadline: DateTime(2026, 6, 9),
    ),
    JobModel(
      id: 108,
      title: 'Python API Trainee',
      company: 'ServerCraft',
      location: 'Kochi',
      salary: '17000/month',
      experience: 'Fresher',
      skills: const ['Python', 'FastAPI', 'SQL'],
      department: 'Python',
      description: 'Build API endpoints and maintain backend services.',
      matchScore: 81,
      applied: false,
      saved: false,
      postedDate: DateTime(2026, 5, 3),
      deadline: DateTime(2026, 6, 7),
    ),
    JobModel(
      id: 109,
      title: 'UI/UX Designer Intern',
      company: 'DesignGrid',
      location: 'Calicut',
      salary: '13000/month',
      experience: 'Fresher',
      skills: const ['UI/UX', 'Figma', 'Wireframing'],
      department: 'UI/UX',
      description: 'Create product flows, wireframes, and interface mockups.',
      matchScore: 83,
      applied: false,
      saved: false,
      postedDate: DateTime(2026, 5, 2),
      deadline: DateTime(2026, 6, 4),
    ),
    JobModel(
      id: 104,
      title: 'Data Analyst Trainee',
      company: 'InsightGrid',
      location: 'Kochi',
      salary: '16000/month',
      experience: 'Fresher',
      skills: const ['Python', 'SQL', 'Power BI'],
      department: 'Data Science',
      description: 'Analyze hiring data and build practical dashboards.',
      matchScore: 74,
      applied: false,
      saved: false,
      postedDate: DateTime(2026, 5, 7),
      deadline: DateTime(2026, 6, 12),
    ),
    JobModel(
      id: 105,
      title: 'HR Operations Intern',
      company: 'PeopleFirst',
      location: 'Thrissur',
      salary: '10000/month',
      experience: 'Fresher',
      skills: const ['Recruitment', 'Communication', 'MS Excel'],
      department: 'Human Resources',
      description: 'Support candidate screening, scheduling, and HR records.',
      matchScore: 69,
      applied: false,
      saved: false,
      postedDate: DateTime(2026, 5, 6),
      deadline: DateTime(2026, 6, 8),
    ),
    JobModel(
      id: 106,
      title: 'Digital Marketing Associate',
      company: 'MarketPulse',
      location: 'Remote',
      salary: '14000/month',
      experience: '0-1 years',
      skills: const ['SEO', 'Content Writing', 'Analytics'],
      department: 'Marketing',
      description: 'Create campaign content and monitor performance metrics.',
      matchScore: 71,
      applied: false,
      saved: false,
      postedDate: DateTime(2026, 5, 5),
      deadline: DateTime(2026, 6, 6),
    ),
  ];

  static final recentApplications = [
    ApplicationModel(
      id: 301,
      jobId: 101,
      status: 'applied',
      matchScore: 92,
      jobTitle: 'Flutter Developer Intern',
      company: 'Nexa Digital',
      jobLocation: 'Kochi',
      jobDepartment: 'Flutter',
      jobDescription: 'Build production Flutter screens and integrate APIs.',
      jobSkills: const ['Flutter', 'Dart', 'REST API'],
      statusMessage: 'Application submitted. Waiting for HR review.',
      candidateName: 'Demo Candidate',
      candidateEmail: 'candidate@example.com',
      candidatePhone: '9876543210',
      candidateCourse: 'Flutter',
      candidateCvUrl: '/media/demo_resume.pdf',
      candidateSkills: skills,
      appliedAt: DateTime(2026, 5, 12),
    ),
    ApplicationModel(
      id: 302,
      jobId: 104,
      status: 'under_review',
      matchScore: 84,
      jobTitle: 'Frontend Developer Trainee',
      company: 'Brightpath Tech',
      jobLocation: 'Remote',
      jobDepartment: 'Flutter',
      jobDescription: 'Support mobile feature delivery with Flutter.',
      jobSkills: const ['Flutter', 'Dart'],
      statusMessage: 'HR is reviewing your application and CV.',
      candidateName: 'Demo Candidate',
      candidateEmail: 'candidate@example.com',
      candidatePhone: '9876543210',
      candidateCourse: 'Flutter',
      candidateCvUrl: '/media/demo_resume.pdf',
      candidateSkills: skills,
      appliedAt: DateTime(2026, 5, 11),
    ),
  ];

  static final hrApplications = [
    ...recentApplications,
    ApplicationModel(
      id: 303,
      jobId: 102,
      status: 'mcq_completed',
      matchScore: 78,
      jobTitle: 'Junior Python Developer',
      company: 'Cloudmint Labs',
      candidateName: 'Amal K',
      candidateEmail: 'amal@example.com',
      candidatePhone: '9876512345',
      candidateCourse: 'B.Tech CSE',
      candidateCvUrl: '/media/amal_resume.pdf',
      candidateSkills: const ['Python', 'Django', 'REST API'],
      appliedAt: DateTime(2026, 5, 9),
      mcqScore: 82,
      mcqPassed: true,
      interviewResult: 'recommended',
      interviewFeedback: 'Strong fundamentals and clear communication.',
      interviewAnalysis: const {
        'technical_fit': 'Good',
        'communication': 'Clear',
        'hiring_notes': 'Ready for junior backend responsibilities.',
      },
    ),
  ];

  static DashboardBundle dashboard() {
    return DashboardBundle(
      profile: profile,
      recommendedJobs: jobs,
      recentApplications: recentApplications,
      savedJobs: jobs.where((job) => job.saved).toList(),
    );
  }

  static JobsPage jobsPage({
    required int page,
    required String query,
    required String location,
    String? department,
    required List<String> selectedSkills,
    List<String> matchSkills = const [],
    bool skillMatch = true,
  }) {
    final normalizedQuery = query.trim().toLowerCase();
    final normalizedLocation = location.trim().toLowerCase();
    final normalizedDepartment = department?.trim().toLowerCase() ?? '';
    final normalizedSkills =
        selectedSkills.map((skill) => skill.toLowerCase()).toList();
    final filtered =
        jobs.where((job) {
            final queryMatch =
                normalizedQuery.isEmpty ||
                job.title.toLowerCase().contains(normalizedQuery) ||
                job.company.toLowerCase().contains(normalizedQuery) ||
                job.skills.any(
                  (skill) => skill.toLowerCase().contains(normalizedQuery),
                );
            final locationMatch =
                normalizedLocation.isEmpty ||
                job.location.toLowerCase().contains(normalizedLocation);
            final departmentMatch =
                normalizedDepartment.isEmpty ||
                departmentMatchesJob(department, job.department);
            final skillsMatch =
                normalizedSkills.isEmpty ||
                normalizedSkills.every(
                  (skill) => job.skills.any(
                    (jobSkill) => jobSkill.toLowerCase().contains(skill),
                  ),
                );
            final relevanceMatch =
                normalizedDepartment.isEmpty || departmentMatch;
            return queryMatch && locationMatch && skillsMatch && relevanceMatch;
          }).toList()
          ..sort((a, b) => b.matchScore.compareTo(a.matchScore));
    return JobsPage(jobs: filtered, hasNext: false, page: page);
  }

  static const mcqQuestions = [
    McqQuestion(
      id: 1,
      question: 'Which widget is commonly used for vertical scrolling?',
      options: ['ListView', 'Stack', 'Opacity', 'Icon'],
    ),
    McqQuestion(
      id: 2,
      question: 'Which language is used by Flutter?',
      options: ['Dart', 'Kotlin only', 'Swift only', 'PHP'],
    ),
    McqQuestion(
      id: 3,
      question: 'What status code usually means a successful POST create?',
      options: ['201', '404', '500', '301'],
    ),
  ];
}
