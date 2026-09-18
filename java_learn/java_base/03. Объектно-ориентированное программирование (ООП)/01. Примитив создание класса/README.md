# О создание классов в Java

- Класс в джава это чертёж объекта, т.е. класс это чертёж машины;
- Когда мы создаем объект машины, мы используем ранее определённый чертёж(класс);
- Класс определяет;
  - состояние класса - его поля (данные?)
  - поведение - методы(например метод ехать, остановиться)
  - конструктуры - как создавать этот объект?

- класс не занимает память, до создания объекта

- Пример обычного класса:
```java
public class Car {
    // поля - состояине класса/объекта
    private int price;
  
    // конструктор - с параметром
    public Car(int price) {
        this.price = price;
    }
  
    // конструктор - без параметров
    public Car() {

    }

    // Поведение объекта - МЕТОДЫ
    // метод ехать
    public void drive() {
        System.out.println("Driving a car");
    }

    // метод получить цену
    public void getPrice() {
        System.out.println("Price car: " + price + " $");
    }
}

```

- Пример использования обычного класса:
```java
// базовый main для игр с машиной
public class Main {
    public static void main(String[] args){
        Car car = new Car();
        car.drive();
        car.getPrice(); // вернет 0 так как нет параметров
    }
}
```

- Пример параметризированного класса:
```java
class Knight {
    private String name = "Sir Thanks-A-Lot";
    private String weapon = "Long Sword";
    private Boolean isGoingToSavePrincess = true;

    // public - модификатор доступа к методу
    // static - метод будет доступен без создания объекта класса
    // void - метод ничего не возвращает
    // scream - имя метода
    public static void scream() {
        System.out.println("STATIC WAR");
    }

    // тут вызываем метод только после объявления объекта
    public void goAndSaveThePrincess() {
        sharpenBlade();
        getFood();
        assembleTeam();
        System.out.println("Da idu uzhe...");
    }

    // тут вызываем приватные(используются только внутри объекта без внешних вызовов) методы для объявленного объекта класса
    private void sharpenBlade() {
        System.out.println("Tochim mech");
    }
    private void getFood() {
        System.out.println("Sobirayem konservy");
    }
    private void assembleTeam() {
        System.out.println("Budim oruzhenostsa");
    }
}
```