import 'package:bluebubbles/helpers/hex_color.dart';
import 'package:bluebubbles/helpers/utils.dart';
import 'package:bluebubbles/managers/contact_manager.dart';
import 'package:bluebubbles/managers/method_channel_interface.dart';
import 'package:bluebubbles/managers/settings_manager.dart';
import 'package:bluebubbles/repository/models/message.dart';
import 'package:faker/faker.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

// Mixin just for commonly shared functions and properties between the SentMessage and ReceivedMessage
abstract class MessageWidgetMixin {
  String contactTitle = "";
  bool hasHyperlinks = false;
  static const double MAX_SIZE = 3 / 5;

  Future<void> initMessageState(Message message, bool showHandle) async {
    this.hasHyperlinks = parseLinks(message.text).isNotEmpty;
    await getContactTitle(message, showHandle);
  }

  Future<void> getContactTitle(Message message, bool showHandle) async {
    if (message.handle == null || !showHandle) return;

    String title = await ContactManager().getContactTitle(message.handle);

    if (title != contactTitle) {
      contactTitle = title;
    }
  }

  /// Adds reacts to a [message] widget
  Widget addReactionsToWidget(
      {@required Widget messageWidget, @required Widget reactions, @required Message message, bool shouldShow = true}) {
    if (!shouldShow) return messageWidget;

    return Stack(
      alignment: message.isFromMe ? AlignmentDirectional.topStart : AlignmentDirectional.topEnd,
      children: [
        messageWidget,
        reactions,
      ],
    );
  }

  /// Adds reacts to a [message] widget
  Widget addStickersToWidget({@required Widget message, @required Widget stickers, @required bool isFromMe}) {
    return Stack(
      alignment: (isFromMe) ? AlignmentDirectional.bottomEnd : AlignmentDirectional.bottomStart,
      children: [
        message,
        stickers,
      ],
    );
  }

  static List<InlineSpan> buildMessageSpans(BuildContext context, Message message, {List<Color> colors: const []}) {
    List<InlineSpan> textSpans = <InlineSpan>[];

    final bool generateContent =
        SettingsManager().settings.redactedMode && SettingsManager().settings.generateFakeMessageContent;
    final bool hideContent =
        SettingsManager().settings.redactedMode && SettingsManager().settings.hideMessageContent && !generateContent;

    if (message != null && !isEmptyString(message.text)) {
      RegExp exp = new RegExp(
          r'((https?://)|(www\.))[-a-zA-Z0-9@:%._+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}([-a-zA-Z0-9/()@:%_.~#?&=*\[\]]*)\b');
      List<RegExpMatch> matches = exp.allMatches(message.text).toList();

      List<int> linkIndexMatches = <int>[];
      matches.forEach((match) {
        linkIndexMatches.add(match.start);
        linkIndexMatches.add(match.end);
      });

      TextStyle textStyle = Theme.of(context).textTheme.bodyText2;
      if (!message.isFromMe) {
        if (SettingsManager().settings.colorfulBubbles) {
          if (!isNullOrEmpty(colors)) {
            bool dark = colors[0].computeLuminance() < 0.179;
            if (!dark) {
              textStyle = Theme.of(context)
                  .textTheme
                  .bodyText2
                  .apply(color: hideContent ? Colors.transparent : darken(colors[0], 0.35));
            } else {
              textStyle = Theme.of(context).textTheme.bodyText2;
              if (hideContent) textStyle = textStyle.apply(color: Colors.transparent);
            }
          } else {
            textStyle = Theme.of(context).textTheme.bodyText2.apply(
                color: hideContent
                    ? Colors.transparent
                    : darken(toColorGradient(message?.handle?.address ?? "")[0], 0.35));
          }
        } else if (hideContent) textStyle = textStyle.apply(color: Colors.transparent);
      } else {
        textStyle = textStyle.apply(color: hideContent ? Colors.transparent : Colors.white);
      }

      if (!isNullOrEmpty(message.subject)) {
        TextStyle _textStyle = message.isFromMe
            ? textStyle.apply(color: Colors.white, fontWeightDelta: 2)
            : textStyle.apply(fontWeightDelta: 2);
        if (hideContent) {
          _textStyle = _textStyle.apply(color: Colors.transparent);
        }
        textSpans.add(
          TextSpan(
            text: "${message.subject}\n",
            style: _textStyle,
          ),
        );
      }

      if (linkIndexMatches.length > 0) {
        for (int i = 0; i < linkIndexMatches.length + 1; i++) {
          if (i == 0) {
            textSpans.add(
              TextSpan(
                text: message.text.substring(0, linkIndexMatches[i]),
                style: textStyle,
              ),
            );
          } else if (i == linkIndexMatches.length && i - 1 >= 0) {
            textSpans.add(
              TextSpan(
                text: message.text.substring(linkIndexMatches[i - 1], message.text.length),
                style: textStyle,
              ),
            );
          } else if (i - 1 >= 0) {
            String text = message.text.substring(linkIndexMatches[i - 1], linkIndexMatches[i]);
            if (exp.hasMatch(text)) {
              textSpans.add(
                TextSpan(
                  text: text,
                  recognizer: new TapGestureRecognizer()
                    ..onTap = () async {
                      String url = text;
                      if (!url.startsWith("http://") && !url.startsWith("https://")) {
                        url = "http://" + url;
                      }

                      MethodChannelInterface().invokeMethod("open-link", {"link": url});
                    },
                  style: textStyle.apply(decoration: TextDecoration.underline),
                ),
              );
            } else {
              textSpans.add(
                TextSpan(
                  text: text,
                  style: textStyle,
                ),
              );
            }
          }
        }
      } else {
        textSpans.add(
          TextSpan(
            text: message.text,
            style: textStyle,
          ),
        );
      }

      if (generateContent) {
        String generatedText = faker.lorem.words(message.text.split(" ").length).join(" ");
        return [TextSpan(text: generatedText, style: textStyle)];
      }
    }

    return textSpans;
  }
}
