#import "@preview/cuti:0.3.0": show-cn-fakebold
#show: show-cn-fakebold
#import "@preview/codelst:2.0.2": sourcecode
#import "@preview/codly:1.3.0": *

#show emph: set text(font: ("Libertinus Serif", "KaiTi"), size: 10pt)

#let title = "实习二：数据库约束设计"
#let date = datetime.today()
#set text(
  lang: "zh",
  font: ("Libertinus Serif", "SimSun"),
  region: "cn",
  size: 10pt,
)
#set page(
  "a4",
  margin: 1in,
	numbering: "第 1 页, 共 1 页",
	header: context {
		if counter(page).at(here()).first() > 1 [
		#grid(
			columns: (1fr, auto, 1fr),
			align: (left, center, right),
			[_北京大学_], [], [2025_年春季学期数据库概论_]
		)
		#v(-10pt)
		#line(length: 100%, stroke: 0.5pt)
	]}
)
#show raw.where(block: false): set text(font: "Maple Mono NF", size: 9pt, weight: "light")
#show raw.where(block: true): set text(font: "Maple Mono NF", size: 8pt, weight: "light")
#set heading(
  numbering: "1.1.1.1."
)
#set enum(
  numbering: "1..a..i."
)
#show link: this => {
	set text(bottom-edge: "bounds", top-edge: "bounds")
	text(this, fill: rgb("#433af4"))
}

#show: codly-init.with()


#align(center,
[#block(text(size: 16pt, [*#title*]))
#block(text(size: 12pt, [_吕杭州_ 2200013126 #h(1cm) _戴思颖_ 2200094811 #h(1cm) _戴傅聪_ 2100013061]))
#block(text(size: 12pt, [
	#date.year()_年_#date.month()_月_#date.day()_日_
]))])

#set par(
	justify: true,
	linebreaks: "optimized"
)

本次实习的目标是请同学们体验如何在数据库中利用各种手段完成数据库约束设计。完善的约束设计功能使得数据一致性维护以及业务规则甚至异常处理都可以统一在服务器端完成，减轻了应用处理的负担。同学们在实现各个约束的时候，应该同时给出正负测试样例，也即符合约束以及违反约束的增删改操作。

具体的约束设计任务我们分为基础、中级、高级、扩展四部分，如下：

= 基本约束设计

我们需要为以下两个表设计约束
- Emp(#underline[eno], ename, birthday, level, position, salary, dno)
- Dept(#underline[dno], dname, budget, manager)

约束要求：
1. eno和dno是递增序列号形式的主键，长度为4的整型，格式为0001、0002等
2. Emp中的dno为参照Dept的外键，Dept的manager为参照Emp的外键
3. 测试外键定义的三种形式
4. 限定dname为枚举类型（数学学院、计算机学院、智能学院、电子学院、元培学院）
5. 限定position为枚举类型（教师、教务、会计、秘书）
6. 限定level为1到5，默认值为3，salary为2000到200000

```python
import os
from sqlalchemy import create_engine, text, MetaData, Column, Integer, String, Float, Date, ForeignKey, CheckConstraint
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker, relationship
from datetime import date
```

```python
# 创建SQLite数据库连接
engine = create_engine('sqlite:///employee_dept.db', echo=True)
metadata = MetaData()
Base = declarative_base()

# 创建会话
Session = sessionmaker(bind=engine)
session = Session()
```

#no-codly[
	```txt
	C:\Users\Dai\AppData\Local\Temp\ipykernel_14120\1065261567.python:4: MovedIn20Warning: The ``declarative_base()`` function is now available as sqlalchemy.orm.declarative_base(). (deprecated since: 2.0) (Background on SQLAlchemy 2.0 at: https://sqlalche.me/e/b8d9)
  Base = declarative_base()
	```
]

```python
# 如果已经存在数据库，删除它
if os.path.exists('employee_dept.db'):
    os.remove('employee_dept.db')
    print("删除现有数据库文件")
```

#no-codly[
	```txt
	删除现有数据库文件
	```
]

```python
# 定义Emp表（放在前面，因为Dept表需要引用它）
class Emp(Base):
    __tablename__ = 'emp'  # 修正了双下划线
    
    eno = Column(String(4), primary_key=True)
    ename = Column(String(50))
    birthday = Column(Date)
    level = Column(Integer, CheckConstraint("level BETWEEN 1 AND 5"), default=3)
    position = Column(String(10), CheckConstraint("position IN ('教师', '教务', '会计', '秘书')"))
    salary = Column(Float, CheckConstraint("salary BETWEEN 2000 AND 200000"))
    dno = Column(String(4), ForeignKey('dept.dno', deferrable=True, initially='DEFERRED'))

    def __repr__(self):
        return f"<Emp(eno='{self.eno}', ename='{self.ename}', level={self.level}, position='{self.position}', salary={self.salary}, dno='{self.dno}')>"
    
    # 注意：我们将在Dept类定义后添加关系

# 定义Dept表
class Dept(Base):
    __tablename__ = 'dept'  # 修正了双下划线
    
    dno = Column(String(4), primary_key=True)
    dname = Column(String(20), CheckConstraint("dname IN ('数学学院', '计算机学院', '智能学院', '电子学院', '元培学院')"))
    budget = Column(Float)
    manager = Column(String(4), ForeignKey('emp.eno', deferrable=True, initially='DEFERRED'))

    def __repr__(self):
        return f"<Dept(dno='{self.dno}', dname='{self.dname}', budget={self.budget}, manager='{self.manager}')>"

# 添加关系引用，解决循环引用问题
Emp.department = relationship("Dept", foreign_keys=[Emp.dno], backref="employees")
Dept.manager_emp = relationship("Emp", foreign_keys=[Dept.manager])
```

```python
# 创建表
Base.metadata.create_all(engine)
```

#no-codly[
	```txt
	2025-04-19 12:11:39,389 INFO sqlalchemy.engine.Engine BEGIN (implicit)
	2025-04-19 12:11:39,391 INFO sqlalchemy.engine.Engine PRAGMA main.table_info("emp")
	2025-04-19 12:11:39,391 INFO sqlalchemy.engine.Engine [raw sql] ()
	2025-04-19 12:11:39,393 INFO sqlalchemy.engine.Engine PRAGMA temp.table_info("emp")
	2025-04-19 12:11:39,393 INFO sqlalchemy.engine.Engine [raw sql] ()
	2025-04-19 12:11:39,395 INFO sqlalchemy.engine.Engine PRAGMA main.table_info("dept")
	2025-04-19 12:11:39,395 INFO sqlalchemy.engine.Engine [raw sql] ()
	2025-04-19 12:11:39,396 INFO sqlalchemy.engine.Engine PRAGMA temp.table_info("dept")
	2025-04-19 12:11:39,397 INFO sqlalchemy.engine.Engine [raw sql] ()
	2025-04-19 12:11:39,399 INFO sqlalchemy.engine.Engine 
	CREATE TABLE emp (
		eno VARCHAR(4) NOT NULL, 
		ename VARCHAR(50), 
		birthday DATE, 
		level INTEGER CHECK (level BETWEEN 1 AND 5), 
		position VARCHAR(10) CHECK (position IN ('教师', '教务', '会计', '秘书')), 
		salary FLOAT CHECK (salary BETWEEN 2000 AND 200000), 
		dno VARCHAR(4), 
		PRIMARY KEY (eno), 
		FOREIGN KEY(dno) REFERENCES dept (dno) DEFERRABLE INITIALLY DEFERRED
	)


	2025-04-19 12:11:39,399 INFO sqlalchemy.engine.Engine [no key 0.00049s] ()
	2025-04-19 12:11:39,452 INFO sqlalchemy.engine.Engine 
	CREATE TABLE dept (
		dno VARCHAR(4) NOT NULL, 
		dname VARCHAR(20) CHECK (dname IN ('数学学院', '计算机学院', '智能学院', '电子学院', '元培学院')), 
		budget FLOAT, 
		manager VARCHAR(4), 
		PRIMARY KEY (dno), 
		FOREIGN KEY(manager) REFERENCES emp (eno) DEFERRABLE INITIALLY DEFERRED
	)


	2025-04-19 12:11:39,454 INFO sqlalchemy.engine.Engine [no key 0.00267s] ()
	2025-04-19 12:11:39,471 INFO sqlalchemy.engine.Engine COMMIT
	```
]

```python
# 定义测试函数
def run_test(test_name, test_func):
    """运行测试并打印结果"""
    print(f"\n测试: {test_name}")
    print("-" * 50)
    try:
        test_func()
        print("✓ 测试通过")
    except Exception as e:
        print(f"✗ 测试失败: {e}")
    finally:
        session.rollback()
```

```python
# 为SQLite创建序列模拟功能
def get_next_id(table_name):
    max_id_query = text(f"SELECT MAX(CAST(SUBSTR({table_name[0]}no, 1, 4) AS INTEGER)) FROM {table_name}")
    result = engine.execute(max_id_query).scalar()
    next_id = 1 if result is None else result + 1
    return f"{next_id:04d}"
```

```python
# 插入初始数据
try:
    session.begin()
    dept1 = Dept(dno="0001", dname="计算机学院", budget=1000000)
    dept2 = Dept(dno="0002", dname="数学学院", budget=800000)
    dept3 = Dept(dno="0003", dname="智能学院", budget=1200000)
    session.add_all([dept1, dept2, dept3])
    session.flush()

    emp1 = Emp(eno="0001", ename="张三", birthday=date(1980, 1, 15), level=4, position="教师", salary=15000, dno="0001")
    emp2 = Emp(eno="0002", ename="李四", birthday=date(1985, 3, 20), level=3, position="教务", salary=8000, dno="0002")
    emp3 = Emp(eno="0003", ename="王五", birthday=date(1990, 7, 10), level=5, position="教师", salary=20000, dno="0003")
    session.add_all([emp1, emp2, emp3])
    session.flush()

    dept1.manager = "0001"
    dept2.manager = "0002"
    dept3.manager = "0003"

    session.commit()
except Exception as e:
    session.rollback()
    print(f"插入数据时出错: {e}")
```

