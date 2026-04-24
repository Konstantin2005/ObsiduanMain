
Штука то что нельзя менять объекты вне класса
```java
public class BankAccount { 
private double balance; // Поле скрыто от внешнего доступа 
private String accountNumber; 
private String ownerName; 
}
```

То есть мы задаем эти штуки и менять мы их можем только когда установим определенные методы



```java
ublic class BankAccount { 
private double balance; 
public double getBalance() { 
return balance; 
} // Сеттер (установка значения с проверкой)
 public void setBalance(double amount) {
	  if (amount >= 0) {
    this.balance = amount; 
	   }else { 
    System.out.println("Баланс не может быть отрицательным"); 
		    }
	     }
      }
```

#One 