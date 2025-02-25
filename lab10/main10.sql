SET SERVEROUTPUT ON;

CREATE OR REPLACE PACKAGE pachet1_233jf AS
    FUNCTION f_numar(v_dept departments.department_id%TYPE)
        RETURN NUMBER;
    FUNCTION f_suma(v_dept departments.department_id%TYPE)
        RETURN NUMBER;
END pachet1_233jf;
/
CREATE OR REPLACE PACKAGE BODY pachet1_233jf AS
    FUNCTION f_numar(v_dept departments.department_id%TYPE)
        RETURN NUMBER IS numar NUMBER;
    BEGIN
        SELECT COUNT(*)INTO numar
        FROM employees
        WHERE department_id = v_dept;
    RETURN numar;
    END f_numar;
    FUNCTION f_suma (v_dept departments.department_id%TYPE)
        RETURN NUMBER IS suma NUMBER;
    BEGIN
        SELECT SUM(salary+salary*NVL(commission_pct,0))
        INTO suma
        FROM employees
        WHERE department_id = v_dept;
    RETURN suma;
    END f_suma;
END pachet1_233jf;
/ 

--in SQL
SELECT pachet1_233jf.f_numar(80)
FROM DUAL;
SELECT pachet1_233jf.f_suma(80)
FROM DUAL;
--in PL/SQL:
BEGIN
 DBMS_OUTPUT.PUT_LINE('numarul de salariati este '||
 pachet1_233jf.f_numar(80));
 DBMS_OUTPUT.PUT_LINE('suma alocata este '||
 pachet1_233jf.f_suma(80));
END;
/ 


--2
CREATE SEQUENCE sec_233jf;

CREATE OR REPLACE PACKAGE pachet2_233jf AS
 PROCEDURE p_dept (v_codd dept_233jf.department_id%TYPE,
 v_nume dept_233jf.department_name%TYPE,
 v_manager dept_233jf.manager_id%TYPE,
 v_loc dept_233jf.location_id%TYPE);
 PROCEDURE p_emp (v_first_name emp_233jf.first_name%TYPE,
 v_last_name emp_233jf.last_name%TYPE,
 v_email emp_233jf.email%TYPE,
 v_phone_number emp_233jf.phone_number%TYPE:=NULL,
 v_hire_date emp_233jf.hire_date%TYPE :=SYSDATE,
 v_job_id emp_233jf.job_id%TYPE,
 v_salary emp_233jf.salary%TYPE :=0,
 v_commission_pct emp_233jf.commission_pct%TYPE:=0,
 v_manager_id emp_233jf.manager_id%TYPE,
 v_department_id emp_233jf.department_id%TYPE);
 FUNCTION exista (cod_loc dept_233jf.location_id%TYPE,
 manager dept_233jf.manager_id%TYPE)
 RETURN NUMBER;
END pachet2_233jf;
/

CREATE OR REPLACE PACKAGE BODY pachet2_233jf AS
FUNCTION exista(cod_loc dept_233jf.location_id%TYPE,
 manager dept_233jf.manager_id%TYPE)
 RETURN NUMBER IS
 rezultat NUMBER:=1;
 rez_cod_loc NUMBER;
 rez_manager NUMBER;
 BEGIN
 SELECT count(*) INTO rez_cod_loc
 FROM locations
 WHERE location_id = cod_loc;

 SELECT count(*) INTO rez_manager
 FROM emp_233jf
 WHERE employee_id = manager;

 IF rez_cod_loc=0 OR rez_manager=0 THEN
 rezultat:=0;
 END IF;
RETURN rezultat;
END;
PROCEDURE p_dept(v_codd dept_233jf.department_id%TYPE,
 v_nume dept_233jf.department_name%TYPE,
 v_manager dept_233jf.manager_id%TYPE,
 v_loc dept_233jf. location_id%TYPE) IS
