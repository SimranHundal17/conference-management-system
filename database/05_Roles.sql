USE conference_management_system;

-- =====================================
-- 05_Roles.sql
-- Conference Management System
-- =====================================

-- Create Roles
CREATE ROLE IF NOT EXISTS 'admin_role';
CREATE ROLE IF NOT EXISTS 'organizer_role';
CREATE ROLE IF NOT EXISTS 'student_role';

-- =====================================
-- ADMIN ROLE
-- Full access to entire database
-- =====================================

GRANT ALL PRIVILEGES
ON conference_management_system.*
TO 'admin_role';

-- =====================================
-- ORGANIZER ROLE
-- Event and conference management
-- =====================================

GRANT SELECT, INSERT, UPDATE
ON conference_management_system.event
TO 'organizer_role';

GRANT SELECT, INSERT, UPDATE
ON conference_management_system.eventschedule
TO 'organizer_role';

GRANT SELECT, INSERT, UPDATE
ON conference_management_system.session
TO 'organizer_role';

GRANT SELECT, INSERT, UPDATE
ON conference_management_system.registration
TO 'organizer_role';

GRANT SELECT, INSERT, UPDATE
ON conference_management_system.speaker
TO 'organizer_role';

GRANT SELECT, INSERT, UPDATE
ON conference_management_system.roombooking
TO 'organizer_role';

GRANT SELECT, INSERT, UPDATE
ON conference_management_system.eventannouncement
TO 'organizer_role';

GRANT SELECT, INSERT, UPDATE
ON conference_management_system.sessionresource
TO 'organizer_role';

GRANT SELECT, INSERT, UPDATE
ON conference_management_system.sessionmaterial
TO 'organizer_role';

GRANT SELECT
ON conference_management_system.student
TO 'organizer_role';

-- =====================================
-- STUDENT ROLE
-- Registration and participation
-- =====================================

GRANT SELECT
ON conference_management_system.event
TO 'student_role';

GRANT SELECT
ON conference_management_system.session
TO 'student_role';

GRANT SELECT, INSERT
ON conference_management_system.registration
TO 'student_role';

GRANT SELECT, INSERT
ON conference_management_system.feedback
TO 'student_role';

GRANT SELECT, INSERT
ON conference_management_system.sessionfeedback
TO 'student_role';

GRANT SELECT
ON conference_management_system.certificate
TO 'student_role';

-- =====================================
-- DEMO USERS
-- =====================================

CREATE USER IF NOT EXISTS 'admin_user'@'localhost'
IDENTIFIED BY 'Admin123!';

CREATE USER IF NOT EXISTS 'organizer_user'@'localhost'
IDENTIFIED BY 'Organizer123!';

CREATE USER IF NOT EXISTS 'student_user'@'localhost'
IDENTIFIED BY 'Student123!';

-- Assign Roles

GRANT 'admin_role'
TO 'admin_user'@'localhost';

GRANT 'organizer_role'
TO 'organizer_user'@'localhost';

GRANT 'student_role'
TO 'student_user'@'localhost';

-- Default Roles

SET DEFAULT ROLE ALL TO
'admin_user'@'localhost',
'organizer_user'@'localhost',
'student_user'@'localhost';

FLUSH PRIVILEGES;

SHOW GRANTS FOR 'admin_user'@'localhost';

SHOW GRANTS FOR 'organizer_user'@'localhost';

SHOW GRANTS FOR 'student_user'@'localhost';