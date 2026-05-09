import re
import uuid

def gen_uuid():
    return uuid.uuid4().hex.upper()[:24]

with open('BuildTrack.xcodeproj/project.pbxproj', 'r') as f:
    content = f.read()

# New files to add with their paths
new_files = {
    # AdminModels.swift -> Domain/Models/AdminModels.swift
    'AdminModels.swift': {
        'build_uuid': gen_uuid(),
        'ref_uuid': gen_uuid(),
        'path': 'Domain/Models/AdminModels.swift',
    },
    # Admin view files -> Features/Admin/
    'AdminDashboardView.swift': {
        'build_uuid': gen_uuid(),
        'ref_uuid': gen_uuid(),
        'path': 'Features/Admin/AdminDashboardView.swift',
    },
    'AdminUsersView.swift': {
        'build_uuid': gen_uuid(),
        'ref_uuid': gen_uuid(),
        'path': 'Features/Admin/AdminUsersView.swift',
    },
    'AdminProjectsView.swift': {
        'build_uuid': gen_uuid(),
        'ref_uuid': gen_uuid(),
        'path': 'Features/Admin/AdminProjectsView.swift',
    },
    'AdminBillingView.swift': {
        'build_uuid': gen_uuid(),
        'ref_uuid': gen_uuid(),
        'path': 'Features/Admin/AdminBillingView.swift',
    },
    # AdminRepository.swift -> Infrastructure/Supabase/
    'AdminRepository.swift': {
        'build_uuid': gen_uuid(),
        'ref_uuid': gen_uuid(),
        'path': 'Infrastructure/Supabase/AdminRepository.swift',
    },
    # Admin ViewModels -> Infrastructure/ViewModels/
    'AdminDashboardViewModel.swift': {
        'build_uuid': gen_uuid(),
        'ref_uuid': gen_uuid(),
        'path': 'Infrastructure/ViewModels/AdminDashboardViewModel.swift',
    },
    'AdminProjectsViewModel.swift': {
        'build_uuid': gen_uuid(),
        'ref_uuid': gen_uuid(),
        'path': 'Infrastructure/ViewModels/AdminProjectsViewModel.swift',
    },
    'AdminUsersViewModel.swift': {
        'build_uuid': gen_uuid(),
        'ref_uuid': gen_uuid(),
        'path': 'Infrastructure/ViewModels/AdminUsersViewModel.swift',
    },
}

# 1. Add PBXBuildFile entries after /* Begin PBXBuildFile section */
build_file_entries = []
for name, info in new_files.items():
    build_file_entries.append(
        f"\t\t{info['build_uuid']} /* {name} in Sources */ = {{isa = PBXBuildFile; fileRef = {info['ref_uuid']} /* {name} */; }};"
    )

build_files_text = '\n'.join(build_file_entries)
content = content.replace(
    '/* Begin PBXBuildFile section */\n',
    f'/* Begin PBXBuildFile section */\n{build_files_text}\n'
)

# 2. Add PBXFileReference entries after /* Begin PBXFileReference section */
file_ref_entries = []
for name, info in new_files.items():
    file_ref_entries.append(
        f"\t\t{info['ref_uuid']} /* {name} */ = {{isa = PBXFileReference; includeInIndex = 1; lastKnownFileType = sourcecode.swift; name = {name}; path = {info['path']}; sourceTree = \"<group>\"; }};"
    )

file_refs_text = '\n'.join(file_ref_entries)
content = content.replace(
    '/* Begin PBXFileReference section */\n',
    f'/* Begin PBXFileReference section */\n{file_refs_text}\n'
)

# 3. Add Admin group under Features
admin_group_uuid = gen_uuid()
admin_children = '\n'.join(
    f"\t\t\t\t{info['ref_uuid']} /* {name} */,"
    for name, info in new_files.items()
    if info['path'].startswith('Features/Admin/')
)
admin_group = f"""\t\t{admin_group_uuid} /* Admin */ = {{
\t\t\tisa = PBXGroup;
\t\t\tchildren = (
{admin_children}
\t\t\t);
\t\t\tname = Admin;
\t\t\tsourceTree = "<group>";
\t\t}};"""

# Insert Admin group before closing of PBXGroup section
# Find the last group entry before "/* End PBXGroup section */"
content = content.replace(
    '/* End PBXGroup section */',
    f'{admin_group}\n\t\t/* End PBXGroup section */'
)

# 4. Add AdminModels.swift to Domain/Models group (find the Models.swift entry)
# Find "Models.swift" group and add AdminModels after it
for name in ['AdminModels.swift']:
    info = new_files[name]
    models_ref = new_files.get('Models.swift', {}).get('ref_uuid', '1F5488D5D1727FE7FF6C08E3')
    content = content.replace(
        f"\t\t\t\t{models_ref} /* Models.swift */",
        f"\t\t\t\t{models_ref} /* Models.swift */\n\t\t\t\t{info['ref_uuid']} /* {name} */,"
    )

# 5. Add AdminRepository to Infrastructure/Supabase group
# Find Repositories.swift ref and add after
repositories_ref = '7818EA60012E7A0AA2C6A817'
for name in ['AdminRepository.swift']:
    info = new_files[name]
    content = content.replace(
        f"\t\t\t\t{repositories_ref} /* Repositories.swift */",
        f"\t\t\t\t{repositories_ref} /* Repositories.swift */\n\t\t\t\t{info['ref_uuid']} /* {name} */,"
    )

# 6. Add Admin ViewModels to Infrastructure/ViewModels group
# Find SafetyViewModel ref and add after
safety_vm_ref = '137494BF89F5DB4A84B43403'
for name in ['AdminDashboardViewModel.swift', 'AdminProjectsViewModel.swift', 'AdminUsersViewModel.swift']:
    info = new_files[name]
    content = content.replace(
        f"\t\t\t\t{safety_vm_ref} /* SafetyViewModel.swift */",
        f"\t\t\t\t{safety_vm_ref} /* SafetyViewModel.swift */\n\t\t\t\t{info['ref_uuid']} /* {name} */,"
    )

# 7. Add Admin group to Features group children
# Find "Onboarding" in Features group and add Admin after
content = content.replace(
    "\t\t\t\t4AFB13B0DE78A04F7950499F /* Onboarding */",
    f"\t\t\t\t4AFB13B0DE78A04F7950499F /* Onboarding */\n\t\t\t\t{admin_group_uuid} /* Admin */,"
)

# 8. Add all new files to PBXSourcesBuildPhase
# Find the last file in Sources and append
build_phase_entries = []
for name, info in new_files.items():
    build_phase_entries.append(
        f"\t\t\t\t{info['build_uuid']} /* {name} in Sources */,"
    )

# Find last entry in PBXSourcesBuildPhase
last_source_pattern = r'(\t\t\t\t[A-F0-9]+ /\* .* in Sources \*/;)\n\t\t\t\);\n\t\t\tname = Sources;'
match = re.search(last_source_pattern, content)
if match:
    last_entry = match.group(1)
    all_entries = '\n'.join(build_phase_entries)
    content = content.replace(
        last_entry + '\n\t\t\t);',
        last_entry + '\n' + all_entries + '\n\t\t\t);'
    )

with open('BuildTrack.xcodeproj/project.pbxproj', 'w') as f:
    f.write(content)

print("Updated pbxproj with", len(new_files), "new files")
for name, info in new_files.items():
    print(f"  - {name}: ref={info['ref_uuid']}, build={info['build_uuid']}")
