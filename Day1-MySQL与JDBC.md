# Day 1 · 数据侧复习（MySQL + JDBC）

> 今天把 MySQL 和 JDBC 一起过完。顺序：MySQL 基础 → MySQL 进阶 → JDBC。学完你脑子里应该有一条线：**「数据存在 MySQL，Java 用 JDBC 去操作它」**。

---

# 第一部分 · MySQL 基础篇

## 1. 常用函数

**一句话核心**：函数是 MySQL 内置好的「小程序」，拿到合适的场景直接调用，省得自己算。四大类：字符串、数值、日期、流程。

### 1.1 字符串函数

| 函数 | 功能 | 举例 |
|------|------|------|
| `CONCAT(a, b, ...)` | 拼接 | `CONCAT('Hello', ' MySQL')` → `Hello MySQL` |
| `LOWER(s)` / `UPPER(s)` | 转小写 / 大写 | `UPPER('hello')` → `HELLO` |
| `LPAD(s, n, pad)` / `RPAD(...)` | 左 / 右填充到 n 位 | `LPAD('01', 5, '0')` → `00001` |
| `TRIM(s)` | 去头尾空格 | `TRIM(' hi ')` → `hi` |
| `SUBSTRING(s, start, len)` | 截取（start 从 **1** 开始） | `SUBSTRING('Hello', 1, 3)` → `Hel` |

**经典案例 —— 工号补零**：

```sql
-- 企业工号统一 5 位，不足前面补 0（1 → 00001）
UPDATE emp SET workno = LPAD(workno, 5, '0');
```

### 1.2 数值函数

| 函数 | 功能 | 举例 |
|------|------|------|
| `CEIL(x)` | 向上取整 | `CEIL(1.1)` → `2` |
| `FLOOR(x)` | 向下取整 | `FLOOR(1.9)` → `1` |
| `MOD(x, y)` | 取模 | `MOD(7, 4)` → `3` |
| `ROUND(x, y)` | 四舍五入保留 y 位 | `ROUND(2.345, 2)` → `2.35` |
| `RAND()` | 0~1 随机数 | `RAND()` → `0.6534...` |

**经典案例 —— 6 位随机验证码**：

```sql
SELECT LPAD(ROUND(RAND() * 1000000, 0), 6, '0');
-- 思路：RAND() 随机小数 → ×100万 → 四舍五入取整 → 不足 6 位左边补 0
```

### 1.3 日期函数

| 函数 | 功能 |
|------|------|
| `CURDATE()` / `CURTIME()` / `NOW()` | 当前日期 / 时间 / 日期+时间 |
| `YEAR(d)` / `MONTH(d)` / `DAY(d)` | 取年 / 月 / 日 |
| `DATE_ADD(d, INTERVAL n TYPE)` | 日期加间隔 |
| `DATEDIFF(d1, d2)` | **d1 - d2** 相差天数（前减后） |

**经典案例 —— 员工入职天数**：

```sql
SELECT name, DATEDIFF(CURDATE(), entrydate) AS '入职天数'
FROM emp
ORDER BY 入职天数 DESC;
```

> ⚠️ 易错：`DATEDIFF(d1, d2)` 是 **d1 减 d2**，别写反了。

### 1.4 流程函数（⭐ 面试爱考）

| 函数 | 功能 |
|------|------|
| `IF(v, t, f)` | v 为真返回 t，否则 f |
| `IFNULL(v1, v2)` | v1 非 NULL 返回 v1，否则 v2 |
| `CASE WHEN 条件 THEN 结果 ... ELSE 默认 END` | 多条件判断 |

**两种 CASE 写法**：

```sql
-- 写法一：等值匹配（只能比 =）
SELECT name,
    CASE workaddress
        WHEN '北京' THEN '一线'
        WHEN '上海' THEN '一线'
        ELSE '二线'
    END AS '城市等级'
FROM emp;

-- 写法二：条件判断（可以比 >= < 等）
SELECT name,
    CASE WHEN math >= 85 THEN '优秀'
         WHEN math >= 60 THEN '及格'
         ELSE '不及格'
    END AS '数学'
FROM score;
```

