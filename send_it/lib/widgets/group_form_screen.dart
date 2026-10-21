import 'package:flutter/cupertino.dart';
import 'package:flutter_contacts/flutter_contacts.dart';

import '../services/contact_search_service.dart';
import '../services/contacts_access_service.dart';
import '../theme/app_surfaces.dart';
import '../theme/app_text.dart';
import 'ui/buttons.dart';
import 'ui/dialogs.dart';
import 'ui/rows.dart';
import 'ui/section_header.dart';

/// Contacts access plus whatever contacts it can read.
typedef ContactsLoad = ({ContactsAccess access, List<Contact> contacts});

/// Name a group and pick its members. Shared by Create and Edit, which
/// only differ in [title], [submitLabel], the starting values and what
/// [onSubmit] does with the result.
class GroupFormScreen extends StatefulWidget {
  const GroupFormScreen({
    super.key,
    required this.title,
    required this.submitLabel,
    required this.allContacts,
    required this.onSubmit,
    this.initialName = '',
    this.initialMembers = const [],
    this.contactsAccess = ContactsAccess.granted,
    this.loadContacts,
  });

  final String title;
  final String submitLabel;
  final List<Contact> allContacts;
  final String initialName;
  final List<Contact> initialMembers;

  /// Access when the form opened. Without read access the member list is
  /// replaced by an explanation, and the iOS prompt only appears after it.
  final ContactsAccess contactsAccess;

  /// Re-checks access and reloads contacts; with `request: true` it shows
  /// the iOS prompt first. Required unless [contactsAccess] can read.
  final Future<ContactsLoad> Function({required bool request})? loadContacts;

  /// Called with a non-empty name and at least one member. The screen
  /// doesn't pop itself; [onSubmit] decides.
  final Future<void> Function(String name, List<Contact> members) onSubmit;

  @override
  State<GroupFormScreen> createState() => _GroupFormScreenState();
}

