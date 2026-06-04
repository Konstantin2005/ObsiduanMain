```js
console.log(path.join(__dirname, 'index.js'));
```
паосинг пути , показывает путь к файлу

__dirname это абсолютный путь до файла

```js
const fullpath = path.resolve(__dirname, 'index.js'));
```
редкая штука лучше юзать join , но если уверен то пользуйся :)

```js
console.log('парсинг строки', path.resolve(fullpath));
```

```js
const siteURL = ''
```
#node_JS   