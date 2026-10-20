import 'package:flutter/cupertino.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:upgrader/upgrader.dart';
import 'models/message_group.dart';
import 'screens/create_group_screen.dart';
import 'screens/group_message_screen.dart';
import 'screens/more_screen.dart';
import 'screens/welcome_screen.dart';
import 'services/analytics_service.dart';
import 'services/appearance_service.dart';
import 'services/blast_feature_service.dart';
import 'services/contacts_access_service.dart';
import 'services/group_storage.dart';
import 'services/onboarding_service.dart';
import 'services/subscription_service.dart';
import 'theme/app_surfaces.dart';
import 'theme/app_theme.dart';
import 'widgets/group_form_screen.dart';
import 'widgets/subscription_gate.dart';
import 'widgets/ui/avatar.dart';
import 'widgets/ui/buttons.dart';
import 'widgets/ui/dialogs.dart';
import 'widgets/ui/empty_state.dart';
import 'widgets/ui/grouped_section.dart';
import 'widgets/ui/rows.dart';
import 'widgets/ui/section_header.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // These two tell fresh installs from existing users by an empty store,
  // so they run before anything else touches it.
  await OnboardingService.instance.initialize();
  await AppearanceService.instance.initialize();
  await AnalyticsService.instance.initialize();
  await SubscriptionService.instance.initialize();
  await BlastFeatureService.instance.initialize();
  runApp(const SendItApp());
}

class SendItApp extends StatelessWidget {
  const SendItApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppearanceService.instance,
      builder: (context, _) => CupertinoApp(
        title: 'Sent It',
        theme: AppTheme.cupertino(
          brightness: AppearanceService.instance.mode.brightness,
        ),
        home: SubscriptionGate(
          child: WelcomeGate(
            child: UpgradeAlert(
              upgrader: Upgrader(
                // debugLogging: true, // Set to true for debugging
                debugDisplayAlways: false,
              ),
              dialogStyle: UpgradeDialogStyle.cupertino,
              child: const HomePage(),
            ),
          ),
        ),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Contact> allContacts = [];
  ContactsAccess contactsAccess = ContactsAccess.notDetermined;
  bool isLoading = true;
  List<MessageGroup> groups = [];

  @override
  void initState() {
    super.initState();
    _initialLoad();
  }

  /// Never prompts for Contacts here: the group form asks, after explaining
  /// why. Groups still load without access (members just can't resolve).
  Future<void> _initialLoad() async {
    await _loadContacts(request: false);
    await _loadGroups();
    if (mounted) setState(() => isLoading = false);
  }

  Future<ContactsLoad> _loadContacts({required bool request}) async {
    final access = request
        ? await ContactsAccessService.request()
        : await ContactsAccessService.status();
    var contacts = <Contact>[];
    if (access.canRead) {
      try {
        contacts = await ContactsAccessService.load();
      } catch (e) {
        if (mounted) {
          showNotice(context, title: "Couldn't Load Contacts", message: '$e');
        }
      }
    }
    final contactsChanged = contacts.length != allContacts.length;
    if (mounted) {
      setState(() {
        contactsAccess = access;
        allContacts = contacts;
      });
    }
    GroupStorage.setContacts(contacts);
    // Members are matched to contacts, so reload groups when they change.
    if (contactsChanged && !isLoading) await _loadGroups();
    return (access: access, contacts: contacts);
  }

  Future<void> _loadGroups() async {
    try {
      final loadedGroups = await GroupStorage.loadGroups(allContacts);
      if (!mounted) return;
      setState(() {
        groups = loadedGroups;
      });
    } catch (e) {
      if (mounted) {
        showNotice(context, title: "Couldn't Load Groups", message: '$e');
      }
    }
  }

  Future<void> _createNewGroup() async {
    await Navigator.push<MessageGroup>(
      context,
      CupertinoPageRoute(
        builder: (context) => CreateGroupScreen(
          allContacts: allContacts,
          contactsAccess: contactsAccess,
          loadContacts: _loadContacts,
          onGroupCreated: (group) async {
            await GroupStorage.addGroup(group);
            if (await OnboardingService.instance.markFirstGroupCreated()) {
              AnalyticsService.instance.firstGroupCreated(
                recipientCount: group.members.length,
              );
            }
            await _loadGroups();
          },
        ),
      ),
    );
  }

  void _openGroup(MessageGroup group) {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => GroupMessageScreen(
          group: group,
          allContacts: allContacts,
          onGroupUpdated: (updatedGroup) async {
            await GroupStorage.updateGroup(updatedGroup);
            await _loadGroups();
          },
          onGroupDeleted: (groupId) async {
            await GroupStorage.deleteGroup(groupId);
            await _loadGroups();
          },
        ),
      ),
    );
  }

  static String _memberCount(MessageGroup group) {
    final n = group.members.length;
    return '$n ${n == 1 ? 'member' : 'members'}';
  }

  @override
  Widget build(BuildContext context) {
    final surfaces = context.surfaces;

    return CupertinoPageScaffold(
      child: Stack(
        children: [
          CustomScrollView(
            slivers: [
              CupertinoSliverNavigationBar(
                largeTitle: const Text('Sent It'),
                border: null,
                trailing: NavIconButton(
                  icon: CupertinoIcons.ellipsis_circle,
                  semanticLabel: 'More',
                  onPressed: () => Navigator.push(
                    context,
                    CupertinoPageRoute(builder: (_) => const MoreScreen()),
                  ),
                ),
              ),
              if (isLoading)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CupertinoActivityIndicator()),
                )
              else if (groups.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(
                    icon: CupertinoIcons.person_3_fill,
                    title: 'Start with a group',
                    message: 'A group is the people you text together, '
                        'like family or your team. Each of them gets '
                        'their own message.',
                    action: PrimaryButton(
                      label: 'Create Your First Group',
                      icon: CupertinoIcons.add,
                      onPressed: _createNewGroup,
                    ),
                  ),
                )
              else
                SliverSafeArea(
                  top: false,
                  sliver: SliverPadding(
                    // Room for the floating button over the last row.
                    padding: const EdgeInsets.only(top: 8, bottom: 112),
                    sliver: SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SectionHeader(
                            'Groups',
                            trailing: Text('${groups.length}'),
                          ),
                          GroupedSection(
                            dividerIndent: 72,
                            children: [
                              for (final group in groups)
                                TappableRow(
                                  title: group.name,
                                  subtitle: _memberCount(group),
                                  leading: InitialAvatar(group.name, size: 44),
                                  trailing: Icon(
                                    CupertinoIcons.chevron_forward,
                                    size: 18,
                                    color: surfaces.faint,
                                  ),
                                  onTap: () => _openGroup(group),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
          if (!isLoading && groups.isNotEmpty)
            Positioned(
              right: 20,
              bottom: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _NewGroupButton(onPressed: _createNewGroup),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Floating round "+" for a new group.
class _NewGroupButton extends StatelessWidget {
  const _NewGroupButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final surfaces = context.surfaces;
    return Semantics(
      button: true,
      label: 'New group',
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: surfaces.accentFill,
            shape: BoxShape.circle,
            boxShadow: surfaces.floating,
          ),
          child: Icon(CupertinoIcons.add, color: surfaces.onAccent, size: 28),
        ),
      ),
    );
  }
}
