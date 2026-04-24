
#Binary_Search
[[FingMInIndex]]
[[FingMaxIndex]]


находим края и после находим уже диапазон , все просто 
```Go
func searchRange(nums []int, target int) []int {  
  
    MinIndex := searchMinIndex(nums, target)  
    MaxIndex := searchMaxIndex(nums, target)  
  
    res := []int{MinIndex, MaxIndex}  
  
    return res  
}
```
