#Nest_JS 

```ts
@Post()  
@HttpCode(HttpCode.CREATED)  
create(@Body() createProductDto: CreateProductDto) {  
    return `Title: ${createProductDto.title}Price: ${createProductDto.price}`;  
}

```

указываем какой будет статус привыполнение функции