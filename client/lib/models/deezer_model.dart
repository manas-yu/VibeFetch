import 'dart:convert';

DeezerSongModel deezerSongModelFromJson(String str) =>
    DeezerSongModel.fromJson(json.decode(str));

String deezerSongModelToJson(DeezerSongModel data) =>
    json.encode(data.toJson());

class DeezerSongModel {
  DeezerSongModel({
    this.id,
    this.readable,
    this.title,
    this.titleShort,
    this.titleVersion,
    this.isrc,
    this.link,
    this.share,
    this.duration,
    this.trackPosition,
    this.diskNumber,
    this.rank,
    this.releaseDate,
    this.explicitLyrics,
    this.explicitContentLyrics,
    this.explicitContentCover,
    this.preview,
    this.bpm,
    this.gain,
    this.availableCountries,
    this.contributors,
    this.md5Image,
    this.artist,
    this.album,
    this.type,
  });

  int? id;
  bool? readable;
  String? title;
  String? titleShort;
  String? titleVersion;
  String? isrc;
  String? link;
  dynamic share;
  dynamic duration;
  dynamic trackPosition;
  dynamic diskNumber;
  dynamic rank;
  DateTime? releaseDate;
  bool? explicitLyrics;
  dynamic explicitContentLyrics;
  dynamic explicitContentCover;
  String? preview;
  dynamic bpm;
  double? gain;
  List<String>? availableCountries;
  List<Contributor>? contributors;
  String? md5Image;
  Artist? artist;
  Album? album;
  String? type;

  factory DeezerSongModel.fromJson(Map<String, dynamic> json) =>
      DeezerSongModel(
        id: json["id"],
        readable: json["readable"],
        title: json["title"],
        titleShort: json["title_short"],
        titleVersion: json["title_version"],
        isrc: json["isrc"],
        link: json["link"],
        share: json["share"],
        duration: json["duration"],
        trackPosition: json["track_position"],
        diskNumber: json["disk_number"],
        rank: json["rank"],
        releaseDate: json["release_date"] != null
            ? DateTime.tryParse(json["release_date"])
            : null,
        explicitLyrics: json["explicit_lyrics"],
        explicitContentLyrics: json["explicit_content_lyrics"],
        explicitContentCover: json["explicit_content_cover"],
        preview: json["preview"],
        bpm: json["bpm"],
        gain: json["gain"] != null ? json["gain"].toDouble() : null,
        availableCountries: json["available_countries"] != null
            ? List<String>.from(json["available_countries"])
            : null,
        contributors: json["contributors"] != null
            ? List<Contributor>.from(
                json["contributors"].map((x) => Contributor.fromJson(x)),
              )
            : null,
        md5Image: json["md5_image"],
        artist: json["artist"] != null ? Artist.fromJson(json["artist"]) : null,
        album: json["album"] != null ? Album.fromJson(json["album"]) : null,
        type: json["type"],
      );

  Map<String, dynamic> toJson() => {
    "id": id,
    "readable": readable,
    "title": title,
    "title_short": titleShort,
    "title_version": titleVersion,
    "isrc": isrc,
    "link": link,
    "share": share,
    "duration": duration,
    "track_position": trackPosition,
    "disk_number": diskNumber,
    "rank": rank,
    "release_date": releaseDate?.toIso8601String(),
    "explicit_lyrics": explicitLyrics,
    "explicit_content_lyrics": explicitContentLyrics,
    "explicit_content_cover": explicitContentCover,
    "preview": preview,
    "bpm": bpm,
    "gain": gain,
    "available_countries": availableCountries,
    "contributors": contributors?.map((x) => x.toJson()).toList(),
    "md5_image": md5Image,
    "artist": artist?.toJson(),
    "album": album?.toJson(),
    "type": type,
  };
}

