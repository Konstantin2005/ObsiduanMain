```js

    for (let n of nums) {
        if (total < 0) {
            total = 0;
        }

        total += n;
        res = Math.max(res, total);
    }
```

let n то куда будет передоваться переменная 
nums тот массив по которому будет итерироваться
#javaSctipt 