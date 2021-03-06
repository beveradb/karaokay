import 'dart:async';

import 'package:flutter/material.dart';
import 'package:karaokay/services/auth.dart';
import 'package:karaokay/widgets/page_dragger.dart';
import 'package:karaokay/widgets/page_reveal.dart';
import 'package:karaokay/widgets/pager_indicator.dart';
import 'package:karaokay/widgets/pages.dart';

class Landing extends StatefulWidget {
  @override
  _LandingPageState createState() => new _LandingPageState();
}

class _LandingPageState extends State<Landing> with TickerProviderStateMixin {
  final AuthService auth = AuthService();

  StreamController<SlideUpdate> slideUpdateStream;
  AnimatedPageDragger animatedPageDragger;

  int activeIndex = 0;

  SlideDirection slideDirection = SlideDirection.none;
  int nextPageIndex = 0;

  double slidePercent = 0.0;

  _LandingPageState() {
    slideUpdateStream = new StreamController<SlideUpdate>();

    slideUpdateStream.stream.listen((SlideUpdate event) {
      setState(() {
        if (event.updateType == UpdateType.dragging) {
          slideDirection = event.direction;
          slidePercent = event.slidePercent;

          if (slideDirection == SlideDirection.leftToRight) {
            nextPageIndex = activeIndex - 1;
          } else if (slideDirection == SlideDirection.rightToLeft) {
            nextPageIndex = activeIndex + 1;
          } else {
            nextPageIndex = activeIndex;
          }
        } else if (event.updateType == UpdateType.doneDragging) {
          if (slidePercent > 0.5) {
            animatedPageDragger = new AnimatedPageDragger(
              slideDirection: slideDirection,
              transitionGoal: TransitionGoal.open,
              slidePercent: slidePercent,
              slideUpdateStream: slideUpdateStream,
              vsync: this,
            );
          } else {
            animatedPageDragger = new AnimatedPageDragger(
              slideDirection: slideDirection,
              transitionGoal: TransitionGoal.close,
              slidePercent: slidePercent,
              slideUpdateStream: slideUpdateStream,
              vsync: this,
            );

            nextPageIndex = activeIndex;
          }

          animatedPageDragger.run();
        } else if (event.updateType == UpdateType.animating) {
          slideDirection = event.direction;
          slidePercent = event.slidePercent;
        } else if (event.updateType == UpdateType.doneAnimating) {
          activeIndex = nextPageIndex;

          slideDirection = SlideDirection.none;
          slidePercent = 0.0;

          animatedPageDragger.dispose();
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      body: new Column(
        children: <Widget>[
          new Expanded(
            child: new Stack(
              children: [
                new Page(
                  viewModel: pages[activeIndex],
                  percentVisible: 1.0,
                ),
                new PageReveal(
                  revealPercent: slidePercent,
                  child: new Page(
                    viewModel: pages[nextPageIndex],
                    percentVisible: slidePercent,
                  ),
                ),
                new PagerIndicator(
                  viewModel: new PagerIndicatorViewModel(
                    pages,
                    activeIndex,
                    slideDirection,
                    slidePercent,
                  ),
                ),
                new PageDragger(
                  canDragLeftToRight: activeIndex > 0,
                  canDragRightToLeft: activeIndex < pages.length - 1,
                  slideUpdateStream: this.slideUpdateStream,
                )
              ],
            ),
            flex: 5,
          ),
          new Expanded(
            child: new Container(
              decoration: const BoxDecoration(color: Colors.grey),
              child: new Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  new Icon(Icons.arrow_forward, size: 50.0),
                  RaisedButton(
                    child: Text('Log in with Google'),
                    onPressed: auth.handleGoogleSignin,
                  ),
                  new Icon(Icons.star, size: 50.0),
                ],
              ),
            ),
            flex: 1,
          ),
        ],
      ),
    );
  }
}
