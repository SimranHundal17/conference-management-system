# Conference Management System Database Explanation

This database models a conference and event system. The central flow is:

`Student -> Registration -> Event -> Session -> Attendance/Feedback/Certificate/Payment/Ticket`

Events are managed by organizers, hosted in venues and rooms, categorized with lookup tables, and supported by reports, notifications, and authentication records.

## Datatype And Field Size Choices

The database uses specific datatypes and field sizes instead of choosing large or generic datatypes for every column. Each size was selected according to the expected real-world maximum length of the value stored in that column.

- Person name fields, such as `first_name` and `last_name`, can use a limited `VARCHAR` size such as `VARCHAR(20)` because these fields store only one part of a person's name, not a full biography or description. This keeps the column realistic and avoids unnecessary storage.
- Full descriptive names, such as `department_name`, `program_name`, `event_title`, `venue_name`, and `room_name`, need larger `VARCHAR` sizes because they may contain several words. These fields should therefore be longer than a simple first name or last name field.
- Email fields need a larger size than names. A practical choice is `VARCHAR(255)` because email addresses can contain usernames, domain names, subdomains, dots, and special characters. Using a smaller value such as `VARCHAR(20)` would reject many valid emails.
- Phone numbers, if stored, should use `VARCHAR` instead of an integer because phone numbers can include leading zeros, country codes, spaces, or symbols such as `+`.
- Short codes and generated references, such as ticket codes, certificate codes, QR codes, and transaction references, use `VARCHAR` with a size based on the expected generated format. They are not stored as numbers because they may contain letters or special characters.
- Identifier columns such as `student_id`, `event_id`, `registration_id`, `session_id`, and other primary/foreign keys use integer-style numeric datatypes. These are efficient for indexing, joins, and relationship enforcement.
- Short controlled values, such as statuses, roles, payment methods, feedback types, room types, and ticket types, are stored in lookup tables instead of being repeated as free text. This improves consistency and avoids spelling variations like `Cancelled`, `Canceled`, or `cancelled`.
- Dates and times use date/time datatypes rather than strings. Event dates, session times, booking times, login times, payment dates, and certificate issue dates can therefore be sorted, compared, filtered, and validated correctly.
- Money-related fields such as event fees, ticket prices, payment amounts, and refund amounts use fixed-point decimal datatypes instead of floating-point datatypes. This avoids rounding problems in financial calculations.
- Capacity, enrollment year, rating, attendance count, waitlist position, and similar whole-number values use integer datatypes because fractional values would not make sense.
- Longer content such as announcements, feedback comments, agenda descriptions, material descriptions, notification messages, and resource descriptions can use longer text fields because their length is less predictable than names or codes.
- Boolean or yes/no style values, if used, should be stored with a boolean/tiny integer datatype instead of text values such as `yes` and `no`.

Overall, the schema avoids choosing `TEXT` or oversized `VARCHAR` fields for everything. Small predictable values, such as first names, can be stored in smaller fields like `VARCHAR(20)`, while emails, titles, messages, and descriptions use larger datatypes because their valid values are naturally longer. This makes the database more reliable, easier to validate, and more efficient for searching and joining tables.

## Core People And Accounts

- `Department`: Stores organizational departments. It is the parent for `AcademicProgram` and `Organizer`.
- `AcademicProgram`: Stores degree programs such as Bachelor or Master programs. Each program belongs to one department.
- `Student`: Stores student profile data. Each student belongs to one academic program.
- `StudentAddress`: Stores one or more addresses for a student, such as home, mailing, or temporary.
- `Organizer`: Stores staff/faculty organizers. Each organizer belongs to one department.
- `Speaker`: Stores external or internal speakers who can present sessions.
- `UserRole`: Defines account roles, such as Student, Organizer, Speaker, or Admin.
- `UserAccount`: Stores database-backed login accounts. A user account has one role and can link to a student, organizer, or speaker record.
- `LoginHistory`: Audit log for account login attempts. Each row belongs to one `UserAccount`.

## Events

- `EventCategory`: Lookup table for event categories.
- `EventStatus`: Lookup table for event states, such as planned, active, completed, or cancelled.
- `Venue`: Stores event locations and capacity information.
- `Event`: Main event table. Each event has a category, organizer, venue, status, capacity, dates, and fee.
- `EventSchedule`: Stores high-level scheduled date/time blocks for an event.
- `EventAgenda`: Stores ordered agenda items for an event.
- `EventAnnouncement`: Stores announcements/messages for an event.
- `EventTag`: Stores reusable labels for event discovery.
- `EventTagMapping`: Bridge table for the many-to-many relationship between `Event` and `EventTag`.

