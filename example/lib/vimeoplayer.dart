library vimeoplayer;

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/services.dart';
import 'src/quality_links.dart';
import 'dart:async';
import 'package:chewie/chewie.dart';

//Класс видео плеера
class VimeoPlayer extends StatefulWidget {
  final String id;
  final bool autoPlay;
  final bool looping;
  final int position;
  final bool allowFullScreen;
  final bool allowPlaybackSpeedChanging;

  VimeoPlayer({
    @required this.id,
    this.autoPlay,
    this.looping,
    this.position,
    @required this.allowFullScreen,
    this.allowPlaybackSpeedChanging = false,
    Key key,
  })  : assert(id != null && allowFullScreen != null),
        super(key: key);

  @override
  _VimeoPlayerState createState() => _VimeoPlayerState(
        id,
        autoPlay,
        looping,
        position,
        allowFullScreen,
        allowPlaybackSpeedChanging,
      );
}

class _VimeoPlayerState extends State<VimeoPlayer> {
  String _id;
  bool autoPlay = false;
  bool looping = false;
  bool _overlay = true;
  bool fullScreen = false;
  int position;
  bool allowFullScreen = false;
  bool allowPlaybackSpeedChanging = false;

  _VimeoPlayerState(
    this._id,
    this.autoPlay,
    this.looping,
    this.position,
    this.allowFullScreen,
    this.allowPlaybackSpeedChanging,
  );

  //Custom controller
  VideoPlayerController _videoPlayerController;
  ChewieController _chewieController;

  //Custom controller
  VideoPlayerController _controller;
  Future<void> initFuture;

  //Quality Class
  QualityLinks _quality;
  Map _qualityValues;
  var _qualityValue;

  //Переменная перемотки
  bool _seek = false;

  //Переменные видео
  double videoHeight;
  double videoWidth;
  double videoMargin;

  //Переменные под зоны дабл-тапа
  double doubleTapRMargin = 36;
  double doubleTapRWidth = 400;
  double doubleTapRHeight = 160;
  double doubleTapLMargin = 10;
  double doubleTapLWidth = 400;
  double doubleTapLHeight = 160;