#no-codly[
```
2025-04-19 12:11:41,364 INFO sqlalchemy.engine.Engine BEGIN (implicit)
2025-04-19 12:11:41,366 INFO sqlalchemy.engine.Engine INSERT INTO dept (dno, dname, budget, manager) VALUES (?, ?, ?, ?)
2025-04-19 12:11:41,367 INFO sqlalchemy.engine.Engine [generated in 0.00080s] [('0001', '计算机学院', 1000000.0, None), ('0002', '数学学院', 800000.0, None), ('0003', '智能学院', 1200000.0, None)]
2025-04-19 12:11:41,370 INFO sqlalchemy.engine.Engine INSERT INTO emp (eno, ename, birthday, level, position, salary, dno) VALUES (?, ?, ?, ?, ?, ?, ?)
2025-04-19 12:11:41,370 INFO sqlalchemy.engine.Engine [generated in 0.00069s] [('0001', '张三', '1980-01-15', 4, '教师', 15000.0, '0001'), ('0002', '李四', '1985-03-20', 3, '教务', 8000.0, '0002'), ('0003', '王五', '1990-07-10', 5, '教师', 20000.0, '0003')]
2025-04-19 12:11:41,374 INFO sqlalchemy.engine.Engine UPDATE dept SET manager=? WHERE dept.dno = ?
2025-04-19 12:11:41,375 INFO sqlalchemy.engine.Engine [generated in 0.00123s] [('0001', '0001'), ('0002', '0002'), ('0003', '0003')]
2025-04-19 12:11:41,376 INFO sqlalchemy.engine.Engine COMMIT
```
]

```python
# 测试默认值
try:
    session.begin()
    emp_default = Emp(eno="0004", ename="吴十", birthday=date(1991, 8, 25), position="秘书", salary=7000, dno="0003")
    session.add(emp_default)
    session.commit()
    emp_result = session.query(Emp).filter_by(ename="吴十").first()
    print(f"默认值测试结果: {emp_result.level}")
except Exception as e:
    session.rollback()
    print(f"测试默认值时出错: {e}")
```

#no-codly[
```
2025-04-19 12:11:42,175 INFO sqlalchemy.engine.Engine BEGIN (implicit)
2025-04-19 12:11:42,177 INFO sqlalchemy.engine.Engine INSERT INTO emp (eno, ename, birthday, level, position, salary, dno) VALUES (?, ?, ?, ?, ?, ?, ?)
2025-04-19 12:11:42,177 INFO sqlalchemy.engine.Engine [generated in 0.00059s] ('0004', '吴十', '1991-08-25', 3, '秘书', 7000.0, '0003')
2025-04-19 12:11:42,192 INFO sqlalchemy.engine.Engine COMMIT
2025-04-19 12:11:42,207 INFO sqlalchemy.engine.Engine BEGIN (implicit)
2025-04-19 12:11:42,209 INFO sqlalchemy.engine.Engine SELECT emp.eno AS emp_eno, emp.ename AS emp_ename, emp.birthday AS emp_birthday, emp.level AS emp_level, emp.position AS emp_position, emp.salary AS emp_salary, emp.dno AS emp_dno 
FROM emp 
WHERE emp.ename = ?
 LIMIT ? OFFSET ?
2025-04-19 12:11:42,209 INFO sqlalchemy.engine.Engine [generated in 0.00060s] ('吴十', 1, 0)
默认值测试结果: 3
```
]

```python
# 正向测试用例
def test_valid_emp_insert():
    """测试正常员工数据插入"""
    emp = Emp(
        eno="0006", 
        ename="吴六", 
        birthday=date(1990, 5, 15), 
        level=2, 
        position="教师", 
        salary=12000, 
        dno="0001"
    )
    session.add(emp)
    session.commit()

    # 验证插入成功
    result = session.query(Emp).filter_by(eno="0003").first()
    assert result is not None, "员工数据未成功插入"
    print(f"成功插入员工: {result}")
    
run_test("正常员工数据插入", test_valid_emp_insert)
```

#no-codly[
```txt

测试: 正常员工数据插入
--------------------------------------------------
2025-04-19 12:11:43,735 INFO sqlalchemy.engine.Engine INSERT INTO emp (eno, ename, birthday, level, position, salary, dno) VALUES (?, ?, ?, ?, ?, ?, ?)
2025-04-19 12:11:43,736 INFO sqlalchemy.engine.Engine [generated in 0.00111s] ('0006', '吴六', '1990-05-15', 2, '教师', 12000.0, '0001')
2025-04-19 12:11:43,741 INFO sqlalchemy.engine.Engine COMMIT
2025-04-19 12:11:43,755 INFO sqlalchemy.engine.Engine BEGIN (implicit)
2025-04-19 12:11:43,758 INFO sqlalchemy.engine.Engine SELECT emp.eno AS emp_eno, emp.ename AS emp_ename, emp.birthday AS emp_birthday, emp.level AS emp_level, emp.position AS emp_position, emp.salary AS emp_salary, emp.dno AS emp_dno 
FROM emp 
WHERE emp.eno = ?
 LIMIT ? OFFSET ?
2025-04-19 12:11:43,758 INFO sqlalchemy.engine.Engine [generated in 0.00128s] ('0003', 1, 0)
成功插入员工: <Emp(eno='0003', ename='王五', level=5, position='教师', salary=20000.0, dno='0003')>
✓ 测试通过
2025-04-19 12:11:43,762 INFO sqlalchemy.engine.Engine ROLLBACK
```
]

```python
def test_valid_dept_insert():
    """测试正常部门数据插入"""
    dept = Dept(
        dno="0005", 
        dname="电子学院", 
        budget=1200000, 
        manager="0004"
    )
    session.add(dept)
    session.commit()
    
    # 验证插入成功
    result = session.query(Dept).filter_by(dno="0003").first()
    assert result is not None, "部门数据未成功插入"
    print(f"成功插入部门: {result}")

run_test("正常部门数据插入", test_valid_dept_insert)
```

#no-codly[
```

测试: 正常部门数据插入
--------------------------------------------------
2025-04-19 12:11:44,521 INFO sqlalchemy.engine.Engine BEGIN (implicit)
2025-04-19 12:11:44,522 INFO sqlalchemy.engine.Engine INSERT INTO dept (dno, dname, budget, manager) VALUES (?, ?, ?, ?)
2025-04-19 12:11:44,522 INFO sqlalchemy.engine.Engine [generated in 0.00065s] ('0005', '电子学院', 1200000.0, '0004')
2025-04-19 12:11:44,525 INFO sqlalchemy.engine.Engine COMMIT
2025-04-19 12:11:44,552 INFO sqlalchemy.engine.Engine BEGIN (implicit)
2025-04-19 12:11:44,553 INFO sqlalchemy.engine.Engine SELECT dept.dno AS dept_dno, dept.dname AS dept_dname, dept.budget AS dept_budget, dept.manager AS dept_manager 
FROM dept 
WHERE dept.dno = ?
 LIMIT ? OFFSET ?
2025-04-19 12:11:44,553 INFO sqlalchemy.engine.Engine [generated in 0.00117s] ('0003', 1, 0)
成功插入部门: <Dept(dno='0003', dname='智能学院', budget=1200000.0, manager='0003')>
✓ 测试通过
2025-04-19 12:11:44,555 INFO sqlalchemy.engine.Engine ROLLBACK
```
]

```python
def test_default_level():
    """测试员工level默认值为3"""
    emp = Emp(
        eno="0005", 
        ename="赵六", 
        birthday=date(1992, 8, 25), 
        position="秘书", 
        salary=7000, 
        dno="0001"
    )
    session.add(emp)
    session.commit()
    
    # 验证默认值
    result = session.query(Emp).filter_by(eno="0005").first()
    assert result.level == 3, f"默认值错误: 预期为3, 实际为{result.level}"
    print(f"默认值测试成功: {result}")

run_test("员工level默认值测试", test_default_level)
```

#no-codly[
```

测试: 员工level默认值测试
--------------------------------------------------
2025-04-19 12:11:45,163 INFO sqlalchemy.engine.Engine BEGIN (implicit)
2025-04-19 12:11:45,165 INFO sqlalchemy.engine.Engine INSERT INTO emp (eno, ename, birthday, level, position, salary, dno) VALUES (?, ?, ?, ?, ?, ?, ?)
2025-04-19 12:11:45,166 INFO sqlalchemy.engine.Engine [cached since 2.99s ago] ('0005', '赵六', '1992-08-25', 3, '秘书', 7000.0, '0001')
2025-04-19 12:11:45,172 INFO sqlalchemy.engine.Engine COMMIT
2025-04-19 12:11:45,202 INFO sqlalchemy.engine.Engine BEGIN (implicit)
2025-04-19 12:11:45,205 INFO sqlalchemy.engine.Engine SELECT emp.eno AS emp_eno, emp.ename AS emp_ename, emp.birthday AS emp_birthday, emp.level AS emp_level, emp.position AS emp_position, emp.salary AS emp_salary, emp.dno AS emp_dno 
FROM emp 
WHERE emp.eno = ?
 LIMIT ? OFFSET ?
2025-04-19 12:11:45,206 INFO sqlalchemy.engine.Engine [cached since 1.448s ago] ('0005', 1, 0)
默认值测试成功: <Emp(eno='0005', ename='赵六', level=3, position='秘书', salary=7000.0, dno='0001')>
✓ 测试通过
2025-04-19 12:11:45,207 INFO sqlalchemy.engine.Engine ROLLBACK
```
]

```python
def test_circular_reference():
    """测试循环引用 - 员工引用部门，部门经理引用员工"""
    # 先创建部门，不设置经理
    dept = Dept(dno="0004", dname="元培学院", budget=900000)
    session.add(dept)
    session.flush()
    
    # 创建员工，引用该部门
    emp = Emp(
        eno="0007", 
        ename="钱七", 
        birthday=date(1988, 9, 12), 
        level=5, 
        position="教师", 
        salary=25000, 
        dno="0004"
    )
    session.add(emp)
    session.flush()
    
    # 将该员工设为部门经理
    dept.manager = "0007"
    session.commit()
    
    # 验证引用关系
    dept_result = session.query(Dept).filter_by(dno="0004").first()
    emp_result = session.query(Emp).filter_by(eno="0007").first()
    
    assert dept_result.manager == "0007", "部门经理未设置成功"
    assert emp_result.dno == "0004", "员工部门未设置成功"
    print(f"循环引用测试成功: 部门{dept_result}, 员工{emp_result}")

run_test("循环引用测试", test_circular_reference)
```

