import 'package:flutter/material.dart';
import 'dart:math';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:csv/csv.dart';
import 'dart:io' show Platform;

void main() {
  runApp(RPGDiceRoller());
}

class RollsHistory {
  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _localFile async {
    final path = await _localPath;
    return File('$path/rolls.txt');
  }

  Future<List<List<dynamic>>> getRollsHistory() async {
    try {
      final file = await _localFile;

      // Read the file
      final contents = await file.readAsString();
      final res = const CsvToListConverter().convert(contents);
      return res;
    } catch (e) {
      // If encountering an error, return 0
      return [[]];
    }
  }

  void writeRoll(roll) async {
    final file = await _localFile;

    final data = [
      [roll.calcSum(), roll.values]
    ];

    String csv = const ListToCsvConverter().convert(data) + "\r" + "\n";

    file.writeAsString(csv, mode: FileMode.append);
  }

  void clearStorage() async {
    final file = await _localFile;

    file.writeAsString("");
  }
}

final storage = new RollsHistory();

class Roll {
  List values = [];

  int calcSum() {
    int sum = 0;
    for (int i = 0; i < values.length; ++i) {
      sum += values[i];
    }
    return sum;
  }
}

class Dice {
  TextEditingController controller = new TextEditingController();
  int numDies = 0;
  bool isPressedMinus = false;
  bool isPressedPlus = false;

  void setDice() {
    if (this.controller.text == '') {
      numDies = 0;
    } else {
      numDies = int.parse(controller.text).abs();
    }
  }

  void init() {
    controller.addListener(setDice);
  }
}

class RPGDiceRoller extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RPG Dice Roller',
      home: DicePage(),
    );
  }
}

class DicePage extends StatefulWidget {
  @override
  _DicePageState createState() => _DicePageState();
}

List createDiceLabel(name) {
  List<Widget> widgets = [
    SizedBox(
      width: 20.0,
    ),
    FittedBox(
      fit: BoxFit.fitHeight,
      child: Text(
        name,
        style: TextStyle(
          letterSpacing: 2.0,
          fontFamily: 'Lato',
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 100,
        ),
      ),
    ),
    Spacer(),
  ];

  return widgets;
}

class _DicePageState extends State<DicePage> {
  final min = 0;
  final max = 99;

  // Array of Dies
  List<Dice> dies = List<Dice>.generate(8, (i) => new Dice());

  // Array of colors being used
  List colors = [
    Color(0xff992e2e),
    Color(0xffC73032),
    Color(0xffeb5b3b),
    Color(0xfff2bd29),
    Color(0xff09ba4a),
    Color(0xff207342),
    Color(0xff007a87),
    Color(0xff2a50a1),
    Color(0xff774099),
  ];

