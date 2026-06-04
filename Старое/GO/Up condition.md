#Binary_Search

Постоянно влево поиск
это когда нам надо найти момент от куда пошло все через жопу 

было все хорошо и резко все плохо и это up condition 

```Go
func firstGoodVersion(n int) int {  
    lo, hi, ans := 1, n, -1  
    for lo <= hi {  
       mi := lo + (hi-lo)/2  
       if isGoodVersion(mi) {  
          ans = mi  
          lo = mi + 1  
       } else {  
          hi = mi - 1  
       }  
    }  
    return ans  
}
```

Мы от lo записываем ответ , а потом ищем дальше

```Go
func isGoodVersion(version int) bool {  
    return version <= 6  
}
```
сам из isGoodVersion говорит что нам надо найти числа меньше или раные 6 

![[Pasted image 20251117211452.png]]