#no-codly[
```

测试: 循环引用测试
--------------------------------------------------
2025-04-19 12:11:45,812 INFO sqlalchemy.engine.Engine BEGIN (implicit)
2025-04-19 12:11:45,812 INFO sqlalchemy.engine.Engine INSERT INTO dept (dno, dname, budget, manager) VALUES (?, ?, ?, ?)
2025-04-19 12:11:45,814 INFO sqlalchemy.engine.Engine [cached since 1.292s ago] ('0004', '元培学院', 900000.0, None)
2025-04-19 12:11:45,820 INFO sqlalchemy.engine.Engine INSERT INTO emp (eno, ename, birthday, level, position, salary, dno) VALUES (?, ?, ?, ?, ?, ?, ?)
2025-04-19 12:11:45,821 INFO sqlalchemy.engine.Engine [cached since 2.086s ago] ('0007', '钱七', '1988-09-12', 5, '教师', 25000.0, '0004')
2025-04-19 12:11:45,823 INFO sqlalchemy.engine.Engine UPDATE dept SET manager=? WHERE dept.dno = ?
2025-04-19 12:11:45,824 INFO sqlalchemy.engine.Engine [generated in 0.00094s] ('0007', '0004')
2025-04-19 12:11:45,825 INFO sqlalchemy.engine.Engine COMMIT
2025-04-19 12:11:45,834 INFO sqlalchemy.engine.Engine BEGIN (implicit)
2025-04-19 12:11:45,836 INFO sqlalchemy.engine.Engine SELECT dept.dno AS dept_dno, dept.dname AS dept_dname, dept.budget AS dept_budget, dept.manager AS dept_manager 
FROM dept 
WHERE dept.dno = ?
 LIMIT ? OFFSET ?
2025-04-19 12:11:45,836 INFO sqlalchemy.engine.Engine [cached since 1.284s ago] ('0004', 1, 0)
2025-04-19 12:11:45,840 INFO sqlalchemy.engine.Engine SELECT emp.eno AS emp_eno, emp.ename AS emp_ename, emp.birthday AS emp_birthday, emp.level AS emp_level, emp.position AS emp_position, emp.salary AS emp_salary, emp.dno AS emp_dno 
FROM emp 
WHERE emp.eno = ?
 LIMIT ? OFFSET ?
2025-04-19 12:11:45,840 INFO sqlalchemy.engine.Engine [cached since 2.083s ago] ('0007', 1, 0)
循环引用测试成功: 部门<Dept(dno='0004', dname='元培学院', budget=900000.0, manager='0007')>, 员工<Emp(eno='0007', ename='钱七', level=5, position='教师', salary=25000.0, dno='0004')>
✓ 测试通过
2025-04-19 12:11:45,840 INFO sqlalchemy.engine.Engine ROLLBACK
```
]

```python
# 负向测试用例
def test_invalid_level():
    """测试员工level约束（1-5之间）"""
    emp = Emp(
        eno="0009", 
        ename="测试", 
        birthday=date(1990, 5, 15), 
        level=6,  # 超出范围
        position="教师", 
        salary=12000, 
        dno="0001"
    )
    session.add(emp)
    session.commit()  # 应该引发异常
    
run_test("非法员工level值(超过上限)", test_invalid_level)
```

#no-codly[
```

测试: 非法员工level值(超过上限)
--------------------------------------------------
2025-04-19 12:11:46,653 INFO sqlalchemy.engine.Engine BEGIN (implicit)
2025-04-19 12:11:46,653 INFO sqlalchemy.engine.Engine INSERT INTO emp (eno, ename, birthday, level, position, salary, dno) VALUES (?, ?, ?, ?, ?, ?, ?)
2025-04-19 12:11:46,653 INFO sqlalchemy.engine.Engine [cached since 2.918s ago] ('0009', '测试', '1990-05-15', 6, '教师', 12000.0, '0001')
2025-04-19 12:11:46,655 INFO sqlalchemy.engine.Engine ROLLBACK
✗ 测试失败: (sqlite3.IntegrityError) CHECK constraint failed: level BETWEEN 1 AND 5
[SQL: INSERT INTO emp (eno, ename, birthday, level, position, salary, dno) VALUES (?, ?, ?, ?, ?, ?, ?)]
[parameters: ('0009', '测试', '1990-05-15', 6, '教师', 12000.0, '0001')]
(Background on this error at: https://sqlalche.me/e/20/gkpj)
```
]

```python
def test_invalid_level_low():
    """测试员工level下限约束"""
    emp = Emp(
        eno="0009", 
        ename="测试", 
        birthday=date(1990, 5, 15), 
        level=0,  # 低于下限
        position="教师", 
        salary=12000, 
        dno="0001"
    )
    session.add(emp)
    session.commit()  # 应该引发异常
run_test("非法员工level值(低于下限)", test_invalid_level)
```

#no-codly[
```

测试: 非法员工level值(低于下限)
--------------------------------------------------
2025-04-19 12:11:47,467 INFO sqlalchemy.engine.Engine BEGIN (implicit)
2025-04-19 12:11:47,468 INFO sqlalchemy.engine.Engine INSERT INTO emp (eno, ename, birthday, level, position, salary, dno) VALUES (?, ?, ?, ?, ?, ?, ?)
2025-04-19 12:11:47,468 INFO sqlalchemy.engine.Engine [cached since 3.733s ago] ('0009', '测试', '1990-05-15', 6, '教师', 12000.0, '0001')
2025-04-19 12:11:47,469 INFO sqlalchemy.engine.Engine ROLLBACK
✗ 测试失败: (sqlite3.IntegrityError) CHECK constraint failed: level BETWEEN 1 AND 5
[SQL: INSERT INTO emp (eno, ename, birthday, level, position, salary, dno) VALUES (?, ?, ?, ?, ?, ?, ?)]
[parameters: ('0009', '测试', '1990-05-15', 6, '教师', 12000.0, '0001')]
(Background on this error at: https://sqlalche.me/e/20/gkpj)
```
]

```python
def test_invalid_position():
    """测试职位枚举约束"""
    emp = Emp(
        eno="0009", 
        ename="测试", 
        birthday=date(1990, 5, 15), 
        level=3, 
        position="主任",  # 不在枚举列表中
        salary=12000, 
        dno="0001"
    )
    session.add(emp)
    session.commit()  # 应该引发异常
run_test("非法职位值", test_invalid_position)
```

#no-codly[
```

测试: 非法职位值
--------------------------------------------------
2025-04-19 12:11:48,525 INFO sqlalchemy.engine.Engine BEGIN (implicit)
2025-04-19 12:11:48,526 INFO sqlalchemy.engine.Engine INSERT INTO emp (eno, ename, birthday, level, position, salary, dno) VALUES (?, ?, ?, ?, ?, ?, ?)
2025-04-19 12:11:48,527 INFO sqlalchemy.engine.Engine [cached since 4.791s ago] ('0009', '测试', '1990-05-15', 3, '主任', 12000.0, '0001')
2025-04-19 12:11:48,527 INFO sqlalchemy.engine.Engine ROLLBACK
✗ 测试失败: (sqlite3.IntegrityError) CHECK constraint failed: position IN ('教师', '教务', '会计', '秘书')
[SQL: INSERT INTO emp (eno, ename, birthday, level, position, salary, dno) VALUES (?, ?, ?, ?, ?, ?, ?)]
[parameters: ('0009', '测试', '1990-05-15', 3, '主任', 12000.0, '0001')]
(Background on this error at: https://sqlalche.me/e/20/gkpj)
```
]

```python
def test_invalid_salary_low():
    """测试薪资下限约束"""
    emp = Emp(
        eno="0009", 
        ename="测试", 
        birthday=date(1990, 5, 15), 
        level=3, 
        position="教师", 
        salary=1000,  # 低于最低薪资
        dno="0001"
    )
    session.add(emp)
    session.commit()  # 应该引发异常
run_test("非法薪资值(低于下限)", test_invalid_salary_low)
```

#no-codly[
```

测试: 非法薪资值(低于下限)
--------------------------------------------------
2025-04-19 12:11:50,138 INFO sqlalchemy.engine.Engine BEGIN (implicit)
2025-04-19 12:11:50,139 INFO sqlalchemy.engine.Engine INSERT INTO emp (eno, ename, birthday, level, position, salary, dno) VALUES (?, ?, ?, ?, ?, ?, ?)
2025-04-19 12:11:50,139 INFO sqlalchemy.engine.Engine [cached since 6.404s ago] ('0009', '测试', '1990-05-15', 3, '教师', 1000.0, '0001')
2025-04-19 12:11:50,141 INFO sqlalchemy.engine.Engine ROLLBACK
✗ 测试失败: (sqlite3.IntegrityError) CHECK constraint failed: salary BETWEEN 2000 AND 200000
[SQL: INSERT INTO emp (eno, ename, birthday, level, position, salary, dno) VALUES (?, ?, ?, ?, ?, ?, ?)]
[parameters: ('0009', '测试', '1990-05-15', 3, '教师', 1000.0, '0001')]
(Background on this error at: https://sqlalche.me/e/20/gkpj)
```
]

```python
def test_invalid_salary_high():
    """测试薪资上限约束"""
    emp = Emp(
        eno="0006", 
        ename="测试", 
        birthday=date(1990, 5, 15), 
        level=3, 
        position="教师", 
        salary=250000,  # 高于最高薪资
        dno="0001"
    )
    session.add(emp)
    session.commit()  # 应该引发异常
run_test("非法薪资值(超过上限)", test_invalid_salary_low)
```

#no-codly[
```

测试: 非法薪资值(超过上限)
--------------------------------------------------
2025-04-19 12:11:51,167 INFO sqlalchemy.engine.Engine BEGIN (implicit)
2025-04-19 12:11:51,167 INFO sqlalchemy.engine.Engine INSERT INTO emp (eno, ename, birthday, level, position, salary, dno) VALUES (?, ?, ?, ?, ?, ?, ?)
2025-04-19 12:11:51,168 INFO sqlalchemy.engine.Engine [cached since 7.433s ago] ('0009', '测试', '1990-05-15', 3, '教师', 1000.0, '0001')
2025-04-19 12:11:51,168 INFO sqlalchemy.engine.Engine ROLLBACK
✗ 测试失败: (sqlite3.IntegrityError) CHECK constraint failed: salary BETWEEN 2000 AND 200000
[SQL: INSERT INTO emp (eno, ename, birthday, level, position, salary, dno) VALUES (?, ?, ?, ?, ?, ?, ?)]
[parameters: ('0009', '测试', '1990-05-15', 3, '教师', 1000.0, '0001')]
(Background on this error at: https://sqlalche.me/e/20/gkpj)
```
]

