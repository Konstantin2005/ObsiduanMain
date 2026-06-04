#javaSctipt 
```js
const Prom1 = new Promise(function(resolve, reject) {  
    setTimeout(() =>{  
        console.log("start")  
        const datavazna ={  
            server: 'true',  
            data:'готово',  
            status:'200'  
        }  
        resolve(datavazna)  
    },2000)  
})  
  
Prom1.then(data=>{  
    console.log(data)  
    setTimeout(()=>{  
        data.server = 'work2'  
        data.status = '203'  
        data.data = 'фигня'  
        console.log(data)  
    },2333)  
    return data  
})
```

promise это модифицырованые калбека

что такое калбекаи это функции которые выполняються после оределеного условия
то есть Promis это умный калбек а точнее по умному инкопсулирован 

можно добовлять вытаскивать и исользовать там где это надо 

```js
return new Promise((delayresolve, reject) => {
      const timeoutId = setTimeout(() => {
        clearTimeout(timeoutId);
        reject("Time Limit Exceeded");
      }, t);
```

умный промисс

