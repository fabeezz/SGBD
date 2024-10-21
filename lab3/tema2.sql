--Jiglau Fabrizzio

-- MEMBER(member_id, last_name, first_name, address, city,  phone, join_date) 
-- TITLE(title_id, title, description, rating, category, release_date) 
-- TITLE_COPY(copy_id, title_id, status) 
-- RENTAL(book_date, copy_id, member_id, title_id, act_ret_date, exp_ret_date) 
-- RESERVATION(res_date, member_id, title_id)

SET SERVEROUTPUT ON;
SET VERIFY OFF;

SELECT * FROM MEMBER;

DECLARE
    nr_filme NUMBER(3);
    nume_membru member.last_name%TYPE := '&nume';
    cnt_membri NUMBER(3);
BEGIN
    SELECT COUNT(*) INTO cnt_membri
    FROM member
    WHERE last_name = nume_membru;
    IF cnt_membri = 0 THEN
        DBMS_OUTPUT.PUT_LINE('Nu exista niciun membru cu numele ' || nume_membru);
    ELSIF cnt_membri > 1 THEN
        DBMS_OUTPUT.PUT_LINE('Exista ' || cnt_membri || ' membri cu numele ' || nume_membru);
    ELSE
        SELECT COUNT(*) INTO nr_filme
        FROM rental r
        JOIN member m ON r.member_id = m.member_id
        WHERE m.last_name = nume_membru;
    DBMS_OUTPUT.PUT_LINE('Nr. de filme inchiriate de ' || nume_membru || ' este: ' || nr_filme);
    END IF;
END;
/


