-- ============================================================
-- 复习综合练习（Day 1 · MySQL 部分）
-- 涵盖：函数 / 多表查询 / 聚合分组 / 事务 / 索引
-- 对应复习笔记：复习/Day1-MySQL与JDBC.md
-- ============================================================

-- ============================================================
-- 【数据准备】先执行下面全部 SQL（用 itcast 库）
-- ============================================================
USE itcast;

-- 部门表
DROP TABLE IF EXISTS dept;
CREATE TABLE dept(
    id   INT         COMMENT '部门ID',
    name VARCHAR(20) COMMENT '部门名称'
) COMMENT '部门表';
INSERT INTO dept VALUES
(1, '研发部'), (2, '市场部'), (3, '财务部'), (4, '销售部'), (5, '人事部');

-- 员工表（dept_id 外键指向 dept，manager_id 自连接指向 emp）
DROP TABLE IF EXISTS emp;
CREATE TABLE emp(
    id         INT             COMMENT '员工ID',
    name       VARCHAR(10)     COMMENT '姓名',
    gender     CHAR(1)         COMMENT '性别',
    age        TINYINT UNSIGNED COMMENT '年龄',
    entrydate  DATE            COMMENT '入职日期',
    salary     INT             COMMENT '月薪',
    dept_id    INT             COMMENT '所属部门ID',
    manager_id INT             COMMENT '直属领导ID（NULL表示无上级）'
) COMMENT '员工表';

INSERT INTO emp VALUES
(1 , '张无忌', '男', 28, '2018-03-01', 15000, 1, NULL),
(2 , '赵敏',   '女', 24, '2020-07-15', 12000, 1, 1),
(3 , '周芷若', '女', 22, '2022-01-10', 11000, 1, 1),
(4 , '韦一笑', '男', 38, '2010-05-20', 20000, 2, NULL),
(5 , '杨逍',   '男', 35, '2012-09-01', 18000, 2, 4),
(6 , '范瑶',   '男', 40, '2009-03-15', 16000, 2, 4),
(7 , '黛绮丝', '女', 36, '2011-11-11', 13000, 3, NULL),
(8 , '常遇春', '男', 30, '2016-06-30', 10000, 3, 7),
(9 , '张三丰', '男', 70, '1990-01-01', 30000, NULL, NULL),
(10, '灭绝',   '女', 50, '2000-08-08', 17000, 4, NULL),
(11, '胡青牛', '男', 45, '2005-04-12', 14000, 4, 10),
(12, '小昭',   '女', 18, '2023-02-28', 8000 , 1, 2);

-- 工资等级表
DROP TABLE IF EXISTS salgrade;
CREATE TABLE salgrade(
    grade INT COMMENT '等级',
    losal INT COMMENT '最低工资',
    hisal INT COMMENT '最高工资'
) COMMENT '工资等级表';
INSERT INTO salgrade VALUES
(1, 0,    10000),
(2, 10001, 15000),
(3, 15001, 20000),
(4, 20001, 99999);

-- 账户表（用于事务练习）
DROP TABLE IF EXISTS account;
CREATE TABLE account(
    id    INT PRIMARY KEY AUTO_INCREMENT COMMENT 'ID',
    name  VARCHAR(10) COMMENT '姓名',
    money DOUBLE(10,2) COMMENT '余额'
) COMMENT '账户表';
INSERT INTO account(name, money) VALUES ('张三', 2000), ('李四', 2000);


-- ============================================================
-- 第一章：函数（字符串 / 日期 / 流程）—— 3 题
-- ============================================================

-- TODO 1: 查询员工姓名和「5 位工号」，工号 = id 左边补 0（如 1 → 00001）
-- 提示：LPAD(字段, 5, '0')
-- 思考：LPAD 和 RPAD 的区别？补零是在左边还是右边？
select name,lpad(id,5,'0') from emp;

-- TODO 2: 查询员工姓名和「入职天数」（入职日期到今天过了多少天），按入职天数降序
-- 提示：DATEDIFF(CURDATE(), entrydate)；注意 DATEDIFF 是「前减后」
-- 思考：DATEDIFF('2021-01-01', '2020-01-01') 结果是正还是负？
select name,datediff(curdate(),entrydate) from emp order by datediff(curdate(),entrydate) desc ;

-- TODO 3: 查询员工姓名、月薪、薪资等级（用 CASE WHEN 把薪资分级）：
--         >=20000 → '高薪'，>=12000 → '中等'，否则 '普通'
-- 提示：CASE WHEN salary >= 20000 THEN ... END
-- 思考：这个分级需求能用「等值匹配」的 CASE 写法实现吗？为什么？
select name,salary,
       case when salary>=20000 then '高薪'