  // Text describing different dies user can use
  List dieTexts = ["d4", "d6", "d8", "d10", "d12", "d20", "d100", "+"];

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 8; ++i) {
      dies[i].init();
    }
  }

  int roll_total = 0;

  // calcRoll() calculates the roll_total
  void calcRoll() {
    List<int> dieValues = [4, 6, 8, 10, 12, 20, 100];
    Roll newRoll = new Roll();
    for (int i = 0; i < 7; ++i) {
      while (dies[i].numDies > 0) {
        newRoll.values.add((Random().nextInt(dieValues[i]) + 1));
        dies[i].numDies -= 1;
      }
    }

    newRoll.values.add(dies[7].numDies);
    dies[7].numDies = 0;
    roll_total = newRoll.calcSum();
    storage.writeRoll(newRoll);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.black,
        actions: <Widget>[
          GestureDetector(
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HistoryPage(),
                  ));
            },
            child: FittedBox(
              fit: BoxFit.fitHeight,
              child: Icon(
                Icons.history, // add custom icons also
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ColoredBox(
              color: colors[0],
              child: Row(
                children: new List.from(createDiceLabel(dieTexts[0]))
                  ..addAll([
                    Row(
                      children: [
                        GestureDetector(
                          child: IconButton(
                            // decreases num_d4 by 1
                            iconSize: 36.0,
                            icon: Icon(Icons.remove),
                            color: Colors.white,
                            onPressed: () {
                              setState(() {
                                if (dies[0].numDies <= min) {
                                  // prevent num_d4 from going < min
                                  dies[0].numDies = min;
                                } else {
                                  // if num_d4 is not min, subtract 1
                                  dies[0].numDies -= 1;
                                }
                                dies[0].controller.text =
                                    dies[0].numDies.toString();
                              });
                            },
                          ),
                          onLongPressStart:
                              (LongPressStartDetails details) async {
                            dies[0].isPressedMinus = true;
                            do {
                              if (dies[0].numDies <= min) {
                                // prevent num_d4 from going < min
                                dies[0].numDies = min;
                              } else {
                                // if num_d4 is not min, subtract 1
                                dies[0].numDies -= 1;
                              }
                              setState(() {
                                dies[0].controller.text =
                                    dies[0].numDies.toString();
                              });
                              await Future.delayed(Duration(milliseconds: 150));
                            } while (dies[0].isPressedMinus);
                          },
                          onLongPressEnd: (LongPressEndDetails details) {
                            setState(() {
                              dies[0].isPressedMinus = false;
                            });
                          },
                        ),
                        SizedBox(
                          width: 80.0,
                          child: TextField(
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(2),
                              FilteringTextInputFormatter.allow(
                                  RegExp("[0,1,2,3,4,5,6,7,8,9]")),
                            ],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.black,
                              fontFamily: 'Lato',
                            ),
                            controller: dies[0].controller,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  width: 2.0,
                                  color: Colors.white,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  width: 2.0,
                                  color: Colors.white,
                                ),
                              ),
                              fillColor: Colors.white,
                              filled: true,
                              hintText: '0',
                            ),
                          ),
                        ),
                        GestureDetector(
                          child: IconButton(
                            // increases num_d4 by 1
                            iconSize: 36.0,
                            icon: Icon(Icons.add),
                            color: Colors.white,
                            onPressed: () {
                              setState(() {
                                if (dies[0].numDies >= max) {
                                  // prevent num_d4 going over max
                                  dies[0].numDies = max;
                                } else {
                                  // if num_d4 is not at max,
                                  dies[0].numDies += 1;
                                }
                                dies[0].controller.text =
                                    dies[0].numDies.toString();
                              });
                            },
                          ),
                          onLongPressStart:
                              (LongPressStartDetails details) async {
                            dies[0].isPressedPlus = true;
                            do {
                              if (dies[0].numDies >= max) {
                                // prevent num_d4 going over max
                                dies[0].numDies = max;
                              } else {
                                // if num_d4 is not at max,
                                dies[0].numDies += 1;
                              }
                              setState(() {
                                dies[0].controller.text =
                                    dies[0].numDies.toString();
                              });
                              await Future.delayed(Duration(milliseconds: 150));
                            } while (dies[0].isPressedPlus);
                          },
                          onLongPressEnd: (LongPressEndDetails details) {
                            setState(() {
                              dies[0].isPressedPlus = false;
                            });
                          },
                        ),
                      ],
                    ),
                    SizedBox(
                      width: 8.0,
                    )
                  ]),
              ),
            ),
          ),
          Expanded(
            child: ColoredBox(
              color: colors[1],
              child: Row(
                children: new List.from(createDiceLabel(dieTexts[1]))
                  ..addAll([
                    Row(
                      children: [
                        GestureDetector(
                          child: IconButton(
                            // decreases num_d4 by 1
                            iconSize: 36.0,
                            icon: Icon(Icons.remove),
                            color: Colors.white,
                            onPressed: () {
                              setState(() {
                                if (dies[1].numDies <= min) {
                                  // prevent num_d4 from going < min
                                  dies[1].numDies = min;
                                } else {
                                  // if num_d4 is not min, subtract 1
                                  dies[1].numDies -= 1;
                                }
                                dies[1].controller.text =
                                    dies[1].numDies.toString();
                              });
                            },
                          ),
                          onLongPressStart:
                              (LongPressStartDetails details) async {
                            dies[1].isPressedMinus = true;
                            do {
                              if (dies[1].numDies <= min) {
                                // prevent num_d4 from going < min
                                dies[1].numDies = min;
                              } else {
                                // if num_d4 is not min, subtract 1
                                dies[1].numDies -= 1;
                              }
                              setState(() {
                                dies[1].controller.text =
                                    dies[1].numDies.toString();
                              });
                              await Future.delayed(Duration(milliseconds: 150));
                            } while (dies[1].isPressedMinus);
                          },
                          onLongPressEnd: (LongPressEndDetails details) {
                            setState(() {
                              dies[1].isPressedMinus = false;
                            });
                          },
                        ),
                        SizedBox(
                          width: 80.0,
                          child: TextField(
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(2),
                              FilteringTextInputFormatter.allow(
                                  RegExp("[0,1,2,3,4,5,6,7,8,9]")),
                            ],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.black,
                              fontFamily: 'Lato',
                            ),
                            controller: dies[1].controller,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  width: 2.0,
                                  color: Colors.white,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  width: 2.0,
                                  color: Colors.white,
                                ),
                              ),
                              fillColor: Colors.white,
                              filled: true,
                              hintText: '0',
                            ),
                          ),
                        ),
                        GestureDetector(
                          child: IconButton(
                            // increases num_d4 by 1
                            iconSize: 36.0,
                            icon: Icon(Icons.add),
                            color: Colors.white,
                            onPressed: () {
                              setState(() {
                                if (dies[1].numDies >= max) {
                                  // prevent num_d4 going over max
                                  dies[1].numDies = max;
                                } else {
                                  // if num_d4 is not at max,
                                  dies[1].numDies += 1;
                                }
                                dies[1].controller.text =
                                    dies[1].numDies.toString();
                              });
                            },
                          ),
                          onLongPressStart:
                              (LongPressStartDetails details) async {
                            dies[1].isPressedPlus = true;
                            do {
                              if (dies[1].numDies >= max) {
                                // prevent num_d4 going over max
                                dies[1].numDies = max;
                              } else {
                                // if num_d4 is not at max,
                                dies[1].numDies += 1;
                              }
                              setState(() {
                                dies[1].controller.text =
                                    dies[1].numDies.toString();
                              });
                              await Future.delayed(Duration(milliseconds: 150));
                            } while (dies[1].isPressedPlus);
                          },
                          onLongPressEnd: (LongPressEndDetails details) {
                            setState(() {
                              dies[1].isPressedPlus = false;
                            });
                          },
                        ),
                      ],
                    ),
                    SizedBox(
                      width: 8.0,
                    )
                  ]),
              ),
            ),
          ),
          Expanded(
            child: ColoredBox(
              color: colors[2],
              child: Row(
                children: new List.from(createDiceLabel(dieTexts[2]))
                  ..addAll([
                    Row(
                      children: [
                        GestureDetector(
                          child: IconButton(
                            // decreases num_d4 by 1
                            iconSize: 36.0,
                            icon: Icon(Icons.remove),
                            color: Colors.white,
                            onPressed: () {
                              setState(() {
                                if (dies[2].numDies <= min) {
                                  // prevent num_d4 from going < min
                                  dies[2].numDies = min;
                                } else {
                                  // if num_d4 is not min, subtract 1
                                  dies[2].numDies -= 1;
                                }
                                dies[2].controller.text =
                                    dies[2].numDies.toString();
                              });
                            },
                          ),
                          onLongPressStart:
                              (LongPressStartDetails details) async {
                            dies[2].isPressedMinus = true;
                            do {
                              if (dies[2].numDies <= min) {
                                // prevent num_d4 from going < min
                                dies[2].numDies = min;
                              } else {
                                // if num_d4 is not min, subtract 1
                                dies[2].numDies -= 1;
                              }
                              setState(() {
                                dies[2].controller.text =
                                    dies[2].numDies.toString();
                              });
                              await Future.delayed(Duration(milliseconds: 150));
                            } while (dies[2].isPressedMinus);
                          },
                          onLongPressEnd: (LongPressEndDetails details) {
                            setState(() {
                              dies[2].isPressedMinus = false;
                            });
                          },
                        ),
                        SizedBox(
                          width: 80.0,
                          child: TextField(
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(2),
                              FilteringTextInputFormatter.allow(
                                  RegExp("[0,1,2,3,4,5,6,7,8,9]")),
                            ],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.black,
                              fontFamily: 'Lato',
                            ),
                            controller: dies[2].controller,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  width: 2.0,
                                  color: Colors.white,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  width: 2.0,
                                  color: Colors.white,
                                ),
                              ),
                              fillColor: Colors.white,
                              filled: true,
                              hintText: '0',
                            ),
                          ),
                        ),
                        GestureDetector(
                          child: IconButton(
                            // increases num_d4 by 1
                            iconSize: 36.0,
                            icon: Icon(Icons.add),
                            color: Colors.white,
                            onPressed: () {
                              setState(() {
                                if (dies[2].numDies >= max) {
                                  // prevent num_d4 going over max
                                  dies[2].numDies = max;
                                } else {
                                  // if num_d4 is not at max,
                                  dies[2].numDies += 1;
                                }
                                dies[2].controller.text =
                                    dies[2].numDies.toString();
                              });
                            },
                          ),
                          onLongPressStart:
                              (LongPressStartDetails details) async {
                            dies[2].isPressedPlus = true;
                            do {
                              if (dies[2].numDies >= max) {
                                // prevent num_d4 going over max
                                dies[2].numDies = max;
                              } else {
                                // if num_d4 is not at max,
                                dies[2].numDies += 1;
                              }
                              setState(() {
                                dies[2].controller.text =
                                    dies[2].numDies.toString();
                              });
                              await Future.delayed(Duration(milliseconds: 150));
                            } while (dies[2].isPressedPlus);
                          },
                          onLongPressEnd: (LongPressEndDetails details) {
                            setState(() {
                              dies[2].isPressedPlus = false;
                            });
                          },
                        ),
                      ],
                    ),
                    SizedBox(
                      width: 8.0,
                    )
                  ]),
              ),
            ),
          ),
          Expanded(
            child: ColoredBox(
              color: colors[3],
              child: Row(
                children: new List.from(createDiceLabel(dieTexts[3]))
                  ..addAll([
                    Row(
                      children: [
                        GestureDetector(
                          child: IconButton(
                            // decreases num_d4 by 1
                            iconSize: 36.0,
                            icon: Icon(Icons.remove),
                            color: Colors.white,
                            onPressed: () {
                              setState(() {
                                if (dies[3].numDies <= min) {
                                  // prevent num_d4 from going < min
                                  dies[3].numDies = min;
                                } else {
                                  // if num_d4 is not min, subtract 1
                                  dies[3].numDies -= 1;
                                }
                                dies[3].controller.text =
                                    dies[3].numDies.toString();
                              });
                            },
                          ),
                          onLongPressStart:
                              (LongPressStartDetails details) async {
                            dies[3].isPressedMinus = true;
                            do {
                              if (dies[3].numDies <= min) {
                                // prevent num_d4 from going < min
                                dies[3].numDies = min;
                              } else {
                                // if num_d4 is not min, subtract 1
                                dies[3].numDies -= 1;
                              }
                              setState(() {
                                dies[3].controller.text =
                                    dies[3].numDies.toString();
                              });
                              await Future.delayed(Duration(milliseconds: 150));
                            } while (dies[3].isPressedMinus);
                          },
                          onLongPressEnd: (LongPressEndDetails details) {
                            setState(() {
                              dies[3].isPressedMinus = false;
                            });
                          },
                        ),
                        SizedBox(
                          width: 80.0,
                          child: TextField(
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(2),
                              FilteringTextInputFormatter.allow(
                                  RegExp("[0,1,2,3,4,5,6,7,8,9]")),
                            ],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.black,
                              fontFamily: 'Lato',
                            ),
                            controller: dies[3].controller,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  width: 2.0,
                                  color: Colors.white,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  width: 2.0,
                                  color: Colors.white,
                                ),
                              ),
                              fillColor: Colors.white,
                              filled: true,
                              hintText: '0',
                            ),
                          ),
                        ),
                        GestureDetector(
                          child: IconButton(
                            // increases num_d4 by 1
                            iconSize: 36.0,
                            icon: Icon(Icons.add),
                            color: Colors.white,
                            onPressed: () {
                              setState(() {
                                if (dies[3].numDies >= max) {
                                  // prevent num_d4 going over max
                                  dies[3].numDies = max;
                                } else {
                                  // if num_d4 is not at max,
                                  dies[3].numDies += 1;
                                }
                                dies[3].controller.text =
                                    dies[3].numDies.toString();
                              });
                            },
                          ),
                          onLongPressStart:
                              (LongPressStartDetails details) async {
                            dies[3].isPressedPlus = true;
                            do {
                              if (dies[3].numDies >= max) {
                                // prevent num_d4 going over max
                                dies[3].numDies = max;
                              } else {
                                // if num_d4 is not at max,
                                dies[3].numDies += 1;
                              }
                              setState(() {
                                dies[3].controller.text =
                                    dies[3].numDies.toString();
                              });
                              await Future.delayed(Duration(milliseconds: 150));
                            } while (dies[3].isPressedPlus);
                          },
                          onLongPressEnd: (LongPressEndDetails details) {
                            setState(() {
                              dies[3].isPressedPlus = false;
                            });
                          },
                        ),
                      ],
                    ),
                    SizedBox(
                      width: 8.0,
                    )
                  ]),
              ),
            ),
          ),
          Expanded(
            child: ColoredBox(
              color: colors[4],
              child: Row(
                children: new List.from(createDiceLabel(dieTexts[4]))
                  ..addAll([
                    Row(
                      children: [
                        GestureDetector(
                          child: IconButton(
                            // decreases num_d4 by 1
                            iconSize: 36.0,
                            icon: Icon(Icons.remove),
                            color: Colors.white,
                            onPressed: () {
                              setState(() {
                                if (dies[4].numDies <= min) {
                                  // prevent num_d4 from going < min
                                  dies[4].numDies = min;
                                } else {
                                  // if num_d4 is not min, subtract 1
                                  dies[4].numDies -= 1;
                                }
                                dies[4].controller.text =
                                    dies[4].numDies.toString();
                              });
                            },
                          ),
                          onLongPressStart:
                              (LongPressStartDetails details) async {
                            dies[4].isPressedMinus = true;
                            do {
                              if (dies[4].numDies <= min) {
                                // prevent num_d4 from going < min
                                dies[4].numDies = min;
                              } else {
                                // if num_d4 is not min, subtract 1
                                dies[4].numDies -= 1;
                              }
                              setState(() {
                                dies[4].controller.text =
                                    dies[4].numDies.toString();
                              });
                              await Future.delayed(Duration(milliseconds: 150));
                            } while (dies[4].isPressedMinus);
                          },
                          onLongPressEnd: (LongPressEndDetails details) {
                            setState(() {
                              dies[4].isPressedMinus = false;
                            });
                          },
                        ),
                        SizedBox(
                          width: 80.0,
                          child: TextField(
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(2),
                              FilteringTextInputFormatter.allow(
                                  RegExp("[0,1,2,3,4,5,6,7,8,9]")),
                            ],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.black,
                              fontFamily: 'Lato',
                            ),
                            controller: dies[4].controller,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  width: 2.0,
                                  color: Colors.white,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  width: 2.0,
                                  color: Colors.white,
                                ),
                              ),
                              fillColor: Colors.white,
                              filled: true,
                              hintText: '0',
                            ),
                          ),
                        ),
                        GestureDetector(
                          child: IconButton(
                            // increases num_d4 by 1
                            iconSize: 36.0,
                            icon: Icon(Icons.add),
                            color: Colors.white,
                            onPressed: () {
                              setState(() {
                                if (dies[4].numDies >= max) {
                                  // prevent num_d4 going over max
                                  dies[4].numDies = max;
                                } else {
                                  // if num_d4 is not at max,
                                  dies[4].numDies += 1;
                                }
                                dies[4].controller.text =
                                    dies[4].numDies.toString();
                              });
                            },
                          ),
                          onLongPressStart:
                              (LongPressStartDetails details) async {
                            dies[4].isPressedPlus = true;
                            do {
                              if (dies[4].numDies >= max) {
                                // prevent num_d4 going over max
                                dies[4].numDies = max;
                              } else {
                                // if num_d4 is not at max,
                                dies[4].numDies += 1;
                              }
                              setState(() {
                                dies[4].controller.text =
                                    dies[4].numDies.toString();
                              });
                              await Future.delayed(Duration(milliseconds: 150));
                            } while (dies[4].isPressedPlus);
                          },
                          onLongPressEnd: (LongPressEndDetails details) {
                            setState(() {
                              dies[4].isPressedPlus = false;
                            });
                          },
                        ),
                      ],
                    ),
                    SizedBox(
                      width: 8.0,
                    )
                  ]),
              ),
            ),
          ),
          Expanded(
            child: ColoredBox(
              color: colors[5],
              child: Row(
                children: new List.from(createDiceLabel(dieTexts[5]))
                  ..addAll([
                    Row(
                      children: [
                        GestureDetector(
                          child: IconButton(
                            // decreases num_d4 by 1
                            iconSize: 36.0,
                            icon: Icon(Icons.remove),
                            color: Colors.white,
                            onPressed: () {
                              setState(() {
                                if (dies[5].numDies <= min) {
                                  // prevent num_d4 from going < min
                                  dies[5].numDies = min;
                                } else {
                                  // if num_d4 is not min, subtract 1
                                  dies[5].numDies -= 1;
                                }
                                dies[5].controller.text =
                                    dies[5].numDies.toString();
                              });
                            },
                          ),
                          onLongPressStart:
                              (LongPressStartDetails details) async {
                            dies[5].isPressedMinus = true;
                            do {
                              if (dies[5].numDies <= min) {
                                // prevent num_d4 from going < min
                                dies[5].numDies = min;
                              } else {
                                // if num_d4 is not min, subtract 1
                                dies[5].numDies -= 1;
                              }
                              setState(() {
                                dies[5].controller.text =
                                    dies[5].numDies.toString();
                              });
                              await Future.delayed(Duration(milliseconds: 150));
                            } while (dies[5].isPressedMinus);
                          },
                          onLongPressEnd: (LongPressEndDetails details) {
                            setState(() {
                              dies[5].isPressedMinus = false;
                            });
                          },
                        ),
                        SizedBox(
                          width: 80.0,
                          child: TextField(
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(2),
                              FilteringTextInputFormatter.allow(
                                  RegExp("[0,1,2,3,4,5,6,7,8,9]")),
                            ],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.black,
                              fontFamily: 'Lato',
                            ),
                            controller: dies[5].controller,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  width: 2.0,
                                  color: Colors.white,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  width: 2.0,
                                  color: Colors.white,
                                ),
                              ),
                              fillColor: Colors.white,
                              filled: true,
                              hintText: '0',
                            ),
                          ),
                        ),
                        GestureDetector(
                          child: IconButton(
                            // increases num_d4 by 1
                            iconSize: 36.0,
                            icon: Icon(Icons.add),
                            color: Colors.white,
                            onPressed: () {
                              setState(() {
                                if (dies[5].numDies >= max) {
                                  // prevent num_d4 going over max
                                  dies[5].numDies = max;
                                } else {
                                  // if num_d4 is not at max,
                                  dies[5].numDies += 1;
                                }
                                dies[5].controller.text =
                                    dies[5].numDies.toString();
                              });
                            },
                          ),
                          onLongPressStart:
                              (LongPressStartDetails details) async {
                            dies[5].isPressedPlus = true;
                            do {
                              if (dies[5].numDies >= max) {
                                // prevent num_d4 going over max
                                dies[5].numDies = max;
                              } else {
                                // if num_d4 is not at max,
                                dies[5].numDies += 1;
                              }
                              setState(() {
                                dies[5].controller.text =
                                    dies[5].numDies.toString();
                              });
                              await Future.delayed(Duration(milliseconds: 150));
                            } while (dies[5].isPressedPlus);
                          },
                          onLongPressEnd: (LongPressEndDetails details) {
                            setState(() {
                              dies[5].isPressedPlus = false;
                            });
                          },
                        ),
                      ],
                    ),
                    SizedBox(
                      width: 8.0,
                    )
                  ]),
              ),
            ),
          ),
          Expanded(
            child: ColoredBox(
              color: colors[6],
              child: Row(
                children: new List.from(createDiceLabel(dieTexts[6]))
                  ..addAll([
                    Row(
                      children: [
                        GestureDetector(
                          child: IconButton(
                            // decreases num_d4 by 1
                            iconSize: 36.0,
                            icon: Icon(Icons.remove),
                            color: Colors.white,
                            onPressed: () {
                              setState(() {
                                if (dies[6].numDies <= min) {
                                  // prevent num_d4 from going < min
                                  dies[6].numDies = min;
                                } else {
                                  // if num_d4 is not min, subtract 1
                                  dies[6].numDies -= 1;
                                }
                                dies[6].controller.text =
                                    dies[6].numDies.toString();
                              });
                            },
                          ),
                          onLongPressStart:
                              (LongPressStartDetails details) async {
                            dies[6].isPressedMinus = true;
                            do {
                              if (dies[6].numDies <= min) {
                                // prevent num_d4 from going < min
                                dies[6].numDies = min;
                              } else {
                                // if num_d4 is not min, subtract 1
                                dies[6].numDies -= 1;
                              }
                              setState(() {
                                dies[6].controller.text =
                                    dies[6].numDies.toString();
                              });
                              await Future.delayed(Duration(milliseconds: 150));
                            } while (dies[6].isPressedMinus);
                          },
                          onLongPressEnd: (LongPressEndDetails details) {
                            setState(() {
                              dies[6].isPressedMinus = false;
                            });
                          },
                        ),
                        SizedBox(
                          width: 80.0,
                          child: TextField(
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(2),
                              FilteringTextInputFormatter.allow(
                                  RegExp("[0,1,2,3,4,5,6,7,8,9]")),
                            ],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.black,
                              fontFamily: 'Lato',
                            ),
                            controller: dies[6].controller,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  width: 2.0,
                                  color: Colors.white,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  width: 2.0,
                                  color: Colors.white,
                                ),
                              ),
                              fillColor: Colors.white,
                              filled: true,
                              hintText: '0',
                            ),
                          ),
                        ),
                        GestureDetector(
                          child: IconButton(
                            // increases num_d4 by 1
                            iconSize: 36.0,
                            icon: Icon(Icons.add),
                            color: Colors.white,
                            onPressed: () {
                              setState(() {
                                if (dies[6].numDies >= max) {
                                  // prevent num_d4 going over max
                                  dies[6].numDies = max;
                                } else {
                                  // if num_d4 is not at max,
                                  dies[6].numDies += 1;
                                }
                                dies[6].controller.text =
                                    dies[6].numDies.toString();
                              });
                            },
                          ),
                          onLongPressStart:
                              (LongPressStartDetails details) async {
                            dies[6].isPressedPlus = true;
                            do {
                              if (dies[6].numDies >= max) {
                                // prevent num_d4 going over max
                                dies[6].numDies = max;
                              } else {
                                // if num_d4 is not at max,
                                dies[6].numDies += 1;
                              }
                              setState(() {
                                dies[6].controller.text =
                                    dies[6].numDies.toString();
                              });
                              await Future.delayed(Duration(milliseconds: 150));
                            } while (dies[6].isPressedPlus);
                          },
                          onLongPressEnd: (LongPressEndDetails details) {
                            setState(() {
                              dies[6].isPressedPlus = false;
                            });
                          },
                        ),
                      ],
                    ),
                    SizedBox(
                      width: 8.0,
                    )
                  ]),
              ),
            ),
          ),
          Expanded(
            child: ColoredBox(
              color: colors[7],
              child: Row(
                children: new List.from(createDiceLabel(dieTexts[7]))
                  ..addAll([
                    Row(
                      children: [
                        GestureDetector(
                          child: IconButton(
                            // decreases num_d4 by 1
                            iconSize: 36.0,
                            icon: Icon(Icons.remove),
                            color: Colors.white,
                            onPressed: () {
                              setState(() {
                                if (dies[7].numDies <= min) {
                                  // prevent num_d4 from going < min
                                  dies[7].numDies = min;
                                } else {
                                  // if num_d4 is not min, subtract 1
                                  dies[7].numDies -= 1;
                                }
                                dies[7].controller.text =
                                    dies[7].numDies.toString();
                              });
                            },
                          ),
                          onLongPressStart:
                              (LongPressStartDetails details) async {
                            dies[7].isPressedMinus = true;
                            do {
                              if (dies[7].numDies <= min) {
                                // prevent num_d4 from going < min
                                dies[7].numDies = min;
                              } else {
                                // if num_d4 is not min, subtract 1
                                dies[7].numDies -= 1;
                              }
                              setState(() {
                                dies[7].controller.text =
                                    dies[7].numDies.toString();
                              });
                              await Future.delayed(Duration(milliseconds: 150));
                            } while (dies[7].isPressedMinus);
                          },
                          onLongPressEnd: (LongPressEndDetails details) {
                            setState(() {
                              dies[7].isPressedMinus = false;
                            });
                          },
                        ),
                        SizedBox(
                          width: 80.0,
                          child: TextField(
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(2),
                              FilteringTextInputFormatter.allow(
                                  RegExp("[0,1,2,3,4,5,6,7,8,9]")),
                            ],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.black,
                              fontFamily: 'Lato',
                            ),
                            controller: dies[7].controller,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  width: 2.0,
                                  color: Colors.white,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(
                                  width: 2.0,
                                  color: Colors.white,
                                ),
                              ),
                              fillColor: Colors.white,
                              filled: true,
                              hintText: '0',
                            ),
                          ),
                        ),
                        GestureDetector(
                          child: IconButton(
                            // increases num_d4 by 1
                            iconSize: 36.0,
                            icon: Icon(Icons.add),
                            color: Colors.white,
                            onPressed: () {
                              setState(() {
                                if (dies[7].numDies >= max) {
                                  // prevent num_d4 going over max
                                  dies[7].numDies = max;
                                } else {
                                  // if num_d4 is not at max,
                                  dies[7].numDies += 1;
                                }
                                dies[7].controller.text =
                                    dies[7].numDies.toString();
                              });
                            },
                          ),
                          onLongPressStart:
                              (LongPressStartDetails details) async {
                            dies[7].isPressedPlus = true;
                            do {
                              if (dies[7].numDies >= max) {
                                // prevent num_d4 going over max
                                dies[7].numDies = max;
                              } else {
                                // if num_d4 is not at max,
                                dies[7].numDies += 1;
                              }
                              setState(() {
                                dies[7].controller.text =
                                    dies[7].numDies.toString();
                              });
                              await Future.delayed(Duration(milliseconds: 150));
                            } while (dies[7].isPressedPlus);
                          },
                          onLongPressEnd: (LongPressEndDetails details) {
                            setState(() {
                              dies[7].isPressedPlus = false;
                            });
                          },
                        ),
                      ],
                    ),
                    SizedBox(
                      width: 8.0,
                    )
                  ]),
              ),
            ),
          ),
          Expanded(
            child: Container(
              color: colors[8],
              child: TextButton(
                onPressed: () {
                  calcRoll();
                  showCupertinoDialog(
                      context: context,
                      builder: (BuildContext context) {
                        if (Platform.isIOS) {
                          return CupertinoAlertDialog(
                            title: Text('Your Roll'),
                            content: Text('$roll_total'),
                            actions: [
                              FlatButton(
                                child: Text('Roll Again'),
                                onPressed: () {
                                  setState(() {
                                    roll_total = 0;
                                    for (int i = 0; i < 8; ++i) {
                                      dies[i].controller.text = "";
                                    }
                                  });
                                  Navigator.pop(context);
                                },
                              )
                            ],
                          );
                        } else {
                          return AlertDialog(
                            title: Text('Your Roll'),
                            content: Text('$roll_total'),
                            actions: [
                              FlatButton(
                                child: Text('Roll Again'),
                                onPressed: () {
                                  setState(() {
                                    roll_total = 0;
                                    for (int i = 0; i < 8; ++i) {
                                      dies[i].controller.text = "";
                                    }
                                  });
                                  Navigator.pop(context);
                                },
                              )
                            ],
                          );
                        }
                      });
                },
                child: ColoredBox(
                  color: colors[8],
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FittedBox(
                        fit: BoxFit.fitHeight,
                        child: Text(
                          'ROLL DIES',
                          style: TextStyle(
                            letterSpacing: 2.0,
                            fontFamily: 'Lato',
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 100,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class HistoryPage extends StatefulWidget {
  HistoryPage({Key key, this.storage}) : super(key: key);
  final RollsHistory storage;

  @override
  _HistoryPageState createState() => _HistoryPageState();
}

Future<List<List<dynamic>>> getPrevRolls() {
  return storage.getRollsHistory();
}

Widget displayHistoryData(history) {
  if (history.length == 0) {
    return Center(
      child: Text(
        "History",
        style: TextStyle(
          letterSpacing: 2.0,
          fontFamily: 'Lato',
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 30,
        ),
      ),
    );
  } else {
    List<Widget> children = [];
    for (int i = history.length - 1; i >= 0; i -= 1) {
      Widget newHistoryBar = Container(
        height: 60,
        decoration: BoxDecoration(
          color: Color(0xff4a4a4a),
          border: Border.all(width: 2.0, color: Colors.black),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 20.0,
            ),
            FittedBox(
              fit: BoxFit.fitHeight,
              child: Text(
                history[i][0].toString(),
                style: TextStyle(
                  letterSpacing: 2.0,
                  fontFamily: 'Lato',
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 100,
                ),
              ),
            ),
          ],
        ),
      );
      children.add(newHistoryBar);
    }
    return ListView(
      children: children,
    );
  }
}

class _HistoryPageState extends State<HistoryPage> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: getPrevRolls(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return Scaffold(
              appBar: AppBar(
                backgroundColor: Colors.black,
              ),
              body: Text("ERROR"),
            );
          } else if (snapshot.hasData) {
            return Scaffold(
                appBar: AppBar(
                  backgroundColor: Colors.black,
                  actions: <Widget>[
                    GestureDetector(
                      onTap: () {
                        storage.clearStorage();
                        setState(() {});
                      },
                      child: FittedBox(
                        fit: BoxFit.fitHeight,
                        child: Icon(
                          Icons.delete,
                        ),
                      ),
                    )
                  ],
                ),
                body: displayHistoryData(snapshot.data));
          }
        }
        return Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.black,
          ),
          body: Text("Loading"),
        );
      },
    );
  }
}
