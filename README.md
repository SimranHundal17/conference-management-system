# Conference Management System

A Flask and MySQL application for managing conference events, registrations, sessions, attendance, payments, feedback, and certificates. It includes role-based interfaces for administrators, organizers, and students, along with a normalized relational schema and reporting features.

## Features

- Role-based dashboards for administrators, organizers, and students
- Event discovery and registration, waitlists, schedules, and attendance tracking
- Session and speaker management, room bookings, and event resources
- Payment and refund workflows, feedback, notifications, and certificates
- MySQL views, indexes, stored procedures, triggers, and reporting queries
- Responsive Bootstrap interface

## Technology

- Python and Flask
- MySQL 8
- `mysql-connector-python`
- Bootstrap 5

## Getting started

### 1. Set up the application

Create and activate a virtual environment, then install the dependencies:

```powershell
python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

On macOS or Linux, activate the environment with:

```bash
source .venv/bin/activate
```

### 2. Configure MySQL

Create and populate the database by running the SQL scripts in order with MySQL Workbench or the MySQL command-line client:

1. `database/01_CreateTables.sql`
2. `database/02_InsertData.sql`
3. `database/03_Views.sql`
4. `database/04_Indexes.sql`
5. `database/05_Roles.sql`
6. `database/06_StoredProcedures.sql`
7. `database/07_Triggers.sql`
8. `database/08_Queries.sql` (example queries)

The first script creates the `conference_management_system` database. The scripts contain sample records for local exploration.

Set the connection settings in the shell where you will run the application. For example, in PowerShell:

```powershell
$env:MYSQL_HOST = "localhost"
$env:MYSQL_PORT = "3306"
$env:MYSQL_USER = "root"
$env:MYSQL_PASSWORD = "your-local-mysql-password"
$env:MYSQL_DATABASE = "conference_management_system"
$env:SECRET_KEY = "replace-with-a-long-random-value"
```

The app reads these variables from the environment. `SECRET_KEY` has a development-only fallback; configure a unique, strong value for any deployment. Do not commit credentials or production secrets.

### 3. Run the application

```powershell
python app.py
```

Open `http://127.0.0.1:5000` in a browser. The application needs a reachable MySQL database with the scripts above applied.

## Local demo accounts

The application includes these demonstration logins:

| Role | Username | Password |
| --- | --- | --- |
| Administrator | `admin` | `admin123` |
| Organizer | `organizer` | `organizer123` |
| Student | `student` | `student123` |

These accounts are for local demonstration only. Replace or disable them and configure production-grade authentication before deploying the application.

## Database design

The schema covers users and academic programs, events, venues and rooms, sessions, registrations, attendance, tickets, payments, refunds, feedback, certificates, and notifications. See [the database schema guide](docs/database-schema.md) and the [entity-relationship diagram](docs/diagrams/ERD_Complete.pdf).

## Project layout

```text
.
├── app.py
├── config.py
├── db.py
├── database/          # Schema, sample data, views, indexes, routines, and queries
├── docs/              # Database notes and ER diagram
├── routes/            # Flask blueprints
├── scripts/           # Optional database-backed readiness checks
├── static/
└── templates/
```

## Checks

`scripts/run_readiness_tests.py` exercises the application against a configured MySQL database and creates test records with an `AUTO_TEST_DEMO_` prefix. Run it only against a development database whose data can be modified.
