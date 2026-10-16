--
-- PostgreSQL database dump
--

-- Dumped from database version 16.4
-- Dumped by pg_dump version 16.4

-- Started on 2026-10-16 17:27:40

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- TOC entry 221 (class 1255 OID 16595)
-- Name: getexampassstatistics(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.getexampassstatistics() RETURNS TABLE(student_id integer, student_name character varying, passed_count integer, failed_count integer, session_type character)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT
        Student.ID AS Student_ID,
        CONCAT(Student.name, ' ', Student.surname)::VARCHAR AS Student_Name,
        SUM(CASE WHEN Results.passed = true THEN 1 ELSE 0 END)::INTEGER AS Passed_Count,
        SUM(CASE WHEN Results.passed = false THEN 1 ELSE 0 END)::INTEGER AS Failed_Count,
        Results.session_type AS Session_Type
    FROM Results
    JOIN Student ON Results.ID = Student.ID
    GROUP BY Student.ID, Student.name, Student.surname, Results.session_type;
END;
$$;


ALTER FUNCTION public.getexampassstatistics() OWNER TO postgres;

--
-- TOC entry 236 (class 1255 OID 16596)
-- Name: getstudentaverageandpassstatus(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.getstudentaverageandpassstatus() RETURNS TABLE(student_id integer, student_name character varying, average_score numeric, all_exams_passed boolean)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        Student.ID AS Student_ID,
        CONCAT(Student.name, ' ', Student.surname)::VARCHAR AS Student_Name,
        AVG(Results.score) AS Average_Score,
        BOOL_AND(Results.passed) AS All_Exams_Passed
    FROM Results
    JOIN Student ON Results.ID = Student.ID
    GROUP BY Student.ID, Student.name, Student.surname;
END;
$$;


ALTER FUNCTION public.getstudentaverageandpassstatus() OWNER TO postgres;

--
-- TOC entry 235 (class 1255 OID 16594)
-- Name: getstudentbestandworstscores(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.getstudentbestandworstscores(student_id integer) RETURNS TABLE(subject character varying, best_score integer, worst_score integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT
        Exams.name AS Subject,
        MAX(Results.score) AS Best_Score,
        MIN(Results.score) AS Worst_Score
    FROM Results
    JOIN Exams ON Results.EX_ID = Exams.EX_ID
    WHERE Results.ID = student_id
    GROUP BY Exams.name;
END;
$$;


ALTER FUNCTION public.getstudentbestandworstscores(student_id integer) OWNER TO postgres;

--
-- TOC entry 234 (class 1255 OID 16610)
-- Name: log_result_changes(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.log_result_changes() RETURNS trigger
    LANGUAGE plpgsql
    AS $$ 
DECLARE
    action_type TEXT;
    action_details TEXT;
BEGIN
    -- Визначаємо тип дії для таблиці Results
    IF TG_OP = 'INSERT' THEN
        action_type := 'INSERT';
        action_details := CONCAT('Додано новий результат для студента з ID: ', NEW.ID, ', Предмет: ', NEW.EX_ID, ', Оцінка: ', NEW.score);
        
    ELSIF TG_OP = 'UPDATE' THEN
        action_type := 'UPDATE';
        action_details := CONCAT('Оновлено результат для студента з ID: ', OLD.ID, '. Попередня оцінка: ', OLD.score, ', Нова оцінка: ', NEW.score);
        
    ELSIF TG_OP = 'DELETE' THEN
        action_type := 'DELETE';
        action_details := CONCAT('Видалено результат для студента з ID: ', OLD.ID, ', Предмет: ', OLD.EX_ID);
    END IF;

    -- Вставляємо запис про зміну в таблицю transaction_logs
    INSERT INTO transaction_logs (transaction_type, transaction_status, details, transaction_time)
    VALUES (action_type, 'Успішно', action_details, CURRENT_TIMESTAMP);

    RETURN NULL;
END;
$$;


ALTER FUNCTION public.log_result_changes() OWNER TO postgres;

--
-- TOC entry 222 (class 1255 OID 16606)
-- Name: log_student_changes(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.log_student_changes() RETURNS trigger
    LANGUAGE plpgsql
    AS $$ 
DECLARE
    action_type TEXT;
    action_details TEXT;
BEGIN
    IF TG_OP = 'INSERT' THEN
        action_type := 'INSERT';
        action_details := CONCAT('Додано нового студента з ID: ', NEW.ID, ', Ім’я: ', NEW.name, ' ', NEW.surname);
        
    ELSIF TG_OP = 'UPDATE' THEN
        action_type := 'UPDATE';
        action_details := CONCAT('Оновлено студента з ID: ', OLD.ID, '. Попередня адреса: ', OLD.address, ', Нова адреса: ', NEW.address);
        
    ELSIF TG_OP = 'DELETE' THEN
        action_type := 'DELETE';
        action_details := CONCAT('Видалено студента з ID: ', OLD.ID, ', Ім’я: ', OLD.name, ' ', OLD.surname);
    END IF;

    INSERT INTO transaction_logs (transaction_type, transaction_status, details, transaction_time)
    VALUES (action_type, 'Успішно', action_details, CURRENT_TIMESTAMP);

    RETURN NULL;
END;
$$;


ALTER FUNCTION public.log_student_changes() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 215 (class 1259 OID 16557)
-- Name: exams; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.exams (
    ex_id integer NOT NULL,
    name character varying(100) NOT NULL,
    main_session_date date NOT NULL,
    additional_session_date date,
    preparation_program text
);


ALTER TABLE public.exams OWNER TO postgres;

--
-- TOC entry 218 (class 1259 OID 16579)
-- Name: results; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.results (
    score integer,
    id integer NOT NULL,
    ex_id integer NOT NULL,
    passed boolean,
    session_type character(1)
);


ALTER TABLE public.results OWNER TO postgres;

--
-- TOC entry 217 (class 1259 OID 16570)
-- Name: student; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.student (
    id integer NOT NULL,
    name character varying(50) NOT NULL,
    surname character varying(50) NOT NULL,
    middlename character varying(50),
    sex character(1) NOT NULL,
    birthday date NOT NULL,
    address character varying(255),
    school character varying(100)
);


ALTER TABLE public.student OWNER TO postgres;

--
-- TOC entry 216 (class 1259 OID 16569)
-- Name: student_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.student_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.student_id_seq OWNER TO postgres;

--
-- TOC entry 4824 (class 0 OID 0)
-- Dependencies: 216
-- Name: student_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.student_id_seq OWNED BY public.student.id;


--
-- TOC entry 220 (class 1259 OID 16598)
-- Name: transaction_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.transaction_logs (
    log_id integer NOT NULL,
    transaction_type character varying(255),
    transaction_status character varying(50),
    details text,
    transaction_time timestamp without time zone
);


ALTER TABLE public.transaction_logs OWNER TO postgres;

--
-- TOC entry 219 (class 1259 OID 16597)
-- Name: transaction_logs_log_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.transaction_logs_log_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.transaction_logs_log_id_seq OWNER TO postgres;

--
-- TOC entry 4825 (class 0 OID 0)
-- Dependencies: 219
-- Name: transaction_logs_log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.transaction_logs_log_id_seq OWNED BY public.transaction_logs.log_id;


--
-- TOC entry 4652 (class 2604 OID 16573)
-- Name: student id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student ALTER COLUMN id SET DEFAULT nextval('public.student_id_seq'::regclass);


--
-- TOC entry 4653 (class 2604 OID 16601)
-- Name: transaction_logs log_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transaction_logs ALTER COLUMN log_id SET DEFAULT nextval('public.transaction_logs_log_id_seq'::regclass);


--
-- TOC entry 4813 (class 0 OID 16557)
-- Dependencies: 215
-- Data for Name: exams; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.exams (ex_id, name, main_session_date, additional_session_date, preparation_program) FROM stdin;
1	Mathematics	2024-05-20	2024-06-15	Mathematics Preparation Program
2	History	2024-05-25	2024-06-20	History Preparation Program
3	Physics	2024-05-30	2024-06-25	Physics Preparation Program
4	Biology	2024-06-05	2024-07-01	Biology Preparation Program
5	English	2024-06-10	2024-07-05	English Preparation Program
6	Chemistry	2024-06-15	2024-07-10	Chemistry Preparation Program
\.


--
-- TOC entry 4816 (class 0 OID 16579)
-- Dependencies: 218
-- Data for Name: results; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.results (score, id, ex_id, passed, session_type) FROM stdin;
\N	3	4	f	A
83	4	1	t	A
97	8	1	t	M
91	10	1	t	A
\N	6	4	f	M
\N	6	6	f	M
92	12	1	t	A
100	7	1	t	A
93	7	2	t	A
81	7	3	t	A
98	12	3	f	A
\N	3	1	f	A
80	3	2	t	A
87	4	2	t	A
93	4	5	t	A
\N	5	1	f	A
90	5	4	t	A
84	5	6	t	A
85	6	3	t	M
90	8	2	t	M
84	8	3	t	M
93	8	5	t	A
86	9	2	t	A
83	9	3	t	A
88	9	4	t	M
94	9	6	t	M
80	10	2	t	A
84	10	3	t	M
89	10	5	t	M
96	11	2	t	M
83	11	3	t	A
87	11	4	t	M
90	11	6	t	A
83	12	2	t	A
\.


--
-- TOC entry 4815 (class 0 OID 16570)
-- Dependencies: 217
-- Data for Name: student; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.student (id, name, surname, middlename, sex, birthday, address, school) FROM stdin;
4	Kateryna	Kovalenko	Ivanivna	F	2004-09-18	Kharkiv, Pushkinska St. 22	School No.1
5	Dmytro	Bondarenko	Viktorovych	M	2004-02-01	Dnipro, Polia St. 45	School No.7
6	Oksana	Melnichenko	Petriivna	F	2004-05-10	Zhytomyr, Korolova St. 33	School No.7
8	Sofiia	Lisova	Tarasivna	F	2004-11-25	Ternopil, Bandery St. 5	School No.2
9	Maksym	Zhuk	Olehivych	M	2005-01-14	Ivano-Frankivsk, Nezalezhnosti St. 9	School No.4
10	Olha	Horobets	Mykolaivna	F	2003-06-30	Poltava, Kotelevska St. 17	School No.6
11	Artem	Stepanenko	Dmytrovych	M	2004-08-09	Vinnytsia, Soborna St. 13	School No.12
12	Pavlo	Kozak	Ivanovych	M	2004-10-10	Chernihiv, Pobedy St. 5	School No.8
3	Andrii	Shevchenko	Mykolaiovych	M	2003-12-05	Kyieriogev, New Address St. 45	School No.7
7	Ivan	Petrenko	Oleksandrovych	M	2004-03-15	Kyieriogev, New Address St. 45	School No.5
\.


--
-- TOC entry 4818 (class 0 OID 16598)
-- Dependencies: 220
-- Data for Name: transaction_logs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.transaction_logs (log_id, transaction_type, transaction_status, details, transaction_time) FROM stdin;
72	UPDATE	Успішно	Оновлено студента з ID: 2. Попередня адреса: Kyiv, New Address St. 45, Нова адреса: Kyiv, New Address St. 45	2024-11-11 15:41:27.413348
73	UPDATE	Успішно	Оновлено студента з ID: 3. Попередня адреса: Kyiv, New Address St. 45, Нова адреса: Kyiv, New Address St. 45	2024-11-11 15:41:27.413348
74	UPDATE	Успішно	Оновлено студента з ID: 1. Попередня адреса: Kyiv, New Address St. 45, Нова адреса: Kyiv, New Address St. 45	2024-11-11 15:41:27.413348
75	Оновлення студентів	Успішно	Оновлено дані для 3 студентів.	2024-11-11 15:41:27.413348
76	UPDATE	Успішно	Оновлено результат для студента з ID: 2. Попередня оцінка: 110, Нова оцінка: 105	2024-11-11 15:41:27.413348
77	UPDATE	Успішно	Оновлено результат для студента з ID: 4. Попередня оцінка: 98, Нова оцінка: 93	2024-11-11 15:41:27.413348
78	UPDATE	Успішно	Оновлено результат для студента з ID: 1. Попередня оцінка: 115, Нова оцінка: 110	2024-11-11 15:41:27.413348
79	UPDATE	Успішно	Оновлено результат для студента з ID: 8. Попередня оцінка: 112, Нова оцінка: 107	2024-11-11 15:41:27.413348
80	UPDATE	Успішно	Оновлено результат для студента з ID: 10. Попередня оцінка: 106, Нова оцінка: 101	2024-11-11 15:41:27.413348
81	UPDATE	Успішно	Оновлено результат для студента з ID: 12. Попередня оцінка: 107, Нова оцінка: 102	2024-11-11 15:41:27.413348
82	Оновлення результатів студентів	Успішно	Оновлено 6 результатів для студентів.	2024-11-11 15:41:27.413348
83	UPDATE	Успішно	Оновлено студента з ID: 2. Попередня адреса: Kyiv, New Address St. 45, Нова адреса: Kyiv, New Address St. 45	2024-11-11 15:41:37.456227
84	UPDATE	Успішно	Оновлено студента з ID: 3. Попередня адреса: Kyiv, New Address St. 45, Нова адреса: Kyiv, New Address St. 45	2024-11-11 15:41:37.456227
85	UPDATE	Успішно	Оновлено студента з ID: 1. Попередня адреса: Kyiv, New Address St. 45, Нова адреса: Kyiv, New Address St. 45	2024-11-11 15:41:37.456227
86	Оновлення студентів	Успішно	Оновлено дані для 3 студентів.	2024-11-11 15:41:37.456227
87	UPDATE	Успішно	Оновлено результат для студента з ID: 2. Попередня оцінка: 105, Нова оцінка: 100	2024-11-11 15:41:37.456227
88	UPDATE	Успішно	Оновлено результат для студента з ID: 4. Попередня оцінка: 93, Нова оцінка: 88	2024-11-11 15:41:37.456227
89	UPDATE	Успішно	Оновлено результат для студента з ID: 1. Попередня оцінка: 110, Нова оцінка: 105	2024-11-11 15:41:37.456227
90	UPDATE	Успішно	Оновлено результат для студента з ID: 8. Попередня оцінка: 107, Нова оцінка: 102	2024-11-11 15:41:37.456227
91	UPDATE	Успішно	Оновлено результат для студента з ID: 10. Попередня оцінка: 101, Нова оцінка: 96	2024-11-11 15:41:37.456227
92	UPDATE	Успішно	Оновлено результат для студента з ID: 12. Попередня оцінка: 102, Нова оцінка: 97	2024-11-11 15:41:37.456227
93	Оновлення результатів студентів	Успішно	Оновлено 6 результатів для студентів.	2024-11-11 15:41:37.456227
94	UPDATE	Успішно	Оновлено студента з ID: 2. Попередня адреса: Kyiv, New Address St. 45, Нова адреса: Kyieriogev, New Address St. 45	2024-11-11 15:42:24.446094
95	UPDATE	Успішно	Оновлено студента з ID: 3. Попередня адреса: Kyiv, New Address St. 45, Нова адреса: Kyieriogev, New Address St. 45	2024-11-11 15:42:24.446094
96	UPDATE	Успішно	Оновлено студента з ID: 1. Попередня адреса: Kyiv, New Address St. 45, Нова адреса: Kyieriogev, New Address St. 45	2024-11-11 15:42:24.446094
97	Оновлення студентів	Успішно	Оновлено дані для 3 студентів.	2024-11-11 15:42:24.446094
98	UPDATE	Успішно	Оновлено результат для студента з ID: 2. Попередня оцінка: 100, Нова оцінка: 95	2024-11-11 15:42:24.446094
99	UPDATE	Успішно	Оновлено результат для студента з ID: 4. Попередня оцінка: 88, Нова оцінка: 83	2024-11-11 15:42:24.446094
100	UPDATE	Успішно	Оновлено результат для студента з ID: 1. Попередня оцінка: 105, Нова оцінка: 100	2024-11-11 15:42:24.446094
101	UPDATE	Успішно	Оновлено результат для студента з ID: 8. Попередня оцінка: 102, Нова оцінка: 97	2024-11-11 15:42:24.446094
102	UPDATE	Успішно	Оновлено результат для студента з ID: 10. Попередня оцінка: 96, Нова оцінка: 91	2024-11-11 15:42:24.446094
103	UPDATE	Успішно	Оновлено результат для студента з ID: 12. Попередня оцінка: 97, Нова оцінка: 92	2024-11-11 15:42:24.446094
104	Оновлення результатів студентів	Успішно	Оновлено 6 результатів для студентів.	2024-11-11 15:42:24.446094
105	UPDATE	Успішно	Оновлено студента з ID: 1. Попередня адреса: Kyieriogev, New Address St. 45, Нова адреса: Kyieriogev, New Address St. 45	2024-11-25 13:04:56.262996
106	UPDATE	Успішно	Оновлено результат для студента з ID: 1. Попередня оцінка: 100, Нова оцінка: 100	2024-11-25 13:04:56.262996
107	UPDATE	Успішно	Оновлено результат для студента з ID: 1. Попередня оцінка: 93, Нова оцінка: 93	2024-11-25 13:04:56.262996
108	UPDATE	Успішно	Оновлено результат для студента з ID: 1. Попередня оцінка: 81, Нова оцінка: 81	2024-11-25 13:04:56.262996
109	DELETE	Успішно	Видалено студента з ID: 2, Ім’я: Olena Ivanova	2024-11-25 13:06:38.884553
110	DELETE	Успішно	Видалено результат для студента з ID: 2, Предмет: 2	2024-11-25 13:06:38.884553
111	DELETE	Успішно	Видалено результат для студента з ID: 2, Предмет: 1	2024-11-25 13:06:38.884553
112	DELETE	Успішно	Видалено результат для студента з ID: 2, Предмет: 3	2024-11-25 13:06:38.884553
\.


--
-- TOC entry 4826 (class 0 OID 0)
-- Dependencies: 216
-- Name: student_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.student_id_seq', 11, true);


--
-- TOC entry 4827 (class 0 OID 0)
-- Dependencies: 219
-- Name: transaction_logs_log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.transaction_logs_log_id_seq', 112, true);


--
-- TOC entry 4655 (class 2606 OID 16563)
-- Name: exams exams_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.exams
    ADD CONSTRAINT exams_pkey PRIMARY KEY (ex_id);


--
-- TOC entry 4659 (class 2606 OID 16583)
-- Name: results results_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.results
    ADD CONSTRAINT results_pkey PRIMARY KEY (id, ex_id);


--
-- TOC entry 4657 (class 2606 OID 16577)
-- Name: student student_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.student
    ADD CONSTRAINT student_pkey PRIMARY KEY (id);


--
-- TOC entry 4661 (class 2606 OID 16605)
-- Name: transaction_logs transaction_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.transaction_logs
    ADD CONSTRAINT transaction_logs_pkey PRIMARY KEY (log_id);


--
-- TOC entry 4667 (class 2620 OID 16613)
-- Name: results log_result_delete; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER log_result_delete AFTER DELETE ON public.results FOR EACH ROW EXECUTE FUNCTION public.log_result_changes();


--
-- TOC entry 4668 (class 2620 OID 16611)
-- Name: results log_result_insert; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER log_result_insert AFTER INSERT ON public.results FOR EACH ROW EXECUTE FUNCTION public.log_result_changes();


--
-- TOC entry 4669 (class 2620 OID 16612)
-- Name: results log_result_update; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER log_result_update AFTER UPDATE ON public.results FOR EACH ROW EXECUTE FUNCTION public.log_result_changes();


--
-- TOC entry 4664 (class 2620 OID 16609)
-- Name: student log_student_delete; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER log_student_delete AFTER DELETE ON public.student FOR EACH ROW EXECUTE FUNCTION public.log_student_changes();


--
-- TOC entry 4665 (class 2620 OID 16607)
-- Name: student log_student_insert; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER log_student_insert AFTER INSERT ON public.student FOR EACH ROW EXECUTE FUNCTION public.log_student_changes();


--
-- TOC entry 4666 (class 2620 OID 16608)
-- Name: student log_student_update; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER log_student_update AFTER UPDATE ON public.student FOR EACH ROW EXECUTE FUNCTION public.log_student_changes();


--
-- TOC entry 4662 (class 2606 OID 16589)
-- Name: results fk_exam; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.results
    ADD CONSTRAINT fk_exam FOREIGN KEY (ex_id) REFERENCES public.exams(ex_id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- TOC entry 4663 (class 2606 OID 16584)
-- Name: results fk_student; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.results
    ADD CONSTRAINT fk_student FOREIGN KEY (id) REFERENCES public.student(id) ON UPDATE CASCADE ON DELETE CASCADE;


-- Completed on 2026-10-16 17:27:40

--
-- PostgreSQL database dump complete
--

