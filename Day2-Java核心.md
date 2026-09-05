# Day 2 · Java 核心复习（多线程 / 集合 / Map / IO / 网络 / 新特性）

> 今天把 Java 语言侧的核心过完。重点在 **集合 + Map + 多线程**（面试手撕重灾区），IO 和网络理解为主，新特性会写就行。

---

## 1. 多线程

### 1.1 synchronized 同步

**一句话核心**：多线程共享同一份数据时，用 `synchronized` 锁住共享对象，保证同一时刻只有一个线程操作。

```java
public class Ticket implements Runnable {
    private static int ticket = 100;  // static：三个窗口共享 100 张票

    @Override
    public void run() {
        while (true) {
            synchronized (Ticket.class) {  // 锁类对象
                if (ticket <= 0) break;
                System.out.println(Thread.currentThread().getName() + " 卖了第 " + ticket-- + " 张");
            }
        }
    }
}

// 使用：三个线程共用同一个 ticket 对象，所以票不会超卖
Thread t1 = new Thread(new Ticket(), "窗口1");
Thread t2 = new Thread(new Ticket(), "窗口2");
```

> 🔥 两种写法等价：同步代码块 `synchronized (锁对象){...}` 和同步方法 `public static synchronized void sell()`。

### 1.2 死锁

**一句话核心**：两个线程各自拿一把锁，又都想要对方那把锁，互相等待 → 卡死。

```
线程一：先拿锁A → 再拿锁B
线程二：先拿锁B → 再拿锁A
→ 线程一拿 A 等 B，线程二拿 B 等 A → 死锁
```

```java
// 线程一
synchronized (LockA.lockA) {       // 拿到 A
    Thread.sleep(100);
    synchronized (LockB.lockB) {}  // 等 B（被线程二拿着）
}
// 线程二
synchronized (LockB.lockB) {       // 拿到 B
    Thread.sleep(100);
    synchronized (LockA.lockA) {}  // 等 A（被线程一拿着）
}
```

> ✅ 避免死锁：**加锁顺序一致**（都先 A 后 B）。

### 1.3 线程池

**一句话核心**：线程池预先造好固定数量的线程，任务提交进去复用，避免每次 new Thread 的开销，还能拿到返回值。

```java
ExecutorService es = Executors.newFixedThreadPool(2);  // 固定 2 个线程
Future<Integer> f1 = es.submit(new MySum());            // submit 提交任务
Future<String> f2 = es.submit(new MyString());
System.out.println(f1.get());  // get() 阻塞获取返回结果
System.out.println(f2.get());
es.shutdown();                 // 用完记得关
```

| | new Thread | 线程池 |
|---|-----------|--------|
| 线程复用 | 每次新建，用完扔 | 复用 |
| 资源控制 | 无限制，可能 OOM | 固定数量可控 |
| 有返回值 | ❌ | ✅ Future |

---

## 2. Collection 接口 & 迭代器

### 2.1 Collection 常用方法

```java
Collection<String> c = new ArrayList<>();  // 接口接实现类
c.add("萧炎");        // 添加
c.addAll(other);      // 合并
c.remove("萧炎");     // 删除
c.contains("萧炎");   // 是否包含
c.isEmpty();          // 是否空
c.size();             // 个数
```

### 2.2 迭代器（Iterator）

```java
Iterator<Object> it = list.iterator();
while (it.hasNext()) {          // 先判断有没有
    Object next = it.next();    // 再取
    System.out.println(next);
}
```

> 🔥 底层：`iterator()` 返回内部类 `Itr`，两个关键变量：`cursor`（下一次 next 的索引，初始 0）、`lastRet`（上一次返回的索引，初始 -1）。每调一次 `next()`：取 cursor 元素 → lastRet = cursor → cursor++。

### 2.3 ConcurrentModificationException（并发修改异常）