  @override
  void initState() {
    fullScreen = allowFullScreen;

    //Create class
    _quality = QualityLinks(_id);

    //Инициализация контроллеров видео при получении данных из Vimeo
    _quality.getQualitiesSync().then((value) {
      _qualityValues = value;
      _qualityValue = value[value.lastKey()];
      _videoPlayerController = VideoPlayerController.network(_qualityValue);
      initFuture = _videoPlayerController.initialize().then((value) {
        _chewieController = ChewieController(
          videoPlayerController: _videoPlayerController,
          // Prepare the video to be played and display the first frame
          autoInitialize: true,
          allowFullScreen: fullScreen,
          deviceOrientationsOnEnterFullScreen: [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight],
          systemOverlaysOnEnterFullScreen: [SystemUiOverlay.bottom],
          deviceOrientationsAfterFullScreen: [DeviceOrientation.portraitDown, DeviceOrientation.portraitUp],
          systemOverlaysAfterFullScreen: [SystemUiOverlay.top, SystemUiOverlay.bottom],
          aspectRatio: _videoPlayerController.value.aspectRatio,
          looping: looping,
          autoPlay: autoPlay,
          allowPlaybackSpeedChanging: allowPlaybackSpeedChanging,
          // Errors can occur for example when trying to play a videos
          // from a non-existent URL
          errorBuilder: (context, errorMessage) {
            return Center(child: Text(errorMessage, style: TextStyle(color: Colors.white)));
          },
        );
      });

      //Обновление состояние приложения и перерисовка
      setState(() {
        SystemChrome.setPreferredOrientations([DeviceOrientation.portraitDown, DeviceOrientation.portraitUp]);
      });
    });

    //На странице видео преимущество за портретной ориентацией
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitDown, DeviceOrientation.portraitUp]);
    SystemChrome.setEnabledSystemUIOverlays(SystemUiOverlay.values);

    super.initState();
  }

  //Отрисовываем элементы плеера
  @override
  Widget build(BuildContext context) {
    return Center(
        child: Stack(
      alignment: AlignmentDirectional.center,
      children: <Widget>[
        GestureDetector(
          child: FutureBuilder(
              future: initFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  //Управление шириной и высотой видео
                  double delta = MediaQuery.of(context).size.width -
                      MediaQuery.of(context).size.height * _videoPlayerController.value.aspectRatio;
                  //Рассчет ширины и высоты видео плеера относительно сторон
                  // и ориентации устройства
                  if (MediaQuery.of(context).orientation == Orientation.portrait || delta < 0) {
                    videoHeight = MediaQuery.of(context).size.width / _videoPlayerController.value.aspectRatio;
                    videoWidth = MediaQuery.of(context).size.width;
                    videoMargin = 0;
                  } else {
                    videoHeight = MediaQuery.of(context).size.height;
                    videoWidth = videoHeight * _videoPlayerController.value.aspectRatio;
                    videoMargin = (MediaQuery.of(context).size.width - videoWidth) / 2;
                  }

                  //Начинаем с того же места, где и остановились при смене качества
                  if (_seek && _videoPlayerController.value.duration.inSeconds > 2) {
                    _videoPlayerController.seekTo(Duration(seconds: position));
                    _seek = false;
                  }

                  //Prevent exception if it failes when initialising the vimeo video player
                  if (_chewieController != null) {
                    return Container(
                      margin: EdgeInsets.only(left: videoMargin),
                      child: Chewie(controller: _chewieController),
                    );
                  }
                  return Container();
                } else {
                  return Center(
                      heightFactor: 6,
                      child: CircularProgressIndicator(
                        strokeWidth: 4,
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF22A3D2)),
                      ));
                }
              }),
          onTap: () {
            //Редактируем размер области дабл тапа при показе оверлея.
            // Сделано для открытия кнопок "Во весь экран" и "Качество"
            setState(() {
              _overlay = !_overlay;
              if (_overlay) {
                doubleTapRHeight = videoHeight - 36;
                doubleTapLHeight = videoHeight - 10;
                doubleTapRMargin = 36;
                doubleTapLMargin = 10;
              } else if (!_overlay) {
                doubleTapRHeight = videoHeight + 36;
                doubleTapLHeight = videoHeight + 16;
                doubleTapRMargin = 0;
                doubleTapLMargin = 0;
              }
            });
          },
        ),
        GestureDetector(
            //======= Перемотка назад =======//
            child: Container(
              width: doubleTapLWidth / 2 - 30,
              height: doubleTapLHeight - 46,
              margin: EdgeInsets.fromLTRB(0, 10, doubleTapLWidth / 2 + 30, doubleTapLMargin + 20),
              decoration: BoxDecoration(
                  //color: Colors.red,
                  ),
            ),

            // Изменение размера блоков дабл тапа. Нужно для открытия кнопок
            // "Во весь экран" и "Качество" при включенном overlay
            onTap: () {
              setState(() {
                _overlay = !_overlay;
                if (_overlay) {
                  doubleTapRHeight = videoHeight - 36;
                  doubleTapLHeight = videoHeight - 10;
                  doubleTapRMargin = 36;
                  doubleTapLMargin = 10;
                } else if (!_overlay) {
                  doubleTapRHeight = videoHeight + 36;
                  doubleTapLHeight = videoHeight + 16;
                  doubleTapRMargin = 0;
                  doubleTapLMargin = 0;
                }
              });
            },
            onDoubleTap: () {
              setState(() {
                _videoPlayerController.seekTo(Duration(seconds: _videoPlayerController.value.position.inSeconds - 10));
              });
            }),
        GestureDetector(
            child: Container(
              //======= Перемотка вперед =======//
              width: doubleTapRWidth / 2 - 45,
              height: doubleTapRHeight - 60,
              margin: EdgeInsets.fromLTRB(doubleTapRWidth / 2 + 45, doubleTapRMargin, 0, doubleTapRMargin + 20),
              decoration: BoxDecoration(
                  //color: Colors.red,
                  ),
            ),
            // Изменение размера блоков дабл тапа. Нужно для открытия кнопок
            // "Во весь экран" и "Качество" при включенном overlay
            onTap: () {
              setState(() {
                _overlay = !_overlay;
                if (_overlay) {
                  doubleTapRHeight = videoHeight - 36;
                  doubleTapLHeight = videoHeight - 10;
                  doubleTapRMargin = 36;
                  doubleTapLMargin = 10;
                } else if (!_overlay) {
                  doubleTapRHeight = videoHeight + 36;
                  doubleTapLHeight = videoHeight + 16;
                  doubleTapRMargin = 0;
                  doubleTapLMargin = 0;
                }
              });
            },
            onDoubleTap: () {
              setState(() {
                _videoPlayerController.seekTo(Duration(seconds: _videoPlayerController.value.position.inSeconds + 10));
              });
            }),
      ],
    ));
  }

  @override
  void dispose() {
    _chewieController.dispose();
    _videoPlayerController.dispose();
    initFuture = null;
    super.dispose();
  }
}
