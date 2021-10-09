import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

typedef StreamStateCallback = void Function(MediaStream stream);

class Signaling {
  Map<String, dynamic> configuration = {
    'iceServers': [
      {
        'urls': [
          'stun:stun1.l.google.com:19302',
          'stun:stun2.l.google.com:19302'
        ]
      }
    ]
  };

  RTCPeerConnection? peerConnection;
  MediaStream? localStream;
  MediaStream? remoteStream;
  String? roomId;
  StreamStateCallback? onAddRemoteStream;

  Future<void> addRoomIdToCallee(
      String callee, String caller, String rid) async {
    Map<String, dynamic> data = <String, dynamic>{
      "roomId": rid,
    };
    FirebaseFirestore db = FirebaseFirestore.instance;
    db
        .collection('users')
        .doc(callee)
        .collection('calls')
        .doc(caller)
        .collection('rooms')
        .doc(rid)
        .set(data);
  }

  Future<String> getRoomId(String callee, String caller) async {
    var rid = FirebaseFirestore.instance
        .collection('users')
        .doc(caller)
        .collection('calls')
        .doc(callee)
        .collection('rooms')
        .get()
        .then((querySnapshot) {
      return querySnapshot.docs.elementAt(0).id;
    });
    return (rid);
  }

  Future<String> createRoom(
      RTCVideoRenderer remoteRenderer, String callee, String userId) async {
    FirebaseFirestore db = FirebaseFirestore.instance;
    DocumentReference roomRef =
        db.collection('users').doc(userId).collection('rooms').doc();

    var rid = roomRef.id;
    addRoomIdToCallee(callee, userId, rid);

    // DocumentReference roomRefCallee = db
    //     .collection('users')
    //     .doc(callee)
    //     .collection('calls')
    //     .doc(userId)
    //     .collection('rooms')
    //     .doc(rid);

    peerConnection = await createPeerConnection(configuration);

    registerPeerConnectionListeners();

    localStream?.getTracks().forEach((track) {
      peerConnection?.addTrack(track, localStream!);
    });

    var callerCandidatesCollection = roomRef.collection('callerCandidates');

    peerConnection?.onIceCandidate = (RTCIceCandidate candidate) {
      callerCandidatesCollection.add(candidate.toMap());
    };

    RTCSessionDescription offer = await peerConnection!.createOffer();
    await peerConnection!.setLocalDescription(offer);

    Map<String, dynamic> roomWithOffer = {'offer': offer.toMap()};

    await roomRef.set(roomWithOffer);
    //await roomRefCallee.set(roomWithOffer);
    //addRoomIdToCallee(callee, userId, rid);

    peerConnection?.onTrack = (RTCTrackEvent event) {
      event.streams[0].getTracks().forEach((track) {
        remoteStream?.addTrack(track);
      });
    };

    roomRef.snapshots().listen((snapshot) async {
      Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
      if (peerConnection?.getRemoteDescription() != null &&
          data['answer'] != null) {
        var answer = RTCSessionDescription(
          data['answer']['sdp'],
          data['answer']['type'],
        );

        await peerConnection?.setRemoteDescription(answer);
      }
    });

    // roomRefCallee.snapshots().listen((snapshot) async {
    //   Map<String, dynamic> data = snapshot.data() as Map<String, dynamic>;
    //   if (peerConnection?.getRemoteDescription() != null &&
    //       data['answer'] != null) {
    //     var answer = RTCSessionDescription(
    //       data['answer']['sdp'],
    //       data['answer']['type'],
    //     );

    //     await peerConnection?.setRemoteDescription(answer);
    //   }
    // });

    roomRef.collection('calleeCandidates').snapshots().listen((snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          Map<String, dynamic> data = change.doc.data() as Map<String, dynamic>;
          peerConnection!.addCandidate(
            RTCIceCandidate(
              data['candidate'],
              data['sdpMid'],
              data['sdpMLineIndex'],
            ),
          );
        }
      }
    });

    // roomRefCallee.collection('calleeCandidates').snapshots().listen((snapshot) {
    //   for (var change in snapshot.docChanges) {
    //     if (change.type == DocumentChangeType.added) {
    //       Map<String, dynamic> data = change.doc.data() as Map<String, dynamic>;
    //       peerConnection!.addCandidate(
    //         RTCIceCandidate(
    //           data['candidate'],
    //           data['sdpMid'],
    //           data['sdpMLineIndex'],
    //         ),
    //       );
    //     }
    //   }
    // });

    return rid;
  }

  Future<void> joinRoom(
      RTCVideoRenderer remoteVideo, String userId, String caller) async {
    FirebaseFirestore db = FirebaseFirestore.instance;

    var rid = await getRoomId(userId, caller);

    DocumentReference roomRef =
        db.collection('users').doc(userId).collection('rooms').doc(rid);
    var roomSnapshot = await roomRef.get();

    if (roomSnapshot.exists) {
      peerConnection = await createPeerConnection(configuration);

      registerPeerConnectionListeners();

      localStream?.getTracks().forEach((track) {
        peerConnection?.addTrack(track, localStream!);
      });

      var calleeCandidatesCollection = roomRef.collection('calleeCandidates');
      peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
        calleeCandidatesCollection.add(candidate.toMap());
      };

      peerConnection?.onTrack = (RTCTrackEvent event) {
        event.streams[0].getTracks().forEach((track) {
          remoteStream?.addTrack(track);
        });
      };

      var data = roomSnapshot.data() as Map<String, dynamic>;
      var offer = data['offer'];
      await peerConnection?.setRemoteDescription(
        RTCSessionDescription(offer['sdp'], offer['type']),
      );
      var answer = await peerConnection!.createAnswer();

      await peerConnection!.setLocalDescription(answer);

      Map<String, dynamic> roomWithAnswer = {
        'answer': {'type': answer.type, 'sdp': answer.sdp}
      };

      await roomRef.update(roomWithAnswer);

      roomRef.collection('callerCandidates').snapshots().listen((snapshot) {
        for (var document in snapshot.docChanges) {
          var data = document.doc.data() as Map<String, dynamic>;
          peerConnection!.addCandidate(
            RTCIceCandidate(
              data['candidate'],
              data['sdpMid'],
              data['sdpMLineIndex'],
            ),
          );
        }
      });
    }
  }

  Future<void> openUserMedia(
    RTCVideoRenderer localVideo,
    RTCVideoRenderer remoteVideo,
  ) async {
    var stream = await navigator.mediaDevices
        .getUserMedia({'video': true, 'audio': false});

    localVideo.srcObject = stream;
    localStream = stream;

    remoteVideo.srcObject = await createLocalMediaStream('key');
  }

  Future<void> hangUp(RTCVideoRenderer localVideo) async {
    List<MediaStreamTrack> tracks = localVideo.srcObject!.getTracks();
    for (var track in tracks) {
      track.stop();
    }

    if (remoteStream != null) {
      remoteStream!.getTracks().forEach((track) => track.stop());
    }
    if (peerConnection != null) peerConnection!.close();

    if (roomId != null) {
      var db = FirebaseFirestore.instance;
      var roomRef = db.collection('rooms').doc(roomId);
      var calleeCandidates = await roomRef.collection('calleeCandidates').get();
      for (var document in calleeCandidates.docs) {
        document.reference.delete();
      }

      var callerCandidates = await roomRef.collection('callerCandidates').get();
      for (var document in callerCandidates.docs) {
        document.reference.delete();
      }

      await roomRef.delete();
    }

    localStream!.dispose();
    remoteStream?.dispose();
  }

  void registerPeerConnectionListeners() {
    peerConnection?.onIceGatheringState = (RTCIceGatheringState state) {};

    peerConnection?.onConnectionState = (RTCPeerConnectionState state) {};

    peerConnection?.onSignalingState = (RTCSignalingState state) {};

    peerConnection?.onIceGatheringState = (RTCIceGatheringState state) {};

    peerConnection?.onAddStream = (MediaStream stream) {
      onAddRemoteStream?.call(stream);
      remoteStream = stream;
    };
  }
}
