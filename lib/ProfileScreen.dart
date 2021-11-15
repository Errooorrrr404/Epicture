import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';

void deleteImageFromBase(line) async {
  final url = "https://api.imgur.com/3/image/" + line.hash.toString();
  await http.delete(url,
    headers: {
      HttpHeaders.authorizationHeader:
      "Bearer a43029e1ffc14bc497f98f3cff2e2cb877a3bca0"
    },
  );
}


Widget PrintProfil(ProfileSystem, context)
{
  return (Stack(
      children: <Widget>[
        Container(
          child: Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: new CachedNetworkImage(
                    imageUrl: ProfileSystem.url,
                    imageBuilder: (context, imageProvider) => Container(
                      width: 80.0,
                      height: 80.0,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                            image: imageProvider, fit: BoxFit.cover),
                      ),
                    ),
                    width: 80.0,
                    placeholder: (context, url) => LinearProgressIndicator(),
                    errorWidget: (context, url, error) => Icon(Icons.error),
                  ),
                ),
                ListTile(
                  title: Center(child: Text(ProfileSystem.title)),
                  subtitle: Center(child:
                    Column( children: [
                        Text("Profile created the : " +
                          DateTime.fromMillisecondsSinceEpoch(ProfileSystem.datetime * 1000).toString(),
                              style: TextStyle(color: Colors.black.withOpacity(0.6))),
                        Text("Reputation : " + ProfileSystem.up.toString(),
                          style: TextStyle(color: Colors.black.withOpacity(0.6))),
                        ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ]
  )
  );
}


class DisplayProfileData extends StatelessWidget {
  final List<Profil> myProfile;
  DisplayProfileData(this.myProfile);
  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.50,
      child: PrintProfil(myProfile[0], context),
    );
  }
}


Future<List<Album>> fetchAlbum() async {
  var Prefs = await SharedPreferences.getInstance();
  final response = await http.get(
    'https://api.imgur.com/3/account/' + Prefs.getString("user_account_name") + '/images/?refresh_token=' + Prefs.getString("user_refresh_token"),
    headers: {
      HttpHeaders.authorizationHeader:
      "Bearer " + Prefs.getString("user_access_token")
    },
  );
  final responseJson = jsonDecode(response.body);
  return fromJson(responseJson);

}

Future<List<Fav>> fetchFav() async {
  var Prefs = await SharedPreferences.getInstance();
  final response = await http.get(
    'https://api.imgur.com/3/account/' + Prefs.getString("user_account_name") + '/gallery_favorites/?refresh_token=' + Prefs.getString("user_refresh_token"),
    headers: {
      HttpHeaders.authorizationHeader:
      "Bearer " + Prefs.getString("user_access_token")
    },
  );
  final responseJson = jsonDecode(response.body);
  return FavfromJson(responseJson);

}

Future<List<Profil>> fetchProfil() async {
  var Prefs = await SharedPreferences.getInstance();
  final response = await http.get(
    'https://api.imgur.com/3/account/' + Prefs.getString("user_account_name") + '/?refresh_token=' + Prefs.getString("user_refresh_token"),
    headers: {
      HttpHeaders.authorizationHeader:
      "Bearer " + Prefs.getString("user_access_token")
    },
  );
  final responseJson = jsonDecode(response.body);
  return ProfilefromJson(responseJson);
}

class Album {
  final String id;
  final String title;
  final String url;
  final bool favorite;
  final int view;
  final int width;
  final int height;
  final int datetime;
  final bool inGallery;
  final int up;
  final int down;
  final String hash;

  Album({this.id, this.title, this.url,  this.favorite, this.view,  this.width,  this.height,  this.datetime,  this.inGallery, this.up, this.down, this.hash});
}

class Fav {
  final String id;
  final String title;
  final String url;
  final bool favorite;
  final int view;
  final int width;
  final int height;
  final int datetime;
  final bool inGallery;
  final int up;
  final int down;
  final String hash;
  final int vote;

  Fav({this.id, this.title, this.url,  this.favorite, this.view,  this.width,  this.height,  this.datetime,  this.inGallery, this.up, this.down, this.hash, this.vote});
}

class Profil {
  final int id;
  final String title;
  final String url;
  final int datetime;
  final int up;

  Profil({this.id, this.title, this.url, this.datetime, this.up});
}

fromJson(Map<String, dynamic> json) {
  List<Album> myAlbum = new List<Album>(json["data"].length);
  for (int i = 0; i < json["data"].length; i++) {
      myAlbum[i] = Album(
        id: json["data"][i]['id'],
        title: json["data"][i]['name'],
        view: json["data"][i]['views'],
        favorite: json["data"][i]['favorite'],
        width: json["data"][i]['width'],
        height: json["data"][i]['height'],
        datetime: json["data"][i]['datetime'],
        inGallery: json["data"][i]['in_gallery'],
        url: json["data"][i]["link"],
        hash: json["data"][i]["deletehash"],
      );
  }
  return myAlbum;
}

