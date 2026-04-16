import 'package:flutter/material.dart';
import '../components/square_button.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment:MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            //  SizedBox(height: 100,),
            Expanded(
              child: GridView.count(crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16,
                children: [

                  SquareButton(
                    icon: Icons.assured_workload,
                    onPressed: () {
                    },
                    title: 'Assets',
                  ),SquareButton(
                    icon: Icons.sync,
                    onPressed: () {
                    },
                    title: 'Sync Now',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );

  }
}