when salary>=12000 then '中等'
else '普通' end as '工资等级' from emp;
-- ============================================================
-- 第二章：多表查询（内连接 / 外连接 / 子查询）—— 3 题
-- ============================================================

-- TODO 4: 查询员工姓名、部门名称、工资等级（三表连接）
-- 提示：emp JOIN dept ON dept_id，再 JOIN salgrade ON salary BETWEEN losal AND hisal
-- 思考：内连接会过滤掉什么？张三丰（dept_id=NULL）会被查出来吗？
select e.name,d.name,s.grade from emp e
    join dept d on e.dept_id = d.id
    join salgrade s on salary  between losal and hisal;

-- TODO 5: 查询「每个部门的平均工资」，没有员工的部门也要显示（平均工资为 NULL 或 0）
-- 提示：dept LEFT JOIN emp，GROUP BY 部门，AVG(salary)
-- 思考：为什么这里要用 dept 作为左表，而不是 emp 作为左表？
select d.name,avg(e.salary) from dept d left join emp e on d.id = e.dept_id group by d.name;

-- TODO 6: 查询工资比「研发部最高工资」还高的员工姓名和薪资
-- 提示：子查询先查出研发部最高工资 MAX(salary)，外层 WHERE salary > (子查询)
-- 思考：这是哪一类子查询（标量/列/行/表）？
select max(salary) from emp join dept d on emp.dept_id = d.id where d.name ='研发部';
select name,salary from emp
where salary>(select max(salary) from emp join dept d on emp.dept_id = d.id where d.name ='研发部');

-- ============================================================
-- 第三章：聚合 + 分组 + 排序 + 分页 —— 2 题
-- ============================================================

-- TODO 7: 查询每个部门的员工人数和最高工资，只显示人数 >= 2 的部门
-- 提示：GROUP BY dept_id，HAVING COUNT(*) >= 2
-- 思考：WHERE 和 HAVING 的区别？为什么这里不能用 WHERE？
select d.name,count(*),max(salary) from emp join dept d on emp.dept_id = d.id group by d.name having count(*)>=2;

-- TODO 8: 查询工资最高的前 3 名员工的姓名和薪资
-- 提示：ORDER BY salary DESC LIMIT 3
-- 思考：如果有并列第 3 名，LIMIT 3 会怎么处理？(知道就行，不用写)
select name,salary from emp order by salary desc limit 3;

-- ============================================================
-- 第四章：事务 —— 2 题
-- ============================================================

-- TODO 9: 用事务实现转账：张三转 500 给李四
-- 要求：
--   ① START TRANSACTION 开启事务
--   ② 张三 money - 500
--   ③ 李四 money + 500
--   ④ COMMIT 提交（写完先别真的提交，想想要是中间出错该写什么）
-- 提示：ROLLBACK 是回滚，写在 COMMIT 之前观察效果
start transaction ;
update account set money=money-500 where name='张三';
update account set money=money+500 where name='李四';
commit ;

-- TODO 10: 查看当前会话的隔离级别，并说明 MySQL 默认隔离级别是什么
-- 提示：SELECT @@TRANSACTION_ISOLATION
-- 思考：默认隔离级别能解决哪些并发问题？不能解决哪个？
select @@TRANSACTION_ISOLATION;

-- ============================================================
-- 第五章：索引 —— 2 题
-- ============================================================

-- TODO 11: 给 emp 表建索引
--   ① 给 name 建一个普通索引 idx_emp_name
--   ② 给 dept_id 建一个普通索引 idx_emp_deptid
--   ③ 用 SHOW INDEX FROM emp 查看建好的索引
-- 提示：CREATE INDEX idx ON emp(字段)
create index idx_emp_name on emp(name);
create index idx_emp_deptid on emp(dept_id);
show index from emp;

-- TODO 12: 用 EXPLAIN 分析下面这条查询，观察 type 和 key 字段
--   EXPLAIN SELECT * FROM emp WHERE name = '张无忌';
-- 要求：
--   ① 先不加索引执行一次，记录 type 和 key
--   ② 加上 idx_emp_name 后再执行一次，观察 type 和 key 的变化
-- 提示：type 从「ALL（全表扫描）」变成「ref（走索引）」就是索引生效了
-- 思考：key 字段为 NULL 说明什么？
EXPLAIN SELECT * FROM emp WHERE name = '张无忌';

