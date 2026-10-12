INSERT INTO student
(
program_id,
first_name,
last_name,
email,
phone_number,
date_of_birth,
enrollment_year,
account_status
)
VALUES

(
1,
'Lukas',
'Gruber',
'student.one@example.com',
'+43 660 1234567',
'2002-04-12',
2021,
'Active'
),

(
1,
'Anna',
'Mayer',
'student.two@example.com',
'+43 676 2345678',
'2001-09-30',
2020,
'Active'
),

(
2,
'David',
'Huber',
'student.three@example.com',
'+43 699 3456789',
'2000-12-18',
2022,
'Inactive'
),

(
2,
'Sophie',
'Wagner',
'student.four@example.com',
'+43 664 4567890',
'2003-03-07',
2023,
'Active'
);

INSERT INTO studentaddress
(
student_id,
street_address,
city,
state_province,
postal_code,
country,
address_type
)
VALUES

(
1,
'Mariahilfer Straße 12',
'Vienna',
'Vienna',
'1060',
'Austria',
'Home'
),

(
2,
'Getreidegasse 5',
'Salzburg',
'Salzburg',
'5020',
'Austria',
'Home'
),

(
3,
'Herrengasse 20',
'Graz',
'Styria',
'8010',
'Austria',
'Temporary'
),

(
4,
'Landstraße 45',
'Linz',
'Upper Austria',
'4020',
'Austria',
'Mailing'
);

INSERT INTO organizer
(
department_id,
first_name,
last_name,
email,
job_title,
phone_number
)
VALUES

(
1,
'Michael',
'Schneider',
'organizer.one@example.com',
'Conference Chair',
'+43 660 5551111'
),

(
2,
'Julia',
'Bauer',
'organizer.two@example.com',
'Event Coordinator',
'+43 676 7772222'
);

INSERT INTO speaker
(
first_name,
last_name,
email,
organization_name,
specialization,
biography,
linkedin_url
)
VALUES

(
'Thomas',
'Fischer',
'speaker.one@example.com',
'Vienna AI Labs',
'Artificial Intelligence',
'Researcher specializing in AI systems and automation.',
'https://linkedin.com/in/thomasfischer'
),

(
'Elena',
'Hofer',
'speaker.two@example.com',
'Austrian Data Institute',
'Data Science',
'Expert in machine learning and predictive analytics.',
'https://linkedin.com/in/elenahofer'
);

INSERT INTO useraccount
(student_id, organizer_id, speaker_id, role_id, username, password_hash)
VALUES

(1,NULL,NULL,1,'lukas_g','hashed_pw_1'),
(2,NULL,NULL,1,'anna_s','hashed_pw_2'),
(3,NULL,NULL,1,'felix_w','hashed_pw_3'),
(4,NULL,NULL,1,'sophie_h','hashed_pw_4'),

(NULL,1,NULL,2,'organizer_maria','hashed_pw_5'),

(NULL,NULL,1,3,'speaker_johann','hashed_pw_6');

INSERT INTO venue
(venue_name, city, address, max_capacity)
VALUES

('Vienna Conference Center','Vienna','Messeplatz 1',500),

('Graz Tech Hall','Graz','Technikerstraße 12',300),

('Linz Innovation Hub','Linz','Industriestraße 44',250);

INSERT INTO roomtype
(type_name, description)
VALUES

('Lecture Hall','Large presentation room'),

('Workshop Room','Interactive training room'),

('Meeting Room','Small collaboration room');

INSERT INTO room
(venue_id, room_type_id, room_name, capacity)
VALUES

(1,1,'Hall A',300),

(1,2,'Workshop Room 1',80),

(2,1,'Tech Auditorium',200),

(3,3,'Innovation Meeting Room',40);

INSERT INTO roomequipment
(room_id, equipment_name, quantity)
VALUES

(1,'Projector',2),

(1,'Microphone',4),

(2,'Whiteboard',2),

(3,'Projector',1),

(4,'Conference Screen',1);

SELECT * FROM venue;

SELECT * FROM room;

SELECT * FROM useraccount;

INSERT INTO event
(
category_id,
organizer_id,
venue_id,
status_id,
event_title,
description,
start_date,
end_date,
registration_deadline,
max_capacity,
registration_fee
)
VALUES

(
1,
1,
1,
1,
'Vienna AI Conference 2026',
'International conference about AI and machine learning',
'2026-07-10',
'2026-07-12',
'2026-06-30',
400,
50.00
),

(
2,
2,
2,
2,
'Cybersecurity Workshop Austria',
'Hands-on cybersecurity training workshop',
'2026-08-05',
'2026-08-05',
'2026-07-25',
150,
120.00
);

INSERT INTO eventschedule
(
event_id,
scheduled_date,
start_time,
end_time,
schedule_notes
)
VALUES

(
1,
'2026-07-10',
'09:00:00',
'12:00:00',
'Opening keynote and AI presentations'
),

(
1,
'2026-07-11',
'13:00:00',
'17:00:00',
'Machine learning workshops'
),

(
2,
'2026-08-05',
'10:00:00',
'15:00:00',
'Cybersecurity hands-on labs'
);

INSERT INTO session
(
event_id,
room_id,
session_type_id,
title,
description,
start_datetime,
end_datetime,
max_participants
)
VALUES

