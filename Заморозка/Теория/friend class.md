#ООП 
это класс для того чтобы можно было использовать один метод в разных классах

как он работает надо сначала написать сам класс
и положить его в private 

потом надо 

#include <iostream>
#include <vector>
#include <string>
using namespace std;



class Apple;//показываем компилятору что у нас есть класс Apple , чтобы он мог его сконпилировать с другим классом


class Human
{
public:
    void takeAple(Apple& apple);
   
};

    class Apple {
    public:

        Apple(int weight, bool food) {
        }
    private:
        int weight = 0;
        bool food = false;

        friend void Human::takeAple(Apple& apple); //важно
    };


  

    void main() {


        Apple apple (234, true);
       

        Human asf;

        asf.takeAple(apple);
    }

    void Human::takeAple(Apple& apple // выносим что происходит в методе за класс
    {
        std::cout <<"sdfsdf" << apple.weight << std::endl;
    }
