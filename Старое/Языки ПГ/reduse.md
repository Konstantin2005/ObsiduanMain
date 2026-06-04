#javaSctipt 
```js
function sum(...rest){  
    return rest.reduce((a, i) => a + i, 0)  
}  
  
const numbers = [1,2,3,4,5,6,7]  
  
console.log(sum(...numbers))

```
в чем прикол он это умный цыкл
он экномит цыкл снизу в цыкл сверху
```js
  
function susdm(rest){  
    for(let i = 0;i<rest.length();i++){  
        let resut= rest[i]+rest[i+1];  
          
    }  
}
```
