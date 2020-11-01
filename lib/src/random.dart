import 'dart:math';

int getRandomNumber({int min=0, int max=10000}){
	var random = Random();
	return min + random.nextInt(max-min);
}