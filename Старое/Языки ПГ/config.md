```js

module.export = {
module : 'developmet' || 'production'
}

```

##### что метод компиляции кода , с коментами или нет по умолчанию в development а так то если в прод то product


```js

module.export = {
entry: path.resolve(__dirname,'src','index.js')
}

```

#### сылка на сборочный файл , от куда стартует сборка



```js

module.export = {
output:{
filename: "bundle.js"
path: path.resolve(__dirname,'build') 
  }
}

```

куда будет собираться проект , то есть где будет храняться собраные файлы


```js

module.export = {
clean : true,
}

```

это то что будет только финальный файл сборки и ничего больше