```python
def test_invalid_dname():
    """测试部门名称枚举约束"""
    dept = Dept(
        dno="0009", 
        dname="物理学院",  # 不在枚举列表中
        budget=1000000, 
        manager="0001"
    )
    session.add(dept)
    session.commit()  # 应该引发异常

run_test("非法部门名称", test_invalid_dname)
```

#no-codly[
```

测试: 非法部门名称
--------------------------------------------------
2025-04-19 12:11:52,124 INFO sqlalchemy.engine.Engine BEGIN (implicit)
2025-04-19 12:11:52,124 INFO sqlalchemy.engine.Engine INSERT INTO dept (dno, dname, budget, manager) VALUES (?, ?, ?, ?)
2025-04-19 12:11:52,125 INFO sqlalchemy.engine.Engine [cached since 7.603s ago] ('0009', '物理学院', 1000000.0, '0001')
2025-04-19 12:11:52,126 INFO sqlalchemy.engine.Engine ROLLBACK
✗ 测试失败: (sqlite3.IntegrityError) CHECK constraint failed: dname IN ('数学学院', '计算机学院', '智能学院', '电子学院', '元培学院')
[SQL: INSERT INTO dept (dno, dname, budget, manager) VALUES (?, ?, ?, ?)]
[parameters: ('0009', '物理学院', 1000000.0, '0001')]
(Background on this error at: https://sqlalche.me/e/20/gkpj)
```
]

```python
def test_unique_key_emp():
    """测试员工主键唯一性约束"""
    # 插入已存在的员工编号
    emp = Emp(
        eno="0001",  # 已存在的ID
        ename="重复", 
        birthday=date(1995, 5, 15), 
        level=3, 
        position="教师", 
        salary=12000, 
        dno="0001"
    )
    session.add(emp)
    session.commit()  # 应该引发异常

run_test("重复员工主键", test_unique_key_emp)
```

#no-codly[
```

测试: 重复员工主键
--------------------------------------------------
2025-04-19 12:11:53,144 INFO sqlalchemy.engine.Engine BEGIN (implicit)
2025-04-19 12:11:53,144 INFO sqlalchemy.engine.Engine SELECT emp.eno AS emp_eno, emp.ename AS emp_ename, emp.birthday AS emp_birthday, emp.level AS emp_level, emp.position AS emp_position, emp.salary AS emp_salary, emp.dno AS emp_dno 
FROM emp 
WHERE emp.eno = ?
2025-04-19 12:11:53,146 INFO sqlalchemy.engine.Engine [generated in 0.00069s] ('0001',)
2025-04-19 12:11:53,148 INFO sqlalchemy.engine.Engine INSERT INTO emp (eno, ename, birthday, level, position, salary, dno) VALUES (?, ?, ?, ?, ?, ?, ?)
2025-04-19 12:11:53,149 INFO sqlalchemy.engine.Engine [cached since 9.413s ago] ('0001', '重复', '1995-05-15', 3, '教师', 12000.0, '0001')
2025-04-19 12:11:53,149 INFO sqlalchemy.engine.Engine ROLLBACK
✗ 测试失败: (sqlite3.IntegrityError) UNIQUE constraint failed: emp.eno
[SQL: INSERT INTO emp (eno, ename, birthday, level, position, salary, dno) VALUES (?, ?, ?, ?, ?, ?, ?)]
[parameters: ('0001', '重复', '1995-05-15', 3, '教师', 12000.0, '0001')]
(Background on this error at: https://sqlalche.me/e/20/gkpj)
C:\Users\Dai\AppData\Local\Temp\ipykernel_14120\3584338704.py:14: SAWarning: New instance <Emp at 0x1c59d6b02e0> with identity key (<class '__main__.Emp'>, ('0001',), None) conflicts with persistent instance <Emp at 0x1c59d63e920>
  session.commit()  # 应该引发异常
```
]

```python
def test_unique_key_dept():
    """测试部门主键唯一性约束"""
    # 插入已存在的部门编号
    dept = Dept(
        dno="0001",  # 已存在的ID
        dname="计算机学院", 
        budget=1000000, 
        manager="0001"
    )
    session.add(dept)
    session.commit()  # 应该引发异常

run_test("重复部门主键", test_unique_key_dept)
```

#no-codly[
```

测试: 重复部门主键
--------------------------------------------------
2025-04-19 12:11:55,080 INFO sqlalchemy.engine.Engine BEGIN (implicit)
2025-04-19 12:11:55,081 INFO sqlalchemy.engine.Engine SELECT dept.dno AS dept_dno, dept.dname AS dept_dname, dept.budget AS dept_budget, dept.manager AS dept_manager 
FROM dept 
WHERE dept.dno = ?
2025-04-19 12:11:55,082 INFO sqlalchemy.engine.Engine [generated in 0.00078s] ('0001',)
2025-04-19 12:11:55,084 INFO sqlalchemy.engine.Engine INSERT INTO dept (dno, dname, budget, manager) VALUES (?, ?, ?, ?)
2025-04-19 12:11:55,084 INFO sqlalchemy.engine.Engine [cached since 10.56s ago] ('0001', '计算机学院', 1000000.0, '0001')
2025-04-19 12:11:55,086 INFO sqlalchemy.engine.Engine ROLLBACK
✗ 测试失败: (sqlite3.IntegrityError) UNIQUE constraint failed: dept.dno
[SQL: INSERT INTO dept (dno, dname, budget, manager) VALUES (?, ?, ?, ?)]
[parameters: ('0001', '计算机学院', 1000000.0, '0001')]
(Background on this error at: https://sqlalche.me/e/20/gkpj)
C:\Users\Dai\AppData\Local\Temp\ipykernel_14120\1215435416.py:11: SAWarning: New instance <Dept at 0x1c59d6b1990> with identity key (<class '__main__.Dept'>, ('0001',), None) conflicts with persistent instance <Dept at 0x1c59d6b3d30>
  session.commit()  # 应该引发异常
```
]

```python
# 查询部门数据
for dept in session.query(Dept).all():
    print(dept)
```

#no-codly[
```
2025-04-19 12:11:55,973 INFO sqlalchemy.engine.Engine BEGIN (implicit)
2025-04-19 12:11:55,975 INFO sqlalchemy.engine.Engine SELECT dept.dno AS dept_dno, dept.dname AS dept_dname, dept.budget AS dept_budget, dept.manager AS dept_manager 
FROM dept
2025-04-19 12:11:55,976 INFO sqlalchemy.engine.Engine [generated in 0.00065s] ()
<Dept(dno='0001', dname='计算机学院', budget=1000000.0, manager='0001')>
<Dept(dno='0002', dname='数学学院', budget=800000.0, manager='0002')>
<Dept(dno='0003', dname='智能学院', budget=1200000.0, manager='0003')>
<Dept(dno='0005', dname='电子学院', budget=1200000.0, manager='0004')>
<Dept(dno='0004', dname='元培学院', budget=900000.0, manager='0007')>
```
]

```python
# 查询员工数据
for emp in session.query(Emp).all():
    print(emp)

# 清理资源
session.close()
print("会话已关闭")
```

#no-codly[
```
2025-04-19 12:11:56,820 INFO sqlalchemy.engine.Engine SELECT emp.eno AS emp_eno, emp.ename AS emp_ename, emp.birthday AS emp_birthday, emp.level AS emp_level, emp.position AS emp_position, emp.salary AS emp_salary, emp.dno AS emp_dno 
FROM emp
2025-04-19 12:11:56,821 INFO sqlalchemy.engine.Engine [generated in 0.00086s] ()
<Emp(eno='0001', ename='张三', level=4, position='教师', salary=15000.0, dno='0001')>
<Emp(eno='0002', ename='李四', level=3, position='教务', salary=8000.0, dno='0002')>
<Emp(eno='0003', ename='王五', level=5, position='教师', salary=20000.0, dno='0003')>
<Emp(eno='0004', ename='吴十', level=3, position='秘书', salary=7000.0, dno='0003')>
<Emp(eno='0006', ename='吴六', level=2, position='教师', salary=12000.0, dno='0001')>
<Emp(eno='0005', ename='赵六', level=3, position='秘书', salary=7000.0, dno='0001')>
<Emp(eno='0007', ename='钱七', level=5, position='教师', salary=25000.0, dno='0004')>
2025-04-19 12:11:56,822 INFO sqlalchemy.engine.Engine ROLLBACK
会话已关闭
```
]

= 中级约束设计
1. 测试延迟约束，往Emp和Dept中插入互相参照的两行。PG是支持延迟约束的，MySQL不支持延迟约束，可以通过设置约束是否有效来完成
2. 将salary划分为5个区间，每个区间对应一个level值，保证每个员工的工资值和他的level值是正确对应的，这属于行级约束
3. 编写函数，输入员工的员工号，输出一个包含员工各方面信息的编码字符串，也即我们第二章中提到的智能码。比如00010002199903020002，对应编码信息如下：

#align(center, [
	#table(
		columns: 6,
		[0001], [0002], [1999], [03], [02], [0002],
		[员工号], [部门号], [出生年份], [级别编码], [职位编码], [部门领导号],
	)
])

同学们在实现时，规范的做法是构造一张编码对照表，而不是把编码对应信息直接放在代码里面

