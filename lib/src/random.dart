import 'dart:math';

// T getRandomNumber<T>({T min, T max}){
// 	var random = Random();
// 	return min + random.nextInt(max-min);
// }

int getRandomNumber({int min=0, int max=10000}){
	var random = Random();
	return min + random.nextInt(max-min);
}