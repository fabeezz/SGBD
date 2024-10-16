SET SERVEROUTPUT ON;

DECLARE
    numar number(3) := 100;
    mesaj1 varchar2(255) := 'text 1';
    mesaj2 varchar2(255) := 'text 2';
BEGIN
    DECLARE
        numar number(3) := 1;
        mesaj1 varchar2(255) := 'text 2';
        mesaj2 varchar2(255) := 'text 3';
    BEGIN
        numar := numar+1;
        mesaj2 := mesaj2 || ' adaugat in sub-bloc';
    DBMS_OUTPUT.PUT_LINE(numar);
    DBMS_OUTPUT.PUT_LINE(mesaj1);
    DBMS_OUTPUT.PUT_LINE(mesaj2);
    END;
    numar:=numar+1; 
    mesaj1:=mesaj1||' adaugat un blocul principal';
    mesaj2:=mesaj2||' adaugat in blocul principal'; 
DBMS_OUTPUT.PUT_LINE(numar);
DBMS_OUTPUT.PUT_LINE(mesaj1);
DBMS_OUTPUT.PUT_LINE(mesaj2);
END;

--4
DECLARE
 v_dep departments.department_name%TYPE;
 nr_angajati number(5);
BEGIN
 SELECT department_name, COUNT(*)
 INTO v_dep, nr_angajati
 FROM employees e, departments d
 WHERE e.department_id=d.department_id
 GROUP BY department_name
 HAVING COUNT(*) = (SELECT MAX(COUNT(*))
 FROM employees
GROUP BY department_id);
 DBMS_OUTPUT.PUT_LINE('Departamentul '|| v_dep || ' - ' || nr_angajati);
END;
/

--7
SET VERIFY OFF
DECLARE
 v_cod employees.employee_id%TYPE:=&p_cod;
 v_bonus NUMBER(8);
 v_salariu_anual NUMBER(8);
BEGIN
 SELECT salary*12 INTO v_salariu_anual
 FROM employees
 WHERE employee_id = v_cod;
 IF v_salariu_anual>=200001
 THEN v_bonus:=20000;
 ELSIF v_salariu_anual BETWEEN 100001 AND 200000
 THEN v_bonus:=10000;
 ELSE v_bonus:=5000;
END IF;
DBMS_OUTPUT.PUT_LINE('Bonusul este ' || v_bonus);
END;
/
SET VERIFY ON

--8
SET VERIFY OFF
DECLARE
 v_cod employees.employee_id%TYPE := &p_cod;
 v_bonus NUMBER(8);
 v_salariu_anual NUMBER(8);
BEGIN
  SELECT salary * 12 INTO v_salariu_anual
  FROM employees
  WHERE employee_id = v_cod;
  v_bonus := CASE
               WHEN v_salariu_anual >= 200001 THEN 20000
               WHEN v_salariu_anual BETWEEN 100001 AND 200000 THEN 10000
               ELSE 5000
             END;
  DBMS_OUTPUT.PUT_LINE('Bonusul este ' || v_bonus);
END;
/
SET VERIFY ON

--9
DEFINE p_cod_sal= 200
DEFINE p_cod_dept = 80
DEFINE p_procent =20
DECLARE
 v_cod_sal emp_***.employee_id%TYPE:= &p_cod_sal;
 v_cod_dept emp_***.department_id%TYPE:= &p_cod_dept;
 v_procent NUMBER(8):=&p_procent;
BEGIN
 UPDATE emp_***
 SET department_id = v_cod_dept,
 salary=salary + (salary* v_procent/100)
 WHERE employee_id= v_cod_sal;
 IF SQL%ROWCOUNT =0 THEN
 DBMS_OUTPUT.PUT_LINE('Nu exista un angajat cu acest cod');
 ELSE DBMS_OUTPUT.PUT_LINE('Actualizare realizata');
 END IF;
END;
/
ROLLBACK;