```python
import sqlite3
from datetime import date

def init_database():
    conn = sqlite3.connect('university.db')
    cursor = conn.cursor()
    
    # Enable foreign key support
    cursor.execute("PRAGMA foreign_keys = ON")
    
    # Create Emp table
    cursor.execute('''
    CREATE TABLE IF NOT EXISTS emp (
        eno TEXT(4) PRIMARY KEY,
        ename TEXT(50),
        birthday DATE,
        level INTEGER DEFAULT 3 CHECK(level BETWEEN 1 AND 5),
        position TEXT(10) CHECK(position IN ('教师', '教务', '会计', '秘书')),
        salary REAL CHECK(salary BETWEEN 2000 AND 200000),
        dno TEXT(4),
        FOREIGN KEY (dno) REFERENCES dept(dno) DEFERRABLE INITIALLY DEFERRED
    )
    ''')
    
    # Create Dept table
    cursor.execute('''
    CREATE TABLE IF NOT EXISTS dept (
        dno TEXT(4) PRIMARY KEY,
        dname TEXT(20) CHECK(dname IN ('数学学院', '计算机学院', '智能学院', '电子学院', '元培学院')),
        budget REAL,
        manager TEXT(4),
        FOREIGN KEY (manager) REFERENCES emp(eno) DEFERRABLE INITIALLY DEFERRED
    )
    ''')
    
    # Create code mapping table
    cursor.execute('''
    CREATE TABLE IF NOT EXISTS code_mapping (
        category TEXT NOT NULL,
        code TEXT NOT NULL,
        value TEXT NOT NULL,
        PRIMARY KEY (category, code)
    )
    ''')
    
    # Insert code mappings
    mappings = [
        # Department codes
        ('dept', '数学学院', '01'),
        ('dept', '计算机学院', '02'),
        ('dept', '智能学院', '03'),
        ('dept', '电子学院', '04'),
        ('dept', '元培学院', '05'),
        
        # Position codes
        ('position', '教师', '01'),
        ('position', '教务', '02'),
        ('position', '会计', '03'),
        ('position', '秘书', '04'),
        
        # Level codes (same as value)
        ('level', '1', '1'),
        ('level', '2', '2'),
        ('level', '3', '3'),
        ('level', '4', '4'),
        ('level', '5', '5'),
    ]
    
    cursor.executemany(
        "INSERT OR IGNORE INTO code_mapping VALUES (?, ?, ?)",
        mappings
    )
    
    conn.commit()
    return conn
```

```python
def insert_with_circular_reference(conn):
    cursor = conn.cursor()
    
    try:
        # Start a transaction
        cursor.execute("BEGIN TRANSACTION")
        
        # Insert department first (manager will be set later)
        cursor.execute(
            "INSERT INTO dept (dno, dname, budget, manager) VALUES (?, ?, ?, ?)",
            ('D001', '计算机学院', 5000000, None)
        )
        
        # Insert employee referencing the department
        cursor.execute(
            "INSERT INTO emp (eno, ename, birthday, level, position, salary, dno) VALUES (?, ?, ?, ?, ?, ?, ?)",
            ('E001', '张教授', date(1975, 5, 15), 4, '教师', 80000, 'D001')
        )
        
        # Now update the department to reference the employee as manager
        cursor.execute(
            "UPDATE dept SET manager = ? WHERE dno = ?",
            ('E001', 'D001')
        )
        
        conn.commit()
        print("Successfully inserted circular references")
        
    except sqlite3.Error as e:
        conn.rollback()
        print("Failed to insert circular references:", e)

def test_constraints(conn):
    cursor = conn.cursor()
    
    print("\nTesting valid inserts:")
    try:
        # Valid employee
        cursor.execute(
            "INSERT INTO emp (eno, ename, level, position, salary) VALUES (?, ?, ?, ?, ?)",
            ('E002', '李老师', 3, '教师', 50000)
        )
        print("- Valid employee inserted")
        
        # Valid department
        cursor.execute(
            "INSERT INTO dept (dno, dname, budget) VALUES (?, ?, ?)",
            ('D002', '数学学院', 3000000)
        )
        print("- Valid department inserted")
        
    except sqlite3.Error as e:
        print("Valid insert failed:", e)
    
    print("\nTesting invalid inserts:")
    
    # Invalid level
    try:
        cursor.execute(
            "INSERT INTO emp (eno, ename, level, position, salary) VALUES (?, ?, ?, ?, ?)",
            ('E003', 'Invalid', 6, '教师', 50000)
        )
    except sqlite3.IntegrityError as e:
        print("- Caught invalid level (6):", e)
    
    # Invalid position
    try:
        cursor.execute(
            "INSERT INTO emp (eno, ename, level, position, salary) VALUES (?, ?, ?, ?, ?)",
            ('E004', 'Invalid', 3, '校长', 50000)
        )
    except sqlite3.IntegrityError as e:
        print("- Caught invalid position (校长):", e)
    
    # Invalid salary
    try:
        cursor.execute(
            "INSERT INTO emp (eno, ename, level, position, salary) VALUES (?, ?, ?, ?, ?)",
            ('E005', 'Invalid', 3, '教师', 1000)
        )
    except sqlite3.IntegrityError as e:
        print("- Caught invalid salary (1000):", e)
    
    # Invalid department name
    try:
        cursor.execute(
            "INSERT INTO dept (dno, dname, budget) VALUES (?, ?, ?)",
            ('D003', '物理学院', 2000000)
        )
    except sqlite3.IntegrityError as e:
        print("- Caught invalid department name (物理学院):", e)
    
    conn.rollback()  # Rollback all test data

def generate_smart_code(conn, eno):
    """Generate a smart code for an employee based on their information"""
    cursor = conn.cursor()
    
    # Get employee information
    cursor.execute('''
    SELECT e.eno, e.ename, e.birthday, e.level, e.position, e.salary, e.dno, d.dname
    FROM emp e LEFT JOIN dept d ON e.dno = d.dno
    WHERE e.eno = ?
    ''', (eno,))
    
    emp = cursor.fetchone()
    if not emp:
        return None
    
    # Get code mappings
    def get_mapping(category, value):
        cursor.execute(
            "SELECT code FROM code_mapping WHERE category = ? AND value = ?",
            (category, str(value)))
        result = cursor.fetchone()
        return result[0] if result else '00'
    
    # Build smart code parts
    parts = []
    
    # 1-4: Employee ID (padded to 4 digits)
    parts.append(emp[0].zfill(4))
    
    # 5-6: Department code
    dept_code = get_mapping('dept', emp[7]) if emp[7] else '00'
    parts.append(dept_code)
    
    # 7-10: Birth year
    birth_year = emp[2][:4] if emp[2] else '0000'
    parts.append(birth_year)
    
    # 11-12: Position code
    pos_code = get_mapping('position', emp[4]) if emp[4] else '00'
    parts.append(pos_code)
    
    # 13: Level code
    level_code = get_mapping('level', emp[3]) if emp[3] else '0'
    parts.append(level_code)
    
    # 14-17: Salary grade (salary / 10000)
    salary_grade = str(int(emp[5] // 10000)).zfill(4) if emp[5] else '0000'
    parts.append(salary_grade)
    
    # Combine all parts
    return ''.join(parts)

def test_smart_code(conn):
    """Test the smart code generation with sample data"""
    cursor = conn.cursor()
    
    # Insert test data
    test_data = [
        # eno, ename, birthday, level, position, salary, dno
        ('T001', '王教授', '1980-08-20', 5, '教师', 150000, 'D001'),
        ('A001', '李会计', '1990-03-15', 3, '会计', 50000, 'D002'),
        ('S001', '张秘书', '1995-11-05', 2, '秘书', 30000, None),
    ]
    
    dept_data = [
        # dno, dname, budget, manager
        ('D001', '计算机学院', 5000000, 'T001'),
        ('D002', '数学学院', 3000000, None),
    ]
    
    cursor.executemany(
        "INSERT OR IGNORE INTO emp VALUES (?, ?, ?, ?, ?, ?, ?)",
        test_data
    )
    
    cursor.executemany(
        "INSERT OR IGNORE INTO dept VALUES (?, ?, ?, ?)",
        dept_data
    )
    
    conn.commit()
    
    # Generate and display smart codes
    print("\nGenerated Smart Codes:")
    for eno in ['T001', 'A001', 'S001']:
        code = generate_smart_code(conn, eno)
        print(f"{eno}: {code}")
        
        # Decode the smart code
        if code:
            print(f"  Decoded: ID={code[:4]}, Dept={code[4:6]}, Birth={code[6:10]}, "
                  f"Position={code[10:12]}, Level={code[12]}, SalaryGrade={code[13:]}")


def test():
    conn = init_database()
    
    # Test circular reference insertion
    print("\n=== Testing Circular Reference ===")
    insert_with_circular_reference(conn)
    
    # Test constraints
    print("\n=== Testing Constraints ===")
    test_constraints(conn)
    
    # Verify the circular reference was successful
    cursor = conn.cursor()
    cursor.execute("SELECT * FROM emp WHERE eno = 'E001'")
    emp = cursor.fetchone()
    print("\nEmployee E001:", emp)
    
    cursor.execute("SELECT * FROM dept WHERE dno = 'D001'")
    dept = cursor.fetchone()
    print("Department D001:", dept)

    test_smart_code(conn)
    
    conn.close()
```

```python
test()
```

#no-codly[
```

=== Testing Circular Reference ===
Failed to insert circular references: UNIQUE constraint failed: dept.dno

=== Testing Constraints ===

Testing valid inserts:
- Valid employee inserted
- Valid department inserted

Testing invalid inserts:
- Caught invalid level (6): CHECK constraint failed: level BETWEEN 1 AND 5
- Caught invalid position (校长): CHECK constraint failed: position IN ('教师', '教务', '会计', '秘书')
- Caught invalid salary (1000): CHECK constraint failed: salary BETWEEN 2000 AND 200000
- Caught invalid department name (物理学院): CHECK constraint failed: dname IN ('数学学院', '计算机学院', '智能学院', '电子学院', '元培学院')

Employee E001: ('E001', '张教授', '1975-05-15', 4, '教师', 80000.0, 'D001')
Department D001: ('D001', '计算机学院', 5000000.0, 'E001')

Generated Smart Codes:
T001: T0010019800050015
  Decoded: ID=T001, Dept=00, Birth=1980, Position=00, Level=5, SalaryGrade=0015
A001: A0010019900030005
  Decoded: ID=A001, Dept=00, Birth=1990, Position=00, Level=3, SalaryGrade=0005
S001: S0010019950020003
  Decoded: ID=S001, Dept=00, Birth=1995, Position=00, Level=2, SalaryGrade=0003
```
]

= 高级约束设计
1. 使用函数约束或者触发器来保证管理者的工资必须高于他所管理的任何一个员工。
2. 使用触发器保证任何一个员工工资的变化额度，都应该体现在他所在部门的预算上面，本质上这相当于实现了一个物化视图的一致性维护机制（触发器应该考虑到员工改变工作部门的情况，从一致性维护效率的角度，完全重算当然最简单，但希望还是实现基于更新行的增量更新）。

