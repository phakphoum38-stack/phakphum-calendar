import 'package:flutter/material.dart';

enum ToolGroup { google, ai, developer, productivity }

@immutable
class ToolDefinition {
  const ToolDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.url,
    required this.icon,
    required this.color,
    required this.group,
    this.usesGoogleAccountChooser = false,
  });

  final String id;
  final String name;
  final String description;
  final String url;
  final IconData icon;
  final Color color;
  final ToolGroup group;
  final bool usesGoogleAccountChooser;

  Uri get uri => Uri.parse(url);
}

const toolCatalog = <ToolDefinition>[
  ToolDefinition(
    id: 'google',
    name: 'Google',
    description: 'ค้นหาข้อมูลบนเว็บ',
    url: 'https://www.google.com/',
    icon: Icons.search,
    color: Color(0xFF4285F4),
    group: ToolGroup.google,
  ),
  ToolDefinition(
    id: 'gmail',
    name: 'Gmail',
    description: 'อีเมล Google พร้อมเลือกบัญชี',
    url:
        'https://accounts.google.com/AccountChooser?continue='
        'https%3A%2F%2Fmail.google.com%2F',
    icon: Icons.mail_outline,
    color: Color(0xFFEA4335),
    group: ToolGroup.google,
    usesGoogleAccountChooser: true,
  ),
  ToolDefinition(
    id: 'drive',
    name: 'Google Drive',
    description: 'ไฟล์และโฟลเดอร์บน Google Drive',
    url:
        'https://accounts.google.com/AccountChooser?continue='
        'https%3A%2F%2Fdrive.google.com%2F',
    icon: Icons.add_to_drive_outlined,
    color: Color(0xFF0F9D58),
    group: ToolGroup.google,
    usesGoogleAccountChooser: true,
  ),
  ToolDefinition(
    id: 'calendar',
    name: 'Google Calendar',
    description: 'ปฏิทิน Google พร้อมเลือกบัญชี',
    url:
        'https://accounts.google.com/AccountChooser?continue='
        'https%3A%2F%2Fcalendar.google.com%2F',
    icon: Icons.calendar_month_outlined,
    color: Color(0xFF4285F4),
    group: ToolGroup.google,
    usesGoogleAccountChooser: true,
  ),
  ToolDefinition(
    id: 'sheets',
    name: 'Google Sheets',
    description: 'เปิดและจัดการสเปรดชีต',
    url:
        'https://accounts.google.com/AccountChooser?continue='
        'https%3A%2F%2Fsheets.google.com%2F',
    icon: Icons.table_chart_outlined,
    color: Color(0xFF188038),
    group: ToolGroup.google,
    usesGoogleAccountChooser: true,
  ),
  ToolDefinition(
    id: 'gemini',
    name: 'Gemini AI',
    description: 'ผู้ช่วย AI จาก Google',
    url:
        'https://accounts.google.com/AccountChooser?continue='
        'https%3A%2F%2Fgemini.google.com%2Fapp',
    icon: Icons.auto_awesome_outlined,
    color: Color(0xFF7B61FF),
    group: ToolGroup.ai,
    usesGoogleAccountChooser: true,
  ),
  ToolDefinition(
    id: 'chatgpt',
    name: 'ChatGPT',
    description: 'ผู้ช่วย AI สำหรับงานและการเรียนรู้',
    url: 'https://chatgpt.com/',
    icon: Icons.psychology_outlined,
    color: Color(0xFF10A37F),
    group: ToolGroup.ai,
  ),
  ToolDefinition(
    id: 'copilot',
    name: 'Microsoft Copilot',
    description: 'ผู้ช่วย AI จาก Microsoft',
    url: 'https://copilot.microsoft.com/',
    icon: Icons.hub_outlined,
    color: Color(0xFF6C47FF),
    group: ToolGroup.ai,
  ),
  ToolDefinition(
    id: 'github',
    name: 'GitHub',
    description: 'Repository, Issues และ Pull Requests',
    url: 'https://github.com/',
    icon: Icons.code,
    color: Color(0xFF24292F),
    group: ToolGroup.developer,
  ),
  ToolDefinition(
    id: 'vscode',
    name: 'VS Code Web',
    description: 'เปิด Visual Studio Code ในเบราว์เซอร์',
    url: 'https://vscode.dev/',
    icon: Icons.developer_mode_outlined,
    color: Color(0xFF007ACC),
    group: ToolGroup.developer,
  ),
  ToolDefinition(
    id: 'google_cloud',
    name: 'Google Cloud',
    description: 'จัดการโปรเจกต์และบริการ Google Cloud',
    url:
        'https://accounts.google.com/AccountChooser?continue='
        'https%3A%2F%2Fconsole.cloud.google.com%2F',
    icon: Icons.cloud_outlined,
    color: Color(0xFF4285F4),
    group: ToolGroup.developer,
    usesGoogleAccountChooser: true,
  ),
  ToolDefinition(
    id: 'notion',
    name: 'Notion',
    description: 'เอกสาร โน้ต และพื้นที่ทำงานร่วมกัน',
    url: 'https://www.notion.so/',
    icon: Icons.description_outlined,
    color: Color(0xFF111111),
    group: ToolGroup.productivity,
  ),
];

const defaultPinnedToolIds = <String>{
  'google',
  'gmail',
  'chatgpt',
  'github',
  'vscode',
};

ToolDefinition? toolById(String id) {
  for (final tool in toolCatalog) {
    if (tool.id == id) return tool;
  }
  return null;
}
