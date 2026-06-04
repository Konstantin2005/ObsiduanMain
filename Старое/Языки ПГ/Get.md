#Nest_JS 

запрос на получение данных с сервера 

запрос отвте ничего больше 

```js
@Get(':id')  
getOne(@Param('id') id: string) {  
    return 'Controller ' + id;  
}
```
декоратор Get и метод GetOne который принимает id  в Декораторе Param