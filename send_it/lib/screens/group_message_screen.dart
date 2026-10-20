import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../constants/diagnostic_constants.dart';
import '../models/message_group.dart';
import '../services/blast_feature_service.dart';
import '../services/group_storage.dart';
import '../services/shortcut_service.dart';
import '../theme/app_surfaces.dart';
import '../theme/app_text.dart';
import '../widgets/ui/buttons.dart';
import '../widgets/ui/dialogs.dart';
import '../widgets/ui/rows.dart';
import '../widgets/ui/section_header.dart';
import 'edit_group_screen.dart';
import 'group_message/composer.dart';
import 'more_screen.dart';

class GroupMessageScreen extends StatefulWidget {
  final MessageGroup group;
  final List<Contact> allContacts;
  final Function(MessageGroup) onGroupUpdated;
  final Function(String) onGroupDeleted;

  const GroupMessageScreen({
    super.key,
    required this.group,
    required this.allContacts,
    required this.onGroupUpdated,
    required this.onGroupDeleted,
  });

  @override
  State<GroupMessageScreen> createState() => _GroupMessageScreenState();
}

class _GroupMessageScreenState extends State<GroupMessageScreen> {
  final TextEditingController _messageController = TextEditingController();
  final FocusNode _textFieldFocusNode = FocusNode();
  final _blastFeature = BlastFeatureService.instance;
  static const platform = MethodChannel('com.sendit/messages');
  late List<Contact> selectedContacts;
  final List<File> _selectedMedia = [];
  final ImagePicker _picker = ImagePicker();
  bool _showActionButtons = false;
  bool _showVariablesList = false;

  @override
  void initState() {
    super.initState();
    selectedContacts = List.from(widget.group.members);
    _messageController.addListener(() {
      setState(() {}); // Rebuild to update send button state
    });
    _blastFeature.addListener(_onBlastFeatureChanged);
  }