> 记忆点：等值匹配用 `CASE 字段 WHEN 值`，范围判断用 `CASE WHEN 条件`。

---

## 2. 约束

**一句话核心**：约束是加在字段上的「规则」，保证数据正确、有效、完整。

### 2.1 约束分类

| 约束 | 关键字 | 说明 |
|------|--------|------|
| 非空 | `NOT NULL` | 不能为 NULL |
| 唯一 | `UNIQUE` | 不能重复（但 **NULL 可以有多个**） |
| 主键 | `PRIMARY KEY` | 非空 + 唯一，**一张表只能一个** |
| 默认 | `DEFAULT` | 不传值时的默认值 |
| 检查 | `CHECK` | 限定取值范围（MySQL 8.0.16+） |
| 外键 | `FOREIGN KEY` | 关联两张表，保证数据一致 |

### 2.2 建表加约束

```sql
CREATE TABLE emp(
    id      INT PRIMARY KEY AUTO_INCREMENT,          -- 主键 + 自增
    name    VARCHAR(10) NOT NULL UNIQUE,             -- 非空 + 唯一
    age     TINYINT CHECK (age >= 0 AND age <= 120), -- 检查
    gender  CHAR(1) DEFAULT '男',                    -- 默认值
    dept_id INT,
    CONSTRAINT fk_dept FOREIGN KEY (dept_id) REFERENCES dept(id)  -- 外键
);
```

### 2.3 外键的删除/更新行为（⭐ 面试重点）

| 行为 | 关键字 | 父表删/改时 |
|------|--------|------------|
| 限制（默认） | `NO ACTION` / `RESTRICT` | 子表有引用就**不允许删** |
| 级联 | `CASCADE` | 子表**跟着一起删/改** |
| 置空 | `SET NULL` | 子表外键**设为 NULL** |
| 设默认 | `SET DEFAULT` | 子表外键**设为默认值** |

```sql
ALTER TABLE emp ADD CONSTRAINT fk_dept
    FOREIGN KEY (dept_id) REFERENCES dept(id)
    ON UPDATE CASCADE     -- 父表改 → 子表跟着改
    ON DELETE SET NULL;   -- 父表删 → 子表外键置空
```

### 2.4 高频面试题

| 问题 | 答案 |
|------|------|
| PK 和 UNIQUE 区别？ | PK 非空+唯一且表只有一个；UNIQUE 允许 NULL 且可多个 |
| CASCADE 和 SET NULL 区别？ | CASCADE 跟着删，SET NULL 只把外键置空 |
| 为什么实际项目不推荐外键？ | 高并发下性能差；用「逻辑外键」（应用层维护）更灵活 |

---

## 3. 多表查询

**一句话核心**：一张表满足不了需求时，把多张表按「关联关系」连起来查。核心是 **JOIN** 和 **子查询**。

### 3.1 多表关系

| 关系 | 例子 | 实现 |
|------|------|------|
| 一对多 | 部门 ↔ 员工 | 在「多」方加外键 |
| 多对多 | 学生 ↔ 课程 | 建中间表，两个外键 |
| 一对一 | 用户 ↔ 用户详情 | 任意一方加唯一外键 |

### 3.2 连接查询

**内连接**（两表都匹配才返回）：

```sql
-- 显式写法（推荐）
SELECT e.name, d.name FROM emp e INNER JOIN dept d ON e.dept_id = d.id;
-- 隐式写法（不推荐，可读性差）
SELECT e.name, d.name FROM emp e, dept d WHERE e.dept_id = d.id;
```

**外连接**（一边全保留，不匹配填 NULL）：

```sql
-- 左外：左表全保留
SELECT e.name, d.name FROM emp e LEFT JOIN dept d ON e.dept_id = d.id;
-- 找「没部门」的员工
SELECT e.name FROM emp e LEFT JOIN dept d ON e.dept_id = d.id WHERE d.id IS NULL;
```

**自连接**（一张表自己连自己，必须起别名区分）：

```sql
-- 查员工及其直属领导
SELECT e.name AS '员工', m.name AS '领导'
FROM emp e LEFT JOIN emp m ON e.manager_id = m.id;
```

**联合查询 UNION**：

