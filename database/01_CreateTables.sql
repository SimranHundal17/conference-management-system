-- Conference and event management system
-- ============================================================
-- MAIN STAKEHOLDERS
-- ============================================================
--
-- 1. STUDENTS
--    - register for events
--    - attend sessions
--    - receive tickets
--    - submit feedback
--    - download certificates
--
-- 2. ORGANIZERS
--    - create/manage events
--    - assign speakers
--    - manage schedules
--    - monitor attendance
--
-- 3. SPEAKERS
--    - conduct sessions
--    - upload materials
--    - view schedules
--
-- 4. VENUE MANAGERS
--    - manage rooms
--    - manage equipment
--    - avoid scheduling conflicts
--
-- ============================================================
-- DESIGN PRINCIPLES
-- ============================================================
--
-- This database is designed using:
--
-- 1. NORMALIZATION (up to 3NF)
--    - reduces redundancy
--    - prevents update anomalies
--    - improves consistency
--
-- 2. PRIMARY & FOREIGN KEYS
--    - enforce referential integrity
--    - maintain relationships
--
-- 3. TRANSACTIONAL DESIGN
--    - supports registrations
--    - payments
--    - attendance
--    - feedback
--
-- 4. SCALABILITY
--    - supports future expansion
--    - modular architecture
--
-- 5. SECURITY
--    - separated authentication table
--    - role-based access structure
--
-- ============================================================
-- WHY MYSQL?
-- ============================================================
--
-- MySQL was selected because:
--
-- - reliable relational DBMS
-- - strong SQL support
-- - supports indexes/views/constraints
-- - easy integration with Python
-- - widely used in industry
--
-- ============================================================
-- CREATE DATABASE
-- ============================================================

CREATE DATABASE IF NOT EXISTS conference_management_system;

USE conference_management_system;

-- ============================================================
-- WHY INT AUTO_INCREMENT FOR PRIMARY KEYS?
-- ============================================================
--
-- INT AUTO_INCREMENT was selected because:
--
-- 1. storage efficient
-- 2. fast indexing
-- 3. optimized joins
-- 4. automatically generates unique IDs
-- 5. industry standard approach
--
-- ============================================================
-- MODULE 1: USER & ACADEMIC MANAGEMENT
-- ============================================================



-- ============================================================
-- TABLE 1: Department
-- ============================================================
--
-- PURPOSE:
-- Stores organizational departments.
--
-- EXAMPLES:
-- - Computer Science
-- - Business
-- - Engineering
--
-- WHY SEPARATE TABLE?
-- Multiple programs belong to departments.
-- Prevents repeated department data.
-- Supports normalization.
--
-- RELATIONSHIPS:
-- Department 1 ---- M AcademicProgram
-- Department 1 ---- M Organizer
--
-- ============================================================

CREATE TABLE Department (

    -- Primary key
    department_id INT AUTO_INCREMENT PRIMARY KEY,

    -- VARCHAR used because names vary in length
    -- 100 chosen as realistic maximum
    department_name VARCHAR(100) NOT NULL UNIQUE,

    -- Office locations vary in size
    office_location VARCHAR(100) NOT NULL,

    -- Email lengths vary
    -- 255 is industry standard
    contact_email VARCHAR(255) NOT NULL UNIQUE,

    -- Tracks record creation
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);



-- ============================================================
-- TABLE 2: AcademicProgram
-- ============================================================
--
-- PURPOSE:
-- Stores degree programs.
--
-- EXAMPLES:
-- - BSc Data Science
-- - MSc Artificial Intelligence
--
-- WHY SEPARATE TABLE?
-- Many students belong to same program.
-- Prevents duplicate program information.
--
-- RELATIONSHIPS:
-- Department 1 ---- M AcademicProgram
-- AcademicProgram 1 ---- M Student
--
-- ============================================================