BEGIN
 IF exista(v_loc, v_manager)=0 THEN
 DBMS_OUTPUT.PUT_LINE('Nu s-au introdus date coerente pentru
tabelul dept_233jf');
 ELSE
 INSERT INTO dept_233jf
 (department_id,department_name,manager_id,location_id)
 VALUES (v_codd, v_nume, v_manager, v_loc);
 END IF;
 END p_dept;
PROCEDURE p_emp
(v_first_name emp_233jf.first_name%TYPE,
 v_last_name emp_233jf.last_name%TYPE,
 v_email emp_233jf.email%TYPE,
 v_phone_number emp_233jf.phone_number%TYPE:=null,
 v_hire_date emp_233jf.hire_date%TYPE :=SYSDATE,
 v_job_id emp_233jf.job_id%TYPE,
 v_salary emp_233jf.salary %TYPE :=0,
 v_commission_pct emp_233jf.commission_pct%TYPE:=0,
 v_manager_id emp_233jf.manager_id%TYPE,
 v_department_id emp_233jf.department_id%TYPE)
AS
 BEGIN
 INSERT INTO emp_233jf
 VALUES (sec_233jf.NEXTVAL, v_first_name, v_last_name, v_email,
 v_phone_number,v_hire_date, v_job_id, v_salary,
 v_commission_pct, v_manager_id,v_department_id);
END p_emp;
END pachet2_233jf;
/ 

BEGIN
 pachet2_233jf.p_dept(50,'Economic',99,2000);
 pachet2_233jf.p_emp('f','l','e',v_job_id=>'j',v_manager_id=>200,
 v_department_id=>50);
END;
/
SELECT * FROM emp_233jf WHERE job_id='j';
ROLLBACK;


--3
CREATE OR REPLACE PACKAGE pachet3_233jf AS
    CURSOR c_emp(nr NUMBER) RETURN employees%ROWTYPE;
    FUNCTION f_max (v_oras locations.city%TYPE) RETURN NUMBER;
END pachet3_233jf;
/

CREATE OR REPLACE PACKAGE BODY pachet3_233jf AS
CURSOR c_emp(nr NUMBER) RETURN employees%ROWTYPE
 IS
 SELECT *
 FROM employees
 WHERE salary >= nr;
FUNCTION f_max (v_oras locations.city%TYPE) RETURN NUMBER IS
 maxim NUMBER;
BEGIN
 SELECT MAX(salary)
 INTO maxim
 FROM employees e, departments d, locations l
 WHERE e.department_id=d.department_id
 AND d.location_id=l.location_id
 AND UPPER(city)=UPPER(v_oras);
 RETURN maxim;
END f_max;
END pachet3_233jf;
/
DECLARE
 oras locations.city%TYPE:= 'Toronto';
 val_max NUMBER;
 lista employees%ROWTYPE;
BEGIN
 val_max:= pachet3_233jf.f_max(oras);
 FOR v_cursor IN pachet3_233jf.c_emp(val_max) LOOP
 DBMS_OUTPUT.PUT_LINE(v_cursor.last_name||' '||
 v_cursor.salary);
 END LOOP;
END;
/ 

--4
CREATE OR REPLACE PACKAGE pachet4_233jf IS
 PROCEDURE p_verific
 (v_cod employees.employee_id%TYPE,
 v_job employees.job_id%TYPE);
 CURSOR c_emp RETURN employees%ROWTYPE;
END pachet4_233jf;
/ 
CREATE OR REPLACE PACKAGE BODY pachet4_233jf IS
CURSOR c_emp RETURN employees%ROWTYPE IS
 SELECT *
 FROM employees; 
 
 PROCEDURE p_verific(v_cod employees.employee_id%TYPE,
 v_job employees.job_id%TYPE)
IS
 gasit BOOLEAN:=FALSE;
 lista employees%ROWTYPE;
BEGIN
 OPEN c_emp;
 LOOP
 FETCH c_emp INTO lista;
 EXIT WHEN c_emp%NOTFOUND;
 IF lista.employee_id=v_cod AND lista.job_id=v_job
 THEN gasit:=TRUE;
 END IF;
 END LOOP;
 CLOSE c_emp;
 IF gasit=TRUE THEN
 DBMS_OUTPUT.PUT_LINE('combinatia data exista');
 ELSE
 DBMS_OUTPUT.PUT_LINE('combinatia data nu exista');
 END IF;
END p_verific;
END pachet4_233jf;
/

EXECUTE pachet4_233jf.p_verific(200,'AD_ASST'); 


DECLARE
-- paramentrii de tip OUT pt procedura GET_LINE
 linie1 VARCHAR2(255);
 stare1 INTEGER;
 linie2 VARCHAR2(255);
 stare2 INTEGER;
 linie3 VARCHAR2(255);
 stare3 INTEGER;
v_emp employees.employee_id%TYPE;
v_job employees.job_id%TYPE;
v_dept employees.department_id%TYPE; 
BEGIN
 SELECT employee_id, job_id, department_id
 INTO v_emp,v_job,v_dept
 FROM employees
 WHERE last_name='Lorentz';
-- se introduce o linie in buffer fara caracter
-- de terminare linie
 DBMS_OUTPUT.PUT(' 1 '||v_emp|| ' ');
-- se incearca extragerea liniei introdusa
-- in buffer si starea acesteia
 DBMS_OUTPUT.GET_LINE(linie1,stare1);
-- se depunde informatie pe aceeasi linie in buffer
 DBMS_OUTPUT.PUT(' 2 '||v_job|| ' ');
-- se inchide linia depusa in buffer si se extrage
-- linia din buffer
 DBMS_OUTPUT.NEW_LINE;
 DBMS_OUTPUT.GET_LINE(linie2,stare2);
-- se introduc informatii pe aceeasi linie
-- si se afiseaza informatia
 DBMS_OUTPUT.PUT_LINE(' 3 ' ||v_emp|| ' '|| v_job);
 DBMS_OUTPUT.GET_LINE(linie3,stare3);
-- se afiseaza ceea ce s-a extras
 DBMS_OUTPUT.PUT_LINE('linie1 = '|| linie1||
 '; stare1 = '||stare1);
 DBMS_OUTPUT.PUT_LINE('linie2 = '|| linie2||
 '; stare2 = '||stare2);
 DBMS_OUTPUT.PUT_LINE('linie3 = '|| linie3||
 '; stare3 = '||stare3);
END;
/