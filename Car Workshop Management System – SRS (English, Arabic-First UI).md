# Car Workshop Management System – Software Requirements Specification (SRS)

## 1. Introduction

### 1.1 Purpose
The purpose of this document is to define the complete Software Requirements Specification (SRS) for a Car Workshop Management System that centralizes and automates all operational and light accounting workflows for an automotive repair center (workshop). The system covers front-desk reception, job cards, technicians’ work, parts inventory, invoicing, customer and supplier accounts, and basic CRM features in a single integrated solution.[^1][^2]

### 1.2 Primary UI Language (Critical Requirement)
The **primary language of the application’s user interface is Arabic**. All screens, labels, menus, notifications, printed documents, and reports must be available in Arabic by default.
- English may be supported as a secondary language in the future (multi-language capability), but **Arabic is mandatory and must be considered the default UI language**.
- Data such as customer names, vehicle details, and notes may be entered in Arabic or English, but system labels and flows must be designed Arabic-first (including right-to-left layout where applicable).[^3][^1]

### 1.3 Scope
The system will provide:
- Customer and vehicle management (simple CRM).
- Supplier and purchasing management.
- Job card (work order) management and diagnostic workflows.
- Appointment scheduling and workshop calendar.
- Parts inventory and stock movements.
- Invoicing and POS with automatic accounting posting.
- Customer account statements (AR sub-ledger).
- Supplier account statements (AP sub-ledger).
- Staff and role-based access control.
- Notifications, reminders, and basic marketing features (later phase).[^2][^4][^5][^1]

### 1.4 Intended Users
- Workshop owner / manager.
- Reception / service advisor.
- Technicians (mechanical, electrical, body shop, etc.).
- Storekeeper / parts manager.
- Accountant / finance officer.
- System administrator / IT manager.[^1][^3]

### 1.5 Definitions and Acronyms
- **Job Card / Work Order**: A document representing work to be performed on a specific vehicle.
- **CRM**: Customer Relationship Management.
- **AR Ledger**: Accounts Receivable sub-ledger (customer account card).
- **AP Ledger**: Accounts Payable sub-ledger (supplier account card).
- **POS**: Point of Sale (invoicing screen).
- **Appointment**: Scheduled time slot for a vehicle service.[^5][^3]

***

## 2. Overall Description

### 2.1 System Perspective
The Car Workshop Management System is a multi-user, role-based web/desktop/mobile application used internally by the workshop staff. It acts as the main operational system that connects reception, technicians, parts store, and accounting in one workflow, with optional integration to external accounting or communication tools in future phases.[^2][^1]

### 2.2 Main Modules
- Customers & Vehicles (CRM).
- Suppliers & Purchases.
- Job Cards & Diagnostics.
- Appointments & Calendar.
- Parts & Inventory Management.
- Invoicing & POS.
- Customer Account Cards (AR sub-ledger).
- Supplier Account Cards (AP sub-ledger).
- Staff & Permissions.
- Notifications & Marketing.[^4][^1][^2]

### 2.3 User Classes and Roles
- **Admin / Owner**: Full access to all modules, configuration, and reports.
- **Reception / Sales**: Manage customers and vehicles, open job cards, create invoices from reception.
- **Technician**: View assigned jobs, update task statuses, add findings and notes.
- **Storekeeper**: Manage parts master data and stock movements, receive purchases.
- **Accountant**: Review and post invoices, manage AR/AP ledgers and financial reports.
- **Marketing / CRM (optional)**: Manage reminders and campaigns.[^6][^3][^1]

***

## 3. Functional Requirements

### 3.1 Customers & Vehicles (CRM)

#### 3.1.1 Manage Customers
- The system shall allow adding a new customer with at least: name, mobile number, email (optional), address, customer type (cash / credit), optional credit limit, and notes.
- The system shall allow editing customer details and maintain a log for critical changes (e.g., credit limit change).
- The system shall not allow deleting customers who have financial transactions; instead, it shall support deactivation.

#### 3.1.2 Manage Vehicles
- The system shall allow linking multiple vehicles to a single customer.
- For each vehicle, the system shall store: plate number, chassis number, make, model, year, color, current odometer reading, and notes.
- The system shall display service history for each vehicle (all related job cards and invoices).[^7][^1]

#### 3.1.3 Interaction History
- The system shall allow adding notes for interactions with the customer (calls, visits, complaints) with date/time and user who added the note.[^3]

***

### 3.2 Suppliers & Purchases

