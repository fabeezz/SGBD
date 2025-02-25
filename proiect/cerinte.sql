SET SERVEROUTPUT ON;
-- ////////// EX6 //////////////
-- sa se afiseze utilizatorii cu nr de notificari peste media numarului de notificari
CREATE OR REPLACE PROCEDURE notif_peste_medie IS
    -- stocam numarul de notificari pentru fiecare utilizator
    TYPE tablou_indexat IS
        TABLE OF NUMBER INDEX BY PLS_INTEGER;
    numar_notificari        tablou_indexat;

    -- stocam notificarile
    TYPE tablou_imbricat IS
        TABLE OF VARCHAR2(256);
    notificari              tablou_imbricat := tablou_imbricat();

    -- stocam utilizatorii cu nr de notificari peste medie
    TYPE vector_utilizatori IS
        VARRAY(100) OF VARCHAR2(50);
    utilizatori_peste_medie vector_utilizatori := vector_utilizatori();
    v_numar_utilizatori     PLS_INTEGER := 0;
    v_total_notificari      NUMBER := 0;
    v_media                 NUMBER;
BEGIN
    -- numarul de notificari pentru fiecare utilizator
    FOR rec IN (
        SELECT
            id_utilizator,
            COUNT(*) AS numar_notificari
        FROM
            notificare
        GROUP BY
            id_utilizator
    ) LOOP
        v_numar_utilizatori := v_numar_utilizatori + 1;
        numar_notificari(v_numar_utilizatori) := rec.numar_notificari;
        v_total_notificari := v_total_notificari + rec.numar_notificari;
    END LOOP;

    -- media notificarilor
    IF v_numar_utilizatori > 0 THEN
        v_media := v_total_notificari / v_numar_utilizatori;
    ELSE
        v_media := 0; -- Evitam diviziunea cu zero
    END IF;

    -- adaugam toate notificarile in tabloul imbricat
    FOR rec IN (
        SELECT
            text_notificare
        FROM
            notificare
    ) LOOP
        notificari.extend;
        notificari(notificari.last) := rec.text_notificare;
    END LOOP;

    dbms_output.put_line('Nr de notificari in medie: ' || v_media);

    -- stocam utilizatorii cu nr de notificari peste medie
    dbms_output.put_line('Utilizatorii cu numar peste medie de notificari:');
    FOR rec IN (
        SELECT
            u.nume_utilizator,
            COUNT(n.id_notificare) AS numar_notificari
        FROM
                 utilizator u
            JOIN notificare n ON u.id_utilizator = n.id_utilizator
        GROUP BY
            u.nume_utilizator
        HAVING
            COUNT(n.id_notificare) > v_media
    ) LOOP
        utilizatori_peste_medie.extend;
        utilizatori_peste_medie(utilizatori_peste_medie.last) := rec.nume_utilizator;
        dbms_output.put_line(rec.nume_utilizator
                             || ' - '
                             || rec.numar_notificari);
    END LOOP;

EXCEPTION
    WHEN OTHERS THEN
        dbms_output.put_line('A aparut o eroare: ' || sqlerrm);
END notif_peste_medie;
/

BEGIN
    notif_peste_medie;
END;
/

-- ////////// EX7 //////////////

-- Afiseaza utilizatorii si numarul de recenzii scrise de fiecare, 
--specificand daca recenzia este pozitiva sau negativa, 
--in functie de continutul textului recenziei.

CREATE OR REPLACE PROCEDURE gestionare_recenzii IS
    -- pentru numele utilizatorului si numarul de recenzii
    CURSOR c_utilizatori IS
    SELECT
        u.id_utilizator,
        u.nume_utilizator,
        COUNT(r.id_recenzie) AS numar_recenzii
    FROM
        utilizator u
        LEFT JOIN recenzie   r ON u.id_utilizator = r.id_utilizator
    GROUP BY
        u.id_utilizator,
        u.nume_utilizator;

    -- pentru detaliile despre recenzii
    CURSOR c_recenzii (
        p_id_utilizator NUMBER
    ) IS
    SELECT
        j.nume_joc,
        r.text_recenzie
    FROM
             recenzie r
        JOIN joc j ON r.id_joc = j.id_joc
    WHERE
        r.id_utilizator = p_id_utilizator;

    v_id_utilizator   utilizator.id_utilizator%TYPE;
    v_nume_utilizator utilizator.nume_utilizator%TYPE;
    v_numar_recenzii  NUMBER;
    v_nume_joc        joc.nume_joc%TYPE;
    v_text_recenzie   recenzie.text_recenzie%TYPE;
