import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class DraggableFAB extends StatefulWidget {
  final VoidCallback onPressed;
  final Icon icon;

  const DraggableFAB({super.key, required this.onPressed, required this.icon});

  @override
  State<DraggableFAB> createState() => _DraggableFABState();
}

class _DraggableFABState extends State<DraggableFAB> {
  Offset _offset = Offset(300, 600);
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _userId => _auth.currentUser!.uid;

  @override
  void initState() {
    super.initState();
    _loadFABPosition();
  }

  Future<void> _loadFABPosition() async {
    try {
      DocumentSnapshot<Map<String, dynamic>> snapshot =
          await _firestore.collection('fab_positions').doc(_userId).get();

      if (snapshot.exists) {
        setState(() {
          double dx = snapshot.data()?["dx"] ?? 300;
          double dy = snapshot.data()?["dy"] ?? 600;
          _offset = Offset(dx, dy);
        });
      }
    } catch (e) {
      debugPrint("FAB pozisyonu yüklenirken hata oluştu: $e");
    }
  }

  Future<void> _saveFABPosition(Offset offset) async {
    try {
      await _firestore.collection('fab_positions').doc(_userId).set({
        "dx": offset.dx,
        "dy": offset.dy,
      });
    } catch (e) {
      debugPrint("FAB pozisyonu kaydedilirken hata oluştu: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            Positioned(
              left: _offset.dx.clamp(0, constraints.maxWidth - 56),
              top: _offset.dy.clamp(0, constraints.maxHeight - 56),
              child: Draggable(
                feedback: FloatingActionButton(
                  onPressed: widget.onPressed,
                  child: widget.icon,
                ),
                childWhenDragging: Container(),
                onDragEnd: (drag) {
                  final RenderBox renderBox =
                      context.findRenderObject() as RenderBox;
                  final Offset localOffset =
                      renderBox.globalToLocal(drag.offset);

                  setState(() {
                    _offset = Offset(
                        localOffset.dx.clamp(0, constraints.maxWidth - 56),
                        localOffset.dy.clamp(0, constraints.maxHeight - 56));
                  });
                  _saveFABPosition(_offset);
                },
                child: FloatingActionButton(
                  onPressed: widget.onPressed,
                  child: widget.icon,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
