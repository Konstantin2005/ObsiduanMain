#2Спринт
```Go
switch wind { 
case 0, 1, 2:
fmt.Println(wind, "- штиль или легкий ветер")
case 3, 4, 5:
fmt.Println(wind, "- умеренный ветер")
case 6, 7, 8:
     fmt.Println(wind, "- сильный ветер")
default: fmt.Println(wind, "- шторм или ураган")
 }
```


А во как надо , а то я то тупил , через && 
```Go
switch { 
case wind <= 2: fmt.Println(wind, "- штиль или легкий ветер") 
case wind >= 3 && wind <= 5: fmt.Println(wind, "- умеренный ветер") 
case wind >= 6 && wind <= 8: fmt.Println(wind, "- сильный ветер") 
default: fmt.Println(wind, "- шторм или ураган") }
```