(
1,
1,
1,
'Future of Artificial Intelligence',
'AI trends and future technologies',
'2026-07-10 09:00:00',
'2026-07-10 11:00:00',
200
),

(
1,
2,
2,
'Machine Learning Workshop',
'Practical ML training session',
'2026-07-11 13:00:00',
'2026-07-11 15:00:00',
80
),

(
2,
3,
1,
'Cybersecurity Threats 2026',
'Modern cybersecurity risks and defense',
'2026-08-05 10:00:00',
'2026-08-05 12:00:00',
150
);

INSERT INTO sessionspeaker
(
session_id,
speaker_id,
speaker_role
)
VALUES

(
1,
1,
'Keynote Speaker'
),

(
2,
2,
'Workshop Trainer'
),

(
3,
1,
'Security Expert'
);

INSERT INTO registration
(
student_id,
event_id,
status_id
)
VALUES

(
1,
1,
1
),

(
2,
1,
1
),

(
3,
2,
1
),

(
4,
2,
2
);

INSERT INTO ticket
(
registration_id,
ticket_type_id,
qr_code
)
VALUES

(
1,
1,
'QR-AUSTRIA-1001'
),

(
2,
1,
'QR-AUSTRIA-1002'
),

(
3,
2,
'QR-AUSTRIA-1003'
),

(
4,
2,
'QR-AUSTRIA-1004'
);

INSERT INTO payment
(
registration_id,
payment_method_id,
amount,
payment_status,
transaction_reference
)
VALUES

(
1,
1,
50.00,
'Completed',
'TXN-AT-1001'
),

(
2,
2,
50.00,
'Completed',
'TXN-AT-1002'
),

(
3,
1,
120.00,
'Pending',
'TXN-AT-1003'
),

(
4,
2,
120.00,
'Completed',
'TXN-AT-1004'
);

INSERT INTO attendancecheckin
(registration_id, checkin_time)
VALUES
(1,NOW()),
(2,NOW()),
(3,NOW());

INSERT INTO feedback
(student_id, event_id, feedback_type_id, rating, comments)
VALUES
(1,1,1,4.5,'Excellent AI conference'),
(2,1,2,4.0,'Workshop was very useful'),
(3,2,1,5.0,'Cybersecurity session was amazing');

INSERT INTO notification
(user_id, notification_type_id, message, is_read)
VALUES
(1,1,'Your registration is confirmed',0),
(2,2,'Workshop starts tomorrow',0),
(3,3,'Payment received successfully',1);

INSERT INTO roombooking
(room_id, session_id, booking_date, booking_start_time, booking_end_time, booking_purpose)
VALUES
(1,1,'2026-07-10','09:00:00','12:00:00','AI keynote session'),
(2,2,'2026-07-11','13:00:00','17:00:00','ML workshop'),
(3,3,'2026-08-05','10:00:00','15:00:00','Cybersecurity lab');

INSERT INTO sessionfeedback
(session_id, student_id, rating, comments)
VALUES
(1,1,4.5,'Very informative session'),
(2,2,4.0,'Hands-on workshop was helpful'),
(3,3,5.0,'Excellent cybersecurity insights');

INSERT INTO loginhistory
(user_id, ip_address, device_info, login_status)
VALUES
(1,'192.168.1.10','Chrome on Windows','Success'),
(2,'192.168.1.11','Edge on Windows','Success'),
(3,'192.168.1.12','Mobile App Android','Failed');

INSERT INTO waitlist
(student_id, event_id, waitlist_position)
VALUES
(4,1,1),
(3,1,2),
(2,2,1);

INSERT INTO refund
(payment_id, refund_amount, refund_reason)
VALUES
(2,50.00,'Event cancellation'),
(3,120.00,'Duplicate payment');

INSERT INTO sessionmaterial
(session_id, file_name, file_path)
VALUES
(1,'AI_Slides.pdf','/materials/ai_slides.pdf'),
(2,'ML_Workshop_Notes.docx','/materials/ml_notes.docx'),
(3,'Cybersecurity_Guide.pdf','/materials/cyber_guide.pdf');

INSERT INTO sessionresource
(session_id, resource_title, resource_link, resource_type)
VALUES
(1,'AI Trends PDF','https://example.com/ai.pdf','PDF'),
(2,'ML GitHub Repo','https://github.com/example/ml','GitHub'),
(3,'Cybersecurity Training Video','https://youtube.com/example','Video');

INSERT INTO certificatetemplate
(template_name, template_file_path)
VALUES
('Participation Certificate','/templates/participation.pdf'),
('Workshop Completion','/templates/workshop.pdf'),
('Speaker Appreciation','/templates/speaker.pdf');

INSERT INTO certificate
(registration_id, template_id, certificate_code, issued_date, certificate_file_path)
VALUES
(1,1,'CERT-AI-1001','2026-07-12','/certificates/cert1.pdf'),
(2,1,'CERT-ML-1002','2026-07-12','/certificates/cert2.pdf'),
(3,2,'CERT-CYBER-1003','2026-08-06','/certificates/cert3.pdf');

INSERT INTO eventannouncement
(event_id, title, message)
VALUES
(1,'Conference Opening','Welcome to the AI conference'),
(1,'Workshop Reminder','ML workshop starts at 1 PM'),
(2,'Cybersecurity Update','Bring laptops for lab session');