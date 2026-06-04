#javaSctipt 
```js
const citiesRUSSIA = ['москва','сакте-петербург','Казань']  
const citiesEuropa = ['париж','милан','прага']  
  
const citi= {  
    Moscow:'12',  
    name:'23',  
    Kazan:'234'  
}  
    //spread  
console.log({...citi})  
  
  
function sum(...rest){  
    return rest.reduce((a, i) => a + i, 0)  
}  
  
const numbers = [1,2,3,4,5,6,7]  
  
console.log(sum(...numbers))

```

в чем смысл оператора Spred он раскрывает массив на много сосотоляюших
то есть в одной переменой он иммет все элементы массива 

а Reat он высоувывает все элементы массива в параметрах это главное различие 

spred используетсья везде а Rest ток в парматрах