class _GroupFormScreenState extends State<GroupFormScreen>
    with WidgetsBindingObserver {
  late final TextEditingController _nameController;
  final TextEditingController _searchController = TextEditingController();
  late List<Contact> _selected;
  late List<Contact> _filtered;
  late List<Contact> _contacts;
  late ContactsAccess _access;
  bool _searchName = true;
  bool _searchCompany = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _selected = List.of(widget.initialMembers);
    _contacts = widget.allContacts;
    _access = widget.contactsAccess;
    _filtered = _contacts;
    _searchController.addListener(_filterContacts);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Back from Settings: access may have changed.
    if (state == AppLifecycleState.resumed &&
        _access != ContactsAccess.granted) {
      _reloadContacts(request: false);
    }
  }

  Future<void> _reloadContacts({required bool request}) async {
    final load = widget.loadContacts;
    if (load == null) return;
    final result = await load(request: request);
    if (!mounted) return;
    setState(() {
      _access = result.access;
      _contacts = result.contacts;
    });
    _filterContacts();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _nameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _filterContacts() {
    setState(() {
      _filtered = ContactSearchService.searchContacts(
        _contacts,
        _searchController.text,
        searchName: _searchName,
        searchCompany: _searchCompany,
      );
    });
  }

  void _toggle(Contact contact, bool selected) {
    setState(() {
      if (selected) {
        _selected.add(contact);
      } else {
        _selected.remove(contact);
      }
    });
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      await showNotice(
        context,
        title: 'Name Your Group',
        message: 'Give the group a name so you can find it later.',
      );
      return;
    }
    if (_selected.isEmpty) {
      await showNotice(
        context,
        title: 'Add Members',
        message: 'Select at least one contact for this group.',
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await widget.onSubmit(name, _selected);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  static String _detailFor(Contact contact) {
    if (contact.organizations.isNotEmpty) {
      final org = contact.organizations.first;
      if (org.company.isNotEmpty) {
        return org.title.isNotEmpty
            ? '${org.company} • ${org.title}'
            : org.company;
      }
    }
    return contact.phones.firstOrNull?.number ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final surfaces = context.surfaces;
    final query = _searchController.text;
    final canRead = _access.canRead;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(middle: Text(widget.title)),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CupertinoTextField(
                            controller: _nameController,
                            placeholder: 'Group name',
                            textCapitalization: TextCapitalization.words,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            style: AppText.body.copyWith(color: surfaces.ink),
                            placeholderStyle:
                                AppText.body.copyWith(color: surfaces.faint),
                            decoration: BoxDecoration(
                              color: surfaces.card,
                              borderRadius: BorderRadius.circular(AppRadii.md),
                              border: Border.all(color: surfaces.hairline),
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (canRead) ...[
                            CupertinoSearchTextField(
                              controller: _searchController,
                              placeholder: 'Search contacts',
                              backgroundColor: surfaces.fill,
                              style: AppText.body.copyWith(color: surfaces.ink),
                              borderRadius: BorderRadius.circular(AppRadii.sm),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Text(
                                  'Search in',
                                  style: AppText.footnote
                                      .copyWith(color: surfaces.muted),
                                ),
                                const SizedBox(width: 8),
                                _FilterChip(
                                  label: 'Name',
                                  selected: _searchName,
                                  onTap: () {
                                    _searchName = !_searchName;
                                    _filterContacts();
                                  },
                                ),
                                const SizedBox(width: 8),
                                _FilterChip(
                                  label: 'Company',
                                  selected: _searchCompany,
                                  onTap: () {
                                    _searchCompany = !_searchCompany;
                                    _filterContacts();
                                  },
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: SectionHeader(
                      'Members',
                      trailing: Text(
                        '${_selected.length} selected',
                      ),
                    ),
                  ),
                  if (_access == ContactsAccess.limited)
                    const SliverToBoxAdapter(
                      child: _LimitedAccessNote(
                        onManage: ContactsAccessService.openSettings,
                      ),
                    ),
                  if (!canRead)
                    SliverToBoxAdapter(
                      child: ContactsPrePrompt(
                        denied: _access == ContactsAccess.denied,
                        onContinue: () => _reloadContacts(request: true),
                        onOpenSettings: ContactsAccessService.openSettings,
                      ),
                    )
                  else if (_filtered.isEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Text(
                          _contacts.isEmpty
                              ? 'No contacts available.'
                              : 'No contacts match "$query".',
                          textAlign: TextAlign.center,
                          style:
                              AppText.subhead.copyWith(color: surfaces.muted),
                        ),
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      sliver: DecoratedSliver(
                        decoration: surfaces.cardDecoration(),
                        sliver: SliverList.separated(
                          itemCount: _filtered.length,
                          separatorBuilder: (_, __) => Padding(
                            padding: const EdgeInsets.only(left: 68),
                            child: Container(
                              height: 0.5,
                              color: surfaces.hairline,
                            ),
                          ),
                          itemBuilder: (context, index) {
                            final contact = _filtered[index];
                            final match = query.isNotEmpty
                                ? ContactSearchService.getSearchResult(
                                    contact,
                                    query,
                                  ).matchSummary
                                : null;
                            return SelectableContactRow(
                              name: contact.displayName,
                              detail: _detailFor(contact),
                              badge: match,
                              selected: _selected.contains(contact),
                              onChanged: (value) => _toggle(contact, value),
                            );
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
            _SubmitBar(
              selectedCount: _selected.length,
              label: widget.submitLabel,
              onPressed: _submitting ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}

/// Explains why Sent It needs Contacts before iOS asks, or (once denied)
/// how to turn it back on.
class ContactsPrePrompt extends StatelessWidget {
  const ContactsPrePrompt({
    super.key,
    required this.denied,
    required this.onContinue,
    required this.onOpenSettings,
  });

  final bool denied;
  final VoidCallback onContinue;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final surfaces = context.surfaces;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: surfaces.cardDecoration(),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: surfaces.accentSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(
              denied
                  ? CupertinoIcons.person_crop_circle_badge_xmark
                  : CupertinoIcons.person_2_fill,
              color: surfaces.accent,
              size: 28,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            denied
                ? 'Contacts access is off'
                : 'Pick people from your contacts',
            textAlign: TextAlign.center,
            style: AppText.headline.copyWith(color: surfaces.ink),
          ),
          const SizedBox(height: 6),
          Text(
            denied
                ? 'Sent It needs Contacts to add people to a group. '
                    'Turn it on in Settings → Sent It → Contacts.'
                : 'Sent It uses your contacts to build groups. '
                    'Their info never leaves your phone.',
            textAlign: TextAlign.center,
            style: AppText.subhead.copyWith(color: surfaces.muted),
          ),
          const SizedBox(height: 18),
          PrimaryButton(
            label: denied ? 'Open Settings' : 'Continue',
            expand: true,
            onPressed: denied ? onOpenSettings : onContinue,
          ),
        ],
      ),
    );
  }
}

/// iOS 18 limited access: say why some people are missing.
class _LimitedAccessNote extends StatelessWidget {
  const _LimitedAccessNote({required this.onManage});

  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    final surfaces = context.surfaces;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Sent It can only see the contacts you shared.',
              style: AppText.footnote.copyWith(color: surfaces.muted),
            ),
          ),
          TextActionButton(label: 'Manage', onPressed: onManage),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final surfaces = context.surfaces;
    final color = selected ? surfaces.accent : surfaces.muted;
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 32),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: ShapeDecoration(
            color: selected ? surfaces.accentSoft : surfaces.fill,
            shape: const StadiumBorder(),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                selected ? CupertinoIcons.checkmark : CupertinoIcons.add,
                size: 14,
                color: color,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: AppText.footnote.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sticky footer: how many are selected, and the submit button.
class _SubmitBar extends StatelessWidget {
  const _SubmitBar({
    required this.selectedCount,
    required this.label,
    required this.onPressed,
  });

  final int selectedCount;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final surfaces = context.surfaces;
    return Container(
      decoration: BoxDecoration(
        color: surfaces.card,
        border: Border(top: BorderSide(color: surfaces.hairline, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          // Both halves shrink to fit, so the button sits flush right.
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  selectedCount == 1
                      ? '1 contact selected'
                      : '$selectedCount contacts selected',
                  style: AppText.subhead.copyWith(color: surfaces.muted),
                ),
              ),
              Flexible(
                child: PrimaryButton(label: label, onPressed: onPressed),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