```sql
-- UNION 去重合并，UNION ALL 不去重（更快）
SELECT name FROM emp WHERE salary > 15000
UNION ALL
SELECT name FROM emp WHERE age < 25;
```

### 3.3 子查询（四类，按返回结果分）

| 分类 | 返回 | 常用操作符 |
|------|------|-----------|
| 标量子查询 | 单个值 | `= > < >= <=` |
| 列子查询 | 一列多行 | `IN` / `ANY` / `ALL` |
| 行子查询 | 一行多列 | `= (col1, col2)` |
| 表子查询 | 多行多列 | `FROM` 后当临时表 |

```sql
-- 标量：查工资最高的员工
SELECT name, salary FROM emp WHERE salary = (SELECT MAX(salary) FROM emp);

-- 列子查询 IN：查「研发部/市场部」员工
SELECT name FROM emp WHERE dept_id IN (SELECT id FROM dept WHERE name IN ('研发部','市场部'));

-- 行子查询：查和「赵敏」同部门同年龄的人
SELECT name FROM emp WHERE (dept_id, age) = (SELECT dept_id, age FROM emp WHERE name='赵敏');

-- 表子查询：子查询结果当临时表
SELECT e.name FROM emp e
INNER JOIN (SELECT * FROM dept WHERE name LIKE '%部') d ON e.dept_id = d.id;
```

> ⚠️ **ANY vs ALL 必考**：
> - `> ALL(子查询)` = 比里面**最大值**还大（比所有都大）
> - `> ANY(子查询)` = 比里面**最小值**大即可（比任意一个大）

---

## 4. 事务（⭐ 面试高频）

**一句话核心**：事务把一组 SQL 当「一个整体」，**要么全成功，要么全失败**，不会做一半。

### 4.1 ACID 四大特性

| 特性 | 含义 |
|------|------|
| **原子性** Atomicity | 不可分割，要么全成功要么全失败 |
| **一致性** Consistency | 事务前后数据保持一致（转账总额不变） |
| **隔离性** Isolation | 并发事务互不干扰 |
| **持久性** Durability | 提交后永久保存到磁盘 |

### 4.2 并发问题

| 问题 | 描述 |
|------|------|
| **脏读** | 读到别人**未提交**的数据 |
| **不可重复读** | 同一行两次读**值**变了（被 UPDATE） |
| **幻读** | 同一条件两次查**行数**变了（被 INSERT/DELETE） |

> 区分口诀：脏读=读到「没定」的；不可重复读=同一行「值」变了；幻读=「行数」变了。

### 4.3 隔离级别

| 隔离级别 | 脏读 | 不可重复读 | 幻读 |
|---------|:--:|:--:|:--:|
| Read Uncommitted | ❌ | ❌ | ❌ |
| Read Committed | ✅ | ❌ | ❌ |
| Repeatable Read（MySQL 默认） | ✅ | ✅ | ❌ |
| Serializable | ✅ | ✅ | ✅ |

> 隔离级别越高越安全，但并发性能越差。

### 4.4 事务操作

```sql
-- 查看当前隔离级别
SELECT @@TRANSACTION_ISOLATION;
-- 查看自动提交模式（1=自动）
SELECT @@autocommit;

-- 显式开启事务（推荐）
START TRANSACTION;  -- 或 BEGIN;
UPDATE account SET money = money - 1000 WHERE name = '张三';
UPDATE account SET money = money + 1000 WHERE name = '李四';
COMMIT;     -- 没问题提交
-- ROLLBACK;  -- 出问题回滚
```

---

# 第二部分 · MySQL 进阶篇

## 5. 存储引擎（⭐ 面试必考）

**一句话核心**：存储引擎决定「数据怎么存、怎么查、支不支持事务」。它**基于表**（每张表可不同），MySQL 默认 **InnoDB**。

### 5.1 三大引擎对比

| 特性 | InnoDB | MyISAM | Memory |
|------|:--:|:--:|:--:|
| 事务 | ✅ | ❌ | ❌ |
| 外键 | ✅ | ❌ | ❌ |
| 行级锁 | ✅ | ❌（表锁） | ❌（表锁） |
| 默认索引 | B+Tree | B+Tree | **Hash** |
| 存储位置 | 磁盘 | 磁盘 | **内存**（重启丢） |
| 适用场景 | 绝大多数 | 读多写少、归档 | 临时/缓存表 |

