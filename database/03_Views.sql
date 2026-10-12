CREATE OR REPLACE VIEW EventRegistrationSummary AS
SELECT
    e.event_id,
    e.event_title,
    COUNT(r.registration_id) AS total_registrations
FROM event e
LEFT JOIN registration r
    ON e.event_id = r.event_id
GROUP BY e.event_id, e.event_title;

CREATE OR REPLACE VIEW RevenueSummary AS
SELECT
    e.event_id,
    e.event_title,
    COALESCE(SUM(p.amount), 0) AS total_revenue
FROM event e
LEFT JOIN registration r
    ON e.event_id = r.event_id
LEFT JOIN payment p
    ON p.registration_id = r.registration_id
    AND p.payment_status = 'Completed'
GROUP BY e.event_id, e.event_title;

SELECT * FROM RevenueSummary;

CREATE OR REPLACE VIEW SessionFeedbackSummary AS
SELECT
    s.session_id,
    s.title,
    AVG(sf.rating) AS average_rating,
    COUNT(sf.session_feedback_id) AS feedback_count
FROM session s
LEFT JOIN sessionfeedback sf
    ON s.session_id = sf.session_id
GROUP BY s.session_id, s.title;

SELECT * FROM SessionFeedbackSummary;

CREATE OR REPLACE VIEW StudentCertificates AS
SELECT
    s.student_id,
    s.first_name,
    s.last_name,
    c.certificate_code,
    c.issued_date
FROM certificate c
JOIN registration r
    ON c.registration_id = r.registration_id
JOIN event e
    ON r.event_id = e.event_id
JOIN student s
    ON r.student_id = s.student_id
WHERE e.end_date < CURDATE();

SELECT * FROM StudentCertificates;

CREATE OR REPLACE VIEW AttendanceSummary AS
SELECT
    s.session_id,
    s.title,
    COUNT(sa.student_id) AS attendee_count
FROM session s
LEFT JOIN sessionattendance sa
    ON s.session_id = sa.session_id
GROUP BY s.session_id, s.title;

SELECT * FROM AttendanceSummary;

SHOW FULL TABLES
WHERE Table_type = 'VIEW';
