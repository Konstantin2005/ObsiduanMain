создание объекта панели
```java
JFrame frame = new JFrame("Моё окно");
```



текстовая метка
```java
JLabel label = new JLabel("Привет, мир!");
```


дефолт раскид
```java
frame.add(label); // добавляем метку в окно 
frame.setSize(300, 150); // размер окна
frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE); // закрытие по крестику
frame.setLocationRelativeTo(null); // по центру экрана
frame.setVisible(true); // показать окно
```


- **`JFrame`** — главное окно приложения
- **`JPanel`** — контейнер/панель (часто наследуют для своей отрисовки)
- **`JLabel`** — текст или картинка
- **`JButton`** — кнопка
- **`JTextField` / `JTextArea`** — поля ввода текста
- **`JOptionPane`** — быстрые диалоговые окна
- **`Graphics`** — объект для рисования (fillRect, drawLine, drawString, setColor и т.д.)


#One 