> 一句话：99% 场景用 **InnoDB**，MyISAM 和 Memory 了解即可。

### 5.2 InnoDB 逻辑存储结构

```
表空间 Tablespace（xxx.ibd 文件）
 └─ 段 Segment
     └─ 区 Extent（1M = 64 页）
         └─ 页 Page（16K，磁盘管理最小单元）
             └─ 行 Row
```

---

## 6. 索引（⭐ 面试重灾区，重点啃）

**一句话核心**：索引是帮助 MySQL **高效获取数据**的**有序**数据结构。默认说的「索引」就是 **B+Tree**。

### 6.1 为什么是 B+Tree 而不是二叉树/红黑树/Hash？

1. **二叉树**：顺序插入会退化成**单向链表**，层级深，慢。
2. **红黑树**：解决了链表，但本质还是二叉树，数据量大层级仍深。
3. **B+Tree**：多路平衡，**矮**；且叶子节点有序 + 双向链表，支持**范围查询和排序**。
4. **Hash**：只支持等值匹配（`=`/`IN`），**不支持范围查询和排序**。

> 一句话：B+Tree 矮 + 有序 → 检索快、支持范围查询和排序。

### 6.2 索引分类

**按功能**：主键索引（PRIMARY，只能一个）、唯一索引（UNIQUE）、普通索引、全文索引（FULLTEXT）。

**按存储形式（InnoDB）**：

| 分类 | 叶子节点存什么 |
|------|--------------|
| **聚集索引** | **行数据**（必须有且只有一个） |
| **二级索引**（辅助索引） | **主键值** |

### 6.3 回表查询 & 覆盖索引（⭐ 必考）

**回表**：先到二级索引查到主键值，再回聚集索引查整行 → 多一次查询。

```sql
-- A：主键查询，直接走聚集索引，一次拿到（快）
SELECT * FROM user WHERE id = 10;
-- B：name 二级索引，先拿主键再回表查（慢）
SELECT * FROM user WHERE name = 'Arm';
```

**覆盖索引**：查询返回的列**全在索引里**，**无需回表**。用 `EXPLAIN` 看 Extra：`Using index` = 覆盖，`Using index condition` = 需回表。

```sql
-- 建联合索引 idx(username, password)
-- 下面三个返回列都在索引里 → 覆盖索引，不回表
SELECT id, username, password FROM tb_user WHERE username = 'itcast';
```

### 6.4 最左前缀法则（⭐ 必考）

联合索引要**从最左列开始，且不跳过中间列**。跳过某一列，后面的字段索引**失效**。

以 `(profession, age, status)` 为例：

| 查询条件 | 结果 |
|---------|------|
| profession + age + status | ✅ 全生效 |
| profession + age | ✅ 生效 |
| profession | ✅ 生效 |
| age + status（无 profession） | ❌ 全失效 |
| profession + status（跳过 age） | ⚠️ 只有 profession 生效 |

> 🔥 **「最左列」指联合索引的第一个字段必须在，跟 SQL 条件书写顺序无关**。

### 6.5 索引失效场景（⭐ 面试至少说 5 个）

| # | 场景 | 例子 |
|---|------|------|
| ① | 索引列上做**运算/函数** | `WHERE substring(phone,10,2)='15'` |
| ② | 字符串**不加引号**（隐式类型转换） | `WHERE phone = 17799990015` |
| ③ | like **头部加 %** | `WHERE name LIKE '%工程'` |
| ④ | or 连接，**一侧没索引** | `WHERE id=10 OR age=23`（age 无索引 → 全失效） |
| ⑤ | 数据分布影响 | 索引筛出**大量数据**时，优化器干脆全表扫描 |

### 6.6 索引设计原则

1. 数据量大、查询频繁的表才建索引。
2. 常作为 `WHERE` / `ORDER BY` / `GROUP BY` 的字段建索引。
3. 选**区分度高**的列，尽量建唯一索引。
4. 长字符串用**前缀索引**。
5. 尽量**联合索引**，减少单列索引（联合索引常能覆盖索引）。
6. 控制索引数量（越多增删改维护代价越大）。
7. 索引列尽量 `NOT NULL`。

