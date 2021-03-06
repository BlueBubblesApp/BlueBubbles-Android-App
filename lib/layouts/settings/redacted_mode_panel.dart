import 'dart:ui';

import 'package:bluebubbles/helpers/constants.dart';
import 'package:bluebubbles/layouts/settings/settings_panel.dart';
import 'package:bluebubbles/layouts/widgets/theme_switcher/theme_switcher.dart';
import 'package:bluebubbles/managers/event_dispatcher.dart';
import 'package:bluebubbles/managers/settings_manager.dart';
import 'package:bluebubbles/repository/models/settings.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RedactedModePanel extends StatefulWidget {
  RedactedModePanel({Key key}) : super(key: key);

  @override
  _RedactedModePanelState createState() => _RedactedModePanelState();
}

class _RedactedModePanelState extends State<RedactedModePanel> {
  Settings _settingsCopy;
  Brightness brightness;
  Color previousBackgroundColor;
  bool gotBrightness = false;
  bool redactedMode = false;

  @override
  void initState() {
    super.initState();
    _settingsCopy = SettingsManager().settings;
    redactedMode = _settingsCopy.redactedMode;

    // Listen for any incoming events
    EventDispatcher().stream.listen((Map<String, dynamic> event) {
      if (!event.containsKey("type")) return;

      if (event["type"] == 'theme-update' && this.mounted) {
        setState(() {
          gotBrightness = false;
        });
      }
    });
  }

  void loadBrightness() {
    Color now = Theme.of(context).backgroundColor;
    bool themeChanged = previousBackgroundColor == null || previousBackgroundColor != now;
    if (!themeChanged && gotBrightness) return;

    previousBackgroundColor = now;
    if (this.context == null) {
      brightness = Brightness.light;
      gotBrightness = true;
      return;
    }

    bool isDark = now.computeLuminance() < 0.179;
    brightness = isDark ? Brightness.dark : Brightness.light;
    gotBrightness = true;
    if (this.mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    loadBrightness();

    List<Widget> redactedWidgets = [];
    if (redactedMode) {
      redactedWidgets.addAll([
        SettingsSwitch(
          onChanged: (bool val) {
            _settingsCopy.hideMessageContent = val;
            saveSettings();
          },
          initialVal: _settingsCopy.hideMessageContent,
          title: "Hide Message Content",
        ),
        Divider(),
        SettingsSwitch(
          onChanged: (bool val) {
            _settingsCopy.hideReactions = val;
            saveSettings();
          },
          initialVal: _settingsCopy.hideReactions,
          title: "Hide Reactions",
        ),
        SettingsSwitch(
          onChanged: (bool val) {
            _settingsCopy.hideAttachments = val;
            saveSettings();
          },
          initialVal: _settingsCopy.hideAttachments,
          title: "Hide Attachments",
        ),
        SettingsSwitch(
          onChanged: (bool val) {
            _settingsCopy.hideAttachmentTypes = val;
            saveSettings();
          },
          initialVal: _settingsCopy.hideAttachmentTypes,
          title: "Hide Attachment Types",
        ),
        Divider(),
        SettingsSwitch(
          onChanged: (bool val) {
            _settingsCopy.hideContactPhotos = val;
            saveSettings();
          },
          initialVal: _settingsCopy.hideContactPhotos,
          title: "Hide Contact Photos",
        ),
        SettingsSwitch(
          onChanged: (bool val) {
            _settingsCopy.hideContactInfo = val;
            saveSettings();
          },
          initialVal: _settingsCopy.hideContactInfo,
          title: "Hide Contact Info",
        ),
        SettingsSwitch(
          onChanged: (bool val) {
            _settingsCopy.removeLetterAvatars = val;
            saveSettings();
          },
          initialVal: _settingsCopy.removeLetterAvatars,
          title: "Remove Letter Avatars",
        ),
        Divider(),
        SettingsSwitch(
          onChanged: (bool val) {
            _settingsCopy.generateFakeContactNames = val;
            saveSettings();
          },
          initialVal: _settingsCopy.generateFakeContactNames,
          title: "Generate Fake Contact Names",
        ),
        SettingsSwitch(
          onChanged: (bool val) {
            _settingsCopy.generateFakeMessageContent = val;
            saveSettings();
          },
          initialVal: _settingsCopy.generateFakeMessageContent,
          title: "Generate Fake Message Content",
        ),
      ]);
    }

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        systemNavigationBarColor: Theme.of(context).backgroundColor,
      ),
      child: Scaffold(
        backgroundColor: Theme.of(context).backgroundColor,
        appBar: PreferredSize(
          preferredSize: Size(MediaQuery.of(context).size.width, 80),
          child: ClipRRect(
            child: BackdropFilter(
              child: AppBar(
                brightness: brightness,
                toolbarHeight: 100.0,
                elevation: 0,
                leading: IconButton(
                  icon: Icon(SettingsManager().settings.skin == Skins.IOS ? Icons.arrow_back_ios : Icons.arrow_back,
                      color: Theme.of(context).primaryColor),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                backgroundColor: Theme.of(context).accentColor.withOpacity(0.5),
                title: Text(
                  "Redacted Mode Settings",
                  style: Theme.of(context).textTheme.headline1,
                ),
              ),
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            ),
          ),
        ),
        body: CustomScrollView(
          physics: ThemeSwitcher.getScrollPhysics(),
          slivers: <Widget>[
            SliverList(
              delegate: SliverChildListDelegate(
                <Widget>[
                  Container(padding: EdgeInsets.only(top: 5.0)),
                  SettingsTile(
                      title: "What is Redacted Mode?",
                      subTitle:
                          ("Redacted Mode hides your personal information such as contact names, message content, and more. This is useful when taking screenshots to send to developers.")),
                  SettingsSwitch(
                    onChanged: (bool val) {
                      _settingsCopy.redactedMode = val;
                      if (this.mounted) {
                        setState(() {
                          redactedMode = val;
                        });
                      }

                      saveSettings();
                    },
                    initialVal: _settingsCopy.redactedMode,
                    title: "Enable Redacted Mode",
                  ),
                  ...redactedWidgets
                ],
              ),
            ),
            SliverList(
              delegate: SliverChildListDelegate(
                <Widget>[],
              ),
            )
          ],
        ),
      ),
    );
  }

  void saveSettings() {
    SettingsManager().saveSettings(_settingsCopy);
  }

  @override
  void dispose() {
    saveSettings();
    super.dispose();
  }
}