```java
// ❌ 迭代时直接调集合的 remove/add 会抛异常
for (...) { list.remove(x); }  // 抛 ConcurrentModificationException

// ✅ 用迭代器自己的 remove，或 listIterator 的 add
it.remove();
listIterator.add(x);
```

> 原因：`Itr` 里有 `expectedModCount`，每次 next() 会跟集合的 `modCount` 比对。直接调 `list.remove()` 只改了 `modCount`，迭代器的 expectedModCount 没跟上 → 炸。

---

## 3. ArrayList 源码三要点

1. **懒加载**：`new ArrayList<>()` 时是**空数组**，第一次 `add()` 才创建容量 10 的数组。
2. **自动扩容**：满了用 `Arrays.copyOf()` 复制到新数组。
3. **扩容倍数**：约 **1.5 倍**（`oldCapacity + oldCapacity >> 1`）。

```java
// 常用方法
list.add(e);                 // 尾部加
list.add(index, e);          // 指定位置插
list.remove(index);          // 按索引删，返回被删元素
list.remove(obj);            // 按元素删，返回 boolean
list.set(index, e);          // 修改，返回旧元素
list.get(index);             // 获取
list.size();                 // 个数
```

---

## 4. HashSet 去重（hashCode + equals）

**一句话核心**：HashSet 存自定义对象**必须重写 hashCode 和 equals**，否则去重失效。

### 4.1 为什么没重写就去重失败？

```java
Person p1 = new Person("张无忌", 19);  // 地址 0x100
Person p2 = new Person("张无忌", 19);  // 地址 0x200
// Object 默认 hashCode 按地址算 → 两个哈希不同 → 分到不同桶 → 不比较 equals → 都存进去
```

### 4.2 HashSet 去重流程

```
add(元素)
  ↓
① 算 hashCode()
  ↓ 桶里没人 → 直接存 ✅
  ↓ 桶里有人 → 进入 ②
② 比 equals()
  ↓ false（内容不同）→ 存 ✅
  ↓ true（内容相同）→ 去重 ❌
```

> 一句话：**先 hashCode 分房间，撞了再 equals 认人。**

### 4.3 标准写法（IDEA 一键 Alt+Insert）

```java
public class Person {
    private String name;
    private Integer age;

    @Override
    public boolean equals(Object o) {
        if (this == o) return true;
        if (o == null || getClass() != o.getClass()) return false;
        Person p = (Person) o;
        return Objects.equals(name, p.name) && Objects.equals(age, p.age);
    }

    @Override
    public int hashCode() {
        return Objects.hash(name, age);
    }
}
```

> 三个方法一个不能少：`toString()`（打印可读）、`hashCode()`（定位桶）、`equals()`（比较内容）。

---

## 5. HashMap 底层原理（⭐ 面试手撕高频）

**一句话核心**：HashMap = **数组 + 链表 + 红黑树**。记住三个数字：**16**（初始容量）、**0.75**（扩容阈值）、**8**（链表转树）。

### 5.1 三个核心问题

**① 数据存哪？** 数组。数组查找快 O(1)。

**② key 怎么变下标？** `hashCode()` + 取模：

```
"apple" → hashCode() = 93029210 → & (数组长度-1) → 下标 2 → 数组[2] = 数据
```

**③ 两个 key 算出同一下标？（哈希碰撞）** 挂链表：

```
数组[2]: [apple, 5] → [banana, 8] → null
查 "banana"：算下标 → 2 → 遍历链表 → equals 比较 → 找到
```

### 5.2 put 完整流程

```
put(key, value)
  → hashCode() → 哈希值 & (数组长度-1) → 下标
  → 数组[下标] 空？ YES → 直接放
              NO → 遍历链表/树
                   ├ 有相同 key（equals）→ 覆盖旧值
                   ├ 无 → 追加链表末尾
                   └ 链表长度 ≥ 8 → 转红黑树
```

### 5.3 为什么 hashCode 和 equals 必须一起重写？