BEGIN
    OPEN c_utilizatori;
    LOOP
        FETCH c_utilizatori INTO
            v_id_utilizator,
            v_nume_utilizator,
            v_numar_recenzii;
        EXIT WHEN c_utilizatori%notfound;
        IF v_numar_recenzii = 1 THEN
            dbms_output.put_line('Utilizatorul '
                                 || v_nume_utilizator
                                 || ' a scris o recenzie.');
        ELSE
            dbms_output.put_line('Utilizatorul '
                                 || v_nume_utilizator
                                 || ' a scris '
                                 || v_numar_recenzii
                                 || ' recenzii.');
        END IF;

        OPEN c_recenzii(v_id_utilizator);
        LOOP
            FETCH c_recenzii INTO
                v_nume_joc,
                v_text_recenzie;
            EXIT WHEN c_recenzii%notfound;

            -- verificam textul recenziei
            IF instr(v_text_recenzie, 'POZITIV') > 0 THEN
                dbms_output.put_line('Joc: '
                                     || v_nume_joc
                                     || ', Recenzie: Pozitiva');
            ELSIF instr(v_text_recenzie, 'NEGATIV') > 0 THEN
                dbms_output.put_line('Joc: '
                                     || v_nume_joc
                                     || ', Recenzie: Negativa');
            ELSE
                dbms_output.put_line('Joc: '
                                     || v_nume_joc
                                     || ', Recenzie: '
                                     || v_text_recenzie);
            END IF;

        END LOOP;

        CLOSE c_recenzii;
    END LOOP;

    CLOSE c_utilizatori;
END;
/

BEGIN
    gestionare_recenzii;
END;
/

-- ////////// EX8 //////////////

--cream un utilizator fara tranzactii
INSERT INTO utilizator (
    id_utilizator,
    nume_utilizator,
    parola,
    email,
    varsta,
    id_tara
) VALUES (
    9,
    'MonsterSlayer',
    'deathh123',
    'ramon.anto@gmail.com',
    21,
    2
);

-- Sa se afiseze pentru un utilizator dat daca suma tranzactiilor sale 
-- este mai mare decat media tranzactiilor efectuate de toti utilizatorii.
-- utilizatorul trebuie sa aiba domiciliu intr-o tara cu salariul mediu peste
-- 20000, iar acesta sa nu aiba mai mult de 3 tranzactii.
CREATE OR REPLACE FUNCTION verifica_tranzactii_utilizator (
    p_id_utilizator NUMBER
) RETURN VARCHAR2 IS
    v_suma_tranzactii   NUMBER;
    v_media_tranzactii  NUMBER;
    v_salariu_mediu     NUMBER;
    v_numar_tranzactii  NUMBER;
    v_exista_utilizator NUMBER;
BEGIN
    SELECT
        COUNT(*)
    INTO v_exista_utilizator
    FROM
        utilizator
    WHERE
        id_utilizator = p_id_utilizator;

    IF v_exista_utilizator = 0 THEN
        raise_application_error(-20001, 'Utilizatorul nu exista.');
    END IF;

    -- verificam numarul de tranzactii ale utilizatorului
    SELECT
        COUNT(*)
    INTO v_numar_tranzactii
    FROM
        tranzactie
    WHERE
        id_utilizator = p_id_utilizator;

    IF v_numar_tranzactii = 0 THEN
        RAISE no_data_found; -- utilizatorul nu are tranzactii
    ELSIF v_numar_tranzactii > 3 THEN
        RAISE too_many_rows; -- are mai mult de 3 tranzactii
    END IF;

    -- suma tranzactiilor utilizatorului
    SELECT
        SUM(suma_tranzactie)
    INTO v_suma_tranzactii
    FROM
        tranzactie
    WHERE
        id_utilizator = p_id_utilizator;

    -- media tranzactiilor tuturor utilizatorilor
    SELECT
        AVG(suma_tranzactie)
    INTO v_media_tranzactii
    FROM
        tranzactie;

    -- salariul mediu din tara utilizatorului
    SELECT
        t.salariu_mediu
    INTO v_salariu_mediu
    FROM
             utilizator u
        JOIN tara t ON u.id_tara = t.id_tara
        -- JOIN locatie l ON t.id_tara = l.id_tara
    WHERE
        u.id_utilizator = p_id_utilizator;
        -- AND LENGTH(l.oras) > 4

    IF v_salariu_mediu <= 20000 THEN
        raise_application_error(-20002, 'Salariul mediu din tara utilizatorului este sub 20000.');
    END IF;
    IF v_suma_tranzactii > v_media_tranzactii THEN
        RETURN 'Suma tranzactiilor utilizatorului este peste media tuturor tranzactiilor ('
               || v_suma_tranzactii
               || ' > '
               || round(v_media_tranzactii, 2)
               || ').';
    ELSE
        RETURN 'Suma tranzactiilor utilizatorului este sub media tuturor tranzactiilor ('
               || v_suma_tranzactii
               || ' < '
               || round(v_media_tranzactii, 2)
               || ').';
    END IF;