### 6.7 索引语法

```sql
CREATE INDEX idx_name ON t(col);              -- 普通索引
CREATE UNIQUE INDEX idx_phone ON t(phone);     -- 唯一索引
CREATE INDEX idx_union ON t(c1, c2, c3);       -- 联合索引
CREATE INDEX idx_email ON t(email(5));         -- 前缀索引
SHOW INDEX FROM t;                             -- 查看
DROP INDEX idx_name ON t;                      -- 删除
EXPLAIN SELECT ...;                            -- 看执行计划
```

> EXPLAIN 关键字段：`type`（NULL > const > eq_ref > ref > range > index > all，越靠前越好）、`key`（实际用的索引）、`Extra`（Using index = 覆盖索引）。

---

## 7. SQL 优化（⭐ 面试高频）

### 7.1 insert 优化

```sql
-- ① 批量插入（减少往返）
INSERT INTO t VALUES (1,'a'), (2,'b'), (3,'c');
-- ② 手动事务（减少自动提交开销）
START TRANSACTION;
INSERT ...; INSERT ...; INSERT ...;
COMMIT;
-- ③ 主键顺序插入（避免页分裂）
```

> ⚠️ 乱序插入会引发**页分裂**（中间插数据要移动后一半到新页），所以主键尽量用自增。

### 7.2 order by 优化

目标：把 **Using filesort**（排序）优化成 **Using index**（走有序索引，无需排序）。

- 给排序字段建索引，多字段**遵循最左前缀**。
- 一升一降（`order by age asc, phone desc`）会失效 → 建 `(age asc, phone desc)` 联合索引。

### 7.3 group by 优化

分组也能用索引，**同样遵循最左前缀**。`EXPLAIN` 看 `Using temporary` 说明没用上索引。

### 7.4 limit 优化

越往后分页越慢（`limit 2000000,10` 要先排序前 2000010 条再丢 2000000 条）。优化：**覆盖索引 + 子查询**。

```sql
SELECT * FROM tb_sku t,
  (SELECT id FROM tb_sku ORDER BY id LIMIT 2000000, 10) a
WHERE t.id = a.id;
```

### 7.5 count 优化

效率排序：`count(字段) < count(主键) < count(1) ≈ count(*)`。

> 📌 **尽量用 `count(*)`**。`count(字段)` 最慢（要判断 null）。

### 7.6 update 优化

> **InnoDB 行锁是加在「索引」上的，索引失效会升级成表锁。**

```sql
UPDATE course SET name='javaEE' WHERE id=1;        -- id 有索引 → 行锁 ✅
UPDATE course SET name='Spring' WHERE name='PHP';  -- name 无索引 → 表锁 ❌
```

> 所以 update/delete 的 WHERE 条件**尽量带索引列**。

---

# 第三部分 · JDBC

## 8. JDBC 核心概念

**一句话核心**：JDBC = **Java 的接口规范** + **各数据库厂商的驱动 jar**，是一种典型的**面向接口编程**。

```
你的 Java 代码（只面向接口写）
        ↓
JDBC 接口规范（java.sql / javax.sql）
        ↓
各厂商驱动实现：MySQL(mysql-connector-j) / Oracle(ojdbc) / ...
```

> 好处：学会接口方法就能操作所有数据库；换数据库只换 jar，代码不用改。

---

## 9. JDBC 六步基本流程（⭐ 必背）

```
① 注册驱动  →  ② 获取连接  →  ③ 创建发送 SQL 的对象
→  ④ 发送 SQL 拿结果  →  ⑤ 解析结果集  →  ⑥ 关闭资源（先开后关）
```

```java
// 1. 注册驱动（反射方式，只注册一次）
Class.forName("com.mysql.cj.jdbc.Driver");

// 2. 获取连接（面向接口：Connection 接口 = 实现类）
Connection conn = DriverManager.getConnection(
    "jdbc:mysql://localhost:3306/atguigu", "root", "root");

// 3. 创建 Statement
Statement stmt = conn.createStatement();

// 4. 发送 SQL
ResultSet rs = stmt.executeQuery("select id,account from t_user;");

// 5. 解析结果集
while (rs.next()) {
    int id = rs.getInt("id");
    String account = rs.getString("account");
    System.out.println(id + "::" + account);
}

// 6. 关闭资源（先开后关：rs → stmt → conn）
rs.close();
stmt.close();
conn.close();
```