```python
import sqlite3
```

```python
# 连接到数据库
conn = sqlite3.connect('employee_dept.db')
cursor = conn.cursor()
```

== 创建经理工资检查触发器
创建经理工资检查触发器：更新经理时检查，插入/更新员工时检查。
- `check_manager_salary_update`.
- `check_employee_salary_insert`.
- `check_employee_salary_update`.

之所以我们这样来创建触发器，是因为SQLite3不支持一些比较高级的Trigger特性。

注意：不可能插入经理，只可能修改经理。

```python
cursor.execute('''
DROP TRIGGER IF EXISTS check_manager_salary_update
''')
conn.commit()
print("已经删除Trigger: check_manager_salary_update")
```

#no-codly[
```
已经删除Trigger: check_manager_salary_update
```
]

```python
cursor.execute('''
-- 更新时检查经理工资
CREATE TRIGGER check_manager_salary_update
BEFORE UPDATE OF salary, dno, eno ON Emp
FOR EACH ROW
WHEN NEW.eno = (SELECT manager FROM Dept WHERE dno = NEW.dno)
  AND (SELECT IFNULL(MAX(salary), 0)
       FROM Emp
       WHERE dno = NEW.dno
         AND eno != NEW.eno) >= NEW.salary
BEGIN
  SELECT RAISE(ABORT, '经理的工资必须高于所有员工');
END;
''')
conn.commit()
print("成功创建更新经理时经理工资检查触发器")
```

#no-codly[
```
成功创建更新经理时经理工资检查触发器
```
]

```python
cursor.execute('''
DROP TRIGGER IF EXISTS check_employee_salary_insert
''')
conn.commit()
print("已经删除Trigger: check_employee_salary_insert")
```

#no-codly[
```
已经删除Trigger: check_employee_salary_insert
```
]

```python
cursor.execute('''
-- 插入时检查员工工资
CREATE TRIGGER check_employee_salary_insert
BEFORE INSERT ON Emp
FOR EACH ROW
WHEN NEW.eno != (SELECT manager FROM Dept WHERE dno = NEW.dno)
  AND NEW.salary >= (
        SELECT salary
        FROM Emp
        WHERE eno = (SELECT manager FROM Dept WHERE dno = NEW.dno)
      )
BEGIN
  SELECT RAISE(ABORT, '员工工资不能高于经理');
END;
''')
conn.commit()
print("成功创建插入员工时经理工资检查触发器")
```

#no-codly[
```
成功创建插入员工时经理工资检查触发器
```
]

```python
cursor.execute('''
DROP TRIGGER IF EXISTS check_employee_salary_update
''')
conn.commit()
print("已经删除Trigger: check_employee_salary_update")
```

#no-codly[
```
已经删除Trigger: check_employee_salary_update
```
]

```python
cursor.execute('''
-- 更新时检查员工工资
CREATE TRIGGER check_employee_salary_update
BEFORE UPDATE OF salary, dno, eno ON Emp
FOR EACH ROW
WHEN NEW.eno != (SELECT manager FROM Dept WHERE dno = NEW.dno)
  AND NEW.salary >= (
        SELECT salary
        FROM Emp
        WHERE eno = (SELECT manager FROM Dept WHERE dno = NEW.dno)
      )
BEGIN
  SELECT RAISE(ABORT, '员工工资不能高于经理');
END;
''')
conn.commit()
print("成功创建更新员工时经理工资检查触发器")
```

#no-codly[
	```
	成功创建更新员工时经理工资检查触发器
	```
]

== 创建预算维护触发器
同样的，分别对于`INSERT`、`DELETE`、`UPDATE`创建触发器。但是考虑到`UPDATE`的时候部门变动的情况，我们需要创建两个触发器。
- `update_budget_on_insert`.
- `update_budget_on_delete`.
- `update_budget_on_dept_change`.
- `update_budget_on_salary_change`.

```python
cursor.execute('''
DROP TRIGGER IF EXISTS update_budget_on_insert
''')
conn.commit()
print("已经删除Trigger: update_budget_on_insert")
```

#no-codly[
	```
	已经删除Trigger: update_budget_on_insert
	```
]

```python
# 创建预算维护触发器 - INSERT
cursor.execute('''
CREATE TRIGGER update_budget_on_insert
AFTER INSERT ON Emp
FOR EACH ROW
BEGIN
    UPDATE Dept SET budget = budget + NEW.salary WHERE dno = NEW.dno;
END;
''')
conn.commit()
print("成功创建插入员工时预算维护触发器")
```

#no-codly[
	```
	成功创建插入员工时预算维护触发器
	```
]

```python
cursor.execute('''
DROP TRIGGER IF EXISTS update_budget_on_delete
''')
conn.commit()
print("已经删除Trigger: update_budget_on_delete")
```

#no-codly[
	```
	已经删除Trigger: update_budget_on_delete
	```
]

```python
# 创建预算维护触发器 - DELETE
cursor.execute('''
CREATE TRIGGER update_budget_on_delete
AFTER DELETE ON Emp
FOR EACH ROW
BEGIN
    UPDATE Dept SET budget = budget - OLD.salary WHERE dno = OLD.dno;
END;
''')
conn.commit()
print("成功创建删除员工时预算维护触发器")
```

#no-codly[
	```
	成功创建删除员工时预算维护触发器
	```
]

```python
cursor.execute('''
DROP TRIGGER IF EXISTS update_budget_on_dept_change
''')
conn.commit()
print("已经删除Trigger: update_budget_on_dept_change")
```

#no-codly[
	```
	已经删除Trigger: update_budget_on_dept_change
	```
]

```python
# 创建预算维护触发器 - UPDATE when dept changes.
cursor.execute('''
-- 部门变更时调整旧/新部门预算
CREATE TRIGGER update_budget_on_dept_change
AFTER UPDATE OF dno, salary ON Emp
FOR EACH ROW
WHEN NEW.dno <> OLD.dno
BEGIN
  UPDATE Dept SET budget = budget - OLD.salary WHERE dno = OLD.dno;
  UPDATE Dept SET budget = budget + NEW.salary WHERE dno = NEW.dno;
END;
''')
conn.commit()
print("成功创建更新员工为不同部门时预算维护触发器")
```

#no-codly[
	```
	成功创建更新员工为不同部门时预算维护触发器
	```
]

```python
cursor.execute('''
DROP TRIGGER IF EXISTS update_budget_on_salary_change
''')
conn.commit()
print("已经删除Trigger: update_budget_on_salary_change")
```

#no-codly[
	```
	已经删除Trigger: update_budget_on_salary_change
	```
]

```python
# 创建预算维护触发器 - UPDATE when dept NOT changes.
cursor.execute('''
-- 同部门工资变动时按差值调整
CREATE TRIGGER update_budget_on_salary_change
AFTER UPDATE OF salary ON Emp
FOR EACH ROW
WHEN NEW.dno = OLD.dno
BEGIN
  UPDATE Dept
    SET budget = budget + (NEW.salary - OLD.salary)
    WHERE dno = NEW.dno;
END;
''')
conn.commit()
print("成功创建更新员工为相同部门时预算维护触发器")
```

#no-codly[
	```
	成功创建更新员工为相同部门时预算维护触发器
	```
]

下面我们对于触发器进行测试。

```python
print("1. 更新经理薪资测试（应失败）：")
try:
    cursor.execute("UPDATE Emp SET salary = 1000 WHERE eno = '0003';")
    conn.commit()
except sqlite3.DatabaseError as e:
    print("Error:", e)
```

#no-codly[
	```
	1. 更新经理薪资测试（应失败）：
	Error: 经理的工资必须高于所有员工
	```
]

```python
print("1. 更新经理薪资测试（应成功）：")
try:
    # 提薪至25000
    cursor.execute("UPDATE Emp SET salary = 25000.0 WHERE eno = '0003'")
    conn.commit()
    print("更新经理薪资成功")
except sqlite3.DatabaseError as e:
    print("Error:", e)
```

#no-codly[
	```
	1. 更新经理薪资测试（应成功）：
	更新经理薪资成功
	```
]

```python
print("2. 插入员工薪资测试（应失败）：")
try:
    cursor.execute("INSERT INTO Emp VALUES ('0009','新人','2000-02-02',2,'秘书',16000.0,'0001');")
    conn.commit()
except sqlite3.DatabaseError as e:
    print("Error:", e)
```

#no-codly[
	```
	2. 插入员工薪资测试（应失败）：
	Error: 员工工资不能高于经理
	```
]

```python
print("2. 插入员工薪资测试（应成功）：")
try:
    # 插入薪资14000，低于经理
    cursor.execute("INSERT INTO Emp VALUES ('0009','新教职','2001-12-31',3,'秘书',14000.0,'0001')")
    conn.commit()
    print("成功插入员工")
except sqlite3.DatabaseError as e:
    print("Error:", e)
```

#no-codly[
	```
	2. 插入员工薪资测试（应成功）：
	成功插入员工
	```
]

```python
print("3. 更新员工薪资测试（应失败）：")
try:
    cursor.execute("UPDATE Emp SET salary = 30000 WHERE eno = '0004';")
    conn.commit()
except sqlite3.DatabaseError as e:
    print("Error:", e)
```

#no-codly[
	```
	3. 更新员工薪资测试（应失败）：
	Error: 员工工资不能高于经理
	```
]

```python
print("3. 更新员工薪资测试（应成功）：")
try:
    # 调薪到6500，低于经理
    cursor.execute("UPDATE Emp SET salary = 6500.0 WHERE eno = '0004'")
    conn.commit()
    print("更新员工薪资成功")
except sqlite3.DatabaseError as e:
    print("Error:", e)
```

#no-codly[
```
3. 更新员工薪资测试（应成功）：
更新员工薪资成功
```
]

```python
def show_budget(dno):
    # 使用 ? 占位符，并通过第二个参数传入参数元组
    budgets = cursor.execute(
        "SELECT * FROM Dept WHERE dno = ?",
        (dno,)
    ).fetchall()
    print(f"Dept budgets for {dno}:", budgets)
```

```python
print("4. 预算 插入触发测试（部门0002预算+6000）：")
show_budget('0002')
try:
    cursor.execute("INSERT INTO Emp VALUES ('0008','测试','1999-10-01',2,'教师',6000.0,'0002')")
    conn.commit()
    show_budget('0002')
except sqlite3.DatabaserError as e:
    print("Error:", e)
```