EXCEPTION
    WHEN no_data_found THEN
        RETURN 'Utilizatorul nu are tranzactii.';
    WHEN too_many_rows THEN
        RETURN 'Utilizatorul are mai mult de 3 tranzactii.';
    WHEN OTHERS THEN
        RETURN 'A aparut o eroare: ' || sqlerrm;
END;
/

BEGIN
    dbms_output.put_line(verifica_tranzactii_utilizator(19)); -- utilizatorul nu exista
END;
/

BEGIN
    dbms_output.put_line(verifica_tranzactii_utilizator(2)); -- utilizatorul are mai mult de 3 tranzactii
END;
/

BEGIN
    dbms_output.put_line(verifica_tranzactii_utilizator(9)); -- utilizatorul nu are tranzactii
END;
/

BEGIN
    dbms_output.put_line(verifica_tranzactii_utilizator(8)); -- tara cu salarii mici
END;
/

BEGIN
    dbms_output.put_line(verifica_tranzactii_utilizator(3)); -- peste medie
END;
/

BEGIN
    dbms_output.put_line(verifica_tranzactii_utilizator(5)); -- sub medie
END;
/

-- ////////// EX9 //////////////

-- pentru utilizatorul cu id 9 cream un inventar cu capacitate mare
-- (pe acesta il vom folosi pentru testarea procedurii)
INSERT INTO inventar (
    id_inventar,
    id_utilizator,
    capacitate
) VALUES (
    9,
    9,
    99
);

-- cream un utilizator cu o varsta mai mica
-- decat varsta recomandata de majoritatea jocurilor
INSERT INTO utilizator (
    id_utilizator,
    nume_utilizator,
    parola,
    email,
    varsta,
    id_tara
) VALUES (
    10,
    'CookieMunchy',
    'milkandcOOkie',
    'donald.duck@yahoo.com',
    8,
    3
);
-- cream inventarul utilizatorului nou adaugat
INSERT INTO inventar (
    id_inventar,
    id_utilizator,
    capacitate
) VALUES (
    10,
    10,
    20
);

-- scrie o procedura care permite adaugarea unui item 
-- in inventarul unui utilizator (id-uri date ca parametrii)
-- 1. verifica daca utilizatorul si itemul exista
-- 2. verifica capacitatea inventarului utilizatorului si daca
-- este posibila adaugarea unui item
-- 3. verifica varsta utilizatorului si compara cu varsta jocului
-- din care face parte itemul

CREATE OR REPLACE PROCEDURE adauga_item_in_inventar (
    p_id_utilizator NUMBER,
    p_id_item       NUMBER
) IS

    v_capacitate         NUMBER;
    v_numar_iteme        NUMBER;
    v_exista_item        NUMBER;
    v_varsta_utilizator  NUMBER;
    v_varsta_recomandata NUMBER;
    e_capacitate_depasita EXCEPTION;
    e_item_inexistent EXCEPTION;
    e_varsta_recomandata EXCEPTION;
    e_utilizator_inexistent EXCEPTION;