```java
new Student("张三", 20) → hashCode() = 12345 → 下标 5
new Student("张三", 20) → hashCode() = 67890 → 下标 10
map.put(stu1, "优秀");  // 存到 数组[5]
map.get(stu2);          // 去 数组[10] 找 → null！
```

> 虽然 equals 说相等，但 hashCode 不同 → 不同下标 → 根本不会比较。**hashCode 决定去哪个下标（先定位），equals 决定在那个链里找哪个（再比较）。**

### 5.4 扩容机制

```
初始数组 16 → 元素超过 16×0.75=12 → 扩容新数组 ×2 → 重新 hash 搬家
链表 ≥ 8 且数组 < 64 → 扩容
链表 ≥ 8 且数组 ≥ 64 → 转红黑树
```

---

## 6. 增强 for & HashMap 遍历

### 6.1 增强 for 语法

```java
for (元素类型 变量名 : 被遍历的集合/数组) {
    // 用「变量名」取值
}

for (String s : list) { System.out.println(s); }
```

> 原则：纯遍历用增强 for（简洁），需要下标（如发牌 `i % 3`）用普通 for。

### 6.2 HashMap 三种遍历（HashMap 不能直接 foreach，要先转换）

```java
// 方式一：keySet（只拿 key，还要回头 get）
for (Integer key : map.keySet()) {
    String value = map.get(key);  // 内部又算一遍 hashCode，多走一步
}

// 方式二：values（只拿 value，拿不到 key）
for (String value : map.values()) {
    System.out.println(value);
}

// 方式三：entrySet（key + value 一起拿，推荐）
Set<Map.Entry<Integer, String>> set = map.entrySet();
for (Map.Entry<Integer, String> entry : set) {
    Integer key = entry.getKey();
    String value = entry.getValue();
}
```

> 🔥 为什么推荐 entrySet？entry 同时装着 key 和 value，一次取出不回头查。keySet 还得再 `map.get(key)` 走一遍 hashCode。

---

## 7. 泛型

### 7.1 基础

```java
// 没有泛型：默认 Object，取数据要强转，易报 ClassCastException
// 有泛型：编译期校验类型，不用强转
ArrayList<String> list = new ArrayList<>();  // 只能装 String
```

> ⚠️ 泛型 `<>` 里只能写**引用类型**，不能写基本类型。`int` → `Integer`，`char` → `Character`。

### 7.2 泛型方法（BaseDao 里那个）

```java
protected <T> ArrayList<T> query(Class<T> clazz, String sql, Object... args)
```

拆解：
1. 方法开头的 `<T>`：声明「这是泛型方法」，告诉 JDK T 是未知引用类型。
2. 返回 `ArrayList<T>`：返回存 T 对象的集合。
3. 参数 `Class<T> clazz`：传 T 类的字节码（如 User.class），用来反射创建 T 对象。

> 作用：一套代码适配所有实体类。查用户返回 `ArrayList<User>`，查订单返回 `ArrayList<Order>`。

---

## 8. IO 流

### 8.1 流分类

| 分类 | 流 | 说明 |
|------|-----|------|
| 字节流 | InputStream / OutputStream | 底层，处理一切（图片/视频/文本） |
| 字符流 | Reader / Writer | 处理文本，避免乱码 |
| 缓冲流 | Buffered* | 提高效率 |
| 转换流 | InputStreamReader / OutputStreamWriter | 字节↔字符 + 指定编码 |
| 对象流 | ObjectInputStream / ObjectOutputStream | 序列化 |

### 8.2 文件复制（字节流）

```java
FileInputStream fis = new FileInputStream("1.txt");
FileOutputStream fos = new FileOutputStream("2.txt");
byte[] buf = new byte[1024];
int len;
while ((len = fis.read(buf)) != -1) {   // 读到 -1 表示读完
    fos.write(buf, 0, len);
}
fis.close();
fos.close();
```

### 8.3 序列化

