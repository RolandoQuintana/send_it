import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/message_group.dart';
import '../services/group_storage.dart';
import '../services/shortcut_service.dart';
import 'edit_group_screen.dart';
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
  static const platform = MethodChannel('com.sendit/messages');
  late List<Contact> selectedContacts;
  List<File> _selectedMedia = [];
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
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Error'),
          content: Text('Error picking media: $e'),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _sendMessages() async {
    if (_messageController.text.isEmpty && _selectedMedia.isEmpty) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Error'),
          content: const Text('Please enter a message or select media'),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
      return;
    }

    if (selectedContacts.isEmpty) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('Error'),
          content: const Text('Please select at least one recipient'),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
      return;
    }

    for (final contact in selectedContacts) {
      final phoneNumber = contact.phones.firstOrNull?.number;
      if (phoneNumber == null) continue;

      // Clean up phone number format
      final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');

      final personalizedMessage = ShortcutService.personalizeMessage(_messageController.text, contact);

      try {
        // Create fresh copies of media files for each message to avoid conflicts
        // Only needed when there are attachments
        final List<String> freshMediaPaths = [];
        if (_selectedMedia.isNotEmpty) {
          for (final mediaFile in _selectedMedia) {
            if (await mediaFile.exists()) {
              final freshFile = File('${mediaFile.parent.path}/fresh_${DateTime.now().millisecondsSinceEpoch}_${mediaFile.uri.pathSegments.last}');
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
        if (selectedContacts.indexOf(contact) > 0 && _selectedMedia.isNotEmpty) {
          await Future.delayed(const Duration(milliseconds: 800));
        }

        final result = await platform.invokeMethod('sendMessage', args);

        if (result == "sent") {
          // Message was sent successfully, continue to next contact
          continue;
        } else if (result == "cancelled") {
          // User cancelled, ask if they want to continue with remaining messages
          final remainingCount = selectedContacts.length - selectedContacts.indexOf(contact) - 1;
          if (remainingCount > 0) {
            final shouldContinue = await showCupertinoDialog<bool>(
              context: context,
              builder: (context) => CupertinoAlertDialog(
                title: const Text('Message Cancelled'),
                content: Text('Do you want to continue sending to the remaining $remainingCount recipients?'),
                actions: [
                  CupertinoDialogAction(
                    isDestructiveAction: true,
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Stop'),
                  ),
                  CupertinoDialogAction(
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
        print('Platform Exception: ${e.code} - ${e.message}');
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text('Error: ${e.message}'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      } catch (e) {
        print('Error: $e');
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Error'),
            content: Text('An unexpected error occurred: $e'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
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
        final freshFiles = tempDir.listSync().where((entity) =>
          entity is File && entity.path.contains('fresh_')
        );
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
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('No Message'),
          content: const Text('Please enter a message before sending via Blast.'),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );
      return;
    }

    if (selectedContacts.isEmpty) {
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('No Recipients'),
          content: const Text('Please select at least one contact.'),
          actions: [
            CupertinoDialogAction(
              child: const Text('OK'),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
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
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Send via Blast?'),
        content: Text(
          'This will automatically send a message to all '
          '${selectedContacts.length} selected contact${selectedContacts.length == 1 ? '' : 's'} '
          'with no confirmation per person.'
          '${hasExtraMedia ? '\n\nOnly the first attachment will be included — Blast supports 1 media file at a time.' : ''}',
        ),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context, false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Send'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

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
        showCupertinoDialog(
          context: context,
          barrierDismissible: true,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Blast Launched'),
            content: const Text(
              'Your messages are being sent via Blast. '
              'The Shortcuts app may ask for permission the first time.',
            ),
            actions: [
              CupertinoDialogAction(
                isDefaultAction: true,
                child: const Text('Got it'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      case ShortcutLaunchResult.notInstalled:
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('Blast Not Installed'),
            content: const Text(
              'Blast isn\'t set up yet. '
              'Go to More → Install Shortcut to get started.',
            ),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      case ShortcutLaunchResult.noValidContacts:
        showCupertinoDialog(
          context: context,
          builder: (context) => CupertinoAlertDialog(
            title: const Text('No Valid Numbers'),
            content: const Text('None of the selected contacts have a valid phone number.'),
            actions: [
              CupertinoDialogAction(
                child: const Text('OK'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
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
    final confirmed = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Delete Group'),
        content: const Text('Are you sure you want to delete this group?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('Cancel'),
            onPressed: () => Navigator.pop(context, false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
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

    // Insert the variable at the current cursor position
    final newText = currentText.replaceRange(
      selection.start,
      selection.end,
      variable,
    );

    _messageController.text = newText;

    // Move cursor to after the inserted variable
    final newCursorPosition = selection.start + variable.length;
    _messageController.selection = TextSelection.collapsed(offset: newCursorPosition);
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

  Widget _buildActionButtons() {
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.black,
        border: Border(
          top: BorderSide(color: CupertinoColors.systemGrey4, width: 0.5),
          bottom: BorderSide(color: CupertinoColors.systemGrey4, width: 0.5),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            _buildActionButton(
              icon: CupertinoIcons.photo,
              label: 'Gallery',
              onTap: () {
                setState(() {
                  _showActionButtons = false;
                });
                _pickMedia();
              },
            ),
            const SizedBox(width: 16),
            _buildActionButton(
              icon: CupertinoIcons.textformat_abc,
              label: 'Variables',
              onTap: () {
                setState(() {
                  _showActionButtons = false;
                  _showVariablesList = true;
                });
              },
            ),
            const SizedBox(width: 16),
            _buildActionButton(
              icon: CupertinoIcons.bolt_fill,
              label: 'Blast',
              onTap: _sendViaShortcut,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVariablesList() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 220),
      child: Container(
        decoration: BoxDecoration(
          color: CupertinoColors.black,
          border: Border(
            top: BorderSide(color: CupertinoColors.systemGrey4, width: 0.5),
            bottom: BorderSide(color: CupertinoColors.systemGrey4, width: 0.5),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 59, 59, 59),
                border: Border(
                  bottom: BorderSide(color: CupertinoColors.systemGrey4, width: 0.5),
                ),
              ),
              child: Row(
                children: [
                  CupertinoButton(
                    padding: EdgeInsets.zero,
                    child: const Icon(
                      CupertinoIcons.back,
                      color: Color(0xFF0fa0ab),
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _showVariablesList = false;
                        _showActionButtons = true;
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Variables',
                    style: TextStyle(
                      color: CupertinoColors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    _buildVariableItem(
                      variable: '{firstname}',
                      description: 'First name',
                      example: 'John',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccessorySlot() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      child: _showVariablesList
          ? _buildVariablesList()
          : _showActionButtons
              ? _buildActionButtons()
              : const SizedBox.shrink(),
    );
  }

  Widget _buildUnifiedBottomPanel() {
    return SafeArea(
      bottom: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: CupertinoColors.black,
              border: Border(
                top: BorderSide(
                  color: CupertinoColors.systemGrey4,
                  width: 0.5,
                ),
              ),
            ),
            child: Column(
              children: [
                if (_selectedMedia.isNotEmpty)
                  Container(
                    height: 100,
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _selectedMedia.length,
                      itemBuilder: (context, index) {
                        return Container(
                          width: 100,
                          margin: const EdgeInsets.only(right: 8),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  _selectedMedia[index],
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: CupertinoButton(
                                  padding: EdgeInsets.zero,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: CupertinoColors.black.withOpacity(0.5),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      CupertinoIcons.xmark,
                                      color: CupertinoColors.white,
                                      size: 16,
                                    ),
                                  ),
                                  onPressed: () {
                                    setState(() {
                                      _selectedMedia.removeAt(index);
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                Row(
                  children: [
                    CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: Icon(
                        (_showActionButtons || _showVariablesList) ? CupertinoIcons.minus : CupertinoIcons.add,
                        color: (_showActionButtons || _showVariablesList) ? const Color(0xFF0fa0ab) : CupertinoColors.systemGrey,
                      ),
                      onPressed: _toggleActionButtons,
                    ),
                    Expanded(
                      child: CupertinoTextField(
                        controller: _messageController,
                        focusNode: _textFieldFocusNode,
                        placeholder: 'Enter your message',
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.newline,
                        onTap: () {
                          // Do not collapse menus; let the keyboard overlay them
                        },
                        decoration: BoxDecoration(
                          border: Border.all(color: CupertinoColors.systemGrey4),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 8.0),
                      child: Stack(
                        children: [
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            child: Container(
                              width: 45,
                              height: 45,
                              decoration: BoxDecoration(
                                color: (selectedContacts.isNotEmpty && _messageController.text.trim().isNotEmpty)
                                    ? const Color(0xFF0fa0ab)
                                    : CupertinoColors.systemGrey,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Icon(
                                CupertinoIcons.paperplane_fill,
                                color: (selectedContacts.isNotEmpty && _messageController.text.trim().isNotEmpty)
                                    ? CupertinoColors.white
                                    : CupertinoColors.systemGrey2,
                                size: 20,
                              ),
                            ),
                            onPressed: (selectedContacts.isNotEmpty && _messageController.text.trim().isNotEmpty)
                                ? _sendMessages
                                : null,
                          ),
                          if (selectedContacts.isNotEmpty)
                            Positioned(
                              top: 0,
                              left: 0,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: CupertinoColors.systemRed,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: CupertinoColors.black,
                                    width: 1.5,
                                  ),
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 16,
                                  minHeight: 16,
                                ),
                                child: Text(
                                  '${selectedContacts.length}',
                                  style: const TextStyle(
                                    color: CupertinoColors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _buildAccessorySlot(),
        ],
      ),
    );
  }

  Widget _buildVariableItem({
    required String variable,
    required String description,
    required String example,
  }) {
    return GestureDetector(
      onTap: () {
        _insertVariable(variable);
        // Keep the variables list open so user can add more variables
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 41, 41, 41),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: CupertinoColors.systemGrey4),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF0fa0ab),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                variable,
                style: const TextStyle(
                  color: CupertinoColors.white,
                  fontWeight: FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    description,
                    style: const TextStyle(
                      color: CupertinoColors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    'Example: $example',
                    style: const TextStyle(
                      color: CupertinoColors.systemGrey2,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              CupertinoIcons.add_circled,
              color: Color(0xFF0fa0ab),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
    bool disabled = false,
    String? disabledReason,
  }) {
    final iconColor = disabled
        ? CupertinoColors.systemGrey
        : const Color(0xFF0fa0ab);

    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: CupertinoColors.systemGrey6,
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            disabled && disabledReason != null ? disabledReason : label,
            style: TextStyle(
              color: disabled ? CupertinoColors.systemGrey : CupertinoColors.white,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
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

  @override
  Widget build(BuildContext context) {
    final bool allSelected = selectedContacts.length == widget.group.members.length;

    return CupertinoPageScaffold(
      resizeToAvoidBottomInset: true,
      navigationBar: CupertinoNavigationBar(
        middle: Text(widget.group.name),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: Icon(
                allSelected ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.circle,
                color: allSelected ? const Color(0xFF0fa0ab) : CupertinoColors.systemGrey,
              ),
              onPressed: () {
                setState(() {
                  if (allSelected) {
                    selectedContacts.clear();
                  } else {
                    selectedContacts = List.from(widget.group.members);
                  }
                });
              },
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.pencil),
              onPressed: _editGroup,
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.delete),
              onPressed: _deleteGroup,
            ),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: _dismissEverything,
                behavior: HitTestBehavior.opaque,
                child: ListView.builder(
                  itemCount: widget.group.members.length,
                  itemBuilder: (context, index) {
                    final contact = widget.group.members[index];
                    final isSelected = selectedContacts.contains(contact);
                    return CupertinoListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF0fa0ab),
                        child: Text(
                          contact.displayName[0],
                          style: const TextStyle(color: CupertinoColors.white),
                        ),
                      ),
                      title: Text(contact.displayName),
                      subtitle: Text(contact.phones.firstOrNull?.number ?? 'No phone number'),
                      trailing: CupertinoSwitch(
                        value: isSelected,
                        onChanged: (bool value) {
                          setState(() {
                            if (value) {
                              selectedContacts.add(contact);
                            } else {
                              selectedContacts.remove(contact);
                            }
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
            _buildUnifiedBottomPanel(),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _textFieldFocusNode.dispose();
    super.dispose();
  }
}