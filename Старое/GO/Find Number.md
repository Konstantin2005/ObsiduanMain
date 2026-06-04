#Binary_Search
![[Pasted image 20251116141709.png]]

просто найти элемент это просто найти элемент , без всяких приских примбобасов 

просто найходим монотонно ходим в нашу нужную сторону и все 

```Go
func searchInsert(nums []int, target int) int {  
    N := len(nums)  
  
    lo, hi, ans := 0, N-1, -1  
  
    for lo <= hi {  
       mi := lo + (hi-lo)/2  
       if nums[mi] == target {  
          return mi  
       } else if nums[mi] > target {  
          hi = mi - 1  
       } else if nums[mi] < target {  
          lo = mi + 1  
       }  
    }  
    return ans  
}
```

без сохранения ответа