```java
// 写对象
ObjectOutputStream oos = new ObjectOutputStream(new FileOutputStream("hero.txt"));
oos.writeObject(list);  // list 是 ArrayList<Hero>
oos.close();

// 读对象（必须强转！）
ObjectInputStream ois = new ObjectInputStream(new FileInputStream("hero.txt"));
ArrayList<Hero> list = (ArrayList<Hero>) ois.readObject();  // readObject 返回 Object
```

> 🔥 **readObject 为什么强转？** 它的返回类型是 `Object`（祖宗类），编译期不知道具体类型，必须强转成 `ArrayList<Hero>` 才能用。转错抛 `ClassCastException`。
> - `transient` 修饰的字段**不参与序列化**（如密码）。

### 8.4 Properties（配置文件读写）

```java
Properties pro = new Properties();
pro.load(new FileInputStream("config.properties"));  // 读
String user = pro.getProperty("username");
```

### 8.5 常见错误

| 错误 | 原因 | 解决 |
|------|------|------|
| 写了就读不到 | 字符流有缓冲区，没 close/flush 数据没落盘 | 先 close 输出流再读 |
| read() 读了没打印 | 返回值没接收 | `int d = isr.read(); print((char)d)` |
| 数组读满垃圾 | 用了 bytes.length 而非实际 len | `new String(bytes, 0, len)` |

---

## 9. 网络编程

### 9.1 通信三要素

```
IP 地址（找电脑） + 协议（怎么传） + 端口号（找程序）
```

- 本机地址：`127.0.0.1` / `localhost`
- 端口 0~1023 系统保留，普通程序用 **1024 以上**

### 9.2 UDP vs TCP

| | UDP | TCP |
|---|-----|-----|
| 连接 | 无连接，直接发 | 面向连接（三次握手） |
| 速度 | 快 | 慢 |
| 可靠 | 可能丢包 | 保证送达 |
| 客户端 | DatagramSocket | Socket |
| 服务端 | DatagramSocket | ServerSocket + Socket |

> 打比方：UDP 像寄平信（不确认收没收到），TCP 像打电话（通了才说话）。

### 9.3 三次握手 & 四次挥手

```
三次握手（建连）：客户端"能连吗"→ 服务端"来吧"→ 客户端"我来了"→ 连接建立
四次挥手（断开）：客户端"我发完了"→ 服务端"等下发最后数据"→ 服务端"可以断了"→ 客户端"拜拜"
```

### 9.4 TCP 客户端 / 服务端

```java
// 服务端
ServerSocket ss = new ServerSocket(9999);
Socket socket = ss.accept();           // 阻塞等连接
InputStream is = socket.getInputStream();
byte[] bytes = new byte[1024];
int len = is.read(bytes);              // 收数据

// 客户端
Socket socket = new Socket("127.0.0.1", 9999);
OutputStream os = socket.getOutputStream();
os.write("你好".getBytes());           // 发数据
```

### 9.5 文件上传关键点

```java
// 客户端发完文件后必须调 shutdownOutput()，告诉服务端"我发完了"
os.shutdownOutput();
// 否则服务端 read() 一直等，不知道发没发完 → 卡死
```

### 9.6 多线程服务端

```java
ServerSocket ss = new ServerSocket(8888);
while (true) {
    Socket socket = ss.accept();       // 主线程循环接客
    new Thread(() -> {                 // 子线程负责服务这个客户端
        // ...读写操作...
    }).start();                        // 别忘 start()！
}
```

---

## 10. JDK 新特性（Lambda / 函数式接口 / Stream）

### 10.1 Lambda 表达式

**一句话核心**：Lambda 是函数式接口（只有一个抽象方法）的简写，用 `() -> {}` 代替匿名内部类。

```java
// 匿名内部类（老写法）
new Thread(new Runnable() {
    @Override
    public void run() { System.out.println("执行了"); }
}).start();

// Lambda（新写法）
new Thread(() -> System.out.println("执行了")).start();
```