> 🔥 关键理解：
> - `ResultSet` = 查询结果表在 Java 里的化身，自带**光标**，初始指向第一行**上面**。
> - `next()` 光标下移一行，有数据返回 true。
> - `getXxx(列名 | 列序号)`：列序号**从 1 开始**。

---

## 10. Statement vs PreparedStatement（⭐ 核心重点）

**一句话核心**：Statement 拼字符串有 **SQL 注入**风险，PreparedStatement 用 `?` 占位符**预编译**，安全且高效。

### 10.1 SQL 注入演示（Statement 反面教材）

```java
// 用户输入账号 = 1' or '1'='1
String sql = "select * from t_user where account='" + account
           + "' and password='" + password + "';";
// 拼出：... where account='1' or '1'='1' and ...
// or '1'='1' 永远为真 → 没密码也能登录成功！
```

> 本质：字符串拼接让「用户输入」混进了「SQL 结构」，数据库分不清哪是数据哪是命令。

### 10.2 PreparedStatement 预编译（正确姿势）

```java
String sql = "select * from t_user where account = ? and password = ?;";
PreparedStatement ps = conn.prepareStatement(sql);  // 创建时传 SQL 骨架
ps.setObject(2, password);  // 给第 2 个 ? 赋值（从 1 开始）
ps.setObject(1, account);   // 给第 1 个 ? 赋值
ResultSet rs = ps.executeQuery();  // 执行时不再传 SQL
```

> 🔥 三个关键点：
> - `?` **只能替代值**，不能替代关键字/表名/列名；`?` 不能加引号（不能写 `'?'`）。
> - `setObject(下标, 值)`：下标**从 1 开始**（最易错）。
> - 预编译 = 数据库先把骨架编译好并缓存，之后填值执行不重编译 → 快 + 安全。

---

## 11. CRUD（两种执行方法）

| 方法 | 用途 | 返回 |
|------|------|------|
| `executeUpdate()` | 非 DQL（INSERT/UPDATE/DELETE） | `int`（受影响行数） |
| `executeQuery()` | DQL（SELECT） | `ResultSet`（结果集） |

```java
// 增
String sql = "insert into t_user(account,password,nickname) values (?,?,?)";
PreparedStatement ps = conn.prepareStatement(sql);
ps.setString(1, "test");
ps.setString(2, "test");
ps.setString(3, "测试");
int rows = ps.executeUpdate();  // 1

// 查并封装成 List<Map>（含元数据）
ResultSet rs = ps.executeQuery();
ResultSetMetaData meta = rs.getMetaData();
int columnCount = meta.getColumnCount();
List<Map> list = new ArrayList<>();
while (rs.next()) {
    Map map = new HashMap();
    for (int i = 1; i <= columnCount; i++) {
        map.put(meta.getColumnLabel(i), rs.getObject(i));  // 列从 1 开始
    }
    list.add(map);
}
```

> `getColumnLabel()` = 有别名返别名，没别名返列名（适配驼峰）；`getColumnName()` 永远返回原始列名。

---

## 12. 自增长主键回显

**一句话核心**：插入时主键是数据库自增生成的，插入后让 Java 拿回这个 id。

```java
// 关键：第二个参数告诉它「把生成的主键带回来」
PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS);
ps.executeUpdate();
ResultSet keys = ps.getGeneratedKeys();  // 拿到一行一列的结果集
keys.next();
int mainId = keys.getInt(1);  // 刚生成的主键
```

> 应用场景：主表 + 从表联动插入，从表外键要用主表刚生成的主键。

---

## 13. 批量插入优化

**一句话核心**：普通循环是「每次 executeUpdate 跑一趟 DB」，批量是「addBatch 装车 + executeBatch 一次发车」。

