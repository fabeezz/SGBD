CREATE TABLE zile_233jf (
    id number(5),
    data date,
    nume_zi varchar2(50),
    primary key (id)
);

--10

DECLARE
 contor NUMBER(6) := 1;
 v_data DATE;
 maxim NUMBER(2) := LAST_DAY(SYSDATE)-SYSDATE;
BEGIN
 LOOP
 v_data := sysdate+contor;
 INSERT INTO zile_233jf
 VALUES (contor,v_data,to_char(v_data,'Day'));
 contor := contor + 1;
 EXIT WHEN contor > maxim;
 END LOOP;
END;
/

--11
DECLARE
 contor NUMBER(6) := 1;
 v_data DATE;
 maxim NUMBER(2) := LAST_DAY(SYSDATE)-SYSDATE;
BEGIN
 WHILE contor <= maxim LOOP
 v_data := sysdate+contor;
 INSERT INTO zile_233jf
 VALUES (contor,v_data,to_char(v_data,'Day'));
 contor := contor + 1;
 END LOOP;
END;
/

--12
DECLARE
 v_data DATE;
 maxim NUMBER(2) := LAST_DAY(SYSDATE)-SYSDATE;
BEGIN
 FOR contor IN 1..maxim LOOP
 v_data := sysdate+contor;
 INSERT INTO zile_233jf
 VALUES (contor,v_data,to_char(v_data,'Day'));
 END LOOP;
END;
/

SELECT * FROM zile_233jf;
rollback;

--13
DECLARE
    i POSITIVE:=1;
 max_loop CONSTANT POSITIVE:=10;
BEGIN
 i:=1;
 LOOP
 i:=i+1;
 DBMS_OUTPUT.PUT_LINE('in loop i=' || i);
 EXIT WHEN i>max_loop;
 END LOOP;
 i:=1;
 DBMS_OUTPUT.PUT_LINE('dupa loop i=' || i);
END;


--LAB2 PL/SQL
--10
CREATE TABLE emp_test_233jf AS
 SELECT employee_id, last_name FROM employees
 WHERE ROWNUM <= 2;
CREATE OR REPLACE TYPE tip_telefon_233jf IS TABLE OF VARCHAR(12);


ALTER TABLE emp_test_233jf
ADD (telefon tip_telefon_233jf)
NESTED TABLE telefon STORE AS tabel_telefon_233jf;
INSERT INTO emp_test_233jf
VALUES (500, 'XYZ',tip_telefon_233jf('074XXX', '0213XXX', '037XXX'));
UPDATE emp_test_233jf
SET telefon = tip_telefon_233jf('073XXX', '0214XXX')
WHERE employee_id=100;
SELECT a.employee_id, b.*
FROM emp_test_233jf a, TABLE (a.telefon) b;
/

DROP TABLE emp_test_233jf;
DROP TYPE tip_telefon_233jf;
/

--11
DECLARE
    TYPE tip_cod IS VARRAY(5) OF NUMBER(3);
    coduri tip_cod := tip_cod(205,206);
BEGIN
    FORALL i IN coduri.FIRST .. coduri.LAST
        DELETE FROM emp_test_233jf
        WHERE employee_id = coduri(i);
END;
/

SELECT * FROM emp_test_233jf;


--
begin
    for i in REVERSE 1..5
    loop
    DBMS_OUTPUT.PUT_LINE(i);
    END LOOP;
end;
/b
    