class Album {
  Album({
    this.id,
    this.title,
    this.link,
    this.cover,
    this.coverSmall,
    this.coverMedium,
    this.coverBig,
    this.coverXl,
    this.md5Image,
    this.releaseDate,
    this.tracklist,
    this.type,
  });

  dynamic id;
  String? title;
  String? link;
  String? cover;
  String? coverSmall;
  String? coverMedium;
  String? coverBig;
  String? coverXl;
  String? md5Image;
  DateTime? releaseDate;
  String? tracklist;
  String? type;

  factory Album.fromJson(Map<String, dynamic> json) => Album(
    id: json["id"],
    title: json["title"],
    link: json["link"],
    cover: json["cover"],
    coverSmall: json["cover_small"],
    coverMedium: json["cover_medium"],
    coverBig: json["cover_big"],
    coverXl: json["cover_xl"],
    md5Image: json["md5_image"],
    releaseDate: json["release_date"] != null
        ? DateTime.tryParse(json["release_date"])
        : null,
    tracklist: json["tracklist"],
    type: json["type"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "title": title,
    "link": link,
    "cover": cover,
    "cover_small": coverSmall,
    "cover_medium": coverMedium,
    "cover_big": coverBig,
    "cover_xl": coverXl,
    "md5_image": md5Image,
    "release_date": releaseDate?.toIso8601String(),
    "tracklist": tracklist,
    "type": type,
  };
}

class Artist {
  Artist({
    this.id,
    this.name,
    this.link,
    this.share,
    this.picture,
    this.pictureSmall,
    this.pictureMedium,
    this.pictureBig,
    this.pictureXl,
    this.radio,
    this.tracklist,
    this.type,
  });

  dynamic id;
  String? name;
  String? link;
  String? share;
  String? picture;
  String? pictureSmall;
  String? pictureMedium;
  String? pictureBig;
  String? pictureXl;
  bool? radio;
  String? tracklist;
  String? type;

  factory Artist.fromJson(Map<String, dynamic> json) => Artist(
    id: json["id"],
    name: json["name"],
    link: json["link"],
    share: json["share"],
    picture: json["picture"],
    pictureSmall: json["picture_small"],
    pictureMedium: json["picture_medium"],
    pictureBig: json["picture_big"],
    pictureXl: json["picture_xl"],
    radio: json["radio"],
    tracklist: json["tracklist"],
    type: json["type"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "link": link,
    "share": share,
    "picture": picture,
    "picture_small": pictureSmall,
    "picture_medium": pictureMedium,
    "picture_big": pictureBig,
    "picture_xl": pictureXl,
    "radio": radio,
    "tracklist": tracklist,
    "type": type,
  };
}

class Contributor {
  Contributor({
    this.id,
    this.name,
    this.link,
    this.share,
    this.picture,
    this.pictureSmall,
    this.pictureMedium,
    this.pictureBig,
    this.pictureXl,
    this.radio,
    this.tracklist,
    this.type,
    this.role,
  });

  dynamic id;
  String? name;
  String? link;
  String? share;
  String? picture;
  String? pictureSmall;
  String? pictureMedium;
  String? pictureBig;
  String? pictureXl;
  bool? radio;
  String? tracklist;
  String? type;
  String? role;

  factory Contributor.fromJson(Map<String, dynamic> json) => Contributor(
    id: json["id"],
    name: json["name"],
    link: json["link"],
    share: json["share"],
    picture: json["picture"],
    pictureSmall: json["picture_small"],
    pictureMedium: json["picture_medium"],
    pictureBig: json["picture_big"],
    pictureXl: json["picture_xl"],
    radio: json["radio"],
    tracklist: json["tracklist"],
    type: json["type"],
    role: json["role"],
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "link": link,
    "share": share,
    "picture": picture,
    "picture_small": pictureSmall,
    "picture_medium": pictureMedium,
    "picture_big": pictureBig,
    "picture_xl": pictureXl,
    "radio": radio,
    "tracklist": tracklist,
    "type": type,
    "role": role,
  };
}
