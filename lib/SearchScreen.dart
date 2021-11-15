import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget favHeart(line) {
  if (line.favorite == true) {
    return Center(child: Icon(Icons.favorite, color: Colors.pink));
  } else {
    return Center(child: Icon(Icons.favorite));
  }
}

Widget PrintData(line, context) {
  return (Stack(children: <Widget>[
    Container(
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            ListTile(
              title: Center(child: Text(line.title)),
              subtitle: Center(
                child: Text(
                    DateTime.fromMillisecondsSinceEpoch(line.datetime * 1000)
                        .toString(),
                    style: TextStyle(color: Colors.black.withOpacity(0.6))),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: CachedNetworkImage(
                imageUrl: line.url,
                fit: BoxFit.fill,
                width: MediaQuery.of(context).size.width * 1,
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
                          child: Center(
                              child: Icon(Icons.thumb_up, color: Colors.blue)),
                        ),
                        Expanded(
                          child: Center(child: Text(line.up.toString())),
                        )
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Center(
                              child: Icon(Icons.thumb_down, color: Colors.red)),
                        ),
                        Expanded(
                          child: Center(child: Text(line.down.toString())),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: favHeart(line),
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
  ]));
}

class DisplayImageData extends StatelessWidget {
  final List<Album> myAlbum;
  DisplayImageData(this.myAlbum);
  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.50,
      child: Column(
        children: [
          for (int i = 0; i < myAlbum.length; i++)
            PrintData(myAlbum[i], context),
        ],
      ),
    );
  }
}

Future<List<Album>> fetchAlbum(search) async {
  if (search == "")
      search = "Epitech";
  var Prefs = await SharedPreferences.getInstance();
  final response = await http.get(
    'https://api.imgur.com/3/gallery/search/?q_any='+ search +'?refresh_token=' +
        Prefs.getString("user_refresh_token"),
    headers: {
      HttpHeaders.authorizationHeader:
          "Bearer " + Prefs.getString("user_access_token")
    },
  );
  final responseJson = jsonDecode(response.body);
  return fromJson(responseJson);
}

class Album {
  final String id;
  final String title;
  final String url;
  final bool favorite;
  final int width;
  final int height;
  final int datetime;
  final bool inGallery;
  final int up;
  final int down;
  final int vote;

  Album({this.id, this.title, this.url,  this.favorite,  this.width,  this.height,  this.datetime,  this.inGallery, this.up, this.down, this.vote});
}

fromJson(Map<String, dynamic> json) {
  int size = 0;
  for (int i = 0; i < json["data"].length; i++) {
    if (json["data"][i]['images'] != null && json["data"][i]["images"][0]["type"] != "video/mp4")
      size++;
  }
  int datavote;
  List<Album> myAlbum = new List<Album>(size);
  for (int i = 0, j = 0; i < json["data"].length; i++) {
    if (json["data"][i]['images'] != null && json["data"][i]["images"][0]["type"] != "video/mp4") {
      if (json["data"][i]['vote'] == null || json["data"][i]['vote'] == "veto")
        datavote = 0;
      else if (json["data"][i]['vote'] == "up")
        datavote = 1;
      else
        datavote = -1;
      myAlbum[j] = Album(
        id: json["data"][i]['id'],
        title: json["data"][i]['title'],
        favorite: json["data"][i]['favorite'],
        width: json["data"][i]['width'],
        height: json["data"][i]['height'],
        datetime: json["data"][i]['datetime'],
        inGallery: json["data"][i]['in_gallery'],
        up: json["data"][i]['ups'],
        down: json["data"][i]['downs'],
        url: json["data"][i]['images'][0]["link"],
        vote: datavote,
      );
      j++;
    }
  }
  return myAlbum;
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

class Search extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => new _Search();
}

class _Search extends State<Search> {
  Future<List<Album>> futureAlbum = fetchAlbum("");
  List<bool> myfav;
  List<int> myVote;
  List<int> mydown;
  List<int> myup;
  String myText = "";
  int loop = 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomPadding: false,
      body: Column(children: [
        Container(
          width: MediaQuery.of(context).size.width * 1,
          child: new Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: TextFormField(
                onChanged: (text) {
                  myText = text;
                  setState(() {});
                },
                onFieldSubmitted: (text) {
                  myText = text;
                  futureAlbum = fetchAlbum(myText.toString().toLowerCase());
                  loop = 0;
                  setState(() {});
                },
                decoration: InputDecoration(
                  hintText: 'Type what you want',
                  labelText: 'Search Bar',
                  suffixIcon: IconButton(
                    onPressed: () {
                      print(myText);
                      futureAlbum = fetchAlbum(myText.toString().toLowerCase());
                      loop = 0;
                      setState(() {
                      });
                    },
                    icon: Icon(Icons.send),
                  ),
                ),
              ),
            ),
          ),
        ),
        Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                width: MediaQuery.of(context).size.width * 1,
                height: MediaQuery.of(context).size.height * 0.65,
                child: new SingleChildScrollView(
                  child: FutureBuilder<List<Album>>(
                      future: futureAlbum,
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
                                                                if (myVote[i] == 1){
                                                                  if (loop != 0)
                                                                    myup[i] -= 1;
                                                                  myVote[i] = 0;
                                                                } else if (myVote[i] == 1){
                                                                  if (loop != 0) {
                                                                    myup[i] += 1;
                                                                  }
                                                                  mydown[i] -= 1;
                                                                  myVote[i] = 1;
                                                                }else {
                                                                  if (loop != 0)
                                                                    myup[i] += 1;
                                                                  myVote[i] = 1;
                                                                }
                                                                updateVoteImage(snapshot.data[i].id, myVote[i]);
                                                                setState(() {
                                                                });
                                                              },
                                                              child: myVote[i] == 1 ? Icon(
                                                                Icons.thumb_up,
                                                                color: Colors.blue,
                                                              ) : Icon(Icons.thumb_up),
                                                            ),
                                                          ),
                                                          Expanded(
                                                            child: Center(child: Text(myup[i].toString())),
                                                          )
                                                        ],
                                                      ),
                                                    ),
                                                    Expanded(
                                                      child: Row(
                                                        children: <Widget>[
                                                          Expanded(
                                                            child: InkWell(
                                                              onTap: () {
                                                                if (myVote[i] == -1){
                                                                  if (loop != 0)
                                                                    mydown[i] -= 1;
                                                                  myVote[i] = 0;
                                                                } else if (myVote[i] == 1){
                                                                  if (loop != 0) {
                                                                    mydown[i] += 1;
                                                                  }
                                                                  myup[i] -= 1;
                                                                  myVote[i] = -1;
                                                                } else {
                                                                  if (loop != 0)
                                                                    mydown[i] += 1;
                                                                  myVote[i] = -1;
                                                                }
                                                                updateVoteImage(snapshot.data[i].id, myVote[i]);
                                                                setState(() {
                                                                });
                                                              },
                                                              child: myVote[i] == -1 ? Icon(
                                                                Icons.thumb_down,
                                                                color: Colors.red,
                                                              ) : Icon(Icons.thumb_down),
                                                            ),),
                                                          Expanded(
                                                            child: Center(
                                                                child: Text(mydown[i].toString())),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
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
                      }),
                ),
              ),
            ]
        ),
      ]),
    );
  }
}