#no-codly[
```
4. 预算 插入触发测试（部门0002预算+6000）：
Dept budgets for 0002: [('0002', '数学学院', 800000.0, '0002')]
Dept budgets for 0002: [('0002', '数学学院', 806000.0, '0002')]
```
]

```python
print("5. 预算 删除触发测试（部门0002预算-6000）：")
show_budget('0002')
try:
    cursor.execute("DELETE FROM Emp WHERE eno = '0008'")
    conn.commit()
    show_budget('0002')
except sqlite3.DatabaseError as e:
    print("Error:", e)
```

#no-codly[
```
5. 预算 删除触发测试（部门0002预算-6000）：
Dept budgets for 0002: [('0002', '数学学院', 806000.0, '0002')]
Dept budgets for 0002: [('0002', '数学学院', 800000.0, '0002')]
```
]

```python
print("6. 预算 部门变更触发测试（0004从部门0003更换至部门0002）")
show_budget('0002')
show_budget('0003')
try:
    cursor.execute("UPDATE Emp SET dno = '0002' WHERE eno = '0004'")
    conn.commit()
    show_budget('0002')
    show_budget('0003')
except sqlite3.DatabaseError as e:
    print("Error:", e)
```

#no-codly[
```
6. 预算 部门变更触发测试（0004从部门0003更换至部门0002）
Dept budgets for 0002: [('0002', '数学学院', 800000.0, '0002')]
Dept budgets for 0003: [('0003', '智能学院', 1204500.0, '0003')]
Dept budgets for 0002: [('0002', '数学学院', 806500.0, '0002')]
Dept budgets for 0003: [('0003', '智能学院', 1198000.0, '0003')]
```
]

```python
print("7. 预算 薪资修改出发测试（0004修改薪资为3500）")
show_budget('0002')
try:
    cursor.execute("UPDATE Emp SET salary = 3500 WHERE eno = '0004'")
    conn.commit()
    show_budget('0002')
except sqlite3.DatabaseError as e:
    print("Error", e)
```

#no-codly[
```
7. 预算 薪资修改出发测试（0004修改薪资为3500）
Dept budgets for 0002: [('0002', '数学学院', 806500.0, '0002')]
Dept budgets for 0002: [('0002', '数学学院', 803500.0, '0002')]
```
]

= 终极约束设计
`my_stock(stock_id, volume, avg_price, profit)`：表示所持有的股票编号、数量、持仓平均价格、利润。

`trans(trans_id,stock_id, date, price, amount, sell_or_buy)`：表示一次交易的编号、股票编号、交易日期、成交价格、成交数量、买入还是卖出。

使用触发器完成下面的工作：
1. 往`trans`里面插入一条记录时，根据其是买入还是卖出，调整`my_stock`中的`volume`以及`avg_price`。如果是初次插入的股票交易，就在`my_stock`中为该股票新建一条记录，`profit`置为0。注意，如果一笔卖出交易的`amount`大于`my_stock`中该股票的`volume`，说明是无效的下单交易，应该加以拒绝，直接抛弃。平均价格的计算：

$ "avg_price" = ("volume" times "avg_price" + "price" times "amount")/("volume"+"amount") $

2. `profit`的计算方式如下：每当有卖出交易发生时，将其与尽可能远的买入交易进行匹配，比如如果`trans`中现有的记录为`{(t01,s01,d01,10,1000,buy), (t02,s01,d02,12,500,buy)}`,如果现在插入`{(t03,s01,d03,11,700,sold)}`，本次交易产生的`profit=(11-10)*700`,如果再插入`{(t04,s01,d04,9,700,sold)}`，本次交易产生的`profit=(9-10)*300 + (9-12)*400 = -1500`.将每次卖出交易的profit都累加到`my_stock`的`profit`上。

```python
# 建表
import sqlite3

sqlite3.enable_callback_tracebacks(True)

conn = sqlite3.connect("stocks")
cursor = conn.cursor()

cursor.execute('''
CREATE TABLE IF NOT EXISTS my_stock (
  stock_id  TEXT    PRIMARY KEY,
  volume    INTEGER NOT NULL,
  avg_price REAL    NOT NULL,
  profit    REAL    NOT NULL DEFAULT 0
);
''')

cursor.execute('''
CREATE TABLE IF NOT EXISTS trans (
  trans_id    TEXT    PRIMARY KEY,
  stock_id    TEXT      NOT NULL REFERENCES my_stock(stock_id),
  date        DATE      NOT NULL,
  price       REAL      NOT NULL,
  amount      INTEGER   NOT NULL,
  sell_or_buy TEXT      NOT NULL CHECK(sell_or_buy IN ('buy','sold'))
);
''')

conn.commit()
print("建表完成")
```

#no-codly[
```
建表完成
```
]

```python
# 打印表结构
def print_table_schema(table_name, db_path="stocks"):
    """
    打印指定 SQLite 数据库中某个表的结构信息。
    
    参数:
        table_name (str): 要查看结构的表名。
    """
    try:
        # 连接到 SQLite 数据库
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        
        # 执行 PRAGMA table_info 命令获取表的结构信息
        cursor.execute(f"PRAGMA table_info('{table_name}')")
        columns = cursor.fetchall()
        
        if not columns:
            print(f"表 '{table_name}' 不存在或没有列信息。")
            return
        
        # 打印表结构信息
        print(f"表 '{table_name}' 的结构信息：")
        print("{:<5} {:<20} {:<15} {:<10} {:<15} {:<5}".format(
            "cid", "name", "type", "notnull", "dflt_value", "pk"
        ))
        print("-" * 80)
        for col in columns:
            cid, name, col_type, notnull, dflt_value, pk = col
            print("{:<5} {:<20} {:<15} {:<10} {:<15} {:<5}".format(
                cid, name, col_type, notnull, str(dflt_value), pk
            ))
    except sqlite3.Error as e:
        print(f"发生错误: {e}")
    finally:
        # 关闭数据库连接
        if conn:
            conn.close()
```

```python
def print_table_data(table_name, db_path="stocks"):
    """
    打印指定 SQLite 数据库中某个表的所有数据，并对齐列。

    参数:
        table_name (str): 要查看数据的表名。
    """
    try:
        # 连接到 SQLite 数据库
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        # 构建 SQL 查询语句
        query = f"SELECT * FROM {table_name}"
        # 执行查询
        cursor.execute(query)
        rows = cursor.fetchall()
        # 获取列名
        column_names = [description[0] for description in cursor.description]
        # 获取列类型信息
        cursor.execute(f"PRAGMA table_info('{table_name}')")
        table_info = cursor.fetchall()
        column_types = [info[2].upper() for info in table_info]
        # 计算每列的最大宽度
        col_widths = [len(col) for col in column_names]
        for row in rows:
            for idx, item in enumerate(row):
                if isinstance(item, float):
                    item_str = f"{item:.2f}"
                else:
                    item_str = str(item)
                col_widths[idx] = max(col_widths[idx], len(item_str))

        # 构建格式化字符串
        format_str = " | ".join(f"{{:<{width}}}" for width in col_widths)
        # 打印列名
        print(f"表 '{table_name}' 的数据：")
        print(format_str.format(*column_names))
        print("-" * (sum(col_widths) + 3 * (len(col_widths) - 1)))
        # 打印每一行数据
        for row in rows:
            formatted_row = []
            for idx, item in enumerate(row):
                if column_types[idx] in ('REAL', 'FLOAT', 'DOUBLE') and isinstance(item, float):
                    formatted_item = f"{item:.2f}"
                else:
                    formatted_item = str(item)
                formatted_row.append(formatted_item)
            print(format_str.format(*formatted_row))

    except sqlite3.Error as e:
        print(f"发生错误: {e}")
    finally:
        # 关闭数据库连接
        if conn:
            conn.close()
```

```python
print_table_schema("my_stock")
```

#no-codly[
```
表 'my_stock' 的结构信息：
cid   name                 type            notnull    dflt_value      pk   
--------------------------------------------------------------------------------
0     stock_id             TEXT            0          None            1    
1     volume               INTEGER         1          None            0    
2     avg_price            REAL            1          None            0    
3     profit               REAL            1          0               0    
```
]

```python
print_table_schema("trans")
```

#no-codly[
```
表 'trans' 的结构信息：
cid   name                 type            notnull    dflt_value      pk   
--------------------------------------------------------------------------------
0     trans_id             TEXT            0          None            1    
1     stock_id             TEXT            1          None            0    
2     date                 DATE            1          None            0    
3     price                REAL            1          None            0    
4     amount               INTEGER         1          None            0    
5     sell_or_buy          TEXT            1          None            0      
```
]

根据要求，我们需要完成3个触发器：
1. 拒绝无效卖出交易
2. 买入后更新持仓数量与加权平均价
3. 卖出后更新持仓数量与加权平均价

```python
# 拒绝无效卖出交易
cursor.execute('''
DROP TRIGGER IF EXISTS before_insert_trans
''')

cursor.execute('''
CREATE TRIGGER before_insert_trans
BEFORE INSERT ON trans
WHEN NEW.sell_or_buy = 'sold'
BEGIN
  -- 如果卖出数量超过当前持仓，Abort 并抛错
  -- 当前甚至没有持仓的话，数量为0
  SELECT RAISE(ABORT, '卖出数量超过持仓，交易被拒绝')
  WHERE NEW.amount > COALESCE(
    (SELECT volume FROM my_stock WHERE stock_id = NEW.stock_id), 0
  );
END;
''')
conn.commit()
```

```python
# 买入后更新持仓数量与加权平均价
cursor.execute('''
DROP TRIGGER IF EXISTS after_insert_buy
''')

cursor.execute('''
CREATE TRIGGER after_insert_buy
AFTER INSERT ON trans
WHEN NEW.sell_or_buy = 'buy'
BEGIN
  -- 如果已有持仓，更新 volume 和 avg_price；否则插入新记录
  INSERT INTO my_stock(stock_id, volume, avg_price, profit)
  VALUES (
    NEW.stock_id,
    NEW.amount,
    NEW.price,
    0
  )
  ON CONFLICT(stock_id) DO UPDATE SET
    volume    = volume + NEW.amount,
    avg_price = (volume * avg_price + NEW.price * NEW.amount)
                / (volume + NEW.amount);
END;
''')
conn.commit()
```

