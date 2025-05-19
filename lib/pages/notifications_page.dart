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
    print('👤 Current userId: $userId');
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
            .orderBy('reply')
            .orderBy('replyTimestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator(color: primaryColor));
          final docs = snapshot.data!.docs;

          print('✅ Notifications reçues : ${docs.length}');
          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            print('🧪 Doc ID: ${doc.id}');
            print('↳ userId: ${data['userId']}');
            print('↳ reply: ${data['reply']}');
            print('↳ replyTimestamp: ${data['replyTimestamp']}');
            print('↳ isReplyRead: ${data['isReplyRead']}');
          }

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
                  title: Text("Votre commentaire : ${data['comment']}",
                      style: TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: Text("Réponse du formateur : ${data['reply']}"),
                  trailing: data['isReplyRead'] == true
                      ? Icon(Icons.check_circle, color: Colors.green)
                      : Icon(Icons.markunread, color: Colors.red),
                    onTap: () async {
                      if (data['isReplyRead'] == false) {
                        await docs[index].reference.update({'isReplyRead': true});

                        // Mise à jour locale pour forcer le changement visuel immédiat
                        setState(() {
                          data['isReplyRead'] = true;
                        });
                      }
                    }
                ),
              );
            },
          );
        },
      ),
    );
  }
}
