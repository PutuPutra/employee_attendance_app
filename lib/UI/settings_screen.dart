import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../blocs/settings/settings_bloc.dart';
import '../blocs/settings/settings_event.dart';
import '../blocs/settings/settings_state.dart';
import '../core/enums/theme_mode_option.dart';
import '../core/enums/language_option.dart';
import '../core/enums/font_option.dart';
import '../l10n/app_localizations.dart';
import './saved_face_screen.dart';
import './account_settings_screen.dart'; // <-- DIIMPOR

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _biometricLogin = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        title: Text(
          l10n.settings,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          if (state is SettingsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is SettingsError) {
            return Center(
              child: Text(
                state.message,
                style: const TextStyle(color: Colors.red),
              ),
            );
          }

          if (state is SettingsLoaded) {
            final settings = state.settings;

            return ListView(
              children: [
                // =========== BAGIAN AKUN BARU ===========
                _sectionHeader(l10n.account),
                _sectionCard([
                  _iosTile(
                    icon: CupertinoIcons.person_circle,
                    title: l10n.editProfile,
                    subtitle: l10n.editProfileDesc,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AccountSettingsScreen(),
                        ),
                      );
                    },
                  ),
                ]),

                // ========================================
                _sectionHeader(l10n.faceRecognition),
                _sectionCard([
                  _iosTile(
                    icon: CupertinoIcons.person,
                    title: l10n.savedFaces,
                    subtitle: l10n.manageFaceData,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SavedFaceScreen(),
                        ),
                      );
                    },
                  ),
                ]),

                _sectionHeader(l10n.personalization),
                _sectionCard([
                  _iosOptionTile(
                    title: l10n.theme,
                    value: _getThemeDisplayName(settings.themeMode, l10n),
                    onTap: () =>
                        _showThemePicker(context, settings.themeMode, l10n),
                  ),
                  _divider(),
                  _iosOptionTile(
                    title: l10n.language,
                    value: _getLanguageDisplayName(settings.language, l10n),
                    onTap: () =>
                        _showLanguagePicker(context, settings.language, l10n),
                  ),
                  _divider(),
                  _iosOptionTile(
                    title: l10n.font,
                    value: _getFontDisplayName(settings.font, l10n),
                    onTap: () => _showFontPicker(context, settings.font, l10n),
                  ),
                ]),

                _sectionHeader(l10n.security),
                _sectionCard([
                  _iosSwitchTile(
                    title: l10n.biometricLogin,
                    subtitle: l10n.biometricLoginDesc,
                    value: _biometricLogin,
                    onChanged: (v) => setState(() => _biometricLogin = v),
                  ),
                  _divider(),
                  _iosTile(
                    icon: CupertinoIcons.lock,
                    title: l10n.changePassword,
                    onTap: () {},
                  ),
                ]),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  String _getThemeDisplayName(ThemeModeOption theme, AppLocalizations l10n) {
    switch (theme) {
      case ThemeModeOption.system:
        return l10n.themeSystem;
      case ThemeModeOption.light:
        return l10n.themeLight;
      case ThemeModeOption.dark:
        return l10n.themeDark;
    }
  }

  String _getLanguageDisplayName(
    LanguageOption language,
    AppLocalizations l10n,
  ) {
    switch (language) {
      case LanguageOption.system:
        return l10n.languageSystem;
      case LanguageOption.english:
        return l10n.languageEnglish;
      case LanguageOption.indonesian:
        return l10n.languageIndonesian;
    }
  }

  String _getFontDisplayName(FontOption font, AppLocalizations l10n) {
    switch (font) {
      case FontOption.system:
        return l10n.fontSystem;
      case FontOption.poppins:
        return l10n.fontAppDefault;
    }
  }

  void _showThemePicker(
    BuildContext context,
    ThemeModeOption currentTheme,
    AppLocalizations l10n,
  ) {
    final options = [
      (ThemeModeOption.system, l10n.themeSystem),
      (ThemeModeOption.light, l10n.themeLight),
      (ThemeModeOption.dark, l10n.themeDark),
    ];

    showCupertinoModalPopup(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: Text(l10n.theme),
        actions: options
            .map(
              (option) => CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(context);
                  context.read<SettingsBloc>().add(ChangeThemeMode(option.$1));
                },
                child: Text(option.$2),
              ),
            )
            .toList(),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          isDefaultAction: true,
          child: Text(l10n.cancel),
        ),
      ),
    );
  }

  void _showLanguagePicker(
    BuildContext context,
    LanguageOption currentLanguage,
    AppLocalizations l10n,
  ) {
    final options = [
      (LanguageOption.system, l10n.languageSystem),
      (LanguageOption.english, l10n.languageEnglish),
      (LanguageOption.indonesian, l10n.languageIndonesian),
    ];

    showCupertinoModalPopup(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: Text(l10n.language),
        actions: options
            .map(
              (option) => CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(context);
                  context.read<SettingsBloc>().add(ChangeLanguage(option.$1));
                },
                child: Text(option.$2),
              ),
            )
            .toList(),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          isDefaultAction: true,
          child: Text(l10n.cancel),
        ),
      ),
    );
  }

  void _showFontPicker(
    BuildContext context,
    FontOption currentFont,
    AppLocalizations l10n,
  ) {
    final options = [
      (FontOption.system, l10n.fontSystem),
      (FontOption.poppins, l10n.fontAppDefault),
    ];

    showCupertinoModalPopup(
      context: context,
      builder: (_) => CupertinoActionSheet(
        title: Text(l10n.font),
        actions: options
            .map(
              (option) => CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(context);
                  context.read<SettingsBloc>().add(ChangeFont(option.$1));
                },
                child: Text(option.$2),
              ),
            )
            .toList(),
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(context),
          isDefaultAction: true,
          child: Text(l10n.cancel),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          color: CupertinoColors.systemGrey,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _sectionCard(List<Widget> children) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(children: children),
      ),
    );
  }

  Widget _divider() {
    return const Padding(
      padding: EdgeInsets.only(left: 16),
      child: Divider(height: 1),
    );
  }

  Widget _iosTile({
    IconData? icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: icon != null
          ? Icon(icon, color: CupertinoColors.systemGrey)
          : null,
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: const Icon(
        Icons.chevron_right,
        size: 18,
        color: CupertinoColors.systemGrey2,
      ),
      onTap: onTap,
    );
  }

  Widget _iosSwitchTile({
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: CupertinoSwitch(value: value, onChanged: onChanged),
    );
  }

  Widget _iosOptionTile({
    required String title,
    required String value,
    required VoidCallback onTap,
  }) {
    return ListTile(
      title: Text(title),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: const TextStyle(color: CupertinoColors.systemGrey),
          ),
          const SizedBox(width: 6),
          const Icon(
            Icons.chevron_right,
            size: 18,
            color: CupertinoColors.systemGrey2,
          ),
        ],
      ),
      onTap: onTap,
    );
  }
}
