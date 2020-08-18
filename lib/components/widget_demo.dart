/**
 * @author Nealyang
 * 
 * 新widget详情页模板
 */
import 'package:flutter/material.dart';
import '../routers/application.dart';
import '../routers/routers.dart';
import '../components/markdown.dart';
import '../model/collection.dart';
import '../widgets/index.dart';
import '../event/event_bus.dart';
import '../event/event_model.dart';
import 'dart:core';

/**
 * widget 详情页  StatefulWidget
 */
class WidgetDemo extends StatefulWidget {
  final List<dynamic> contentList;
  final String docUrl;
  final String title;
  final String codeUrl;
  final Widget bottomNaviBar;

  WidgetDemo(
      {Key key,
      @required this.title,
      @required this.contentList,
      @required this.codeUrl,
      @required this.docUrl,
      this.bottomNaviBar})
      : super(key: key);

  _WidgetDemoState createState() => _WidgetDemoState();

}

class _WidgetDemoState extends State<WidgetDemo> {
  bool _hasCollected = false;
  CollectionControlModel _collectionControl = new CollectionControlModel();
  var _collectionIcons;
  List widgetDemosList = new WidgetDemoList().getDemos();
  String _router = '';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<Widget> _buildContent() {
    List<Widget> _list = [
      SizedBox(
        height: 10.0,
      ),
    ];
    //集合  上个页面传输过来
    widget.contentList.forEach((item) {
      if (item.runtimeType == String) {// ---string  就用 markdown展示
        _list.add(MarkdownBody(item));
        _list.add(
          SizedBox(
            height: 20.0,
          ),
        );
      } else {//widget  直接添加
        _list.add(item);
      }
    });
    return _list;
  }

  @override
  void initState() {
    super.initState();
    _collectionControl.getRouterByName(widget.title).then((list) {
      widgetDemosList.forEach((item) {
        if (item.name == widget.title) {
          _router = item.routerName;
        }
      });
      if (this.mounted) {//只要涉及到异步还有各种回调(callback)，都不要忘了检查该值。
        setState(() {
          _hasCollected = list.length > 0;
        });
      }
    });
  }


// 点击收藏按钮
  _getCollection() {
    if (_hasCollected) {
      // 删除操作
      _collectionControl.deleteByName(widget.title).then((result) {
        if (result > 0 && this.mounted) {
          setState(() {
            _hasCollected = false;
          });
          _scaffoldKey.currentState
              .showSnackBar(SnackBar(content: Text('已取消收藏')));//底部toast
          if (ApplicationEvent.event != null) {//删除成功后  发出通知
            ApplicationEvent.event
                .fire(CollectionEvent(widget.title, _router, true));
          }
          return;
        }
        print('删除错误');
      });
    } else {
      // 插入操作
      _collectionControl
          .insert(Collection(name: widget.title, router: _router))
          .then((result) {
        if (this.mounted) {
          setState(() {
            _hasCollected = true;
          });

          if (ApplicationEvent.event != null) {//插入成功后  发出通知
            ApplicationEvent.event
                .fire(CollectionEvent(widget.title, _router, false));
          }

          _scaffoldKey.currentState
              .showSnackBar(SnackBar(content: Text('收藏成功')));
        }
      });
    }
  }

  void _selectValue(value) {
    if (value == 'doc') {
      // _launchURL(widget.docUrl);
      Application.router.navigateTo(context,
          '${Routes.webViewPage}?title=${Uri.encodeComponent(widget.title)} Doc&&url=${Uri.encodeComponent(widget.docUrl)}');
    } else if (value == 'code') {
      Application.router.navigateTo(context,
          '${Routes.codeView}?filePath=${Uri.encodeComponent(widget.codeUrl)}');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_hasCollected) {
      _collectionIcons = Icons.favorite;
    } else {
      _collectionIcons = Icons.favorite_border;
    }
    return Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: Text(widget.title),
          actions: <Widget>[
            new IconButton(//图标按钮
              tooltip: 'goBack home',
              onPressed: () {
//                Navigator.popUntil(context, ModalRoute.withName('/home'));
              _goHomePage(context);
              },
              icon: Icon(Icons.home),
            ),
            new IconButton(//图标按钮
              tooltip: 'collection',
              onPressed: _getCollection,
              icon: Icon(_collectionIcons),
            ),
            PopupMenuButton<String>(
              onSelected: _selectValue,
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[//弹框
                    const PopupMenuItem<String>(
                      value: 'doc',
                      child: ListTile(
                        leading: Icon(
                          Icons.library_books,
                          size: 22.0,
                        ),
                        title: Text('查看文档'),
                      ),
                    ),
                    const PopupMenuDivider(),//分割线
                    const PopupMenuItem<String>(
                      value: 'code',
                      child: ListTile(
                        leading: Icon(
                          Icons.code,
                          size: 22.0,
                        ),
                        title: Text('查看Demo'),
                      ),
                    ),
                  ],
            ),
          ],
        ),
        body: Container(
          padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
          child: ListView(
            shrinkWrap: true,//为true可以解决子控件必须设置高度的问题
//            physics:NeverScrollableScrollPhysics(),//禁用滑动事件
            padding: const EdgeInsets.all(0.0),
            children: <Widget>[
              Column(
                children: _buildContent(),
              ),
            ],
          ),
        ),
        bottomNavigationBar:
            (widget.bottomNaviBar is Widget) ? widget.bottomNaviBar : null);

  }

  _goHomePage(context) {
    Navigator.of(context)
        .pushNamedAndRemoveUntil('/home', (Route<dynamic> route) => false);
  }
}
