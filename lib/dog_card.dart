
import 'package:flutter/cupertino.dart';
import 'dog_model.dart';

class DogCard extends StatefulWidget {
  final Dog dog;

  const DogCard(this.dog, {super.key});

  @override
  _DogCardState createState() => _DogCardState(dog);
}

class _DogCardState extends State<DogCard> {
  Dog dog;

  _DogCardState(this.dog);

  @override
  Widget build(BuildContext context){
    print("render URL : $renderUrl");
    Widget dogImg = dogImage;
    Stack child = Stack(children: [],);
    return Container(
      height: 115.0,
      child: Stack(
        children:<Widget> [
          Positioned(child: dogImg)
        ],
      ),
    );
  }

  String renderUrl = "";

  Widget get dogImage {

    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        image: DecorationImage(
          fit: BoxFit.cover,
          image: NetworkImage("https://images.dog.ceo/breeds/terrier-norwich/n02094258_992.jpg")
        )
      ),
    );
  }

  @override
  void initState(){
    super.initState();
    renderDogPic();
  }

  void renderDogPic() async {
    await dog.getImageUrl();
    print("image url : ${dog.imageUrl}");
    if(mounted) {
      setState(() {
        renderUrl = dog.imageUrl;
      });
    }
  }
}