# 两天复习冲刺 · Java + MySQL + JDBC

> 用法：每个知识点都是 **「一句话核心 → 举例 → 易错点/记忆点」** 三段式，先看核心回忆，想不起来再看举例。刷完一节就打勾 ✅。

---

## 两天怎么分

| 天 | 主题 | 内容 | 预估时长 |
|----|------|------|---------|
| **Day 1** | 数据侧 | MySQL 全部（基础 + 进阶）+ JDBC 全部 | 6~8 小时 |
| **Day 2** | 语言侧 | Java 核心（多线程 / 集合 / Map / IO / 网络 / JDK新特性） | 6~8 小时 |

> 为什么 MySQL 和 JDBC 放一天？因为 JDBC 就是「用 Java 代码操作 MySQL」，两者强关联，一起刷能互相印证。Java 那堆集合、IO、多线程是纯语言侧，独立成一天。

---

## Day 1 复习清单（MySQL + JDBC）

### 一、MySQL 基础篇

- [ ] 1. 常用函数（字符串 / 数值 / 日期 / 流程）
- [ ] 2. 约束（NOT NULL / UNIQUE / PK / DEFAULT / CHECK / 外键）
- [ ] 3. 多表查询（内连接 / 外连接 / 自连接 / 联合 / 子查询）
- [ ] 4. 事务（ACID / 隔离级别 / 并发问题）

### 二、MySQL 进阶篇

- [ ] 5. 存储引擎（InnoDB / MyISAM / Memory）
- [ ] 6. 索引（B+Tree / 最左前缀 / 失效场景 / 回表 / 覆盖索引）
- [ ] 7. SQL 优化（insert / order by / group by / limit / count / update）

### 三、JDBC

- [ ] 8. 核心概念（接口 + 驱动）
- [ ] 9. 六步基本流程
- [ ] 10. Statement vs PreparedStatement（SQL 注入）
- [ ] 11. CRUD（executeUpdate / executeQuery）
- [ ] 12. 自增长主键回显
- [ ] 13. 批量插入优化
- [ ] 14. JDBC 事务
- [ ] 15. Druid 连接池
- [ ] 16. 工具类封装 + ThreadLocal
- [ ] 17. BaseDao（泛型 + 反射）

---

## Day 2 复习清单（Java 核心）

- [ ] 1. 多线程（synchronized / 死锁 / 线程池）
- [ ] 2. Collection 接口 & 迭代器
- [ ] 3. ArrayList 源码三要点（懒加载 / 扩容）
- [ ] 4. HashSet 去重（hashCode + equals）
- [ ] 5. HashMap 底层原理（数组 + 链表 + 红黑树）
- [ ] 6. 增强 for & HashMap 三种遍历
- [ ] 7. 泛型（基础 & 泛型方法）
- [ ] 8. IO 流（字节 / 字符 / 缓冲 / 序列化 / Properties）
- [ ] 9. 网络编程（TCP / UDP / 三次握手四次挥手）
- [ ] 10. JDK 新特性（Lambda / 函数式接口 / Stream）

---

## 复习建议

1. **先回忆再看**：每个知识点先自己说一遍「它是什么、怎么用」，卡壳了再看笔记。直接看等于没复习。
2. **手敲一遍**：所有代码/SQL 示例，别光看，**自己敲一遍**。尤其 JDBC 六步、HashMap 底层、索引失效，这些都是面试手撕常客。
3. **优先背熟标 ⭐ 的**：面试高频点我都标了 ⭐，时间不够先啃这些。
4. **睡前过一遍速查表**：每个章节末尾都有速查表，睡前 5 分钟扫一遍，效果翻倍。

---

## 配套练习题（在 `练习题/` 目录）

> 每题都是「数据准备 + TODO + 提示 + 思考」，**没有答案**，自己动手写。重点知识点 3 题、非重点 2 题。

| 文件 | 内容 | 题量 |
|------|------|------|
| `练习题/01_综合复习练习.sql` | SQL 综合：函数 / 多表查询 / 聚合分组 / 事务 / 索引 | 12 题 |
| `练习题/JdbcReviewExercise.java` | JDBC：CRUD / 事务 / 主键回显 | 3 题 |
| `练习题/ThreadReviewExercise.java` | 多线程：synchronized 售票 / 死锁 / 线程池 | 3 题 |
| `练习题/MapReviewExercise.java` | 集合 Map：HashSet 去重 / HashMap 遍历 / 嵌套 List | 3 题 |

**使用说明**：
- SQL 文件：先执行文件头部的【数据准备】建表脚本，再做题。
- Java 文件：已去掉 package 声明（默认包），新建一个 Java 项目把文件丢进去即可编译运行；JDBC 那题需要先建表 + 引入 mysql-connector-j 驱动 jar（建表 SQL 在文件底部注释）。

---

## 备注

- 笔记基于你 GitHub 上的 `Mysql_excises`、`JDBC`、`java-learning` 三个仓库的笔记整理。
- 原仓库笔记没写清楚的地方（比如 MySQL 函数、约束、索引的练习 SQL），我补充了完整可运行的例子。
