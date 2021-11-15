import 'package:DEV_epicture_2020/SearchScreen.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:imgur/imgur.dart' as imgur;


Future<List<Album>> fetchAlbum() async {
  var Prefs = await SharedPreferences.getInstance();
  final response = await http.get(
    'https://api.imgur.com/3/gallery/hot/viral/?refresh_token=' + Prefs.getString("user_refresh_token"),
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

void SendImage(image, title) async{
  var Prefs = await SharedPreferences.getInstance();

  final client = imgur.Imgur(imgur.Authentication.fromToken(Prefs.getString("user_access_token")));

  await client.image
      .uploadImage(
      imagePath: image.toString(),
      title: title,
      description: title,
      name: title)
      .then((image) => print('Uploaded image to: ${image.link}'));
}


class SecondRoute extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => new _SecondRoute();
}

class _SecondRoute extends State<SecondRoute> {
  File _image;
  String title = "";
  String ImageTitle =  "./assets/upload.png";
  _imgFromCamera() async {
    File image = await ImagePicker.pickImage(
        source: ImageSource.camera, imageQuality: 50
    );
    _image = image;
    ImageTitle = image.path.toString();
    setState(() {

    });
  }

  _imgFromGallery() async {
    File image = await ImagePicker.pickImage(
        source: ImageSource.gallery, imageQuality: 50
    );
    _image = image;

    ImageTitle = image.path.toString();
    setState(() {

    });
  }
  addPhotos(context){
    showModalBottomSheet(
        context: context,
        builder: (BuildContext bc) {
          return SafeArea(
            child: Container(
              child: new Wrap(
                children: <Widget>[
                  new ListTile(
                      leading: new Icon(Icons.photo_library),
                      title: new Text('Photo Library'),
                      onTap: () {
                        _imgFromGallery();
                        Navigator.of(context).pop();
                      }),
                  new ListTile(
                    leading: new Icon(Icons.photo_camera),
                    title: new Text('Camera'),
                    onTap: () {
                      _imgFromCamera();
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              ),
            ),
          );
        }
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Upload"),
        ),
      body: SingleChildScrollView(child: Container(
        child: Card(
          clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
              Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ListTile(
                    title: Center(child: Text("Touch the middle of your screen if you want to add your photo.", textAlign: TextAlign.center)),
                    subtitle: Center(child: Text(
                      DateTime.now().toString(),
                      style: TextStyle(color: Colors.black.withOpacity(0.6))),
              ),
            ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: GestureDetector(
                  onTap:(){
                    addPhotos(context);
                },
                  child: Image(
                    image: AssetImage(ImageTitle.toString()),
                    fit: BoxFit.fill,
                    width: MediaQuery.of(context).size.width * 1,
                ),
                ),
              ),
                Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child : TextFormField(
                      onChanged: (text) {
                        title = text.toString();
                        setState(() {

                        });
                      },
                      decoration: InputDecoration(
                      hintText: 'MyPhoto',
                      labelText: 'Title of your photo',
                    ),
                  ),
                ),
              ),
                Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child :  FloatingActionButton(
                        backgroundColor: (ImageTitle.toString() != "./assets/upload.png" && ImageTitle.toString() != "" && title != "") ? Colors.green: Colors.grey,
                        onPressed:(){
                          if (ImageTitle.toString() != "./assets/upload.png" && ImageTitle.toString() != "" && title != "") {
                            SendImage(ImageTitle.toString(), title);
                            ImageTitle = "./assets/upload.png";
                              Navigator.of(context).pop();
                          }
                          setState(() {
                          });
                        },
                        child: Icon(Icons.send),
                        tooltip: 'Upload',
                  ),
                  ),
                ),
              ],
            ),
        ),
      ),
      ),
    );
  }
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


class HomePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => new _HomePage();
}
class _HomePage extends State<HomePage>{
  List<bool> myfav;
  List<int> myVote;
  List<int> mydown;
  List<int> myup;
  int loop = 0;
 Future<List<Album>> futureAlbum = fetchAlbum();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
          children: <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Container(
                  width: MediaQuery.of(context).size.width * 1,
                  height: MediaQuery.of(context).size.height * 0.80,
                  child: new SingleChildScrollView(child: FutureBuilder<List<Album>>(
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
                    },),
                  ),
                ),
              ],
            ),
            ],
          ),
      );
   }
}