```java
// url 必须加 rewriteBatchedStatements=true
Connection conn = DriverManager.getConnection(
    "jdbc:mysql:///atguigu?rewriteBatchedStatements=true", "root", "root");
String sql = "insert into t_user(account,password,nickname) values (?,?,?)";  // 无分号！
PreparedStatement ps = conn.prepareStatement(sql);
for (int i = 0; i < 10000; i++) {
    ps.setObject(1, "user" + i);
    ps.setObject(2, "pwd");
    ps.setObject(3, "用户" + i);
    ps.addBatch();  // 装车：只暂存不执行
}
ps.executeBatch();  // 发车：一次性执行
```

> ⚠️ 三个细节：① url 要加 `rewriteBatchedStatements=true`；② SQL 末尾**不能有分号**；③ `addBatch()` 装货，`executeBatch()` 发车。

---

## 14. JDBC 事务

**一句话核心**：`setAutoCommit(false)` 关自动提交 = 开事务，成功 `commit()`，失败 `rollback()`。

```java
try {
    connection.setAutoCommit(false);  // ① 开事务
    bankDao.addMoney(addAccount, money, connection);  // 加钱
    bankDao.subMoney(subAccount, money, connection);  // 减钱
    connection.commit();               // ② 全成功提交
} catch (Exception e) {
    connection.rollback();             // ③ 有异常回滚
    throw e;
} finally {
    connection.close();                // ④ 无论如何关连接
}
```

> 🔥 **关键设计**：加钱和减钱**必须用同一个 connection**（所以 DAO 方法要接收 connection 参数）。各自 new 连接就是两个事务，回滚失效。

---

## 15. Druid 连接池

**一句话核心**：每次 `getConnection` 都新建连接开销大且连接数不可控，连接池**预先备好一批连接，用时借、用完还**。

```java
// 硬编码（了解，不推荐）
DruidDataSource ds = new DruidDataSource();
ds.setDriverClassName("com.mysql.cj.jdbc.Driver");
ds.setUsername("root");
ds.setPassword("root");
ds.setUrl("jdbc:mysql:///atguigu");

// 软编码（推荐：配置与代码分离）
Properties props = new Properties();
InputStream ips = DruidDemo.class.getClassLoader().getResourceAsStream("druid.properties");
props.load(ips);
DataSource ds = DruidDataSourceFactory.createDataSource(props);  // 工厂创建

Connection conn = ds.getConnection();  // 从池子借
conn.close();                          // 归还（不是真断开！）
```

> 🔥 **close() 含义变了**：连接池里 close 是「归还到池子」复用，不是物理断开。

---

## 16. 工具类封装 + ThreadLocal

**一句话核心**：把「建池、拿连接、还连接」抽成静态工具类。v1.0 缺陷是每次拿新连接，**ThreadLocal** 让同一线程拿到**同一个连接**（事务才不乱）。

```java
public class JDBCTools {
    private static DataSource ds;
    private static ThreadLocal<Connection> tl = new ThreadLocal<>();

    static {  // 类加载时初始化连接池（只一次）
        Properties pro = new Properties();
        pro.load(ClassLoader.getSystemResourceAsStream("druid.properties"));
        ds = DruidDataSourceFactory.createDataSource(pro);
    }

    public static Connection getConnection() throws SQLException {
        Connection conn = tl.get();      // 先拿本线程的连接
        if (conn == null) {              // 第一次：借一个存进柜子
            conn = ds.getConnection();
            tl.set(conn);
        }
        return conn;                     // 同一线程拿同一个
    }

    public static void free() throws SQLException {
        Connection conn = tl.get();
        if (conn != null) {
            tl.remove();                 // 清掉，防内存泄漏
            conn.setAutoCommit(true);    // 恢复自动提交
            conn.close();                // 还给池子
        }
    }
}
```

> 🔥 ThreadLocal 打比方：每个线程一个「寄存柜」，各存各的连接，互不干扰。A 存的连接 B 永远拿不到。

---

## 17. BaseDao（泛型 + 反射）（⭐ 面试高频）

**一句话核心**：每个表都要写重复的增删改查，抽成父类 BaseDao，子类只传「SQL + 参数」就能用。

### 17.1 通用 update（增删改统一）

