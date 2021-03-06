import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

import 'package:picknmelt/store/data_notifier.dart';
import 'package:provider/provider.dart';

import 'package:picknmelt/store/index.dart';
import 'package:picknmelt/widgets/custom_searchbtn.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

// modle
import "package:picknmelt/model/stock_item_model.dart";

import 'package:pull_to_refresh/pull_to_refresh.dart';
// page
import 'package:picknmelt/widgets/stock_item.dart';
import 'package:picknmelt/widgets/cart_total.dart';
import 'package:picknmelt/pages/scanner_page.dart';
import 'package:picknmelt/pages/login_page.dart';
import 'dart:convert';

class SerachResultPage extends StatefulWidget {
  const SerachResultPage({Key key}) : super(key: key);

  @override
  _SerachResultPage createState() => _SerachResultPage();
}

class _SerachResultPage extends State<SerachResultPage> {
  AppState state;

  RefreshController _refreshController =
      RefreshController(initialRefresh: false);

  TextEditingController _searchController;
  PanelController _pc;
  final double _initFabHeight = 50.0;
  double _fabHeight = 0;
  double _panelHeightOpen = 0.0;
  final double _panelHeightClosed = 0.0;
  double appHeight = 0.0;
  double _delta = 0.0;
  bool _show = true;

  List<StockItemModel> items = <StockItemModel>[];
  bool status = false;
  @override
  void initState() {
    super.initState();
    state = Provider.of<AppState>(context, listen: false);
    _searchController = TextEditingController();
    _pc = PanelController();
    _fabHeight = _initFabHeight;
    appHeight = AppBar().preferredSize.height;
    _delta = 50;
    getStockData();
    setState(() {});
  }

  void getStockData() async {
    setState(() {
      status = true;
    });
    print(state.sku);
    if (state.sku.toString().isEmpty) {
      // Provider.of<DataNotifier>(context, listen: false)
      //     .updateStocks(<StockItemModel>[]);
      setState(() {
        // items = <StockItemModel>[];
        status = false;
      });
      print(1);
    } else {
      String _tempURL =
          'https://appdev01.picknmelt.com/wp-json/picknmelt/v1/get_inventories/' +
              state.sku;
      // String _tempURL =
      //     'https://appdev01.picknmelt.com/wp-json/picknmelt/v1/get_inventories/PO-frangipane-1000g';
      print(state.token);
      state.getAuth(Uri.parse(_tempURL)).then((data) {
        var body = jsonDecode(data.body);
        // print(body);
        if (data.statusCode == 422) {
          Map<String, dynamic> response = jsonDecode(data.body);
          Map<String, dynamic> errors = response['errors'];
          state.notifyToastDanger(
              context: context, message: errors.values.toList()[0][0]);
        } else if (data.statusCode == 200) {
          var inventories = body['inventories'];
          state.productName = body['product_name'];
          items.clear();
          List _dates = [];
          inventories.keys.forEach((String key) {
            _dates.add(key);
          });
          for (int i = 0; i < _dates.length; i++) {
            final StockItemModel _item = StockItemModel(
              inventoryId: inventories[_dates[i]]['inventory_id'] as int,
              inventoryName: inventories[_dates[i]]['inventory_name'],
              inventoryStock: inventories[_dates[i]]['inventory_stock'] as int,
            );
            setState(() {
              items.add(_item);
            });
          }
          // print(items.toString());
          Provider.of<DataNotifier>(context, listen: false).updateStocks(items);
          setState(() {
            // items.addAll(inventories);
            status = false;
          });
        } else {
          state.notifyToastDanger(
              context: context, message: "Error occured while getting data");
        }
        setState(() {
          status = false;
        });
      }).catchError((error) {
        print(error);
        setState(() {
          status = false;
        });
      });
      setState(() {
        status = false;
      });
    }
  }

