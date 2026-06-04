#Binary_Search

Постоянно в право поиск
это когда нам надо найти момент от куда пошло все через жопу 

было все хорошо и резко все плохо и это Down condition 

```Go
func firstBadVersion(n int) int {  
    lo, hi, ans := 1, n, -1  
    for lo <= hi {  
       mi := lo + (hi-lo)/2  
       if isBadVersion(mi) {  
          ans = mi  
          hi = mi - 1  
       } else {  
          lo = mi + 1  
       }   
    }  
    return ans  
}
```

Мы от lo записываем ответ , а потом ищем дальше

```Go
func isBadVersion(version int) bool {  
    return version >= 2  
}
```
сам из isBadVersion говорит что нам надо найти числа больше или равные 2

![[Pasted image 20251117211639.png]]