FavfromJson(Map<String, dynamic> json) {
  List<Fav> myAlbum = new List<Fav>(json["data"].length);
  int datavote;
  for (int i = 0; i < json["data"].length; i++) {
    if (json["data"][i]['vote'] == null || json["data"][i]['vote'] == "veto" || json["data"][i]['vote'] == "")
      datavote = 0;
    else if (json["data"][i]['vote'] == "up")
      datavote = 1;
    else
      datavote = -1;
    myAlbum[i] = Fav(
      id: json["data"][i]['id'],
      title: json["data"][i]['title'],
      view: json["data"][i]['views'],
      favorite: json["data"][i]['favorite'],
      width: json["data"][i]['width'],
      height: json["data"][i]['height'],
      datetime: json["data"][i]['datetime'],
      inGallery: json["data"][i]['in_gallery'],
      url: json["data"][i]["images"][0]["link"],
      vote: datavote,
    );
  }
  return myAlbum;
}


ProfilefromJson(Map<String, dynamic> json) {
  List<Profil> profile= new List<Profil>(1);
  profile[0] = Profil(
    id: json["data"]["id"],
    title: json["data"]["url"],
    datetime: json["data"]["created"],
    up: json["data"]["reputation"],
    url: json["data"]["avatar"],
  );
  return profile;
}

List<bool> initFav(myfav, myList, loop)
{
  if (loop != 0)
    return myfav;
  List<bool> _active = new List<bool>(myList.length);
  for (int i = 0; i < myList.length; i++)
    _active[i] = myList[i].favorite;
  return _active;
}

List<int> initUp(myfav, myList, loop)
{
  if (loop != 0)
    return myfav;
  List<int> _active = new List<int>(myList.length);
  for (int i = 0; i < myList.length; i++)
    _active[i] = myList[i].up;
  return _active;
}

List<int> initDown(myfav, myList, loop)
{
  if (loop != 0)
    return myfav;
  List<int> _active = new List<int>(myList.length);
  for (int i = 0; i < myList.length; i++)
    _active[i] = myList[i].down;
  return _active;
}

List<int> initVote(myfav, myList, loop)
{
  if (loop != 0)
    return myfav;
  List<int> _active = new List<int>(myList.length);
  for (int i = 0; i < myList.length; i++)
    _active[i] = myList[i].vote;
  return _active;
}

updateVoteImage(id, vote) async
{
  String finalVote = (vote == 1) ? "up" : ((vote == 0) ? "veto" : "down");
  var Prefs = await SharedPreferences.getInstance();
  final response = await http.post(
    'https://api.imgur.com/3/gallery/' + id.toString()  +'/vote/' + finalVote + '?refresh_token=' + Prefs.getString("user_refresh_token"),
    headers: {
      HttpHeaders.authorizationHeader:
      "Bearer " + Prefs.getString("user_access_token")
    },
  );
}

updateFavImage(id) async
{
  var Prefs = await SharedPreferences.getInstance();
  final response = await http.post(
    'https://api.imgur.com/3/album/' + id.toString()  +'/favorite?refresh_token=' + Prefs.getString("user_refresh_token"),
    headers: {
      HttpHeaders.authorizationHeader:
      "Bearer " + Prefs.getString("user_access_token")
    },
  );
}