**省略规则**：① 参数类型可省 ② 单参数小括号可省 ③ 单语句大括号+分号可省 ④ 单语句 return 可省。

```java
(String s) -> { return s.length(); }   // 完整
s -> s.length()                        // 全省略
```

### 10.2 四大函数式接口（⭐ 必记）

| 接口 | 抽象方法 | 作用 | 口诀 |
|------|---------|------|------|
| `Supplier<T>` | `T get()` | 供给型，无中生有 | 无进有出 |
| `Consumer<T>` | `void accept(T t)` | 消费型，操作数据 | 有进无出 |
| `Function<T,R>` | `R apply(T t)` | 转换型，类型转换 | 有进有出 |
| `Predicate<T>` | `boolean test(T t)` | 判断型，条件判断 | 有进出布尔 |

```java
Supplier<Integer> s = () -> 7;              // get() → 7
Consumer<String> c = x -> System.out.println(x.length());  // accept("hi") → 2
Function<String, Integer> f = x -> Integer.parseInt(x);    // apply("123") → 123
Predicate<String> p = x -> x.startsWith("张");             // test("张三丰") → true
```

### 10.3 Stream 流

**一句话核心**：Stream ≠ IO 流，它是**流式编程**，像流水线。中间方法返回新 Stream（可链式），终结方法用完流就关。

| 类别 | 方法 | 参数 |
|------|------|------|
| 获取流 | `list.stream()` / `Stream.of(...)` | — |
| 中间方法 | `filter`(Predicate) / `map`(Function) / `limit`(long) / `skip`(long) / `distinct` / `sorted` | 返回新 Stream |
| 终结方法 | `forEach`(Consumer) / `count` / `collect`(Collector) | 用完关闭 |

```java
// 经典链式：过滤 → 转换 → 收集
List<String> result = Stream.of("a", "bb", "ccc")
    .filter(s -> s.length() >= 2)      // Predicate 过滤
    .map(s -> s.toUpperCase())         // Function 转换
    .collect(Collectors.toList());     // 收集

// 统计
long count = Stream.of(1, 2, 3, 4, 5).filter(n -> n > 3).count();  // 2

// 跳过 + 限制（分页）
stream.skip(2).limit(3)  // 跳过前 2 个取 3 个 = 第 3~5 条
```

> 🔥 三者关系：Stream 的方法参数几乎全是**函数式接口**，函数式接口用 **Lambda** 简化。三者是天然一家人。

---

# Day 2 速查表（睡前扫一遍）

| 考点 | 一句话答案 |
|------|-----------|
| synchronized 锁什么 | 共享对象（对象锁 / 类锁） |
| 死锁原因 & 避免 | 互相持锁等待；加锁顺序一致 |
| 线程池好处 | 复用线程、控制数量、有返回值(Future) |
| 迭代器并发修改异常 | 迭代时直接 list.remove/add；改用 it.remove() |
| ArrayList 扩容 | 懒加载（首次 add 建10）→ 1.5 倍扩容 |
| HashSet 去重要重写啥 | hashCode + equals（先 hash 分桶再 equals 比内容） |
| HashMap 底层 | 数组+链表+红黑树；16/0.75/8 |
| hashCode 和 equals 关系 | hashCode 定位下标，equals 在链里找节点 |
| HashMap 遍历推荐 | entrySet（一次拿 key+value） |
| 泛型方法 `<T>` | 声明泛型方法，返回 ArrayList<T> |
| readObject 为什么强转 | 返回 Object，不转没法用 |
| transient | 字段不参与序列化 |
| TCP vs UDP | TCP 有连接可靠慢，UDP 无连接快不可靠 |
| 文件上传卡死 | 客户端没调 shutdownOutput() |
| 四大函数式接口 | Supplier/Consumer/Function/Predicate |
| Stream 中间 vs 终结 | 中间返回新 Stream，终结用完关闭 |
