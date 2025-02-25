SET SERVEROUTPUT ON;

CREATE TABLE new_emp AS
SELECT employee_id, salary
FROM employees;

SELECT * FROM new_emp;

DECLARE
    TYPE tablou_ang IS TABLE OF employees.employee_id%TYPE INDEX BY BINARY_INTEGER;
    TYPE salary_table IS TABLE OF employees.salary%TYPE INDEX BY BINARY_INTEGER;

    t tablou_ang;
    old_salaries salary_table;
    new_salaries salary_table;
BEGIN
    -- put ids in t
    SELECT employee_id
    BULK COLLECT INTO t
    FROM employees
    WHERE salary IN (
            SELECT salary
            FROM (
                SELECT e.salary
                FROM employees e
                ORDER BY e.salary
            )
            WHERE ROWNUM <= 5
    );
    
    -- old
    FOR i IN t.FIRST .. t.LAST LOOP
        SELECT salary INTO old_salaries(i) FROM new_emp WHERE employee_id = t(i);
    END LOOP;

    -- change the salary
    FORALL i IN t.FIRST .. t.LAST
        UPDATE new_emp
        SET salary = salary * 1.05
        WHERE employee_id = t(i);

    -- new
    FOR i IN t.FIRST .. t.LAST LOOP
        SELECT salary INTO new_salaries(i) FROM new_emp WHERE employee_id = t(i);
    END LOOP;
    
    FOR i IN t.FIRST .. t.LAST LOOP
        DBMS_OUTPUT.PUT_LINE('Employee ID: ' || t(i) ||
                             ', Old Salary: ' || old_salaries(i) ||
                             ', New Salary: ' || new_salaries(i));
    END LOOP;
    
    COMMIT;
END;
/

