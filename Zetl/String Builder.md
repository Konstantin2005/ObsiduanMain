

## Проблема конкатенации

Такой код неэффективен:

```java
String result = "";for (int i = 0; i < 1000; i++) {    result += i;}
```

Каждая операция создаёт новый объект String.

---

## Решение

```java
StringBuilder sb = new StringBuilder();sb.append("Hello");sb.append("World");
```

---

## Внутреннее устройство

Использует:

```java
char[]
```

или в новых версиях Java:

```java
byte[]
```

Буфер расширяется по мере необходимости.