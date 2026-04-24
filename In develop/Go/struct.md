4 bg mjm mnyСтруктура - это пользовательский тип данных который обьеденяет значения нескольних типов в одно целое

```Go
type StructName struct {
Field1 type1
Field2 type2 
 // ... }
```

есть основной метод то есть родительский , и уже от него уже пляшут , все остальные 

как топологическое дерево , прям в точку

```Go

type Character struct {
    Name   string // имя
    Health int    // здоровье
    Speed  int    // скорость
    Power  int    // сила
    Woman  bool   // true, если женский персонаж
}

type Magician struct {
    Character
    Magic      int
}
```