  void _onBlastFeatureChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _pickMedia() async {
    try {
      final XFile? media = await _picker.pickMedia(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (media != null) {
        setState(() {
          _selectedMedia.add(File(media.path));
        });
      }
    } catch (e) {
      if (!mounted) return;
      showNotice(context, title: "Couldn't Add Media", message: '$e');
    }
  }

  Future<void> _sendMessages() async {
    if (_messageController.text.isEmpty && _selectedMedia.isEmpty) {
      showNotice(
        context,
        title: 'Nothing to Send',
        message: 'Write a message or add a photo first.',
      );
      return;
    }

    if (selectedContacts.isEmpty) {
      showNotice(
        context,
        title: 'No Recipients',
        message: 'Select at least one person to send to.',
      );
      return;
    }

    for (final contact in selectedContacts) {
      final phoneNumber = contact.phones.firstOrNull?.number;
      if (phoneNumber == null) continue;

      // Clean up phone number format
      final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');

      final personalizedMessage =
          ShortcutService.personalizeMessage(_messageController.text, contact);

      try {
        // Create fresh copies of media files for each message to avoid conflicts
        // Only needed when there are attachments
        final List<String> freshMediaPaths = [];
        if (_selectedMedia.isNotEmpty) {
          for (final mediaFile in _selectedMedia) {
            if (await mediaFile.exists()) {
              final freshFile = File(
                  '${mediaFile.parent.path}/fresh_${DateTime.now().millisecondsSinceEpoch}_${mediaFile.uri.pathSegments.last}');
              await mediaFile.copy(freshFile.path);
              freshMediaPaths.add(freshFile.path);
            }
          }
        }

        final args = {
          'recipient': cleanNumber,
          'message': personalizedMessage,
          'mediaPaths': freshMediaPaths,
        };

        // Add a delay between message composers to allow proper cleanup and avoid race conditions
        // Only apply delay when there are attachments, as the issue only occurs with attachments
        if (selectedContacts.indexOf(contact) > 0 &&
            _selectedMedia.isNotEmpty) {
          await Future.delayed(const Duration(milliseconds: 800));
        }

        final result = await platform.invokeMethod('sendMessage', args);

        if (result == "sent") {
          // Message was sent successfully, continue to next contact
          continue;
        } else if (result == "cancelled") {
          // User cancelled, ask if they want to continue with remaining messages
          final remainingCount =
              selectedContacts.length - selectedContacts.indexOf(contact) - 1;
          if (remainingCount > 0 && mounted) {
            final shouldContinue = await showCupertinoDialog<bool>(
              context: context,
              builder: (context) => CupertinoAlertDialog(
                title: const Text('Message Cancelled'),
                content: Text(
                    'Do you want to continue sending to the remaining $remainingCount recipients?'),
                actions: [
                  CupertinoDialogAction(
                    isDestructiveAction: true,
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Stop'),
                  ),
                  CupertinoDialogAction(
                    isDefaultAction: true,
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Continue'),
                  ),
                ],
              ),
            );

            if (shouldContinue != true) {
              // User chose to stop sending
              break;
            }
          }
          // If user chose to continue or there are no more recipients, continue to next contact
          continue;
        }
      } on PlatformException catch (e) {
        debugPrint('Platform Exception: ${e.code} - ${e.message}');
        if (mounted) {
          showNotice(
            context,
            title: "Couldn't Send",
            message: e.message ?? e.code,
          );
        }
      } catch (e) {
        debugPrint('Error: $e');
        if (mounted) {
          showNotice(context, title: 'Something Went Wrong', message: '$e');
        }
      }
    }

    // Remember if there were attachments before clearing
    final hadAttachments = _selectedMedia.isNotEmpty;

    // Clear the message and media after sending
    setState(() {
      _messageController.clear();
      _selectedMedia.clear();
    });

    // Clean up any fresh media files that may have been created (only when there were attachments)
    if (hadAttachments) {
      try {
        final tempDir = Directory.systemTemp;
        final freshFiles = tempDir.listSync().where(
            (entity) => entity is File && entity.path.contains('fresh_'));
        for (final file in freshFiles) {
          await file.delete();
        }
      } catch (e) {
        // Ignore cleanup errors
      }
    }
  }

  Future<void> _sendViaShortcut() async {
    if (_messageController.text.trim().isEmpty) {
      showNotice(
        context,
        title: 'No Message',
        message: 'Write a message before sending with Blast.',
      );
      return;
    }

    if (selectedContacts.isEmpty) {
      showNotice(
        context,
        title: 'No Recipients',
        message: 'Select at least one person to send to.',
      );
      return;
    }

    final blastInstalled = await ShortcutService.isBlastInstalled();
    if (!mounted) return;
    if (!blastInstalled) {
      showCupertinoDialog(
        context: context,
        builder: (ctx) => CupertinoAlertDialog(
          title: const Text('Set Up Required'),
          content: const Text(
            'You need to install the Blast shortcut before using this feature.',
          ),
          actions: [
            CupertinoDialogAction(
              child: const Text('Don\'t Show Again'),
              onPressed: () {
                Navigator.pop(ctx);
                ShortcutService.markBlastInstalled();
              },
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              child: const Text('Set Up Blast'),
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.push(
                  context,
                  CupertinoPageRoute(builder: (_) => const MoreScreen()),
                );
              },
            ),
          ],
        ),
      );
      return;
    }

    final hasExtraMedia = _selectedMedia.length > 1;
    final diagnosticsNote = ShortcutService.isBlastDiagnosticsEnabled
        ? '\n\nEach send is logged to ${DiagnosticConstants.diagnosticLogFileName} '
            'in the Files app (created automatically). Share that file with us after.'
        : '';
    final count = selectedContacts.length;
    final confirmed = await showConfirm(
      context,
      title: 'Send via Blast?',
      message: 'This will automatically send a message to all '
          '$count selected contact${count == 1 ? '' : 's'} '
          'with no confirmation per person.'
          '${hasExtraMedia ? '\n\nOnly the first attachment will be included — Blast supports 1 media file at a time.' : ''}'
          '$diagnosticsNote',
      confirm: 'Send',
      destructive: true,
    );

    if (!confirmed) return;

    setState(() => _showActionButtons = false);

    final result = await ShortcutService.sendViaShortcut(
      contacts: selectedContacts,
      messageTemplate: _messageController.text,
      mediaFile: _selectedMedia.isNotEmpty ? _selectedMedia.first : null,
    );

    if (!mounted) return;

    switch (result) {
      case ShortcutLaunchResult.launched:
        setState(() {
          _messageController.clear();
          _selectedMedia.clear();
        });
        showNotice(
          context,
          title: 'Blast Launched',
          message: 'Your messages are being sent via Blast. '
              'The Shortcuts app may ask for permission the first time.',
          action: 'Got it',
        );
      case ShortcutLaunchResult.notInstalled:
        showNotice(
          context,
          title: 'Blast Not Installed',
          message: 'Blast isn\'t set up yet. '
              'Go to More → Install Shortcut to get started.',
        );
      case ShortcutLaunchResult.noValidContacts:
        showNotice(
          context,
          title: 'No Valid Numbers',
          message: 'None of the selected contacts have a valid phone number.',
        );
    }
  }

  Future<void> _editGroup() async {
    final updatedGroup = await Navigator.push<MessageGroup>(
      context,
      CupertinoPageRoute(
        builder: (context) => EditGroupScreen(
          group: widget.group,
          allContacts: widget.allContacts,
          onGroupUpdated: widget.onGroupUpdated,
        ),
      ),
    );

    if (updatedGroup != null && mounted) {
      setState(() {
        widget.group.members.clear();
        widget.group.members.addAll(updatedGroup.members);
        // Update selected contacts to match the new group members
        selectedContacts = List.from(updatedGroup.members);
      });
    }
  }