class Profile extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => new _Profile();
}
class _Profile extends State<Profile> {
  Future<List<Album>> futureAlbum = fetchAlbum();
  Future<List<Fav>> futureFav = fetchFav();
  Future<List<Profil>> futureProfile = fetchProfil();
  String dropdownValue = 'My Photos';
  List<bool> myfav;
  List<int> myVote;
  List<int> mydown;
  List<int> myup;
  int loop = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: new SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              width: MediaQuery.of(context).size.width * 1,
              child: FutureBuilder<List<Profil>>(
                future: futureProfile,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return DisplayProfileData(snapshot.data);
                  }
                  return LinearProgressIndicator();
                },
              ),
            ),
        Center(child:
        DropdownButton<String>(
          value: dropdownValue,
          icon: Icon(Icons.arrow_drop_down),
          iconSize: 24,
          elevation: 16,
          style: TextStyle(color: Colors.deepPurple),
          underline: Container(
            height: 2,
            color: Colors.deepPurpleAccent,
          ),
          onChanged: (String newValue) {
              dropdownValue = newValue;
              setState(() {

              });
          },
          items: <String>['My Photos', 'Favorite']
              .map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
              onTap: () {
                dropdownValue = value;
                loop = 0;
                setState(() {
                });
                },
            );
          }).toList(),
          ),
          ),
            if (dropdownValue == "Favorite")
              Container(
                width: MediaQuery.of(context).size.width * 1,
                child: FutureBuilder<List<Fav>>(
                  future: futureFav,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      myfav = initFav(myfav, snapshot.data, loop);
                      myup = initUp(myup, snapshot.data, loop);
                      mydown = initDown(mydown, snapshot.data, loop);
                      myVote = initVote(myVote, snapshot.data, loop);
                      loop++;
                      return Column(
                        children: [
                          for (int i = 0; i < snapshot.data.length; i++)
                            Stack(
                                children: <Widget>[
                                  Container(
                                    child: Card(
                                      clipBehavior: Clip.antiAlias,
                                      child: Column(
                                        children: [
                                          ListTile(
                                            title: Center(child: Text(snapshot.data[i].title)),
                                            subtitle: Center(child: Text(
                                                DateTime.fromMillisecondsSinceEpoch(
                                                    snapshot.data[i].datetime * 1000).toString(),
                                                style: TextStyle(color: Colors.black.withOpacity(0.6))),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(16.0),
                                            child: CachedNetworkImage(
                                              imageUrl: snapshot.data[i].url,
                                              fit: BoxFit.fill,
                                              width: MediaQuery
                                                  .of(context)
                                                  .size
                                                  .width * 1,
                                              placeholder: (context, url) => LinearProgressIndicator(),
                                              errorWidget: (context, url, error) => Icon(Icons.error),
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.all(16.0),
                                            child: Row(
                                              children: <Widget>[
                                                Expanded(
                                                  child: Row(
                                                    children: <Widget>[
                                                      Expanded(
                                                        child: InkWell(
                                                          onTap: () {
                                                            myfav[i] = !myfav[i];
                                                            setState(() {
                                                            });
                                                            updateFavImage(snapshot.data[i].id);
                                                          },
                                                          child: myfav[i] ? Icon(
                                                            Icons.favorite,
                                                            color: Colors.red,
                                                          ) : Icon(Icons.favorite),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ]
                            ),
                        ],
                      );
                    }
                    return LinearProgressIndicator();
                  }
                )
              )
            else
              Container(
              width: MediaQuery.of(context).size.width * 1,
              child: FutureBuilder<List<Album>>(
                future: futureAlbum,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    myfav = initFav(myfav, snapshot.data, loop);
                    loop++;
                    return Column(
                      children: [
                        for (int i = 0; i < snapshot.data.length; i++)
                          Stack(
                              children: <Widget>[
                                Container(
                                  child: Card(
                                    clipBehavior: Clip.antiAlias,
                                    child: Column(
                                      children: [
                                        ListTile(
                                          title: Center(child: Text(snapshot.data[i].title)),
                                          subtitle: Center(child: Text(
                                              DateTime.fromMillisecondsSinceEpoch(
                                                  snapshot.data[i].datetime * 1000).toString(),
                                              style: TextStyle(color: Colors.black.withOpacity(0.6))),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: CachedNetworkImage(
                                            imageUrl: snapshot.data[i].url,
                                            fit: BoxFit.fill,
                                            width: MediaQuery
                                                .of(context)
                                                .size
                                                .width * 1,
                                            placeholder: (context, url) => LinearProgressIndicator(),
                                            errorWidget: (context, url, error) => Icon(Icons.error),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(16.0),
                                          child: Row(
                                            children: <Widget>[
                                              Expanded(
                                                child: Row(
                                                  children: <Widget>[
                                                    Expanded(
                                                      child: Center(child: Icon(Icons.remove_red_eye, color: Colors.green)),
                                                    ),
                                                    Expanded(
                                                      child: Center(child: Text(snapshot.data[i].view.toString())),
                                                    )
                                                  ],
                                                ),
                                              ),
                                               Expanded(
                                                 child: InkWell(
                                                   onTap: () {
                                                     myfav[i] = !myfav[i];
                                                     setState(() {
                                                     });
                                                     updateFavImage(snapshot.data[i].id);
                                                   },
                                                   child: myfav[i] ? Icon(
                                                     Icons.favorite,
                                                     color: Colors.red,
                                                   ) : Icon(Icons.favorite),
                                                 ),
                                               ),
                                              Expanded(
                                                child: InkWell(
                                                  onTap: () {
                                                    deleteImageFromBase(snapshot.data[i]);
                                                    futureAlbum = fetchAlbum();
                                                    loop = 0;
                                                    setState(() {
                                                    });
                                                  },
                                                  child: Icon(Icons.delete_forever, color: Colors.red,),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ]
                          ),
                      ],
                    );
                  }
                  return LinearProgressIndicator();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
/**/