BEGIN
    -- utilizatorul exista
    SELECT
        COUNT(*)
    INTO v_exista_item
    FROM
        utilizator
    WHERE
        id_utilizator = p_id_utilizator;

    IF v_exista_item = 0 THEN
        RAISE e_utilizator_inexistent;
    END IF;

    -- itemul exista
    SELECT
        COUNT(*)
    INTO v_exista_item
    FROM
        item
    WHERE
        id_item = p_id_item;

    IF v_exista_item = 0 THEN
        RAISE e_item_inexistent;
    END IF;

    -- capacitatea inventarului utilizatorului
    SELECT
        capacitate
    INTO v_capacitate
    FROM
        inventar
    WHERE
        id_utilizator = p_id_utilizator;

    -- verificam numarul de iteme din inventar
    SELECT
        COUNT(*)
    INTO v_numar_iteme
    FROM
        inventar_item
    WHERE
        id_inventar = (
            SELECT
                id_inventar
            FROM
                inventar
            WHERE
                id_utilizator = p_id_utilizator
        );

    IF v_numar_iteme >= v_capacitate THEN
        RAISE e_capacitate_depasita;
    END IF;

    -- varsta recomandata a jocului asociat itemului
    SELECT
        j.varsta_recomandata
    INTO v_varsta_recomandata
    FROM
             item i
        JOIN joc j ON i.id_joc = j.id_joc
    WHERE
        i.id_item = p_id_item;

    SELECT
        varsta
    INTO v_varsta_utilizator
    FROM
        utilizator
    WHERE
        id_utilizator = p_id_utilizator;

    IF v_varsta_recomandata > v_varsta_utilizator THEN
        RAISE e_varsta_recomandata;
    END IF;

    -- adaugam itemul in inventar
    INSERT INTO inventar_item (
        id_item,
        id_inventar
    ) VALUES (
        p_id_item,
        (
            SELECT
                id_inventar
            FROM
                inventar
            WHERE
                id_utilizator = p_id_utilizator
        )
    );

    dbms_output.put_line('Itemul a fost adaugat cu succes in inventar.');
EXCEPTION
    WHEN e_capacitate_depasita THEN
        dbms_output.put_line('Capacitatea inventarului a fost depasita.');
    WHEN e_item_inexistent THEN
        dbms_output.put_line('Itemul nu exista.');
    WHEN e_varsta_recomandata THEN
        dbms_output.put_line('Itemul nu poate fi adaugat (varsta utilizatorului prea mica).');
    WHEN e_utilizator_inexistent THEN
        dbms_output.put_line('Utilizatorul nu exista.');
    WHEN OTHERS THEN
        dbms_output.put_line('A aparut o eroare: ' || sqlerrm);
END;
/

BEGIN
    adauga_item_in_inventar(9, 7); -- utilizator existent, item existent, capacitate suficienta
END;
/

BEGIN
    adauga_item_in_inventar(99, 2); -- utilizatorul nu exista
END;
/

BEGIN
    adauga_item_in_inventar(9, 51); -- item-ul nu exista
END;
/

BEGIN
    adauga_item_in_inventar(2, 3); -- capacitate depasita
END;
/

BEGIN
    adauga_item_in_inventar(10, 1); -- varsta prea mica (utilizator de 8 ani, joc de 16 ani)
END;
/

-- //////// EX10 ///////
-- cream o tabela audit care va stoca toate operatiile LMD
CREATE TABLE log_inventare (
    id_log     NUMBER
        GENERATED BY DEFAULT AS IDENTITY
    PRIMARY KEY,
    actiune    VARCHAR2(10),
    data_modif TIMESTAMP DEFAULT current_timestamp
);

-- scrieti un trigger care se declanseaza la fiecare adaugare de item in inventar.
CREATE OR REPLACE TRIGGER trg_lmd_comanda AFTER
    INSERT OR UPDATE OR DELETE ON inventar_item
DECLARE
    actiune VARCHAR2(20);
BEGIN
    IF inserting THEN
        actiune := 'insert';
        dbms_output.put_line('Un item a fost adaugat in inventar.');
    ELSIF updating THEN
        actiune := 'update';
        dbms_output.put_line('Un item din inventar a fost modificat.');
    ELSIF deleting THEN
        actiune := 'delete';
        dbms_output.put_line('Un item a fost sters din inventar.');
    END IF;

    -- ne folosim de log pentru a inregistra actiunea
    INSERT INTO log_inventare (
        actiune,
        data_modif
    ) VALUES (
        actiune,
        systimestamp
    );

