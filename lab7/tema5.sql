-- Jiglau Fabrizzio
SET SERVEROUTPUT ON;

SELECT * FROM EMPLOYEES;
SELECT * FROM JOBS;
SELECT * FROM DEPARTMENTS;

--a
DECLARE
    CURSOR job_cursor IS
        SELECT job_id, job_title FROM jobs;
    v_job_id jobs.job_id%TYPE;
    v_title jobs.job_title%TYPE;
BEGIN
    OPEN job_cursor;
    LOOP
        FETCH job_cursor INTO v_job_id, v_title;
        EXIT WHEN job_cursor%NOTFOUND;

        DBMS_OUTPUT.PUT_LINE('--- Job: ' || v_title ||' ---');

        FOR emp IN (SELECT first_name, salary FROM employees WHERE job_id = v_job_id) LOOP
            DBMS_OUTPUT.PUT_LINE(emp.first_name || ' Salary: ' || emp.salary);
        END LOOP;

        IF SQL%ROWCOUNT = 0 THEN
            DBMS_OUTPUT.PUT_LINE('!No employees.');
        END IF;
    END LOOP;
    CLOSE job_cursor;
END;
/

--b
DECLARE
    CURSOR job_cursor IS
        SELECT job_id, job_title FROM jobs;
BEGIN
    FOR job IN job_cursor LOOP
        DBMS_OUTPUT.PUT_LINE('--- Job: ' || job.job_title || ' ---');

        FOR emp IN (SELECT first_name, salary FROM employees WHERE job_id = job.job_id) LOOP
            DBMS_OUTPUT.PUT_LINE(emp.first_name || ' Salary: ' || emp.salary);
        END LOOP;

        IF SQL%ROWCOUNT = 0 THEN
            DBMS_OUTPUT.PUT_LINE('!No employees.');
        END IF;
    END LOOP;
END;
/

--c
BEGIN
    FOR job IN (SELECT job_id, job_title FROM jobs) LOOP
        DBMS_OUTPUT.PUT_LINE('--- Job: ' || job.job_title || ' ---');

        FOR emp IN (SELECT first_name, salary FROM employees WHERE job_id = job.job_id) LOOP
            DBMS_OUTPUT.PUT_LINE(emp.first_name || ' Salary: ' || emp.salary);
        END LOOP;

        IF SQL%ROWCOUNT = 0 THEN
            DBMS_OUTPUT.PUT_LINE('!No employees.');
        END IF;
    END LOOP;
END;
/

--d
DECLARE
    TYPE ref_cursor IS REF CURSOR;
    v_cursor ref_cursor;
    v_job_id jobs.job_id%TYPE;
    v_title jobs.job_title%TYPE;
    v_emp_name employees.first_name%TYPE;
    v_emp_salary employees.salary%TYPE;
BEGIN
    OPEN v_cursor FOR 
        SELECT job_id, job_title FROM jobs;

    LOOP
        FETCH v_cursor INTO v_job_id, v_title;
        EXIT WHEN v_cursor%NOTFOUND;

        DBMS_OUTPUT.PUT_LINE('--- Job: ' || v_title || ' ---');

        FOR emp IN (SELECT first_name, salary FROM employees WHERE job_id = v_job_id) LOOP
            DBMS_OUTPUT.PUT_LINE(emp.first_name || ' Salary: ' || emp.salary);
        END LOOP;

        IF SQL%ROWCOUNT = 0 THEN
            DBMS_OUTPUT.PUT_LINE('!No employees.');
        END IF;
    END LOOP;

    CLOSE v_cursor;
END;
/