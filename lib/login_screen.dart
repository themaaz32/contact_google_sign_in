import 'package:contact_google_sign_in/google_contact_model.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  GoogleSignIn _googleSignIn;
  GoogleSignInAccount _currentUser;
  GoogleContacts contacts;
  bool isLoading = false;

  Future getUserContacts() async {
    final host = "https://people.googleapis.com";
    final endPoint =
        "/v1/people/me/connections?personFields=names,phoneNumbers";
    final header = await _currentUser.authHeaders;

    setState(() {
      isLoading = true;
    });

    print("loading contact");
    final request = await http.get("$host$endPoint", headers: header);
    print("Loading completed");
    setState(() {
      isLoading = false;
    });

    if (request.statusCode == 200) {
      print("Api working perfect");
      setState(() {
        contacts = googleContactsFromJson(request.body);
      });
    } else {
      print("Api got error");
      print(request.body);
    }
  }

  @override
  initState() {
    super.initState();

    _googleSignIn = GoogleSignIn(scopes: [
      "https://www.googleapis.com/auth/contacts.readonly",
    ]);

    _googleSignIn.onCurrentUserChanged.listen((user) {
      setState(() {
        _currentUser = user;
      });

      if (user != null) {
        getUserContacts();
        print(_currentUser.displayName);
      }


    });
  }

  Widget getLoginWidget() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "See contacts saved in your gmail",
          style: TextStyle(fontSize: 24),
        ),
        SizedBox(
          height: 16,
        ),
        FlatButton(
          onPressed: () async {
            try {
              await _googleSignIn.signIn();
            } on Exception catch (e) {
              print(e);
            }
          },
          child: Text("Google Sign in"),
          color: Colors.grey[900],
          textColor: Colors.white,
        )
      ],
    );
  }

  Widget getContactListWidget(context) {
    return ListView.separated(
      itemBuilder: (context, index) {
        final currentContact = contacts.connections[index];
        return ListTile(
          title: Text("${currentContact.names.first.displayName}"),
          onTap: () {
            Scaffold.of(context).showSnackBar(SnackBar(
                content: Text(
                    "Phone number is ${currentContact.phoneNumbers.first.value}")));
          },
        );
      },
      separatorBuilder: (context, index) => Divider(),
      itemCount: contacts.connections.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: _currentUser == null
          ? Container()
          : FloatingActionButton(
              onPressed: () {
                try {
                  _googleSignIn.signOut();
                } on Exception catch (e) {
                  print(e);
                }
              },
              child: Icon(Icons.logout),
            ),
      appBar: AppBar(
        title: Text("Contacts app"),
      ),
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        child: isLoading
            ? Center(
                child: CircularProgressIndicator(),
              )
            : contacts != null && _currentUser != null
                ? getContactListWidget(context)
                : getLoginWidget(),
      ),
    );
  }
}