#### 3.2.1 Manage Suppliers
- The system shall allow adding suppliers with contact information, address, payment terms (cash / credit with period), and notes.
- The system shall allow editing supplier data and prevent deletion if financial transactions exist (use deactivation instead).[^8][^4]

#### 3.2.2 Supplier Invoices
- The system shall allow creating a supplier invoice with: invoice date, external reference number, supplier, line items (parts/services), quantities, purchase prices, taxes, and totals.
- Supplier invoices that include parts must generate incoming stock movements into the selected store/warehouse.[^4][^8]

#### 3.2.3 Supplier Payments
- The system shall allow recording payments to suppliers (cash, transfer, cheque, etc.) and allocate them to specific invoices or as on-account payments.
- Supplier payments shall update the supplier account card (AP ledger) automatically.[^5][^4]

***

### 3.3 Job Cards & Diagnostics

#### 3.3.1 Create Job Card
- From the reception screen, the user shall be able to:
  - Select an existing customer or create a new one.
  - Select an existing vehicle for that customer or create a new vehicle.
  - Enter the customer complaint/request (e.g., noise in suspension, periodic service, accident repair).
  - Capture vehicle condition on arrival (external/internal condition, fuel level, existing scratches), with ability to attach photos.
  - Enter current odometer reading.
- The system shall create a job card with an initial status (e.g., "Under Inspection").[^1][^2]

#### 3.3.2 Job Tasks and Parts
- The system shall allow adding multiple labor tasks under each job card with: description, service type (mechanical/electrical/body/etc.), assigned technician, estimated time, and labor price.
- The system shall allow assigning parts to the job card by selecting from inventory, with quantity and selling price for each part.
- The system may support predefined templates for common periodic services (optional).[^7][^2]

#### 3.3.3 Job Status Workflow
- The system shall support at least the following statuses: New, Under Inspection, Waiting for Customer Approval, In Progress, Waiting for Parts, Completed, Delivered.
- Every status change shall be logged with timestamp and user.
- The system may send notifications to the customer when specific status changes occur (e.g., job completed and vehicle ready for pickup).[^3][^2]

#### 3.3.4 Technician Time Tracking
- The system shall allow logging start and end times for each task per technician (manual buttons or equivalent).
- Time tracking data shall be used for productivity analysis and to estimate labor cost per job (later reporting).[^6][^2]

***

### 3.4 Appointments & Calendar

#### 3.4.1 Create Service Appointment
- The system shall allow creating service appointments with date and time, preliminary service type, and linking to a customer and vehicle.
- Appointments may optionally be linked to a specific bay or technician.

#### 3.4.2 Workshop Calendar
- The system shall provide a daily/weekly calendar view showing scheduled appointments and open job cards.
- The system shall visually differentiate appointment statuses (confirmed, arrived, cancelled).[^9][^2]

#### 3.4.3 Appointment Reminders
- The system shall support automatic reminders to customers before their appointments (configurable lead time, e.g., 24 hours).
- The system shall support internal reminders to reception or technicians for upcoming appointments.[^1][^3]

***

### 3.5 Parts & Inventory Management

#### 3.5.1 Parts Master Data
- The system shall allow defining parts with at least: item code, name, category, brand, compatible models, minimum stock level, unit of measure, default purchase price, default selling price, and target margin.
- The system shall support multiple storage locations (main store, sub-store, shelf locations).[^8][^1]

#### 3.5.2 Stock Movements
- The system shall record stock movements for:
  - Goods receipt from supplier invoices.
  - Issue to job cards.
  - Returns from job cards.
  - Inventory adjustments (stock count differences).
- Stock quantities shall be updated in real time.
- The system shall generate alerts when stock falls below minimum levels.[^5][^8][^1]

#### 3.5.3 Inventory Valuation
- The system shall support a basic inventory valuation method (e.g., weighted average or FIFO) for use in financial reports in a later phase.[^8]

***

### 3.6 Invoicing, POS, and Accounting Integration

#### 3.6.1 Invoice Creation from Reception
- From a job card, the reception user shall be able to click "Complete & Generate Invoice".
- The system shall convert job tasks and parts into invoice line items automatically.
- The system shall automatically calculate:
  - Total labor value.
  - Total parts value.
  - Discounts (per line or overall invoice).
  - Taxes based on configured tax rules.
  - Net amount due from the customer.
- The user shall select payment method: cash, card, bank transfer, e-wallet, or credit (on account).[^2][^7][^1]