## Rooms And Sessions

- `RoomType`: Lookup table for room categories.
- `Room`: Stores rooms inside venues. Each room belongs to one venue and one room type.
- `RoomEquipment`: Stores equipment available in a room.
- `SessionType`: Lookup table for session categories, such as keynote, workshop, or panel.
- `Session`: Stores event sessions. Each session belongs to one event, one room, and one session type.
- `SessionSpeaker`: Bridge table for the many-to-many relationship between `Session` and `Speaker`.
- `RoomBooking`: Stores reservations that connect a room to a session at a specific date/time.
- `SessionMaterial`: Stores uploaded files for a session.
- `SessionResource`: Stores external links or resources for a session.

## Registration, Attendance, And Tickets

- `RegistrationStatus`: Lookup table for registration states.
- `Registration`: Connects a student to an event. This is the key transaction table for event enrollment.
- `Waitlist`: Stores students waiting for a full event. It links a student and event with a waitlist position.
- `CancellationRequest`: Stores cancellation requests for registrations.
- `AttendanceCheckIn`: Stores event-level check-ins tied to registrations.
- `SessionAttendance`: Stores attendance for individual sessions by student.
- `TicketType`: Lookup table for ticket types and prices.
- `Ticket`: Stores the ticket/QR code generated for a registration.

## Payments And Refunds

- `PaymentMethod`: Lookup table for payment methods.
- `Payment`: Stores payment records for registrations, including amount, status, and transaction reference.
- `Refund`: Stores refunds connected to payments.

## Feedback And Certificates

- `FeedbackType`: Lookup table for event feedback categories.
- `Feedback`: Stores student feedback for whole events.
- `SessionFeedback`: Stores student feedback for individual sessions.
- `CertificateTemplate`: Stores reusable certificate templates.
- `Certificate`: Stores issued certificates. Each certificate belongs to one registration and one template.

## Notifications

- `NotificationType`: Lookup table for notification categories.
- `Notification`: Stores messages sent to user accounts.

## Reporting Views

- `AttendanceSummary`: Summarizes attendance count by session.
- `EventRegistrationSummary`: Summarizes registration count by event.
- `RevenueSummary`: Summarizes completed payment revenue by event.
- `SessionFeedbackSummary`: Summarizes average rating and feedback count by session.
- `StudentCertificates`: Shows student certificate details in a report-friendly form.

## Main Relationship Patterns

- One `Department` has many `AcademicProgram` records.
- One `Department` has many `Organizer` records.
- One `AcademicProgram` has many `Student` records.
- One `Student` can have many `StudentAddress`, `Registration`, `Feedback`, `SessionAttendance`, `SessionFeedback`, and `Waitlist` records.
- One `Organizer` can manage many `Event` records.
- One `Venue` can host many `Event` records and contain many `Room` records.
- One `EventCategory` can classify many `Event` records.
- One `EventStatus` can be used by many `Event` records.
- One `Event` can have many `Registration`, `Session`, `EventSchedule`, `EventAgenda`, `EventAnnouncement`, `Feedback`, `Waitlist`, and `EventTagMapping` records.
- One `Registration` can have one `Ticket`, one `Certificate`, many `Payment` records, many `AttendanceCheckIn` records, and many `CancellationRequest` records.
- One `Payment` can have many `Refund` records.
- One `RoomType` can describe many `Room` records.
- One `Room` can have many `Session`, `RoomBooking`, and `RoomEquipment` records.
- One `SessionType` can describe many `Session` records.
- One `Session` can have many `SessionAttendance`, `SessionFeedback`, `SessionMaterial`, `SessionResource`, `RoomBooking`, and `SessionSpeaker` records.
- `SessionSpeaker` makes `Session` and `Speaker` a many-to-many relationship.
- `EventTagMapping` makes `Event` and `EventTag` a many-to-many relationship.
- One `UserRole` can be assigned to many `UserAccount` records.
- One `UserAccount` can have many `LoginHistory` and `Notification` records.
- One `NotificationType` can classify many `Notification` records.

## How The Flask App Uses The Database

- The normal student, organizer, and admin dashboards use the operational tables for events, registrations, payments, sessions, certificates, reports, and notifications.
- Login now checks `UserAccount` and `UserRole` first and records attempts in `LoginHistory`. The original demo users still work because the current sample `UserAccount.password_hash` values are placeholders, not real Werkzeug password hashes.
- Admins can open **Schema Explorer** to browse every table and view, inspect columns, see incoming and outgoing relationships, and preview rows.
- The app calls the stored procedures `RegisterStudentForEvent` and `GenerateCertificate` for registration and certificate workflows.
