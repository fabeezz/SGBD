-- Jiglau Fabrizzio

SET SERVEROUTPUT ON;

DECLARE
    TYPE emp_record IS RECORD (
        nume departments.department_name%TYPE,
        nr   NUMBER(30)
    );
    
    TYPE emp_table IS TABLE OF emp_record;
    dep_table emp_table;
    
    CURSOR c IS 
        SELECT department_name nume, COUNT(employee_id) nr   
        FROM   departments d, employees e 
        WHERE  d.department_id = e.department_id(+) 
        GROUP BY department_name;
BEGIN
    OPEN c;
    LOOP
        FETCH c BULK COLLECT INTO dep_table LIMIT 5;
        EXIT WHEN dep_table.COUNT = 0;
        
        FOR i IN 1..dep_table.COUNT LOOP
            IF dep_table(i).nr = 0 THEN
                DBMS_OUTPUT.PUT_LINE('In departamentul ' || dep_table(i).nume || ' nu lucreaza angajati');
            ELSIF dep_table(i).nr = 1 THEN
                DBMS_OUTPUT.PUT_LINE('In departamentul ' || dep_table(i).nume || ' lucreaza un angajat');
            ELSE
                DBMS_OUTPUT.PUT_LINE('In departamentul ' || dep_table(i).nume || ' lucreaza ' || dep_table(i).nr || ' angajati');
            END IF;
        END LOOP;
    END LOOP;
    CLOSE c;
END;
/