#### 3.6.2 Invoice Flow from Reception to Accounting
- On saving the invoice, it shall be stored with status `pending_accounting`.
- The invoice shall appear in the accounting screen under "Invoices pending review".
- The accountant shall not re-enter invoice data; all amounts must come from the reception-generated invoice.

#### 3.6.3 Posting (Accounting) of Invoices
- When the accountant reviews and clicks "Post", the system shall:
  - Change invoice status to `posted`.
  - Generate accounting entries automatically (sales, taxes, cash/bank or accounts receivable).
  - Create a movement in the customer account card (AR ledger) if the invoice is on credit.
- Editing a posted invoice should be restricted; corrections shall be through credit notes or adjustment documents.[^2][^5]

#### 3.6.4 Payment Management
- The system shall allow recording payments against invoices with payment type, date, amount, and reference.
- The system shall support partial payments for a single invoice.
- The system shall allow allocating one payment to multiple invoices (bulk collection).[^5][^1]

***

### 3.7 Customer Account Cards (AR Ledger)

#### 3.7.1 Automatic Ledger Entries
- When a credit invoice is posted, the system shall create a debit entry in `customer_ledger` for that customer.
- When a payment is recorded, the system shall create a credit entry in `customer_ledger` and optionally allocate it to specific invoices or leave it as on-account.
- The system shall maintain a running balance after each entry.[^10][^5]

#### 3.7.2 Customer Account Statement Screen
- The system shall display all movements for a customer in chronological order with:
  - Transaction type (invoice, payment, discount, adjustment).
  - Date.
  - Reference (invoice/receipt number).
  - Debit/credit amount.
  - Balance after transaction.
- The user shall be able to filter by date range and print or export a statement (PDF/Excel).[^10][^5]

#### 3.7.3 Aging Report
- The system shall provide an aging report for customer balances (0–30 days, 30–60, 60–90, >90 days).
- This report shall help monitor overdue receivables and manage credit risk.[^10][^5]

***

### 3.8 Supplier Account Cards (AP Ledger)

#### 3.8.1 Automatic AP Entries
- When a supplier invoice is saved, the system shall create a credit entry for the supplier in `ap_transactions`.
- When a payment is made to a supplier, the system shall create a debit entry and allow allocation to specific

---

## References

1. [#1 Auto Repair Software | ARI | Best Value for Money](https://ari.app) - Avoid missing unpaid repair invoices and eliminate payment delays by tracking all your expenses and ...

2. [Auto Repair POS System & Payments Software - autoGMS](https://myautogms.com/auto-repair-accounting-financial-reporting) - Use one automotive point of sale and finance workflow to collect payments, manage deposits, track cr...

3. [Best Auto Repair CRMs for Managing Clients, Jobs & Workflows](https://noloco.io/blog/best-auto-repair-crm) - An auto repair CRM ties together customers, vehicles, job statuses, estimates, and approvals so advi...

4. [Car Workshop Accounting System: Enhancing the Performance of ...](https://sparktech.sa/en/car-workshop-accounting-system-enhancing-the-performance-of-auto-workshops-in-an-integrated-manne/) - This accounting system enables tracking customer accounts statements and issuing accounting statemen...

5. [Automotive Repair Shop Accounting Sub-Ledgers - FastTrak](https://fasttrakauto.com/2023/08/29/automotive-repair-shop-accounting-sub-ledgers/) - Charges and payments are posted in the subledger and the summary of the balance is kept at the gener...

6. [Best Accounting Software For Auto Repair Companies - HelloBooks.ai](https://hellobooks.ai/blog/best-accounting-software-for-auto-repair-companies) - Practical guide to choosing accounting software for auto repair shops, covering job costing, invento...

7. [Expert Guide to Automotive Accounting for Repair Shop Success](https://www.taxfyle.com/blog/automotive-accounting) - Detailed Invoices: For every repair job, create detailed invoices that include the customer's inform...

8. [Bookkeeping For Auto Repair Shops: Best Practices | BooksTime](https://www.bookstime.com/articles/bookkeeping-for-auto-repair-shops) - One of the basic accounting approaches in auto shops is a detailed entry of all invoices and bills g...

9. [Auto Repair Software - Prices & Reviews - Capterra](https://www.capterra.ae/directory/20006/auto-repair/software) - Auto repair shop management tool that streamlines operations, including customizable workflows for m...

10. [Top 5 Accounting Software For Auto Repair Shops - Hoops & Gears](https://hgautotech.com/top-accounting-software-for-auto-repair-shops/) - Simplify your operations by integrating auto repair accounting software into your business suite. He...