  void onStockSave() async {
    var _stocks = Provider.of<DataNotifier>(context, listen: false).stocks;
    var _sendData = [];
    for (StockItemModel _temp in _stocks) {
      Map _tempData = {_temp.inventoryId.toString(): _temp.inventoryStock};
      _sendData.add(_tempData);
      // _sendData[_temp.inventoryId.toString()] = _temp.inventoryStock.toString();
    }
    // print(_sendData.isNotEmpty);
    setState(() {
      status = true;
    });
    if (_sendData.isNotEmpty) {
      String _url =
          "https://appdev01.picknmelt.com/wp-json/picknmelt/v1/update_inventories";
      // String _url =
      //     "https://appdev01.picknmelt.com/?test_action=api_update&sku=${state.sku}";
      Map sendData = {"sku": state.sku, "inventories": jsonEncode(_sendData)};
      print("send data ==================================================");
      print(_sendData);
      state.postAuthWithContentType(Uri.parse(_url), sendData).then((data) {
        var body = jsonDecode(data.body);
        print(body);
        // print(data);
        // print(data.statusCode);
        if (data.statusCode == 422) {
          Map<String, dynamic> response = jsonDecode(data.body);
          Map<String, dynamic> errors = response['errors'];
          state.notifyToastDanger(
              context: context, message: errors.values.toList()[0][0]);
        } else if (data.statusCode == 200) {
          setState(() {
            // items.addAll(inventories);
            status = false;
          });
        } else if (data.statusCode == 403) {
          state.notifyToastDanger(context: context, message: body['message']);
        } else {
          state.notifyToastDanger(
              context: context, message: "Error occured while saving");
        }
        setState(() {
          // items.addAll(inventories);
          status = false;
        });
      }).catchError((error) {
        print(error);
        setState(() {
          // items.addAll(inventories);
          status = false;
        });
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void showAppBar() {
    setState(() {
      _show = true;
      _delta = 50;
    });
  }

  void hideAppBar() {
    setState(() {
      _show = false;
      _delta = 20;
    });
  }

  void logOut() async {
    await state.sp.clear();
    state.user = null;
    state.token = null;
    state.sku = "";
    state.productName = "";
    Navigator.push(
        context, MaterialPageRoute(builder: (context) => const LoginPage()));
  }

  void search() async {
    if (state.user == null) {
      state.notifyToastDanger(context: context, message: "User must sign in.");
    } else {
      _pc.close();
      if (_searchController.text.isNotEmpty) {
        state.sku = _searchController.text.trim();
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const SerachResultPage(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Color backColor = Colors.white;
    _panelHeightOpen = MediaQuery.of(context).size.height * .35;
    TextStyle headerText = Theme.of(context).textTheme.headline4;
    return WillPopScope(
      onWillPop: () {},
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: backColor,
        appBar: _show
            ? AppBar(
                leading: Container(),
                title: GestureDetector(
                  onTap: () {
                    _pc.open();
                    hideAppBar();
                  },
                  child: Image.asset(
                    "assets/images/top_draw_icon.png",
                    fit: BoxFit.contain,
                    width: 25,
                    height: 25,
                  ),
                ),
                centerTitle: true,
                backgroundColor: Theme.of(context).primaryColor,
              )
            : PreferredSize(
                child: Container(),
                preferredSize: const Size(0.0, 0.0),
              ),
        body: SlidingUpPanel(
          slideDirection: SlideDirection.DOWN,
          maxHeight: _panelHeightOpen,
          minHeight: _panelHeightClosed,
          parallaxEnabled: true,
          parallaxOffset: 0.1,
          controller: _pc,
          isDraggable: false,
          color: Theme.of(context).primaryColor,
          panelBuilder: (sc) => _panel(sc),
          body: _body(),
          onPanelSlide: (double pos) {
            setState(() {
              _fabHeight = pos * (_panelHeightOpen - _panelHeightClosed) +
                  _initFabHeight;
              if (pos == 0.0) {
                _show = true;
              }
            });
          },
          header: (_pc.isAttached)
              ? (_pc.isPanelOpen)
                  ? Container(
                      width: MediaQuery.of(context).size.width,
                      padding: const EdgeInsets.only(bottom: 15),
                      margin: EdgeInsets.zero,
                      child: GestureDetector(
                        onTap: () {
                          _pc.close();
                          showAppBar();
                        },
                        child: Center(
                          child: Image.asset(
                            "assets/images/top_up_icon.png",
                            fit: BoxFit.contain,
                            width: 20,
                            height: 20,
                          ),
                        ),
                      ),
                    )
                  : const SizedBox(
                      height: 0,
                    )
              : const SizedBox(
                  height: 0,
                ),
        ),
      ),
    );
  }

  Widget _body() {
    return SafeArea(
      child: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.only(top: 10),
          height: MediaQuery.of(context).size.height - appHeight - _delta,
          width: MediaQuery.of(context).size.width,
          child: (status)
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    CircularProgressIndicator(
                        backgroundColor: Color.fromRGBO(255, 126, 0, 1.0),
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        strokeWidth: 2)
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    const SizedBox(
                      height: 10.0,
                    ),
                    Container(
                      padding: const EdgeInsets.only(left: 10, right: 10),
                      child: Text(
                        (state.productName.toString().isEmpty)
                            ? "Product Name"
                            : state.productName,
                        style: const TextStyle(
                          fontSize: 18,
                          color: Color.fromRGBO(165, 102, 48, 1),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(
                      height: 16,
                    ),
                    Container(
                      padding: const EdgeInsets.only(left: 10, right: 10),
                      child: Text(
                        'SKU : ${state.sku}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color.fromRGBO(165, 102, 48, 1),
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 10),
                      padding: const EdgeInsets.only(
                          left: 0, right: 0, top: 5, bottom: 5),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Container(
                            alignment: Alignment.center,
                            width: MediaQuery.of(context).size.width * 0.25,
                            padding: const EdgeInsets.only(left: 5),
                          ),
                          Container(
                            alignment: Alignment.center,
                            width: MediaQuery.of(context).size.width * 0.3,
                            padding: EdgeInsets.zero,
                            child: Text(
                              "Current Stock",
                              style: TextStyle(
                                fontSize: 16.0,
                                fontWeight: FontWeight.w300,
                                fontFamily: "OpenSans",
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "New Amount",
                                  style: TextStyle(
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.w300,
                                    fontFamily: "OpenSans",
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.only(bottom: 20),
                        width: MediaQuery.of(context).size.width,
                        // height: 50,
                        child: Column(
                          children: <Widget>[
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.zero,
                                child: SmartRefresher(
                                  controller: _refreshController,
                                  enablePullUp: true,
                                  enablePullDown: true,
                                  header: const WaterDropMaterialHeader(),
                                  child: (items.isEmpty)
                                      ? const Center(
                                          child: Text(
                                            "No data yet.",
                                            style: TextStyle(
                                              fontFamily: "OpenSans",
                                              fontSize: 16,
                                              color: Colors.black,
                                            ),
                                          ),
                                        )
                                      : SingleChildScrollView(
                                          child: Column(
                                            children: <Widget>[
                                              for (var item in items)
                                                Container(
                                                  child: StockItem(
                                                    data: item,
                                                  ),

                                                  width: MediaQuery.of(context)
                                                      .size
                                                      .width,
                                                  padding:
                                                      const EdgeInsets.only(
                                                    left: 15,
                                                    right: 15,
                                                    top: 15,
                                                  ),
                                                  // margin: EdgeInsets.only(bottom: 20),
                                                ),
                                            ],
                                          ),
                                        ),
                                  footer: CustomFooter(
                                    builder: (BuildContext context,
                                        LoadStatus mode) {
                                      Widget body;
                                      if (mode == LoadStatus.idle) {
                                        body = const Text("pull up load");
                                      } else if (mode == LoadStatus.loading) {
                                        body =
                                            const CupertinoActivityIndicator();
                                      } else if (mode == LoadStatus.failed) {
                                        body = const Text(
                                            "Load Failed!Click retry!");
                                      } else if (mode ==
                                          LoadStatus.canLoading) {
                                        body =
                                            const Text("release to load more");
                                      } else {
                                        body = const Text("No more Data");
                                      }
                                      // if (nextPage == null) {
                                      //   body = Text("");
                                      // }
                                      return SizedBox(
                                        height: 55.0,
                                        child: Center(child: body),
                                      );
                                    },
                                  ),
                                  onRefresh: () {
                                    setState(() {
                                      items = [];
                                    });
                                    getStockData();
                                    _refreshController.refreshCompleted();
                                  },
                                  onLoading: () {
                                    if (items.isEmpty) {
                                      _refreshController.loadNoData();
                                    } else {
                                      getStockData();
                                    }
                                    _refreshController.loadComplete();
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 30),
                            CartTotal(onTap: () async {
                              onStockSave();
                            })
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _panel(ScrollController sc) {
    return MediaQuery.removePadding(
      context: context,
      removeTop: true,
      child: ListView(
        padding: const EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: 0,
        ),
        controller: sc,
        children: <Widget>[
          const SizedBox(
            height: 24.0,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                state.user['username'],
                style: const TextStyle(
                  fontWeight: FontWeight.normal,
                  fontSize: 22.0,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 12.0,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              InkWell(
                onTap: () {
                  logOut();
                },
                child: Row(
                  children: const [
                    Icon(
                      Icons.logout,
                      color: Colors.white,
                      size: 24.0,
                    ),
                    SizedBox(
                      width: 5,
                    ),
                    Text(
                      "Sign out",
                      style: TextStyle(
                        fontWeight: FontWeight.normal,
                        fontSize: 22.0,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 12.0,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              InkWell(
                onTap: () {
                  _pc.close();
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const ScannerPage()));
                },
                child: Row(
                  children: const [
                    Icon(
                      Icons.scanner,
                      color: Colors.white,
                      size: 24.0,
                    ),
                    SizedBox(
                      width: 5,
                    ),
                    Text(
                      "Scanner",
                      style: TextStyle(
                        fontWeight: FontWeight.normal,
                        fontSize: 22.0,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 12.0,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: const <Widget>[
              Icon(
                Icons.search_rounded,
                color: Colors.white,
                size: 24.0,
              ),
              SizedBox(
                width: 5,
              ),
              Text(
                "Search by SKU",
                style: TextStyle(
                  fontWeight: FontWeight.normal,
                  fontSize: 22.0,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(
            height: 12.0,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  autofocus: false,
                  style: const TextStyle(color: Colors.black),
                  controller: _searchController,
                  keyboardType: TextInputType.text,
                  decoration: const InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    hintText: 'SKU',
                    hintStyle: TextStyle(
                      fontFamily: "Oepn-Sans",
                      fontSize: 15,
                      color: Colors.black,
                    ),
                    contentPadding:
                        EdgeInsets.only(left: 14.0, bottom: 8.0, top: 8.0),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                  ),
                ),
              ),
              Expanded(
                  flex: 1,
                  child: SearchButton(
                    onTap: () {
                      FocusScope.of(context).requestFocus(FocusNode());
                      search();
                    },
                    text: 'Search',
                  ))
            ],
          )
        ],
      ),
    );
  }
}
