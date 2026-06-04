#Binary_Search

ищем максимально левый таргет и все 

```Go
func searchMinIndex(nums []int, target int) int {  
    N := len(nums)  
  
    lo, hi, ans := 0, N-1, -1  
  
    for lo <= hi {  
       mi := lo + (hi-lo)/2  
       if nums[mi] == target {  
          ans = mi  
          hi = mi - 1  
       } else if nums[mi] > target {  
          hi = mi - 1  
       } else if nums[mi] < target {  
          lo = mi + 1  
       }  
    }  
  
    return ans  
}
```