END;
/

--inserare
INSERT INTO inventar_item (
    id_item,
    id_inventar
) VALUES (
    17,
    9
);

--update
UPDATE inventar_item
SET
    id_item = 18
WHERE
        id_item = 17
    AND id_inventar = 9;

--delete
DELETE FROM inventar_item
WHERE
        id_item = 18
    AND id_inventar = 9;

SELECT
    *
FROM
    log_inventare;

ALTER TRIGGER trg_lmd_comanda DISABLE;

-- //////// EX11 ////////

-- scrieti un trigger care se declanseaza la inserarea in 
-- tabelul Developer si care verifica conditiile:
-- 1. studioul sa nu existe deja
-- 2. studioul sa nu fi fost lansat in ultimii 4 ani
-- 3. locatia studioului sa fie valida


CREATE OR REPLACE TRIGGER trg_verifica_developer BEFORE
    INSERT OR UPDATE ON developer
    FOR EACH ROW
DECLARE
    v_count_dev     NUMBER;
    v_count_locatie NUMBER;
BEGIN
    -- verif daca studioul deja exista
    SELECT
        COUNT(*)
    INTO v_count_dev
    FROM
        developer
    WHERE
        nume_developer = :new.nume_developer;

    IF v_count_dev > 0 THEN
        raise_application_error(-20001, 'Studio-ul exista deja in tabela.');
    END IF;

    -- cel putin 4 ani
    IF months_between(sysdate, :new.data_lansare_studio) < 48 THEN
        raise_application_error(-20002, 'Studio-ul trebuie sa fie lansat de cel putin 4 ani.');
    END IF;

    -- locatie valida
    SELECT
        COUNT(*)
    INTO v_count_locatie
    FROM
        locatie
    WHERE
        id_locatie = :new.id_locatie;

    IF v_count_locatie = 0 THEN
        raise_application_error(-20003, 'Locatia asociata nu exista in tabela locatie.');
    END IF;
END;
/

-- studio lansat in ultimii 4 ani
INSERT INTO developer (
    id_developer,
    id_locatie,
    nume_developer,
    data_lansare_studio,
    salariu_angajati
) VALUES (
    13,
    1,
    'New Studio',
    TO_DATE('2023-01-01', 'YYYY-MM-DD'),
    50000
);

-- studio deja existent
INSERT INTO developer (
    id_developer,
    id_locatie,
    nume_developer,
    data_lansare_studio,
    salariu_angajati
) VALUES (
    14,
    5,
    'Kojima Productions',
    TO_DATE('2005-12-01', 'YYYY-MM-DD'),
    45000
);

-- locatia nu exista
INSERT INTO developer (
    id_developer,
    id_locatie,
    nume_developer,
    data_lansare_studio,
    salariu_angajati
) VALUES (
    15,
    99,
    'Epic Games',
    TO_DATE('2021-01-01', 'YYYY-MM-DD'),
    80000
);

-- insert valid
INSERT INTO developer (
    id_developer,
    id_locatie,
    nume_developer,
    data_lansare_studio,
    salariu_angajati
) VALUES (
    20,
    6,
    'Riot',
    TO_DATE('2002-01-01', 'YYYY-MM-DD'),
    70000
);

-- //////// EX12 ////////

--cream un tabel de care se va folosi trigger-ul pentru log-uri
CREATE TABLE log_ldd (
    id_log      NUMBER
        GENERATED BY DEFAULT AS IDENTITY
    PRIMARY KEY,
    username    VARCHAR2(50),
    actiune     VARCHAR2(50),
    tabel_modif VARCHAR2(50),
    data_modif  DATE
);

CREATE OR REPLACE TRIGGER trg_ldd AFTER CREATE OR ALTER OR DROP ON DATABASE DECLARE
    v_user  VARCHAR2(50);
    v_tabel VARCHAR2(100);
    v_ldd   VARCHAR2(50);
BEGIN
    v_user := sys_context('USERENV', 'SESSION_USER');
    v_tabel := ora_dict_obj_name;
    v_ldd := ora_sysevent;
    INSERT INTO log_ldd (
        username,
        actiune,
        tabel_modif,
        data_modif
    ) VALUES (
        v_user,
        v_ldd,
        v_tabel,
        systimestamp
    );

    dbms_output.put_line('S-a detectat o operatie LDD: '
                         || v_ldd
                         || ' pe tabelul '
                         || v_tabel
                         || ' de user-ul '
                         || v_user);

