SET SERVEROUTPUT ON;

-- Jiglau Fabrizzio 233
-- EX1

CREATE TABLE info_233jf (
    utilizator VARCHAR2(100),
    data TIMESTAMP,
    comanda VARCHAR2(255),
    nr_linii NUMBER,
    eroare VARCHAR2(255)
);

--EX2

CREATE OR REPLACE FUNCTION f2_233jf  
    (v_nume employees.last_name%TYPE DEFAULT 'Bell')     
RETURN VARCHAR2 IS 
    v_salaries VARCHAR2(4000) := ''; 
BEGIN 
    -- iteram prin salariile angajatilor cu numele specificat
    FOR rec IN (SELECT salary FROM employees WHERE last_name = v_nume) LOOP
        v_salaries := v_salaries || rec.salary || ', '; 
    END LOOP;

    IF v_salaries IS NOT NULL THEN
        v_salaries := RTRIM(v_salaries, ', ');
    END IF;

    INSERT INTO info_233jf (utilizator, data, comanda, nr_linii, eroare)
    VALUES (USER, SYSTIMESTAMP, 'SELECT salary FROM employees WHERE last_name = ' || v_nume, 1, NULL);

    -- verificam daca s-au gasit salarii
    IF v_salaries IS NULL OR v_salaries = '' THEN
        RETURN 'Nu exista angajati cu numele dat'; 
    END IF;

    RETURN v_salaries; 
EXCEPTION 
    WHEN OTHERS THEN 
       INSERT INTO info_233jf (utilizator, data, comanda, nr_linii, eroare)
       VALUES (USER, SYSTIMESTAMP, 'SELECT salary FROM employees WHERE last_name = ' || v_nume, 0, 'Alta eroare!');
       RETURN 'Alta eroare!'; 
END f2_233jf; 
/

CREATE OR REPLACE PROCEDURE p4_233jf 
    (v_nume employees.last_name%TYPE) 
IS  
    salariu employees.salary%TYPE; 
BEGIN 
    -- Selectam salariul angajatului cu numele specificat
    SELECT salary INTO salariu  
    FROM   employees 
    WHERE  last_name = v_nume; 
    INSERT INTO info_233jf (utilizator, data, comanda, nr_linii, eroare)
    VALUES (USER, SYSTIMESTAMP, 'SELECT salary FROM employees WHERE last_name = ' || v_nume, 1, NULL);
    DBMS_OUTPUT.PUT_LINE('Salariul este ' || salariu); 
EXCEPTION 
    WHEN NO_DATA_FOUND THEN 
        INSERT INTO info_233jf (utilizator, data, comanda, nr_linii, eroare)
        VALUES (USER, SYSTIMESTAMP, 'SELECT salary FROM employees WHERE last_name = ' || v_nume, 0, 'Nu exista angajati cu numele dat');
        DBMS_OUTPUT.PUT_LINE('Nu exista angajati cu numele dat'); 
       
    WHEN OTHERS THEN 
       INSERT INTO info_233jf (utilizator, data, comanda, nr_linii, eroare)
       VALUES (USER, SYSTIMESTAMP, 'SELECT salary FROM employees WHERE last_name = ' || v_nume, 0, 'Alta eroare!');
       DBMS_OUTPUT.PUT_LINE('Alta eroare!'); 
END p4_233jf; 
/

SELECT * FROM EMPLOYEES;

DECLARE
    v_salary VARCHAR2(4000); 
BEGIN
    -- Apelam functiile
    v_salary := f2_233jf('Lorentz'); 
    DBMS_OUTPUT.PUT_LINE('Salariul este: ' || v_salary);

    v_salary := f2_233jf('Hunold'); 
    DBMS_OUTPUT.PUT_LINE('Salariul este: ' || v_salary);

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Eroare: ' || SQLERRM);
END;
/

DECLARE
    v_nume employees.last_name%TYPE;
BEGIN
    v_nume := 'Lorentz';
    p4_233jf(v_nume);

    v_nume := 'Hunold';
    p4_233jf(v_nume);
    
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Eroare: ' || SQLERRM);
END;
/