  Future<void> _deleteGroup() async {
    final confirmed = await showConfirm(
      context,
      title: 'Delete Group',
      message: 'Delete "${widget.group.name}"? Your contacts aren\'t affected.',
      confirm: 'Delete',
      destructive: true,
    );

    if (confirmed) {
      await GroupStorage.deleteGroup(widget.group.id);
      widget.onGroupDeleted(widget.group.id);
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  void _insertVariable(String variable) {
    final currentText = _messageController.text;
    final selection = _messageController.selection;

    // Insert the variable at the current cursor position (or the end when
    // the field has never been focused).
    final start = selection.isValid ? selection.start : currentText.length;
    final end = selection.isValid ? selection.end : currentText.length;
    final newText = currentText.replaceRange(start, end, variable);

    _messageController.text = newText;

    // Move cursor to after the inserted variable
    final newCursorPosition = start + variable.length;
    _messageController.selection =
        TextSelection.collapsed(offset: newCursorPosition);
  }

  void _toggleActionButtons() {
    final trayOpen = _showActionButtons || _showVariablesList;

    setState(() {
      if (trayOpen) {
        _showActionButtons = false;
        _showVariablesList = false;
      } else {
        _showActionButtons = true;
        _showVariablesList = false;
      }
    });
  }

  Widget _buildAccessorySlot() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      child: _showVariablesList
          ? VariablesPanel(
              onBack: () => setState(() {
                _showVariablesList = false;
                _showActionButtons = true;
              }),
              // Keep the list open so more variables can be added.
              onInsert: _insertVariable,
            )
          : _showActionButtons
              ? ActionTray(
                  blastEnabled: _blastFeature.isEnabled,
                  onGallery: () {
                    setState(() => _showActionButtons = false);
                    _pickMedia();
                  },
                  onVariables: () => setState(() {
                    _showActionButtons = false;
                    _showVariablesList = true;
                  }),
                  onBlast: _sendViaShortcut,
                )
              : const SizedBox.shrink(),
    );
  }

  void _dismissKeyboard() {
    FocusScope.of(context).unfocus();
  }

  void _dismissEverything() {
    _dismissKeyboard();
    setState(() {
      _showActionButtons = false;
      _showVariablesList = false;
    });
  }

  void _toggleContact(Contact contact, bool selected) {
    setState(() {
      if (selected) {
        selectedContacts.add(contact);
      } else {
        selectedContacts.remove(contact);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final surfaces = context.surfaces;
    final members = widget.group.members;
    final bool allSelected = selectedContacts.length == members.length;
    final canSend = selectedContacts.isNotEmpty &&
        _messageController.text.trim().isNotEmpty;

    return CupertinoPageScaffold(
      resizeToAvoidBottomInset: true,
      navigationBar: CupertinoNavigationBar(
        middle: Text(widget.group.name),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            NavIconButton(
              icon: CupertinoIcons.pencil,
              semanticLabel: 'Edit group',
              onPressed: _editGroup,
            ),
            NavIconButton(
              icon: CupertinoIcons.trash,
              semanticLabel: 'Delete group',
              color: surfaces.danger,
              onPressed: _deleteGroup,
            ),
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: _dismissEverything,
                behavior: HitTestBehavior.opaque,
                child: CustomScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: SectionHeader(
                          'Recipients',
                          trailing: CupertinoButton(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(44, 28),
                            onPressed: () => setState(() {
                              selectedContacts =
                                  allSelected ? [] : List.from(members);
                            }),
                            child: Text(
                              allSelected ? 'Deselect All' : 'Select All',
                              style: AppText.footnote.copyWith(
                                color: surfaces.accent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                        child: Text(
                          '${selectedContacts.length} of ${members.length} '
                          'will get a personal message',
                          style:
                              AppText.footnote.copyWith(color: surfaces.muted),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      sliver: DecoratedSliver(
                        decoration: surfaces.cardDecoration(),
                        sliver: SliverList.separated(
                          itemCount: members.length,
                          separatorBuilder: (_, __) => Padding(
                            padding: const EdgeInsets.only(left: 68),
                            child: Container(
                              height: 0.5,
                              color: surfaces.hairline,
                            ),
                          ),
                          itemBuilder: (context, index) {
                            final contact = members[index];
                            return SelectableContactRow(
                              name: contact.displayName,
                              detail: contact.phones.firstOrNull?.number ??
                                  'No phone number',
                              selected: selectedContacts.contains(contact),
                              onChanged: (value) =>
                                  _toggleContact(contact, value),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // The composer's card runs under the home indicator; SafeArea
            // keeps its content above it (and collapses with the keyboard).
            ColoredBox(
              color: surfaces.card,
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MessageComposer(
                      controller: _messageController,
                      focusNode: _textFieldFocusNode,
                      trayOpen: _showActionButtons || _showVariablesList,
                      onToggleTray: _toggleActionButtons,
                      media: _selectedMedia,
                      onRemoveMedia: (index) =>
                          setState(() => _selectedMedia.removeAt(index)),
                      recipientCount: selectedContacts.length,
                      onSend: canSend ? _sendMessages : null,
                    ),
                    _buildAccessorySlot(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _blastFeature.removeListener(_onBlastFeatureChanged);
    _messageController.dispose();
    _textFieldFocusNode.dispose();
    super.dispose();
  }
}
