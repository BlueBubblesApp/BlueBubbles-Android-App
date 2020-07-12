import 'dart:io';

import 'package:bluebubble_messages/helpers/utils.dart';
import 'package:bluebubble_messages/managers/method_channel_interface.dart';
import 'package:bluebubble_messages/managers/settings_manager.dart';
import 'package:bluebubble_messages/repository/models/attachment.dart';
import 'package:bluebubble_messages/repository/models/message.dart';
import 'package:bluebubble_messages/socket_manager.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:metadata_fetch/metadata_fetch.dart';

class UrlPreviewWidget extends StatefulWidget {
  UrlPreviewWidget({
    Key key,
    @required this.linkPreviews,
    @required this.message,
    @required this.onFinish,
    this.existingMetaData,
  }) : super(key: key);
  final List<Attachment> linkPreviews;
  final Message message;
  final Function(Metadata) onFinish;
  final Metadata existingMetaData;

  @override
  _UrlPreviewWidgetState createState() => _UrlPreviewWidgetState();
}

class _UrlPreviewWidgetState extends State<UrlPreviewWidget>
    with AutomaticKeepAliveClientMixin {
  bool isFetching = true;
  Metadata data;
  String url;

  @override
  void initState() {
    super.initState();
    if (widget.existingMetaData != null) data = widget.existingMetaData;
    for (Attachment preview in widget.linkPreviews) {
      if (SocketManager().attachmentSenders.containsKey(preview.guid)) {}
    }
  }

  bool attachmentSaved(Attachment attachment) {
    String appDocPath = SettingsManager().appDocDir.path;
    String pathName =
        "$appDocPath/attachments/${attachment.guid}/${attachment.transferName}";
    if (FileSystemEntity.typeSync(pathName) == FileSystemEntityType.notFound) {
      return false;
    } else {
      return true;
    }
  }

  File attachmentFile(Attachment attachment) {
    String appDocPath = SettingsManager().appDocDir.path;
    String pathName =
        "$appDocPath/attachments/${attachment.guid}/${attachment.transferName}";
    return File(pathName);
  }

  @override
  void didChangeDependencies() async {
    super.didChangeDependencies();
    if (data == null && !isEmptyString(widget.message.text)) {
      url = widget.message.text;

      if (!widget.message.text.startsWith("http://") &&
          !widget.message.text.startsWith("https://")) {
        url = "http://" + widget.message.text;
      }
      data = await extract(url);
      widget.onFinish(data);
      if (this.mounted)
        setState(() {
          isFetching = false;
          // isFetching = !checkIfImagesAreSaved();
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (isEmptyString(widget.message.text) || data == null) return Container();
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Theme.of(context).accentColor,
          child: InkResponse(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              MethodChannelInterface().invokeMethod("open-link", {"link": url});
            },
            child: Container(
              width: MediaQuery.of(context).size.width * 2 / 3,
              child: Column(
                children: <Widget>[
                  widget.linkPreviews.length > 1
                      ? attachmentSaved(widget.linkPreviews.last)
                          ? Image.file(
                              attachmentFile(widget.linkPreviews.last),
                            )
                          : CupertinoActivityIndicator(
                              animating: true,
                            )
                      : Container(),
                  Padding(
                    padding: EdgeInsets.all(14.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        data != null
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  data != null
                                      ? Padding(
                                          padding: const EdgeInsets.only(
                                            bottom: 8.0,
                                          ),
                                          child: Text(
                                            data.title,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyText1
                                                .apply(fontWeightDelta: 2),
                                          ),
                                        )
                                      : Container(),
                                  data != null && data.description != null
                                      ? Container(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              4 /
                                              9,
                                          child: Text(
                                            data.description,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodyText1
                                                .apply(fontSizeDelta: -5),
                                          ),
                                        )
                                      : Container(),
                                ],
                              )
                            : Container(),
                        attachmentSaved(widget.linkPreviews.first)
                            ? Image.file(
                                attachmentFile(widget.linkPreviews.first),
                                width: 40,
                                fit: BoxFit.contain,
                              )
                            : CupertinoActivityIndicator(
                                animating: true,
                              )
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}