END;
/

SELECT
    *
FROM
    log_ldd;

CREATE TABLE test (
    nume VARCHAR2(50)
);

DROP TABLE test;

-- ///////// EX 13 ///////////

CREATE OR REPLACE PROCEDURE afiseaza_iteme_in_inventar (
    p_id_utilizator NUMBER
) IS
BEGIN
    DECLARE
        v_exista_utilizator NUMBER;
    BEGIN
        SELECT
            COUNT(*)
        INTO v_exista_utilizator
        FROM
            utilizator
        WHERE
            id_utilizator = p_id_utilizator;

        IF v_exista_utilizator = 0 THEN
            raise_application_error(-20001, 'Utilizatorul nu exista.');
        END IF;
    END;

    FOR rec IN (
        SELECT
            i.id_item,
            i.nume_item
        FROM
                 inventar_item ii
            JOIN inventar inv ON ii.id_inventar = inv.id_inventar
            JOIN item     i ON ii.id_item = i.id_item
        WHERE
            inv.id_utilizator = p_id_utilizator
    ) LOOP
        dbms_output.put_line('Item ID: '
                             || rec.id_item
                             || ', Nume Item: '
                             || rec.nume_item);
    END LOOP;

    IF SQL%rowcount = 0 THEN
        dbms_output.put_line('Utilizatorul nu are iteme in inventar.');
    END IF;
END;
/

CREATE OR REPLACE PROCEDURE afiseaza_jocuri (
    p_id_developer NUMBER
) IS

    TYPE joc_record IS RECORD (
            id_joc             NUMBER(5),
            id_developer       NUMBER(5),
            nume_joc           VARCHAR2(50),
            pret_joc           NUMBER(5),
            data_lansare_joc   DATE,
            varsta_recomandata NUMBER(3),
            rating             NUMBER(1)
    );
    TYPE joc_table IS
        TABLE OF joc_record INDEX BY PLS_INTEGER;
    v_joc   joc_table;
    v_index PLS_INTEGER := 0;
BEGIN
    -- inserturi pe tabela de jocuri pentru un anumit dezvoltator
    FOR rec IN (
        SELECT
            id_joc,
            id_developer,
            nume_joc,
            pret_joc,
            data_lansare_joc,
            varsta_recomandata,
            rating
        FROM
            joc
        WHERE
            id_developer = p_id_developer
    ) LOOP
        v_index := v_index + 1;
        v_joc(v_index).id_joc := rec.id_joc;
        v_joc(v_index).id_developer := rec.id_developer;
        v_joc(v_index).nume_joc := rec.nume_joc;
        v_joc(v_index).pret_joc := rec.pret_joc;
        v_joc(v_index).data_lansare_joc := rec.data_lansare_joc;
        v_joc(v_index).varsta_recomandata := rec.varsta_recomandata;
        v_joc(v_index).rating := rec.rating;
    END LOOP;

    IF v_index > 0 THEN
        FOR i IN 1..v_index LOOP
            dbms_output.put_line('ID Joc: '
                                 || v_joc(i).id_joc
                                 || ', Nume Joc: '
                                 || v_joc(i).nume_joc
                                 || ', Pret: '
                                 || v_joc(i).pret_joc
                                 || ', Data Lansare: '
                                 || to_char(v_joc(i).data_lansare_joc, 'YYYY-MM-DD')
                                 || ', Varsta Recomandata: '
                                 || v_joc(i).varsta_recomandata
                                 || ', Rating: '
                                 || v_joc(i).rating);
        END LOOP;

    ELSE
        dbms_output.put_line('Nu exista jocuri inregistrate pentru dezvoltatorul cu ID: ' || p_id_developer);
    END IF;

END;
/

BEGIN
    afiseaza_jocuri(6);
END;
/

CREATE OR REPLACE FUNCTION calculeaza_numar_iteme (
    p_id_utilizator NUMBER,
    p_valoare       NUMBER
) RETURN NUMBER IS
    v_numar_iteme NUMBER;