```java
protected int update(String sql, Object... args) throws SQLException {
    Connection conn = JDBCTools.getConnection();
    PreparedStatement ps = conn.prepareStatement(sql);
    if (args != null && args.length > 0) {
        for (int i = 0; i < args.length; i++) {
            ps.setObject(i + 1, args[i]);  // ? 从 1 开始，数组从 0 开始 → i+1
        }
    }
    int len = ps.executeUpdate();
    ps.close();
    if (conn.getAutoCommit()) {  // 没开事务才关连接
        JDBCTools.free();
    }
    return len;
}
```

### 17.2 通用 query（反射封装成 JavaBean 列表）

```java
protected <T> ArrayList<T> query(Class<T> clazz, String sql, Object... args) throws Exception {
    // ...建连接、赋值占位符（同 update）...
    ResultSet res = ps.executeQuery();
    ResultSetMetaData meta = res.getMetaData();
    int columnCount = meta.getColumnCount();
    ArrayList<T> list = new ArrayList<>();
    while (res.next()) {
        T t = clazz.newInstance();  // 反射造对象（要求无参构造）
        for (int i = 1; i <= columnCount; i++) {
            Object value = res.getObject(i);
            String columnName = meta.getColumnLabel(i);
            Field field = clazz.getDeclaredField(columnName);  // 按列名找属性
            field.setAccessible(true);  // 允许访问 private
            field.set(t, value);        // 值塞进属性
        }
        list.add(t);
    }
    return list;
}
```

> 🔥 高频面试点（原 `问题总结.txt` 已整理）：
> - **为什么传 `Class<T> clazz`？** 泛型擦除不能 `new T()`，只能靠 Class 反射创建实体对象。
> - **为什么用 `getColumnLabel` 不用 `getColumnName`？** label 是 SQL 别名，适配实体驼峰命名；name 是数据库原始字段名。
> - **为什么 `getDeclaredField` 不是 `getField`？** getField 只拿 public，getDeclaredField 拿本类所有权限（含 private）。
> - **为什么用抽象类不用接口？** 接口不能写完整的 JDBC 实现方法，抽象类可以抽取通用反射查询逻辑。
> - **`newInstance()` 前提？** 实体类必须有无参构造。
> - **`if (conn.getAutoCommit())` 为什么判断？** true=没开事务，安全还连接；false=事务中，保留连接等业务 commit/rollback。

---

# Day 1 速查表（睡前扫一遍）

| 考点 | 一句话答案 |
|------|-----------|
| MySQL 默认存储引擎 | InnoDB（事务、外键、行锁） |
| InnoDB vs MyISAM | InnoDB 支持事务/外键/行锁；MyISAM 只支持表锁，不支持事务 |
| 索引结构 | B+Tree（矮 + 有序，支持范围查询排序） |
| 回表 vs 覆盖索引 | 回表=二级索引拿主键再查聚集索引；覆盖=返回列全在索引，不回表 |
| 最左前缀法则 | 联合索引从最左列开始，不跳中间列 |
| 索引失效 5 种 | 列运算 / 字符串不加引号 / like 头部% / or 一侧无索引 / 数据分布 |
| ACID | 原子性、一致性、隔离性、持久性 |
| 脏读/不可重复读/幻读 | 读未提交 / 同一行值变 / 行数变 |
| MySQL 默认隔离级别 | Repeatable Read |
| insert 优化 | 批量 + 手动事务 + 主键顺序 |
| count 优化 | 用 count(*) |
| JDBC 六步 | 注册驱动→连接→建对象→发SQL→解析→关资源 |
| SQL 注入怎么防 | PreparedStatement 预编译 + ? 占位 |
| executeUpdate vs executeQuery | 前者非 DQL 返 int，后者 DQL 返 ResultSet |
| 主键回显 | prepareStatement(sql, RETURN_GENERATED_KEYS) + getGeneratedKeys() |
| 批量插入 | addBatch + executeBatch + rewriteBatchedStatements=true |
| JDBC 事务 | setAutoCommit(false) + commit/rollback + 同一个 connection |
| 连接池 close() | 归还连接，不是物理断开 |
| ThreadLocal 作用 | 同一线程拿同一个连接 |
| BaseDao 为什么传 Class | 泛型擦除不能 new T()，靠反射创建对象 |
