import java.sql.*;
import java.util.*;

/**
 * JDBC 复习练习（Day 1 · JDBC 部分）—— 参考答案（已补全）
 * 对应复习笔记：复习/Day1-MySQL与JDBC.md
 *
 * 涵盖知识点（都是重点，各 1 题）：
 *   1. PreparedStatement 的 CRUD（增删改查）
 *   2. JDBC 事务（转账，同一个 connection）
 *   3. 自增长主键回显（RETURN_GENERATED_KEYS）
 *
 * ⚠️ 前置准备：先在 MySQL 里执行本文件【底部注释】的建表 SQL，建好表再运行。
 * ⚠️ 依赖：需要 mysql-connector-j 驱动 jar（8.0.27 或以上）。
 */
public class JdbcReviewExercise {

    // ============================================================
    // 连接信息（统一用常量，别在方法里手打）
    // ============================================================
    private static final String URL      = "jdbc:mysql://localhost:3306/itcast";
    private static final String USER     = "root";
    private static final String PASSWORD = "123456";


    // ====================================================================
    // 题1：PreparedStatement 的 CRUD（增删改查）
    // ====================================================================

    public static void question1Insert() throws Exception {
        // 1. 注册驱动
        Class.forName("com.mysql.cj.jdbc.Driver");
        // 2. 获取连接
        Connection conn = DriverManager.getConnection(URL, USER, PASSWORD);
        // 3. SQL 骨架（? 占位）
        String sql = "insert into t_user(account, password, nickname) values (?, ?, ?)";
        // 4. 建 PreparedStatement
        PreparedStatement ps = conn.prepareStatement(sql);
        // 5. 给 ? 赋值（下标从 1 开始）
        ps.setString(1, "test");
        ps.setString(2, "test");
        ps.setString(3, "测试");
        // 6. 执行，打印影响行数
        int rows = ps.executeUpdate();
        System.out.println("插入 " + rows + " 行");
        // 7. 关资源
        ps.close();
        conn.close();
    }

    public static void question1Update() throws Exception {
        Class.forName("com.mysql.cj.jdbc.Driver");
        Connection conn = DriverManager.getConnection(URL, USER, PASSWORD);
        String sql = "update t_user set nickname = ? where account = ?";
        PreparedStatement ps = conn.prepareStatement(sql);
        ps.setString(1, "tomcat");
        ps.setString(2, "test");
        int rows = ps.executeUpdate();
        System.out.println("修改 " + rows + " 行");
        ps.close();
        conn.close();
    }

    public static void question1Delete() throws Exception {
        Class.forName("com.mysql.cj.jdbc.Driver");
        Connection conn = DriverManager.getConnection(URL, USER, PASSWORD);
        String sql = "delete from t_user where account = ?";
        PreparedStatement ps = conn.prepareStatement(sql);
        ps.setString(1, "test");
        int rows = ps.executeUpdate();
        System.out.println("删除 " + rows + " 行");
        ps.close();
        conn.close();
    }

    public static void question1Query() throws Exception {
        Class.forName("com.mysql.cj.jdbc.Driver");
        Connection conn = DriverManager.getConnection(URL, USER, PASSWORD);
        String sql = "select * from t_user";
        PreparedStatement ps = conn.prepareStatement(sql);
        ResultSet rs = ps.executeQuery();

        // 拿列信息
        ResultSetMetaData metaData = rs.getMetaData();
        int columnCount = metaData.getColumnCount();

        List<Map<String, Object>> list = new ArrayList<>();
        while (rs.next()) {                           // 每一行
            Map<String, Object> map = new HashMap<>();
            for (int i = 1; i <= columnCount; i++) {  // 列下标从 1 开始
                String columnName = metaData.getColumnLabel(i); // 列名当 key
                Object value      = rs.getObject(i);           // 列值当 value
                map.put(columnName, value);
            }
            list.add(map);
        }

        for (Map<String, Object> map : list) {
            System.out.println(map);
        }

        rs.close();
        ps.close();
        conn.close();
    }


    // ====================================================================
    // 题2：JDBC 事务（转账）
    // ====================================================================

