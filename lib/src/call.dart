import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:webrtc3/src/remotes.dart';
import 'package:webrtc3/src/signaling.dart';

class Calls extends StatefulWidget {
  const Calls({Key? key, this.caller, this.callee}) : super(key: key);

  final String? caller;
  final String? callee;

  @override
  _CallsState createState() => _CallsState();
}

class _CallsState extends State<Calls> {
  bool _inCalling = false;
  bool _caller = false;
  Signaling signaling = Signaling();
  Remotes remotes = Remotes();
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  TextEditingController textEditingController = TextEditingController(text: '');

  @override
  void initState() {
    super.initState();
    initRenders();

    signaling.onAddRemoteStream = ((stream) {
      _remoteRenderer.srcObject = stream;
      setState(() {});
    });
    signaling.openUserMedia(_localRenderer, _remoteRenderer);
  }

  @override
  deactivate() {
    super.deactivate();
    _disposeRenderers();
  }

  void _disposeRenderers() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
  }

  void initRenders() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }

  @override
  Widget build(BuildContext context) {
    var widgets = <Widget>[
      Expanded(
        child: _caller
            ? RTCVideoView(_localRenderer)
            : RTCVideoView(
                _localRenderer,
                mirror: true,
              ),
      ),
      Expanded(
        child: _caller
            ? RTCVideoView(_remoteRenderer, mirror: true)
            : RTCVideoView(_remoteRenderer),
      )
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('WebRTC'),
        actions: [
          IconButton(
              onPressed: () {
                signaling.joinRoom(
                    _remoteRenderer, widget.callee!, widget.caller!);
                _inCalling = true;
                setState(() {});
              },
              icon: const Icon(Icons.call))
        ],
      ),
      body: OrientationBuilder(
        builder: (context, orientation) {
          return Center(
            child: Container(
              decoration: const BoxDecoration(color: Colors.black54),
              child: orientation == Orientation.portrait
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: widgets)
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: widgets),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: _inCalling ? Colors.red : Colors.green,
        onPressed: () async {
          if (_inCalling) {
            signaling.hangUp(_localRenderer);
            Navigator.pop(context);
            _inCalling = false;
          } else {
            signaling.createRoom(
                _remoteRenderer, widget.callee!, widget.caller!);
            remotes.addLoginCallerToCallee(widget.callee!, widget.caller!);
            _caller = true;
            _inCalling = true;
            setState(() {});
          }
        },
        child: _inCalling
            ? const Icon(
                Icons.call_end,
              )
            : const Icon(
                Icons.call,
              ),
      ),
    );
  }
}