```python
# 卖出后更新持仓数量与加权平均价
# 注意：检查是否存在这只股票的触发器已经在前面定义了
cursor.execute('''
DROP TRIGGER IF EXISTS after_insert_sell
''')

cursor.execute('''
CREATE TRIGGER after_insert_sell
AFTER INSERT ON trans
WHEN NEW.sell_or_buy = 'sold'
BEGIN
  -- 扣减持仓
  UPDATE my_stock
    SET volume = volume - NEW.amount
    WHERE stock_id = NEW.stock_id;
END;
''')
conn.commit()
```

由于SQLite3不支持循环等复杂操作，我们在Python中实现先入先出（FIFO）式的匹配股票操作，并且使用Sqlite3的`create_function`将Python函数暴露给SQL引擎。同时，我们创建一个新的表`sale_buy_alloc`来进行配对记录。

考虑到在读数据库的时候数据库被上锁的问题，我们新建一个数据库来保存分配信息。

但是问题在于 SQLite 不支持在触发器中使用 UDF。不过，#link("https://sqlite.org/forum/forumpost/96160a6536e33f71")[Gunter Hick]给出了一个解决方案：“The trigger program is compiled when the `CREATE TRIGGER` statement is executed (during initial execution or when the schema is loaded from the file). Any functions referenced in triggers need to be defined at that point in time. Your schema will fail to load unless the functions referenced in trigger programs are defined.

You should be able to build an extension that creates your user defined functions and then executes one or more `CREATE TEMP TRIGGER` statements that use the now-defined functions. See #link("https://sqlite.org/loadext.html")”。

我们在这里使用这种方案解决 SQLite 的这个问题。

```python
conn_alloc = sqlite3.connect("alloc")
cursor_alloc = conn_alloc.cursor()

cursor_alloc.execute('''
CREATE TABLE IF NOT EXISTS sale_buy_alloc (
  sale_trans_id TEXT NOT NULL,
  buy_trans_id  TEXT NOT NULL,
  alloc_amt     INTEGER NOT NULL,
  PRIMARY KEY (sale_trans_id, buy_trans_id)
);
''')

cursor_alloc.execute('''
DELETE FROM sale_buy_alloc
''')
conn_alloc.commit()
print_table_schema("sale_buy_alloc", db_path="alloc")
```

#no-codly[
```
表 'sale_buy_alloc' 的结构信息：
cid   name                 type            notnull    dflt_value      pk   
--------------------------------------------------------------------------------
0     sale_trans_id        TEXT            1          None            1    
1     buy_trans_id         TEXT            1          None            2    
2     alloc_amt            INTEGER         1          None            0    
```
]

```python
def calculate_profit(sale_trans_id, stock_id, sell_price, sell_amt):
    conn = sqlite3.connect('stocks')
    conn.row_factory = sqlite3.Row  # 让 fetch 回来的是 dict-like 行
    cursor = conn.cursor()

    profit = 0.0

    # 把另一个数据库里的东西挂载进来
    cursor.execute("ATTACH DATABASE ? AS allocdb", ('alloc',))

    # 查询所有未完全分配的买入记录
    cursor.execute("""
        SELECT
            t.trans_id,
            t.price AS buy_price,
            t.amount - COALESCE(SUM(a.alloc_amt), 0) AS remain
        FROM trans t
        LEFT JOIN allocdb.sale_buy_alloc a
            ON t.trans_id = a.buy_trans_id
        WHERE t.stock_id = ?
          AND t.sell_or_buy = 'buy'
        GROUP BY t.trans_id, t.price, t.amount
        HAVING remain > 0
        ORDER BY t.date ASC
    """, (stock_id,))

    conn_alloc = sqlite3.connect('alloc')
    cursor_alloc = conn_alloc.cursor()
    
    for buy in cursor:
        if sell_amt <= 0:
            break
        buy_trans_id, buy_price, remain = buy[0], buy[1], buy[2]
        match_amt = min(remain, sell_amt)
        profit += (sell_price - buy_price) * match_amt
        # 写入分配关系
        cursor_alloc.execute("INSERT INTO sale_buy_alloc "
                       "(sale_trans_id, buy_trans_id, alloc_amt) "
                       "VALUES (?, ?, ?)",
                       (sale_trans_id, buy_trans_id, match_amt))
        sell_amt -= match_amt

    conn_alloc.commit()
    conn.commit()

    conn_alloc.close()
    conn.close()
    return profit
```

```python
# 卖出后计算利润
cursor.execute('''
DROP TRIGGER IF EXISTS profit_after_buy
''')

# 注册 UDF, -1表示可以有不限制的参数个数
conn.create_function("calculate_profit", -1, calculate_profit)

cursor.execute('''
CREATE TEMP TRIGGER profit_after_buy
AFTER INSERT ON trans
WHEN NEW.sell_or_buy = 'sold'
BEGIN
  -- 调用 Python 注册的 UDF，执行 FIFO 配对 & 更新 profit 并返回本次 profit
  UPDATE my_stock
    SET profit = profit + calculate_profit(NEW.trans_id, NEW.stock_id, NEW.price, NEW.amount)
    WHERE stock_id = NEW.stock_id;
END;
''')
conn.commit()
```

现在我们使用提供的触发器的测试数据进行测试。

```python
# 清空表
cursor.execute("DELETE FROM my_stock")
cursor.execute("DELETE FROM trans")
conn.commit()
```

```python
def test(trans_id, stock_id, date, price, amount, sell_or_buy):
    try:
        cursor.execute("INSERT INTO trans"
                    "(trans_id, stock_id, date, price, amount, sell_or_buy)"
                    "VALUES (?,?,?,?,?,?)",
                    (trans_id, stock_id, date, price, amount, sell_or_buy))
        conn.commit()
        print_table_data("my_stock")
        print_table_data("trans")
    except Exception as e:
        print("触发器拦截非法操作:", e)
        conn.rollback()
```

```python
test('1', '1', '2025-01-01', 10, 1000, 'buy')
```

#no-codly[
```
表 'my_stock' 的数据：
stock_id | volume | avg_price | profit
--------------------------------------
1        | 1000   | 10.00     | 0.00  
表 'trans' 的数据：
trans_id | stock_id | date       | price | amount | sell_or_buy
---------------------------------------------------------------
1        | 1        | 2025-01-01 | 10.00 | 1000   | buy        
```
]

```python
test('2', '1', '2025-01-02', 11, 500, 'buy')
```

#no-codly[
```
表 'my_stock' 的数据：
stock_id | volume | avg_price | profit
--------------------------------------
1        | 1500   | 10.33     | 0.00  
表 'trans' 的数据：
trans_id | stock_id | date       | price | amount | sell_or_buy
---------------------------------------------------------------
1        | 1        | 2025-01-01 | 10.00 | 1000   | buy        
2        | 1        | 2025-01-02 | 11.00 | 500    | buy        
```
]

```python
test('3', '1', '2025-01-03', 12, 800, 'sold')
```

#no-codly[
```
表 'my_stock' 的数据：
stock_id | volume | avg_price | profit 
---------------------------------------
1        | 700    | 10.33     | 1600.00
表 'trans' 的数据：
trans_id | stock_id | date       | price | amount | sell_or_buy
---------------------------------------------------------------
1        | 1        | 2025-01-01 | 10.00 | 1000   | buy        
2        | 1        | 2025-01-02 | 11.00 | 500    | buy        
3        | 1        | 2025-01-03 | 12.00 | 800    | sold       
```
]

```python
test('4', '1', '2025-01-04', 12.0, 1000, 'sold')
```

#no-codly[
```
触发器拦截非法操作: 卖出数量超过持仓，交易被拒绝  
```
]

```python
test('5', '1', '2025-01-05', 9.0, 1000, 'buy')
```

#no-codly[
```
表 'my_stock' 的数据：
stock_id | volume | avg_price | profit 
---------------------------------------
1        | 1700   | 9.55      | 1600.00
表 'trans' 的数据：
trans_id | stock_id | date       | price | amount | sell_or_buy
---------------------------------------------------------------
1        | 1        | 2025-01-01 | 10.00 | 1000   | buy        
2        | 1        | 2025-01-02 | 11.00 | 500    | buy        
3        | 1        | 2025-01-03 | 12.00 | 800    | sold       
5        | 1        | 2025-01-05 | 9.00  | 1000   | buy         
```
]

```python
test('6', '1', '2025-01-06', 12.0, 800, 'sold')
```

#no-codly[
```
表 'my_stock' 的数据：
stock_id | volume | avg_price | profit 
---------------------------------------
1        | 900    | 9.55      | 2800.00
表 'trans' 的数据：
trans_id | stock_id | date       | price | amount | sell_or_buy
---------------------------------------------------------------
1        | 1        | 2025-01-01 | 10.00 | 1000   | buy        
2        | 1        | 2025-01-02 | 11.00 | 500    | buy        
3        | 1        | 2025-01-03 | 12.00 | 800    | sold       
5        | 1        | 2025-01-05 | 9.00  | 1000   | buy        
6        | 1        | 2025-01-06 | 12.00 | 800    | sold
```
]

```python
test('7', '1', '2025-01-07', 7.0, 800, 'sold')
```

#no-codly[
```
表 'my_stock' 的数据：
stock_id | volume | avg_price | profit 
---------------------------------------
1        | 100    | 9.55      | 1200.00
表 'trans' 的数据：
trans_id | stock_id | date       | price | amount | sell_or_buy
---------------------------------------------------------------
1        | 1        | 2025-01-01 | 10.00 | 1000   | buy        
2        | 1        | 2025-01-02 | 11.00 | 500    | buy        
3        | 1        | 2025-01-03 | 12.00 | 800    | sold       
5        | 1        | 2025-01-05 | 9.00  | 1000   | buy        
6        | 1        | 2025-01-06 | 12.00 | 800    | sold       
7        | 1        | 2025-01-07 | 7.00  | 800    | sold
```
]

```python
print_table_data("sale_buy_alloc", db_path="alloc")
```

#no-codly[
```
表 'sale_buy_alloc' 的数据：
sale_trans_id | buy_trans_id | alloc_amt
----------------------------------------
3             | 1            | 800      
6             | 1            | 200      
6             | 2            | 500      
6             | 5            | 100      
7             | 5            | 800      
```
]