CREATE TABLE AcademicProgram (

    program_id INT AUTO_INCREMENT PRIMARY KEY,

    -- Foreign key to Department
    department_id INT NOT NULL,

    -- Program names vary in length
    program_name VARCHAR(100) NOT NULL,

    -- ENUM used because values are fixed and limited
    degree_level ENUM(
        'Bachelor',
        'Master',
        'PhD',
        'Diploma'
    ) NOT NULL,

    -- TINYINT used because duration values are small
    duration_years TINYINT UNSIGNED NOT NULL,

    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_program_department
        FOREIGN KEY (department_id)
        REFERENCES Department(department_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);



-- ============================================================
-- TABLE 3: Student
-- ============================================================
--
-- PURPOSE:
-- Main student entity.
--
-- WHY IMPORTANT?
-- Students are the primary transactional users.
--
-- STUDENTS:
-- - register for events
-- - attend sessions
-- - submit feedback
-- - receive certificates
--
-- RELATIONSHIPS:
-- AcademicProgram 1 ---- M Student
-- Student 1 ---- M Registration
-- Student 1 ---- M Feedback
--
-- ============================================================

CREATE TABLE Student (

    student_id INT AUTO_INCREMENT PRIMARY KEY,

    -- Each student belongs to one academic program
    program_id INT NOT NULL,

    -- VARCHAR because names vary in length
    -- CHAR would waste storage
    first_name VARCHAR(50) NOT NULL,

    last_name VARCHAR(50) NOT NULL,

    -- 255 is practical email standard
    email VARCHAR(255) NOT NULL UNIQUE,

    -- VARCHAR instead of INT because:
    -- - contains +
    -- - country codes
    -- - leading zeros
    phone_number VARCHAR(20),

    -- DATE used because full date required
    date_of_birth DATE NOT NULL,

    -- YEAR datatype more efficient than DATE
    enrollment_year YEAR NOT NULL,

    -- ENUM ensures valid status values only
    account_status ENUM(
        'Active',
        'Inactive',
        'Suspended'
    ) DEFAULT 'Active',

    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_student_program
        FOREIGN KEY (program_id)
        REFERENCES AcademicProgram(program_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);



-- ============================================================
-- TABLE 4: StudentAddress
-- ============================================================
--
-- PURPOSE:
-- Stores student addresses separately.
--
-- WHY SEPARATE TABLE?
-- Supports normalization.
-- Prevents repeating address columns.
-- Supports multiple addresses in future.
--
-- RELATIONSHIP:
-- Student 1 ---- M StudentAddress
--
-- ============================================================

CREATE TABLE StudentAddress (

    address_id INT AUTO_INCREMENT PRIMARY KEY,

    student_id INT NOT NULL,

    -- Address sizes vary significantly
    street_address VARCHAR(150) NOT NULL,

    city VARCHAR(50) NOT NULL,

    state_province VARCHAR(50),

    -- Postal codes vary internationally
    postal_code VARCHAR(20) NOT NULL,

    country VARCHAR(50) NOT NULL,

    -- ENUM used for controlled values
    address_type ENUM(
        'Home',
        'Temporary',
        'Mailing'
    ) DEFAULT 'Home',

    CONSTRAINT fk_address_student
        FOREIGN KEY (student_id)
        REFERENCES Student(student_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);



-- ============================================================
-- TABLE 5: UserRole
-- ============================================================
--
-- PURPOSE:
-- Stores system roles.
--
-- EXAMPLES:
-- - Student
-- - Organizer
-- - Speaker
--
-- WHY SEPARATE TABLE?
-- Supports role-based access control.
-- Prevents repeated role text.
--
-- ============================================================

CREATE TABLE UserRole (

    role_id INT AUTO_INCREMENT PRIMARY KEY,

    role_name VARCHAR(50) NOT NULL UNIQUE,

    -- TEXT used because descriptions vary in size
    description TEXT
);



-- ============================================================
-- TABLE 6: Organizer
-- ============================================================
--
-- PURPOSE:
-- Stores event organizers.
--
-- ORGANIZERS:
-- - create events
-- - manage schedules
-- - assign speakers
-- - monitor attendance
--
-- RELATIONSHIPS:
-- Department 1 ---- M Organizer
-- Organizer 1 ---- M Event
--
-- ============================================================

CREATE TABLE Organizer (

    organizer_id INT AUTO_INCREMENT PRIMARY KEY,

    department_id INT NOT NULL,

    first_name VARCHAR(50) NOT NULL,

    last_name VARCHAR(50) NOT NULL,

    email VARCHAR(255) NOT NULL UNIQUE,

    -- Job titles vary significantly
    job_title VARCHAR(100),

    phone_number VARCHAR(20),

    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_organizer_department
        FOREIGN KEY (department_id)
        REFERENCES Department(department_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);



-- ============================================================
-- TABLE 7: Speaker
-- ============================================================
--
-- PURPOSE:
-- Stores conference speakers.
--
-- SPEAKERS:
-- - conduct sessions
-- - upload materials
-- - present workshops
--
-- RELATIONSHIPS:
-- Speaker M ---- M Session
--
-- ============================================================

CREATE TABLE Speaker (

    speaker_id INT AUTO_INCREMENT PRIMARY KEY,

    first_name VARCHAR(50) NOT NULL,

    last_name VARCHAR(50) NOT NULL,

    email VARCHAR(255) NOT NULL UNIQUE,

    organization_name VARCHAR(100),

    specialization VARCHAR(100),

    -- TEXT used because biographies can be long
    biography TEXT,

    linkedin_url VARCHAR(255),

    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);



-- ============================================================
-- TABLE 8: UserAccount
-- ============================================================
--
-- PURPOSE:
-- Stores login/authentication information.
--
-- WHY SEPARATE TABLE?
--
-- 1. Better security
-- 2. Better normalization
-- 3. Separates authentication from profile data
-- 4. Supports multiple user types
--
-- USERS CAN BE:
-- - Student
-- - Organizer
-- - Speaker
--
-- ============================================================

CREATE TABLE UserAccount (

    user_id INT AUTO_INCREMENT PRIMARY KEY,

    student_id INT NULL,

    organizer_id INT NULL,

    speaker_id INT NULL,

    role_id INT NOT NULL,

    -- Usernames vary in size
    username VARCHAR(50) NOT NULL UNIQUE,

    -- Password hashes are long encrypted strings
    password_hash VARCHAR(255) NOT NULL,

    -- BOOLEAN because only true/false values required
    account_locked BOOLEAN DEFAULT FALSE,

    last_login DATETIME,

    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_user_student
        FOREIGN KEY (student_id)
        REFERENCES Student(student_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT fk_user_organizer
        FOREIGN KEY (organizer_id)
        REFERENCES Organizer(organizer_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT fk_user_speaker
        FOREIGN KEY (speaker_id)
        REFERENCES Speaker(speaker_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT fk_user_role
        FOREIGN KEY (role_id)
        REFERENCES UserRole(role_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);



-- ============================================================
-- TABLE 9: LoginHistory
-- ============================================================
--
-- PURPOSE:
-- Tracks login activity.
--
-- WHY IMPORTANT?
-- Supports:
-- - security auditing
-- - suspicious login tracking
-- - account monitoring
--
-- ============================================================

CREATE TABLE LoginHistory (

    login_history_id INT AUTO_INCREMENT PRIMARY KEY,

    user_id INT NOT NULL,

    login_timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,

    -- 45 chars supports IPv6 addresses
    ip_address VARCHAR(45),

    device_info VARCHAR(255),

    login_status ENUM(
        'Success',
        'Failed'
    ) NOT NULL,

    CONSTRAINT fk_loginhistory_user
        FOREIGN KEY (user_id)
        REFERENCES UserAccount(user_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);



-- ============================================================
-- MODULE 2: VENUE MANAGEMENT
-- ============================================================



-- ============================================================
-- TABLE 10: Venue
-- ============================================================
--
-- PURPOSE:
-- Stores event locations.
--
-- EXAMPLES:
-- - Main Auditorium
-- - Innovation Center
--
-- RELATIONSHIPS:
-- Venue 1 ---- M Room
-- Venue 1 ---- M Event
--
-- ============================================================

CREATE TABLE Venue (

    venue_id INT AUTO_INCREMENT PRIMARY KEY,

    venue_name VARCHAR(100) NOT NULL,

    address VARCHAR(255) NOT NULL,

    city VARCHAR(50) NOT NULL,

    -- UNSIGNED because capacity cannot be negative
    max_capacity INT UNSIGNED NOT NULL,

    contact_email VARCHAR(255),

    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);



-- ============================================================
-- TABLE 11: RoomType
-- ============================================================
--
-- PURPOSE:
-- Stores room categories.
--
-- EXAMPLES:
-- - Lab
-- - Auditorium
-- - Seminar Hall
--
-- WHY SEPARATE TABLE?
-- Prevents repeated room type text.
--
-- ============================================================

CREATE TABLE RoomType (

    room_type_id INT AUTO_INCREMENT PRIMARY KEY,

    type_name VARCHAR(50) NOT NULL UNIQUE,

    description TEXT
);



-- ============================================================
-- TABLE 12: Room
-- ============================================================
--
-- PURPOSE:
-- Stores rooms within venues.
--
-- RELATIONSHIPS:
-- Venue 1 ---- M Room
-- RoomType 1 ---- M Room
--
-- ============================================================

CREATE TABLE Room (

    room_id INT AUTO_INCREMENT PRIMARY KEY,

    venue_id INT NOT NULL,

    room_type_id INT NOT NULL,

    room_name VARCHAR(50) NOT NULL,

    capacity INT UNSIGNED NOT NULL,

    -- Small integer values sufficient
    floor_number TINYINT,

    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_room_venue
        FOREIGN KEY (venue_id)
        REFERENCES Venue(venue_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT fk_room_type
        FOREIGN KEY (room_type_id)
        REFERENCES RoomType(room_type_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);



-- ============================================================
-- TABLE 13: RoomEquipment
-- ============================================================
--
-- PURPOSE:
-- Tracks room equipment.
--
-- EXAMPLES:
-- - Projector
-- - Microphone
-- - Smart Board
--
-- WHY IMPORTANT?
-- Prevents equipment conflicts.
--
-- ============================================================

CREATE TABLE RoomEquipment (

    equipment_id INT AUTO_INCREMENT PRIMARY KEY,

    room_id INT NOT NULL,

    equipment_name VARCHAR(100) NOT NULL,

    quantity TINYINT UNSIGNED DEFAULT 1,

    condition_status ENUM(
        'Available',
        'Damaged',
        'Maintenance'
    ) DEFAULT 'Available',

    CONSTRAINT fk_equipment_room
        FOREIGN KEY (room_id)
        REFERENCES Room(room_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);



-- ============================================================
-- INDEXES
-- ============================================================
--
-- WHY INDEXES?
--
-- Improve query performance for:
-- - searches
-- - joins
-- - filtering
-- - sorting
--
-- ============================================================

CREATE INDEX idx_student_email
ON Student(email);

CREATE INDEX idx_venue_city
ON Venue(city);

CREATE INDEX idx_room_capacity
ON Room(capacity);



-- ============================================================
-- SAMPLE DATA
-- ============================================================

INSERT INTO Department
(department_name, office_location, contact_email)
VALUES
('Computer Science', 'Building A', 'cs@example.com'),
('Business', 'Building B', 'business@example.com');

INSERT INTO AcademicProgram
(department_id, program_name, degree_level, duration_years)
VALUES
(1, 'BSc Data Science', 'Bachelor', 4),
(1, 'MSc Artificial Intelligence', 'Master', 2);

INSERT INTO UserRole
(role_name, description)
VALUES
('Student', 'Student system access'),
('Organizer', 'Event management access'),
('Speaker', 'Speaker access');



-- ============================================================
-- END OF PHASE 1
-- ============================================================
--
-- NEXT MODULES WILL INCLUDE:
--
-- 1. Event Management
-- 2. Session Management
-- 3. Registration & Ticketing
-- 4. Payments
-- 5. Certificates
-- 6. Feedback
-- 7. Notifications
--
-- ============================================================

USE conference_management_system;

SELECT * FROM Department;

SELECT * FROM AcademicProgram;

SELECT * FROM UserRole;

USE conference_management_system;
-- ============================================================
-- MODULE 3: EVENT MANAGEMENT
-- ============================================================
--
-- PURPOSE OF THIS MODULE:
--
-- This module handles:
-- - academic events
-- - event scheduling
-- - event categories
-- - announcements
-- - event tagging
-- - session management
--
-- WHY THIS MODULE IS IMPORTANT?
--
-- This is the CORE transactional module of the system.
--
-- It connects:
-- - organizers
-- - students
-- - rooms
-- - speakers
-- - registrations
--
-- ============================================================



-- ============================================================
-- TABLE 14: EventCategory
-- ============================================================
--
-- PURPOSE:
-- Stores categories of events.
--
-- EXAMPLES:
-- - Conference
-- - Workshop
-- - Seminar
-- - Hackathon
--
-- WHY SEPARATE TABLE?
-- Prevents repeated category text.
-- Supports normalization.
--
-- RELATIONSHIP:
-- EventCategory 1 ---- M Event
--
-- ============================================================

CREATE TABLE EventCategory (

    category_id INT AUTO_INCREMENT PRIMARY KEY,

    category_name VARCHAR(50) NOT NULL UNIQUE,

    description TEXT
);



-- ============================================================
-- TABLE 15: EventStatus
-- ============================================================
--
-- PURPOSE:
-- Stores event lifecycle states.
--
-- EXAMPLES:
-- - Planned
-- - Active
-- - Completed
-- - Cancelled
--
-- WHY SEPARATE TABLE?
-- Better normalization.
-- Easier future expansion.
--
-- ============================================================

CREATE TABLE EventStatus (

    status_id INT AUTO_INCREMENT PRIMARY KEY,

    status_name VARCHAR(30) NOT NULL UNIQUE
);



-- ============================================================
-- TABLE 16: Event
-- ============================================================
--
-- PURPOSE:
-- Main event entity.
--
-- EVENTS:
-- - conferences
-- - seminars
-- - workshops
--
-- WHY IMPORTANT?
-- Central business entity of system.
--
-- RELATIONSHIPS:
-- EventCategory 1 ---- M Event
-- Organizer 1 ---- M Event
-- Venue 1 ---- M Event
-- Event 1 ---- M Session
-- Event 1 ---- M Registration
--
-- ============================================================

CREATE TABLE Event (

    event_id INT AUTO_INCREMENT PRIMARY KEY,

    category_id INT NOT NULL,

    organizer_id INT NOT NULL,

    venue_id INT NOT NULL,

    status_id INT NOT NULL,

    -- Event titles vary significantly
    event_title VARCHAR(150) NOT NULL,

    -- TEXT because descriptions can be large
    description TEXT,

    start_date DATE NOT NULL,

    end_date DATE NOT NULL,

    registration_deadline DATE,

    -- Capacity cannot be negative
    max_capacity INT UNSIGNED NOT NULL,

    -- DECIMAL used for precise currency values
    registration_fee DECIMAL(10,2) DEFAULT 0.00,

    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_event_category
        FOREIGN KEY (category_id)
        REFERENCES EventCategory(category_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    CONSTRAINT fk_event_organizer
        FOREIGN KEY (organizer_id)
        REFERENCES Organizer(organizer_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    CONSTRAINT fk_event_venue
        FOREIGN KEY (venue_id)
        REFERENCES Venue(venue_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    CONSTRAINT fk_event_status
        FOREIGN KEY (status_id)
        REFERENCES EventStatus(status_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    -- Prevent invalid date ranges
    CONSTRAINT chk_event_dates
        CHECK (end_date >= start_date)
);



-- ============================================================
-- TABLE 17: EventSchedule
-- ============================================================
--
-- PURPOSE:
-- Stores detailed scheduling information.
--
-- WHY SEPARATE TABLE?
-- One event may have:
-- - multiple schedule entries
-- - multiple days
-- - multiple timing blocks
--
-- ============================================================

CREATE TABLE EventSchedule (

    schedule_id INT AUTO_INCREMENT PRIMARY KEY,

    event_id INT NOT NULL,

    scheduled_date DATE NOT NULL,

    start_time TIME NOT NULL,

    end_time TIME NOT NULL,

    schedule_notes VARCHAR(255),

    CONSTRAINT fk_schedule_event
        FOREIGN KEY (event_id)
        REFERENCES Event(event_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT chk_schedule_time
        CHECK (end_time > start_time)
);



-- ============================================================
-- TABLE 18: EventAgenda
-- ============================================================
--
-- PURPOSE:
-- Stores agenda items for events.
--
-- EXAMPLES:
-- - Opening Ceremony
-- - AI Panel Discussion
-- - Networking Session
--
-- WHY SEPARATE TABLE?
-- One event contains many agenda items.
--
-- ============================================================

CREATE TABLE EventAgenda (

    agenda_id INT AUTO_INCREMENT PRIMARY KEY,

    event_id INT NOT NULL,

    agenda_title VARCHAR(100) NOT NULL,

    agenda_description TEXT,

    agenda_order TINYINT UNSIGNED NOT NULL,

    CONSTRAINT fk_agenda_event
        FOREIGN KEY (event_id)
        REFERENCES Event(event_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);



-- ============================================================
-- TABLE 19: EventAnnouncement
-- ============================================================
--
-- PURPOSE:
-- Stores announcements related to events.
--
-- EXAMPLES:
-- - room change
-- - schedule update
-- - cancellation notice
--
-- ============================================================

CREATE TABLE EventAnnouncement (

    announcement_id INT AUTO_INCREMENT PRIMARY KEY,

    event_id INT NOT NULL,

    title VARCHAR(100) NOT NULL,

    message TEXT NOT NULL,

    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_announcement_event
        FOREIGN KEY (event_id)
        REFERENCES Event(event_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);



-- ============================================================
-- TABLE 20: EventTag
-- ============================================================
--
-- PURPOSE:
-- Stores searchable event tags.
--
-- EXAMPLES:
-- - AI
-- - Cybersecurity
-- - Machine Learning
--
-- WHY SEPARATE TABLE?
-- Supports:
-- - event filtering
-- - event searching
-- - many-to-many relationships
--
-- ============================================================

CREATE TABLE EventTag (

    tag_id INT AUTO_INCREMENT PRIMARY KEY,

    tag_name VARCHAR(50) NOT NULL UNIQUE
);



-- ============================================================
-- TABLE 21: EventTagMapping
-- ============================================================
--
-- PURPOSE:
-- Bridge table for many-to-many relationship.
--
-- WHY NEEDED?
--
-- One event can have many tags.
-- One tag can belong to many events.
--
-- MANY-TO-MANY RELATIONSHIP:
-- Event M ---- M EventTag
--
-- ============================================================

CREATE TABLE EventTagMapping (

    event_id INT NOT NULL,

    tag_id INT NOT NULL,

    PRIMARY KEY (event_id, tag_id),

    CONSTRAINT fk_tagmapping_event
        FOREIGN KEY (event_id)
        REFERENCES Event(event_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT fk_tagmapping_tag
        FOREIGN KEY (tag_id)
        REFERENCES EventTag(tag_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);



-- ============================================================
-- MODULE 4: SESSION MANAGEMENT
-- ============================================================
--
-- PURPOSE:
-- Handles individual event sessions.
--
-- WHY IMPORTANT?
--
-- Sessions connect:
-- - speakers
-- - rooms
-- - attendance
-- - feedback
-- - materials
--
-- ============================================================



-- ============================================================
-- TABLE 22: SessionType
-- ============================================================
--
-- PURPOSE:
-- Stores session categories.
--
-- EXAMPLES:
-- - Keynote
-- - Workshop
-- - Panel Discussion
--
-- ============================================================

CREATE TABLE SessionType (

    session_type_id INT AUTO_INCREMENT PRIMARY KEY,

    type_name VARCHAR(50) NOT NULL UNIQUE,

    description TEXT
);



-- ============================================================
-- TABLE 23: Session
-- ============================================================
--
-- PURPOSE:
-- Stores individual sessions inside events.
--
-- VERY IMPORTANT TABLE:
--
-- Session connects:
-- - Event
-- - Room
-- - Speaker
-- - Attendance
-- - Materials
--
-- WHY ROOM CONNECTS TO SESSION?
--
-- Because one event may use multiple rooms.
-- Therefore rooms should connect to sessions,
-- NOT directly to entire events.
--
-- RELATIONSHIPS:
-- Event 1 ---- M Session
-- Room 1 ---- M Session
-- SessionType 1 ---- M Session
--
-- ============================================================

CREATE TABLE Session (

    session_id INT AUTO_INCREMENT PRIMARY KEY,

    event_id INT NOT NULL,

    room_id INT NOT NULL,

    session_type_id INT NOT NULL,

    title VARCHAR(150) NOT NULL,

    description TEXT,

    start_datetime DATETIME NOT NULL,

    end_datetime DATETIME NOT NULL,

    max_participants INT UNSIGNED,

    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_session_event
        FOREIGN KEY (event_id)
        REFERENCES Event(event_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT fk_session_room
        FOREIGN KEY (room_id)
        REFERENCES Room(room_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    CONSTRAINT fk_session_type
        FOREIGN KEY (session_type_id)
        REFERENCES SessionType(session_type_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    CONSTRAINT chk_session_time
        CHECK (end_datetime > start_datetime)
);



-- ============================================================
-- TABLE 24: SessionSpeaker
-- ============================================================
--
-- PURPOSE:
-- Bridge table for many-to-many relationship.
--
-- WHY MANY-TO-MANY?
--
-- One session may have many speakers.
-- One speaker may conduct many sessions.
--
-- EXAMPLE:
-- AI Panel:
-- - Speaker A
-- - Speaker B
-- - Speaker C
--
-- ============================================================

CREATE TABLE SessionSpeaker (

    session_id INT NOT NULL,

    speaker_id INT NOT NULL,

    speaker_role VARCHAR(50),

    PRIMARY KEY (session_id, speaker_id),

    CONSTRAINT fk_sessionspeaker_session
        FOREIGN KEY (session_id)
        REFERENCES Session(session_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT fk_sessionspeaker_speaker
        FOREIGN KEY (speaker_id)
        REFERENCES Speaker(speaker_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);



-- ============================================================
-- TABLE 25: SessionMaterial
-- ============================================================
--
-- PURPOSE:
-- Stores uploaded session materials.
--
-- EXAMPLES:
-- - PDF slides
-- - research papers
-- - presentation files
--
-- WHY FILE PATH?
--
-- Actual files are stored externally.
-- Database stores file metadata only.
--
-- ============================================================

CREATE TABLE SessionMaterial (

    material_id INT AUTO_INCREMENT PRIMARY KEY,

    session_id INT NOT NULL,

    file_name VARCHAR(255) NOT NULL,

    file_path VARCHAR(255) NOT NULL,

    uploaded_at DATETIME DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_material_session
        FOREIGN KEY (session_id)
        REFERENCES Session(session_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);



-- ============================================================
-- INDEXES
-- ============================================================

CREATE INDEX idx_event_title
ON Event(event_title);

CREATE INDEX idx_event_dates
ON Event(start_date, end_date);

CREATE INDEX idx_session_datetime
ON Session(start_datetime);

CREATE INDEX idx_schedule_date
ON EventSchedule(scheduled_date);



-- ============================================================
-- SAMPLE DATA
-- ============================================================

INSERT INTO EventCategory
(category_name, description)
VALUES
('Conference', 'Large academic conference'),
('Workshop', 'Hands-on learning workshop'),
('Seminar', 'Academic seminar');

INSERT INTO EventStatus
(status_name)
VALUES
('Planned'),
('Active'),
('Completed'),
('Cancelled');

INSERT INTO SessionType
(type_name, description)
VALUES
('Keynote', 'Main presentation session'),
('Workshop', 'Interactive practical session'),
('Panel', 'Group discussion session');

USE conference_management_system;
-- ============================================================
-- MODULE 5: REGISTRATION & TICKETING
-- ============================================================
--
-- PURPOSE OF THIS MODULE:
--
-- Handles:
-- - event registrations
-- - ticket generation
-- - attendance check-ins
-- - waitlists
-- - cancellation requests
--
-- WHY THIS MODULE IS IMPORTANT?
--
-- This is one of the most important transactional modules.
--
-- It generates:
-- - joins
-- - aggregation queries
-- - reports
-- - transactional records
--
-- ============================================================



-- ============================================================
-- TABLE 26: RegistrationStatus
-- ============================================================
--
-- PURPOSE:
-- Stores registration states.
--
-- EXAMPLES:
-- - Pending
-- - Confirmed
-- - Cancelled
--
-- WHY SEPARATE TABLE?
-- Prevents repeated text values.
-- Supports normalization.
--
-- ============================================================

CREATE TABLE RegistrationStatus (

    status_id INT AUTO_INCREMENT PRIMARY KEY,

    status_name VARCHAR(30) NOT NULL UNIQUE
);



-- ============================================================
-- TABLE 27: Registration
-- ============================================================
--
-- PURPOSE:
-- Stores student registrations for events.
--
-- VERY IMPORTANT TABLE:
--
-- Connects:
-- - Student
-- - Event
-- - Payment
-- - Ticket
-- - Certificate
--
-- RELATIONSHIPS:
-- Student 1 ---- M Registration
-- Event 1 ---- M Registration
--
-- ============================================================

CREATE TABLE Registration (

    registration_id INT AUTO_INCREMENT PRIMARY KEY,

    student_id INT NOT NULL,

    event_id INT NOT NULL,

    status_id INT NOT NULL,

    registration_date DATETIME
        DEFAULT CURRENT_TIMESTAMP,

    -- Prevents duplicate registrations
    CONSTRAINT uq_student_event
        UNIQUE (student_id, event_id),

    CONSTRAINT fk_registration_student
        FOREIGN KEY (student_id)
        REFERENCES Student(student_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT fk_registration_event
        FOREIGN KEY (event_id)
        REFERENCES Event(event_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT fk_registration_status
        FOREIGN KEY (status_id)
        REFERENCES RegistrationStatus(status_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);



-- ============================================================
-- TABLE 28: TicketType
-- ============================================================
--
-- PURPOSE:
-- Stores ticket categories.
--
-- EXAMPLES:
-- - Standard
-- - VIP
-- - Student Pass
--
-- WHY SEPARATE TABLE?
-- Prevents repeated ticket type text.
-- Supports pricing flexibility.
--
-- ============================================================

CREATE TABLE TicketType (

    ticket_type_id INT AUTO_INCREMENT PRIMARY KEY,

    type_name VARCHAR(50) NOT NULL UNIQUE,

    -- DECIMAL for precise money values
    price DECIMAL(10,2) NOT NULL
);



-- ============================================================
-- TABLE 29: Ticket
-- ============================================================
--
-- PURPOSE:
-- Stores generated event tickets.
--
-- RELATIONSHIP:
-- Registration 1 ---- 1 Ticket
--
-- WHY UNIQUE REGISTRATION_ID?
--
-- One registration should generate
-- only one valid ticket.
--
-- ============================================================

CREATE TABLE Ticket (

    ticket_id INT AUTO_INCREMENT PRIMARY KEY,

    registration_id INT NOT NULL UNIQUE,

    ticket_type_id INT NOT NULL,

    -- QR values vary in length
    qr_code VARCHAR(255) NOT NULL UNIQUE,

    issued_at DATETIME DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_ticket_registration
        FOREIGN KEY (registration_id)
        REFERENCES Registration(registration_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT fk_ticket_type
        FOREIGN KEY (ticket_type_id)
        REFERENCES TicketType(ticket_type_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);



-- ============================================================
-- TABLE 30: AttendanceCheckIn
-- ============================================================
--
-- PURPOSE:
-- Tracks event entry/check-ins.
--
-- WHY IMPORTANT?
--
-- Used for:
-- - attendance tracking
-- - event participation
-- - analytics
--
-- ============================================================

CREATE TABLE AttendanceCheckIn (

    checkin_id INT AUTO_INCREMENT PRIMARY KEY,

    registration_id INT NOT NULL,

    checkin_time DATETIME
        DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_checkin_registration
        FOREIGN KEY (registration_id)
        REFERENCES Registration(registration_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);



-- ============================================================
-- TABLE 31: SessionAttendance
-- ============================================================
--
-- PURPOSE:
-- Tracks attendance for individual sessions.
--
-- WHY SEPARATE FROM EVENT CHECK-IN?
--
-- Event attendance and session attendance
-- are different business processes.
--
-- Example:
-- Student attended event,
-- but only attended 2 out of 5 sessions.
--
-- ============================================================

CREATE TABLE SessionAttendance (

    attendance_id INT AUTO_INCREMENT PRIMARY KEY,

    session_id INT NOT NULL,

    student_id INT NOT NULL,

    attendance_time DATETIME
        DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_session_student
        UNIQUE (session_id, student_id),

    CONSTRAINT fk_sessionattendance_session
        FOREIGN KEY (session_id)
        REFERENCES Session(session_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT fk_sessionattendance_student
        FOREIGN KEY (student_id)
        REFERENCES Student(student_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);



-- ============================================================
-- TABLE 32: Waitlist
-- ============================================================
--
-- PURPOSE:
-- Stores students waiting for full events.
--
-- WHY IMPORTANT?
--
-- Real conference systems often
-- support waitlisting.
--
-- ============================================================

CREATE TABLE Waitlist (

    waitlist_id INT AUTO_INCREMENT PRIMARY KEY,

    student_id INT NOT NULL,

    event_id INT NOT NULL,

    waitlist_position INT UNSIGNED NOT NULL,

    joined_at DATETIME DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_waitlist
        UNIQUE (student_id, event_id),

    CONSTRAINT fk_waitlist_student
        FOREIGN KEY (student_id)
        REFERENCES Student(student_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT fk_waitlist_event
        FOREIGN KEY (event_id)
        REFERENCES Event(event_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);



-- ============================================================
-- TABLE 33: CancellationRequest
-- ============================================================
--
-- PURPOSE:
-- Stores cancellation requests.
--
-- WHY SEPARATE TABLE?
--
-- Maintains cancellation history.
-- Useful for audit/reporting.
--
-- ============================================================

CREATE TABLE CancellationRequest (

    cancellation_id INT AUTO_INCREMENT PRIMARY KEY,

    registration_id INT NOT NULL,

    reason TEXT,

    request_date DATETIME
        DEFAULT CURRENT_TIMESTAMP,

    approval_status ENUM(
        'Pending',
        'Approved',
        'Rejected'
    ) DEFAULT 'Pending',

    CONSTRAINT fk_cancellation_registration
        FOREIGN KEY (registration_id)
        REFERENCES Registration(registration_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);



-- ============================================================
-- INDEXES
-- ============================================================

CREATE INDEX idx_registration_student
ON Registration(student_id);

CREATE INDEX idx_registration_event
ON Registration(event_id);

CREATE INDEX idx_ticket_qr
ON Ticket(qr_code);

CREATE INDEX idx_sessionattendance_session
ON SessionAttendance(session_id);

CREATE INDEX idx_waitlist_event
ON Waitlist(event_id);



-- ============================================================
-- SAMPLE DATA
-- ============================================================

INSERT INTO RegistrationStatus
(status_name)
VALUES
('Pending'),
('Confirmed'),
('Cancelled');

INSERT INTO TicketType
(type_name, price)
VALUES
('Standard', 50.00),
('VIP', 120.00),
('Student Pass', 25.00);

-- ============================================================
-- END OF REGISTRATION & TICKETING MODULE
-- ============================================================

USE conference_management_system;
-- ============================================================
-- MODULE 6: PAYMENTS & CERTIFICATES
-- ============================================================
--
-- PURPOSE OF THIS MODULE:
--
-- Handles:
-- - event payments
-- - payment methods
-- - refunds
-- - certificate generation
--
-- WHY IMPORTANT?
--
-- This module supports:
-- - financial transactions
-- - attendance validation
-- - post-event certification
--
-- ============================================================



-- ============================================================
-- TABLE 34: PaymentMethod
-- ============================================================
--
-- PURPOSE:
-- Stores available payment methods.
--
-- EXAMPLES:
-- - Credit Card
-- - Debit Card
-- - Cash
-- - PayPal
--
-- WHY SEPARATE TABLE?
-- Prevents repeated text values.
-- Supports future expansion.
--
-- ============================================================

CREATE TABLE PaymentMethod (

    payment_method_id INT AUTO_INCREMENT PRIMARY KEY,

    method_name VARCHAR(50) NOT NULL UNIQUE,

    description TEXT
);



-- ============================================================
-- TABLE 35: Payment
-- ============================================================
--
-- PURPOSE:
-- Stores payment transactions.
--
-- RELATIONSHIPS:
-- Registration 1 ---- M Payment
-- PaymentMethod 1 ---- M Payment
--
-- WHY IMPORTANT?
--
-- Tracks:
-- - registration payments
-- - payment statuses
-- - financial reporting
--
-- ============================================================

CREATE TABLE Payment (

    payment_id INT AUTO_INCREMENT PRIMARY KEY,

    registration_id INT NOT NULL,

    payment_method_id INT NOT NULL,

    -- DECIMAL used for accurate currency storage
    amount DECIMAL(10,2) NOT NULL,

    payment_date DATETIME
        DEFAULT CURRENT_TIMESTAMP,

    payment_status ENUM(
        'Pending',
        'Completed',
        'Failed',
        'Refunded'
    ) DEFAULT 'Pending',

    transaction_reference VARCHAR(100) UNIQUE,

    CONSTRAINT fk_payment_registration
        FOREIGN KEY (registration_id)
        REFERENCES Registration(registration_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT fk_payment_method
        FOREIGN KEY (payment_method_id)
        REFERENCES PaymentMethod(payment_method_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);



-- ============================================================
-- TABLE 36: Refund
-- ============================================================
--
-- PURPOSE:
-- Stores refund records.
--
-- WHY SEPARATE TABLE?
--
-- One payment may have:
-- - partial refunds
-- - multiple refund operations
--
-- Supports:
-- - auditing
-- - financial tracking
--
-- ============================================================

CREATE TABLE Refund (

    refund_id INT AUTO_INCREMENT PRIMARY KEY,

    payment_id INT NOT NULL,

    refund_amount DECIMAL(10,2) NOT NULL,

    refund_reason TEXT,

    refund_date DATETIME
        DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_refund_payment
        FOREIGN KEY (payment_id)
        REFERENCES Payment(payment_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);



-- ============================================================
-- TABLE 37: CertificateTemplate
-- ============================================================
--
-- PURPOSE:
-- Stores certificate templates.
--
-- WHY SEPARATE TABLE?
--
-- Different event types may use
-- different certificate designs.
--
-- ============================================================

CREATE TABLE CertificateTemplate (

    template_id INT AUTO_INCREMENT PRIMARY KEY,

    template_name VARCHAR(100) NOT NULL UNIQUE,

    template_file_path VARCHAR(255) NOT NULL,

    created_at DATETIME
        DEFAULT CURRENT_TIMESTAMP
);



-- ============================================================
-- TABLE 38: Certificate
-- ============================================================
--
-- PURPOSE:
-- Stores issued certificates.
--
-- RELATIONSHIPS:
-- Registration 1 ---- 1 Certificate
-- CertificateTemplate 1 ---- M Certificate
--
-- WHY UNIQUE REGISTRATION_ID?
--
-- One registration should receive
-- only one certificate.
--
-- ============================================================

CREATE TABLE Certificate (

    certificate_id INT AUTO_INCREMENT PRIMARY KEY,

    registration_id INT NOT NULL UNIQUE,

    template_id INT NOT NULL,

    certificate_code VARCHAR(100) NOT NULL UNIQUE,

    issued_date DATE NOT NULL,

    certificate_file_path VARCHAR(255),

    CONSTRAINT fk_certificate_registration
        FOREIGN KEY (registration_id)
        REFERENCES Registration(registration_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT fk_certificate_template
        FOREIGN KEY (template_id)
        REFERENCES CertificateTemplate(template_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);



-- ============================================================
-- MODULE 7: FEEDBACK & COMMUNICATION
-- ============================================================
--
-- PURPOSE:
-- Handles:
-- - event feedback
-- - session ratings
-- - notifications
--
-- WHY IMPORTANT?
--
-- Supports:
-- - quality analysis
-- - event improvement
-- - attendee satisfaction tracking
--
-- ============================================================



-- ============================================================
-- TABLE 39: FeedbackType
-- ============================================================
--
-- PURPOSE:
-- Stores feedback categories.
--
-- EXAMPLES:
-- - Event Feedback
-- - Session Feedback
-- - Speaker Feedback
--
-- WHY SEPARATE TABLE?
-- Supports normalization.
--
-- ============================================================

CREATE TABLE FeedbackType (

    feedback_type_id INT AUTO_INCREMENT PRIMARY KEY,

    type_name VARCHAR(50) NOT NULL UNIQUE
);



-- ============================================================
-- TABLE 40: Feedback
-- ============================================================
--
-- PURPOSE:
-- Stores event-level feedback.
--
-- RELATIONSHIPS:
-- Student 1 ---- M Feedback
-- Event 1 ---- M Feedback
--
-- WHY DECIMAL(2,1) FOR RATING?
--
-- Supports values like:
-- 4.5
-- 3.0
-- 5.0
--
-- ============================================================

CREATE TABLE Feedback (

    feedback_id INT AUTO_INCREMENT PRIMARY KEY,

    student_id INT NOT NULL,

    event_id INT NOT NULL,

    feedback_type_id INT NOT NULL,

    rating DECIMAL(2,1) NOT NULL,

    comments TEXT,

    submitted_at DATETIME
        DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_feedback_student
        FOREIGN KEY (student_id)
        REFERENCES Student(student_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT fk_feedback_event
        FOREIGN KEY (event_id)
        REFERENCES Event(event_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT fk_feedback_type
        FOREIGN KEY (feedback_type_id)
        REFERENCES FeedbackType(feedback_type_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,

    CONSTRAINT chk_feedback_rating
        CHECK (rating >= 0 AND rating <= 5)
);



-- ============================================================
-- TABLE 41: SessionFeedback
-- ============================================================
--
-- PURPOSE:
-- Stores feedback for individual sessions.
--
-- WHY SEPARATE FROM EVENT FEEDBACK?
--
-- Event feedback and session feedback
-- are different business processes.
--
-- ============================================================

CREATE TABLE SessionFeedback (

    session_feedback_id INT AUTO_INCREMENT PRIMARY KEY,

    session_id INT NOT NULL,

    student_id INT NOT NULL,

    rating DECIMAL(2,1) NOT NULL,

    comments TEXT,

    submitted_at DATETIME
        DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT uq_session_feedback
        UNIQUE (session_id, student_id),

    CONSTRAINT fk_sessionfeedback_session
        FOREIGN KEY (session_id)
        REFERENCES Session(session_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT fk_sessionfeedback_student
        FOREIGN KEY (student_id)
        REFERENCES Student(student_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT chk_session_rating
        CHECK (rating >= 0 AND rating <= 5)
);



-- ============================================================
-- TABLE 42: NotificationType
-- ============================================================
--
-- PURPOSE:
-- Stores notification categories.
--
-- EXAMPLES:
-- - Reminder
-- - Update
-- - Warning
--
-- ============================================================

CREATE TABLE NotificationType (

    notification_type_id INT AUTO_INCREMENT PRIMARY KEY,

    type_name VARCHAR(50) NOT NULL UNIQUE
);



-- ============================================================
-- TABLE 43: Notification
-- ============================================================
--
-- PURPOSE:
-- Stores user notifications.
--
-- RELATIONSHIP:
-- UserAccount 1 ---- M Notification
--
-- WHY IMPORTANT?
--
-- Supports:
-- - reminders
-- - schedule updates
-- - cancellations
--
-- ============================================================

CREATE TABLE Notification (

    notification_id INT AUTO_INCREMENT PRIMARY KEY,

    user_id INT NOT NULL,

    notification_type_id INT NOT NULL,

    message TEXT NOT NULL,

    sent_at DATETIME
        DEFAULT CURRENT_TIMESTAMP,

    is_read BOOLEAN DEFAULT FALSE,

    CONSTRAINT fk_notification_user
        FOREIGN KEY (user_id)
        REFERENCES UserAccount(user_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT fk_notification_type
        FOREIGN KEY (notification_type_id)
        REFERENCES NotificationType(notification_type_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
);



-- ============================================================
-- INDEXES
-- ============================================================

CREATE INDEX idx_payment_registration
ON Payment(registration_id);

CREATE INDEX idx_payment_status
ON Payment(payment_status);

CREATE INDEX idx_feedback_event
ON Feedback(event_id);

CREATE INDEX idx_feedback_rating
ON Feedback(rating);

CREATE INDEX idx_notification_user
ON Notification(user_id);



-- ============================================================
-- SAMPLE DATA
-- ============================================================

INSERT INTO PaymentMethod
(method_name, description)
VALUES
('Credit Card', 'Payment using credit card'),
('Debit Card', 'Payment using debit card'),
('Cash', 'Cash payment'),
('PayPal', 'Online PayPal payment');

INSERT INTO FeedbackType
(type_name)
VALUES
('Event Feedback'),
('Session Feedback'),
('Speaker Feedback');

INSERT INTO NotificationType
(type_name)
VALUES
('Reminder'),
('Update'),
('Warning');

-- ============================================================
-- END OF PAYMENT + CERTIFICATE + FEEDBACK MODULE
-- ============================================================

USE conference_management_system;
-- ============================================================
-- MODULE 8: ADVANCED SESSION & RESOURCE MANAGEMENT
-- ============================================================
--
-- PURPOSE OF THIS MODULE:
--
-- Handles:
-- - additional session resources
-- - room bookings
-- - session capacity tracking
-- - organizer assignments
--
-- WHY IMPORTANT?
--
-- This module improves:
-- - normalization
-- - scheduling control
-- - resource allocation
-- - reporting capability
--
-- ============================================================



-- ============================================================
-- TABLE 44: SessionResource
-- ============================================================
--
-- PURPOSE:
-- Stores additional learning resources
-- related to sessions.
--
-- EXAMPLES:
-- - GitHub repository
-- - research paper link
-- - video tutorial
-- - documentation
--
-- WHY SEPARATE FROM SessionMaterial?
--
-- SessionMaterial stores uploaded files.
-- SessionResource stores external resources/URLs.
--
-- ============================================================

CREATE TABLE SessionResource (

    resource_id INT AUTO_INCREMENT PRIMARY KEY,

    session_id INT NOT NULL,

    resource_title VARCHAR(150) NOT NULL,

    resource_link VARCHAR(255) NOT NULL,

    resource_type ENUM(
        'PDF',
        'Video',
        'GitHub',
        'Website',
        'Documentation'
    ) NOT NULL,

    added_at DATETIME
        DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_resource_session
        FOREIGN KEY (session_id)
        REFERENCES Session(session_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
);



-- ============================================================
-- TABLE 45: RoomBooking
-- ============================================================
--
-- PURPOSE:
-- Stores room reservation records.
--
-- WHY SEPARATE TABLE?
--
-- A room may be booked:
-- - for sessions
-- - for rehearsals
-- - for preparation
-- - for setup activities
--
-- Supports future scalability.
--
-- RELATIONSHIPS:
-- Room 1 ---- M RoomBooking
-- Session 1 ---- M RoomBooking
--
-- ============================================================

CREATE TABLE RoomBooking (

    booking_id INT AUTO_INCREMENT PRIMARY KEY,

    room_id INT NOT NULL,

    session_id INT NOT NULL,

    booking_date DATE NOT NULL,

    booking_start_time TIME NOT NULL,

    booking_end_time TIME NOT NULL,

    booking_purpose VARCHAR(255),

    created_at DATETIME
        DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT fk_booking_room
        FOREIGN KEY (room_id)
        REFERENCES Room(room_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT fk_booking_session
        FOREIGN KEY (session_id)
        REFERENCES Session(session_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,

    CONSTRAINT chk_booking_time
        CHECK (booking_end_time > booking_start_time)
);



-- ============================================================
-- INDEXES
-- ============================================================

CREATE INDEX idx_resource_session
ON SessionResource(session_id);

CREATE INDEX idx_booking_room
ON RoomBooking(room_id);

CREATE INDEX idx_booking_date
ON RoomBooking(booking_date);

-- ============================================================
-- FINAL DATABASE STATUS
-- ============================================================
--
-- TOTAL TABLES CREATED: 45
--
-- MODULES COMPLETED:
--
-- 1. User & Academic Management
-- 2. Venue Management
-- 3. Event Management
-- 4. Session Management
-- 5. Registration & Ticketing
-- 6. Payments & Certificates
-- 7. Feedback & Communication
-- 8. Advanced Resource Management
--
-- ============================================================
--
-- DATABASE FEATURES IMPLEMENTED:
--
-- ✔ Primary Keys
-- ✔ Foreign Keys
-- ✔ Many-to-Many Relationships
-- ✔ Bridge Tables
-- ✔ Check Constraints
-- ✔ ENUM Constraints
-- ✔ Unique Constraints
-- ✔ Indexes
-- ✔ Audit Fields
-- ✔ Transactional Design
-- ✔ Normalized Structure (3NF)
--
-- ============================================================
--
-- IMPORTANT MANY-TO-MANY RELATIONSHIPS:
--
-- 1. Session M ---- M Speaker
--    using SessionSpeaker
--
-- 2. Event M ---- M EventTag
--    using EventTagMapping
--
-- ============================================================
--
-- IMPORTANT TRANSACTIONAL FLOWS:
--
-- Student
-- → Registration
-- → Payment
-- → Ticket
-- → Attendance
-- → Certificate
-- → Feedback
--
-- ============================================================
