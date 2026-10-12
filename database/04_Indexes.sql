USE conference_management_system;

-- =====================================================
-- EVENT INDEXES
-- =====================================================

CREATE INDEX idx_event_title
ON event(event_title);

CREATE INDEX idx_event_dates
ON event(start_date, end_date);

-- =====================================================
-- EVENT SCHEDULE INDEXES
-- =====================================================

CREATE INDEX idx_schedule_date
ON eventschedule(scheduled_date);

-- =====================================================
-- FEEDBACK INDEXES
-- =====================================================

CREATE INDEX idx_feedback_event
ON feedback(event_id);

CREATE INDEX idx_feedback_rating
ON feedback(rating);

-- =====================================================
-- NOTIFICATION INDEXES
-- =====================================================

CREATE INDEX idx_notification_user
ON notification(user_id);

-- =====================================================
-- PAYMENT INDEXES
-- =====================================================

CREATE INDEX idx_payment_registration
ON payment(registration_id);

CREATE INDEX idx_payment_status
ON payment(payment_status);

-- =====================================================
-- REGISTRATION INDEXES
-- =====================================================

CREATE INDEX idx_registration_student
ON registration(student_id);

CREATE INDEX idx_registration_event
ON registration(event_id);

-- =====================================================
-- ROOM INDEXES
-- =====================================================

CREATE INDEX idx_room_capacity
ON room(capacity);

-- =====================================================
-- ROOM BOOKING INDEXES
-- =====================================================

CREATE INDEX idx_booking_date
ON roombooking(booking_date);

CREATE INDEX idx_booking_room
ON roombooking(room_id);

-- =====================================================
-- SESSION INDEXES
-- =====================================================

CREATE INDEX idx_session_datetime
ON session(start_datetime);

-- =====================================================
-- SESSION ATTENDANCE INDEXES
-- =====================================================

CREATE INDEX idx_sessionattendance_session
ON sessionattendance(session_id);

-- =====================================================
-- SESSION RESOURCE INDEXES
-- =====================================================

CREATE INDEX idx_resource_session
ON sessionresource(session_id);

-- =====================================================
-- STUDENT INDEXES
-- =====================================================

CREATE INDEX idx_student_email
ON student(email);

-- =====================================================
-- TICKET INDEXES
-- =====================================================

CREATE INDEX idx_ticket_qr
ON ticket(qr_code);

-- =====================================================
-- VENUE INDEXES
-- =====================================================

CREATE INDEX idx_venue_city
ON venue(city);

-- =====================================================
-- WAITLIST INDEXES
-- =====================================================

CREATE INDEX idx_waitlist_event
ON waitlist(event_id);