BEGIN
    SELECT
        COUNT(*)
    INTO v_numar_iteme
    FROM
             inventar_item ii
        JOIN inventar inv ON ii.id_inventar = inv.id_inventar
        JOIN item     i ON ii.id_item = i.id_item
    WHERE
            inv.id_utilizator = p_id_utilizator
        AND i.pret_item > p_valoare;

    RETURN v_numar_iteme;
END;
/



-- ////////// EX13 /////////////

-- Creati un package care afiseaza itemele unui user,
-- jocurile unui dezvoltator dat, 
-- numarul de iteme ale utilizatorului care au valoare mai mare decat un pret dat
-- si jocurile dezvoltate in tara utilizatorului.

CREATE OR REPLACE PACKAGE steam_pack AS
    -- RECORD pentru jocuri
    TYPE joc_record IS RECORD (
            id_joc             NUMBER(5),
            id_developer       NUMBER(5),
            nume_joc           VARCHAR2(50),
            pret_joc           NUMBER(5),
            data_lansare_joc   DATE,
            varsta_recomandata NUMBER(3),
            rating             NUMBER(1)
    );

    -- RECORD pentru jocuri din tara utilizatorului
    TYPE jocuri_natale IS RECORD (
            id_joc         NUMBER(5),
            nume_joc       VARCHAR2(50),
            nume_developer VARCHAR2(50),
            tara           VARCHAR2(50)
    );
    TYPE jocuri_natale_table IS
        TABLE OF jocuri_natale INDEX BY PLS_INTEGER;
    TYPE joc_table IS
        TABLE OF joc_record INDEX BY PLS_INTEGER;
    PROCEDURE afiseaza_iteme_in_inventar (
        p_id_utilizator NUMBER
    );

    PROCEDURE afiseaza_jocuri (
        p_id_developer NUMBER
    );

    FUNCTION calculeaza_numar_iteme (
        p_id_utilizator NUMBER,
        p_valoare       NUMBER
    ) RETURN NUMBER;

    FUNCTION afisare_jocuri_natale (
        p_id_utilizator NUMBER
    ) RETURN jocuri_natale_table;

END steam_pack;
/

