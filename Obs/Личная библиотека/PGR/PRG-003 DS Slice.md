[[0 Data Structures]]
[[1 Programming]]

Slice - это гошная реализация динамического Array
Slice - дает возможность добавлять элементы и удалять элементы
Slice - это ссылочный тип
из чего состоит слайс

Len
Cap
сcылка на массив

1. как работает append
2. как расcчитывается начальный Len и cap слайса
3. слайс - ссылочный тип Механика работы ссылочного типа

append 

```Go
a := []int8{1,2,3}               len = 3 cap = 3 array
```


начальные Len cap

```Go
a := []int8{1,2,3}               len = 3 cap = 3 array
```

```Go
a := []int{}

a = append(a,[]int{1,2,3}...) len = 3, cap = 0
```



```Go
a := []int{}

a = append(a,[]int{1,2,3}...) len = 3, cap = 0
```