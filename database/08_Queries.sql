USE conference_management_system;

-- =====================================================
-- Query 1: Student Registrations with Event Names
-- =====================================================

SELECT
    s.student_id,
    CONCAT(s.first_name, ' ', s.last_name) AS student_name,
    e.event_title,
    r.registration_date
FROM registration r
JOIN student s
    ON r.student_id = s.student_id
JOIN event e
    ON r.event_id = e.event_id;


-- =====================================================
-- Query 2: Student + Event + Registration Status
-- =====================================================

SELECT
    CONCAT(s.first_name, ' ', s.last_name) AS student_name,
    e.event_title,
    rs.status_name,
    r.registration_date
FROM registration r
JOIN student s
    ON r.student_id = s.student_id
JOIN event e
    ON r.event_id = e.event_id
JOIN registrationstatus rs
    ON r.status_id = rs.status_id;


-- =====================================================
-- Query 3: Registration Count Per Event
-- =====================================================

SELECT
    e.event_title,
    COUNT(r.registration_id) AS total_registrations
FROM event e
LEFT JOIN registration r
    ON e.event_id = r.event_id
GROUP BY e.event_id, e.event_title;


-- =====================================================
-- Query 4: Sessions Per Event
-- =====================================================

SELECT
    e.event_title,
    COUNT(s.session_id) AS total_sessions
FROM event e
LEFT JOIN session s
    ON e.event_id = s.event_id
GROUP BY e.event_id, e.event_title;


-- =====================================================
-- Query 5: Events Having More Than One Registration
-- =====================================================

SELECT
    e.event_title,
    COUNT(r.registration_id) AS registrations
FROM event e
JOIN registration r
    ON e.event_id = r.event_id
GROUP BY e.event_id, e.event_title
HAVING COUNT(r.registration_id) > 1;


-- =====================================================
-- Query 6: Students Registered For Latest Event
-- (Subquery)
-- =====================================================

SELECT
    s.student_id,
    s.first_name,
    s.last_name
FROM student s
JOIN registration r
    ON s.student_id = r.student_id
WHERE r.event_id =
(
    SELECT event_id
    FROM event
    ORDER BY start_date DESC
    LIMIT 1
);


-- =====================================================
-- Query 7: Students Who Registered For At Least One Event
-- (EXISTS)
-- =====================================================

SELECT
    s.student_id,
    s.first_name,
    s.last_name
FROM student s
WHERE EXISTS
(
    SELECT 1
    FROM registration r
    WHERE r.student_id = s.student_id
);


-- =====================================================
-- Query 8: Event Revenue Summary
-- =====================================================

SELECT
    e.event_title,
    SUM(p.amount) AS total_revenue
FROM payment p
JOIN registration r
    ON p.registration_id = r.registration_id
JOIN event e
    ON r.event_id = e.event_id
WHERE p.payment_status = 'Completed'
GROUP BY e.event_id, e.event_title;


-- =====================================================
-- Query 9: Payment Details By Student
-- =====================================================

SELECT
    CONCAT(s.first_name, ' ', s.last_name) AS student_name,
    p.amount,
    p.payment_status,
    p.payment_date
FROM payment p
JOIN registration r
    ON p.registration_id = r.registration_id
JOIN student s
    ON r.student_id = s.student_id;


-- =====================================================
-- Query 10: Students With Certificates
-- =====================================================

SELECT
    CONCAT(s.first_name, ' ', s.last_name) AS student_name,
    c.certificate_code,
    c.issued_date
FROM certificate c
JOIN registration r
    ON c.registration_id = r.registration_id
JOIN student s
    ON r.student_id = s.student_id;