    public static void question2Transfer() throws Exception {
        Class.forName("com.mysql.cj.jdbc.Driver");
        Connection conn = DriverManager.getConnection(URL, USER, PASSWORD);
        try {
            conn.setAutoCommit(false);       // 开事务（关自动提交）
            subMoney("张三", 500, conn);     // 张三 -500
            addMoney("李四", 500, conn);     // 李四 +500（同一个 conn）
            conn.commit();                   // 全部成功才提交
            System.out.println("转账成功");
        } catch (Exception e) {
            conn.rollback();                 // 出错回滚
            System.out.println("转账失败，已回滚");
            throw e;
        } finally {
            conn.close();
        }
    }

    // 加钱（用调用方传入的 conn，不自己 new 连接）
    private static void addMoney(String account, double money, Connection conn) throws SQLException {
        String sql = "update t_bank set money = money + ? where account = ?";
        PreparedStatement ps = conn.prepareStatement(sql);
        ps.setDouble(1, money);
        ps.setString(2, account);
        ps.executeUpdate();
        ps.close();   // 只关 ps，不关 conn（conn 归调用方管）
    }

    // 减钱
    private static void subMoney(String account, double money, Connection conn) throws SQLException {
        String sql = "update t_bank set money = money - ? where account = ?";
        PreparedStatement ps = conn.prepareStatement(sql);
        ps.setDouble(1, money);
        ps.setString(2, account);
        ps.executeUpdate();
        ps.close();
    }


    // ====================================================================
    // 题3：自增长主键回显
    // ====================================================================

    public static void question3ReturnKey() throws Exception {
        Class.forName("com.mysql.cj.jdbc.Driver");
        Connection conn = DriverManager.getConnection(URL, USER, PASSWORD);
        String sql = "insert into t_user(account, password, nickname) values (?, ?, ?)";
        // 关键：prepareStatement 第二个参数传 RETURN_GENERATED_KEYS
        PreparedStatement ps = conn.prepareStatement(sql, Statement.RETURN_GENERATED_KEYS);
        ps.setString(1, "zhang");
        ps.setString(2, "123");
        ps.setString(3, "张三");
        ps.executeUpdate();                       // ★ 必须先执行插入

        ResultSet keys = ps.getGeneratedKeys();   // 拿主键结果集
        if (keys.next()) {                        // 游标先下移
            int id = keys.getInt(1);              // 第 1 列就是主键
            System.out.println("新插入的主键 id = " + id);
        }
        keys.close();
        ps.close();
        conn.close();
    }


    // ========== 运行 ==========
    public static void main(String[] args) throws Exception {
        System.out.println("========== 题1：CRUD ==========");
        question1Insert();
        question1Query();
        question1Update();
        question1Query();
        question1Delete();
        question1Query();

        System.out.println("========== 题2：事务转账 ==========");
        question2Transfer();

        System.out.println("========== 题3：主键回显 ==========");
        question3ReturnKey();
    }
}

/*
 * ============================================================
 * 建表 SQL（先在 MySQL 执行）
 * ============================================================
USE itcast;

-- 用户表（题1 CRUD 和 题3 主键回显 用）
DROP TABLE IF EXISTS t_user;
CREATE TABLE t_user(
    id       INT PRIMARY KEY AUTO_INCREMENT COMMENT '用户主键',
    account  VARCHAR(20) NOT NULL UNIQUE COMMENT '账号',
    password VARCHAR(64) NOT NULL COMMENT '密码',
    nickname VARCHAR(20) NOT NULL COMMENT '昵称'
);
INSERT INTO t_user(account,password,nickname) VALUES
('root','123456','经理'),('admin','666666','管理员');

-- 银行表（题2 事务 用）
DROP TABLE IF EXISTS t_bank;
CREATE TABLE t_bank(
    id      INT PRIMARY KEY AUTO_INCREMENT COMMENT '账号主键',
    account VARCHAR(20) NOT NULL UNIQUE COMMENT '账号',
    money   DOUBLE(10,2) COMMENT '余额'
);
INSERT INTO t_bank(account,money) VALUES ('张三', 2000), ('李四', 2000);
 * ============================================================
 */