CREATE OR REPLACE PACKAGE BODY steam_pack AS

    PROCEDURE afiseaza_iteme_in_inventar (
        p_id_utilizator NUMBER
    ) IS
        v_exista_utilizator NUMBER;
    BEGIN
        SELECT
            COUNT(*)
        INTO v_exista_utilizator
        FROM
            utilizator
        WHERE
            id_utilizator = p_id_utilizator;

        IF v_exista_utilizator = 0 THEN
            raise_application_error(-20001, 'Utilizatorul nu exista.');
        END IF;
        FOR rec IN (
            SELECT
                i.id_item,
                i.nume_item,
                i.pret_item
            FROM
                     inventar_item ii
                JOIN inventar inv ON ii.id_inventar = inv.id_inventar
                JOIN item     i ON ii.id_item = i.id_item
            WHERE
                inv.id_utilizator = p_id_utilizator
        ) LOOP
            IF rec.pret_item IS NOT NULL THEN
                dbms_output.put_line('Item ID: '
                                     || rec.id_item
                                     || ', Nume Item: '
                                     || rec.nume_item
                                     || ', Pret: '
                                     || rec.pret_item);

            ELSE
                dbms_output.put_line('Item ID: '
                                     || rec.id_item
                                     || ', Nume Item: '
                                     || rec.nume_item);
            END IF;
        END LOOP;

        IF SQL%rowcount = 0 THEN
            dbms_output.put_line('Utilizatorul nu are iteme in inventar.');
        END IF;
    END afiseaza_iteme_in_inventar;

    PROCEDURE afiseaza_jocuri (
        p_id_developer NUMBER
    ) IS
        v_joc   joc_table;
        v_index PLS_INTEGER := 0;
    BEGIN
        FOR rec IN (
            SELECT
                id_joc,
                id_developer,
                nume_joc,
                pret_joc,
                data_lansare_joc,
                varsta_recomandata,
                rating
            FROM
                joc
            WHERE
                id_developer = p_id_developer
        ) LOOP
            v_index := v_index + 1;
            v_joc(v_index).id_joc := rec.id_joc;
            v_joc(v_index).id_developer := rec.id_developer;
            v_joc(v_index).nume_joc := rec.nume_joc;
            v_joc(v_index).pret_joc := rec.pret_joc;
            v_joc(v_index).data_lansare_joc := rec.data_lansare_joc;
            v_joc(v_index).varsta_recomandata := rec.varsta_recomandata;
            v_joc(v_index).rating := rec.rating;
        END LOOP;

        IF v_index > 0 THEN
            FOR i IN 1..v_index LOOP
                dbms_output.put_line('ID Joc: '
                                     || v_joc(i).id_joc
                                     || ', Nume Joc: '
                                     || v_joc(i).nume_joc
                                     || ', Pret: '
                                     || v_joc(i).pret_joc
                                     || ', Data Lansare: '
                                     || to_char(v_joc(i).data_lansare_joc, 'YYYY-MM-DD')
                                     || ', Varsta Recomandata: '
                                     || v_joc(i).varsta_recomandata
                                     || ', Rating: '
                                     || v_joc(i).rating);
            END LOOP;

        ELSE
            dbms_output.put_line('Nu exista jocuri inregistrate pentru dezvoltatorul cu ID: ' || p_id_developer);
        END IF;

    END afiseaza_jocuri;

    FUNCTION calculeaza_numar_iteme (
        p_id_utilizator NUMBER,
        p_valoare       NUMBER
    ) RETURN NUMBER IS
        v_numar_iteme NUMBER;
    BEGIN
        SELECT
            COUNT(*)
        INTO v_numar_iteme
        FROM
                 inventar_item ii
            JOIN inventar inv ON ii.id_inventar = inv.id_inventar
            JOIN item     i ON ii.id_item = i.id_item
        WHERE
                inv.id_utilizator = p_id_utilizator
            AND i.pret_item > p_valoare;

        RETURN v_numar_iteme;
    END calculeaza_numar_iteme;

    FUNCTION afisare_jocuri_natale (
        p_id_utilizator NUMBER
    ) RETURN jocuri_natale_table IS
        v_jocuri    jocuri_natale_table;
        v_index     PLS_INTEGER := 0;
        v_id_tara   NUMBER;
        v_nume_tara VARCHAR2(50);
    BEGIN
        SELECT
            id_tara
        INTO v_id_tara
        FROM
            utilizator
        WHERE
            id_utilizator = p_id_utilizator;

        SELECT
            nume_tara
        INTO v_nume_tara
        FROM
            tara
        WHERE
            id_tara = v_id_tara;

        FOR rec IN (
            SELECT
                j.id_joc,
                j.nume_joc,
                d.nume_developer
            FROM
                     joc j
                JOIN developer d ON j.id_developer = d.id_developer
                JOIN locatie   loc ON d.id_locatie = loc.id_locatie
            WHERE
                loc.id_tara = v_id_tara
        ) LOOP
            v_index := v_index + 1;
            v_jocuri(v_index).id_joc := rec.id_joc;
            v_jocuri(v_index).nume_joc := rec.nume_joc;
            v_jocuri(v_index).nume_developer := rec.nume_developer;
            v_jocuri(v_index).tara := v_nume_tara;
        END LOOP;

        RETURN v_jocuri;
    END afisare_jocuri_natale;

END steam_pack;
/

DECLARE
    v_jocuri steam_pack.jocuri_natale_table;
BEGIN
    dbms_output.put_line('Toate itemele utilizatorului: ');
    steam_pack.afiseaza_iteme_in_inventar(1); -- id user
    dbms_output.put_line('Toate jocurile dezvoltatorului: ');
    steam_pack.afiseaza_jocuri(6); -- id dezvoltator
    dbms_output.put_line('Numarul de iteme cu pret mai mare de 50 din inventarul utilizatorului: '
                         || steam_pack.calculeaza_numar_iteme(1, 50)); -- id user

    v_jocuri := steam_pack.afisare_jocuri_natale(1); -- id user

    dbms_output.put_line('Toate jocurile dezvoltate in tara utilizatorului: ');
    FOR i IN 1..v_jocuri.count LOOP
        dbms_output.put_line('ID Joc: '
                             || v_jocuri(i).id_joc
                             || ', Nume Joc: '
                             || v_jocuri(i).nume_joc
                             || ', Nume Developer: '
                             || v_jocuri(i).nume_developer
                             || ', Tara: '
                             || v_jocuri(i).tara);
    END LOOP;

END;
/

SET SERVEROUTPUT ON;