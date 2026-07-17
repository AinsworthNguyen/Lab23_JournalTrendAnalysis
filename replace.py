import re

file_path = 'lib/features/home/presentation/screens/home_screen.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace('onBackground', 'onSurface')
content = re.sub(r'\.withOpacity\((.*?)\)', r'.withValues(alpha: \1)', content)
content = content.replace("'dashboard.recent_searches'.tr() + ' is empty'", "'${\\'dashboard.recent_searches\\'.tr()} is empty'")

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print('Replaced content in home_screen.dart')
