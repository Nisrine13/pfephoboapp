import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({Key? key}) : super(key: key);

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String userId = FirebaseAuth.instance.currentUser!.uid;
  final Color primaryColor = const Color(0xFF30B0C7);
  final Color darkGray = const Color(0xFF757575);
  final Color lightGray = const Color(0xFFEEEEEE);

  @override
  void initState() {
    super.initState();
    _markRepliesAsRead();
  }

  Future<void> _markRepliesAsRead() async {
    final snapshot = await _firestore
        .collectionGroup('comments')
        .where('userId', isEqualTo: userId)
        .where('reply', isGreaterThan: '')
        .where('isReplyRead', isEqualTo: false)
        .get();

    for (final doc in snapshot.docs) {
      await doc.reference.update({'isReplyRead': true});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightGray,
      appBar: AppBar(
        title: Text("Mes Notifications", style: TextStyle(color: Colors.white)),
        backgroundColor: primaryColor,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collectionGroup('comments')
            .where('userId', isEqualTo: userId)
            .where('reply', isGreaterThan: '')
            .orderBy('replyTimestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator(color: primaryColor));
          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return Center(child: Text("Aucune nouvelle réponse pour l’instant.", style: TextStyle(color: darkGray)));
          }

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              return Card(
                margin: EdgeInsets.all(10),
                child: ListTile(
                  leading: Icon(Icons.reply, color: primaryColor),
                  title: Text("Votre commentaire : ${data['comment']}", style: TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: Text("Réponse du formateur : ${data['reply']}"),
                  trailing: Icon(Icons.check_circle, color: Colors.green),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
