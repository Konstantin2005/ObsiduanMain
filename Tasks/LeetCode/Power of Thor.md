https://www.codingame.com/training/easy/power-of-thor-episode-1

#java 

Цель задачки определить направление тора. 
Чтобы он мог двигаться в нужном направление 

На вход дается стартовые точки куда надо прийти и где мы находимся.
И нам надо циклом сделать чтобы мы могли правельным образом привести игрока в нужное место.

Я тупил на моменте когда этот тор дошел до места и надо его остановить
И когда надо было обновлять позиции тора, я то думал это постоянные фрагменты, а это оказывается были штуки которые начальные и решил задачку прикольная задачка


![[Pasted image 20260416211123.png]]

![[Pasted image 20260416211413.png]]


```java
import java.util.*;

import java.io.*;

import java.math.*;

  

class Player {

  

    public static void main(String args[]) {

        Scanner in = new Scanner(System.in);
        int lightX = in.nextInt(); // the X position of the light of power
        int lightY = in.nextInt(); // the Y position of the light of power
        int initialTx = in.nextInt(); // Thor's starting X position
        int initialTy = in.nextInt(); // Thor's starting Y position

        // game loop

        while (true) {
            int remainingTurns = in.nextInt(); // The remaining amount of turns Thor can move. Do not remove this line.

  

        if (lightX == initialTx && lightY == initialTy){
            break;
        }

          if (lightX > initialTx && lightY > initialTy){
                System.out.println("SE");
                lightX++;
                lightY--;    
            }

            else if( lightX > initialTx && lightY < initialTy ){
                System.out.println("NE");
                lightX++;
                lightY++;

            }else if ( lightX < initialTx && lightY > initialTy){
                System.out.println("SW");
                lightX--;
                lightY--;

            }else if (lightX < initialTx && lightY < initialTy){
                lightX--;
                lightY++;
                System.out.println("NW");

            }else if (lightX > initialTx){
                System.out.println("E");
                lightX++;

            } else if (lightX < initialTx){
                System.out.println("W");
                lightX--;

            } else if (lightY > initialTy){
                System.out.println("S");
                lightY--;

            }else if (lightY < initialTy){
                System.out.println("N");
                lightY++;

            }

    }

}

}
```