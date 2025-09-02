-- Library Management System Project 2



--create database Library_P2

GO 

use Library_P2

/*CREATING TABLE*/

-- creating branch table

DROP TABLE IF EXISTS branch

create table branch (
branch_id varchar(10) PRIMARY KEY
,manager_id varchar(10)
,branch_address varchar(255)
,contact_no varchar(10)
)

ALTER TABLE branch
ALTER COLUMN contact_no varchar(20)

--select * from branch

-- create employee table

drop table if exists employee

create table employee(
emp_id varchar(10) PRIMARY KEY
,emp_name varchar(25)
,position varchar(15)
,salary int
,branch_id varchar(10)
)


-- create books table

drop table if exists books

create table books (
isbn varchar(20) PRIMARY KEY
,book_title varchar(80)
,category varchar(10)
,rental_price float
,status varchar(15)
,author varchar(50)
,publisher varchar(55)
)

ALTER TABLE books
ALTER COLUMN category varchar(20)

-- create members table

DROP TABLE IF EXISTS members

create table members(
member_id varchar(20) PRIMARY KEY
,member_name varchar(25)
,member_address varchar(75)
,reg_date date
)

-- create issued_status table

DROP TABLE IF EXISTS issued_status

create table issued_status(
issued_id varchar(10) PRIMARY KEY
,issued_member_id varchar(20)
,issued_book_name varchar(75)
,issued_date date
,issued_book_isbn varchar(20)
,issued_emp_id varchar(10)
)


-- create return_status table

DROP TABLE IF EXISTS return_status

create table return_status(
return_id varchar(10) PRIMARY KEY
,issued_id varchar(10)
,return_book_name varchar(75)
,return_date date
,return_book_isbn varchar(20)
)

-- ADDING CONSTRAINTS

ALTER TABLE issued_status 
ADD CONSTRAINT fk_members
FOREIGN KEY (issued_member_id)
REFERENCES members(member_id)

ALTER TABLE issued_status 
ADD CONSTRAINT fk_books
FOREIGN KEY (issued_book_isbn)
REFERENCES books(isbn)

ALTER TABLE issued_status 
ADD CONSTRAINT fk_employee
FOREIGN KEY (issued_emp_id)
REFERENCES employee(emp_id)

ALTER TABLE employee
ADD CONSTRAINT fk_branch
FOREIGN KEY (branch_id)
REFERENCES branch(branch_id)

ALTER TABLE return_status
ADD CONSTRAINT fk_issued
FOREIGN KEY (issued_id)
REFERENCES issued_status(issued_id)

ALTER TABLE return_status
ADD CONSTRAINT fk_return_books
FOREIGN KEY (return_book_isbn)
REFERENCES books(isbn)


select * from books
select * from branch
select * from employee
select * from issued_status
select * from members
select * from return_status

-- Project TASK

-- ### 2. CRUD Operations

-- Task 1. Create a New Book Record
-- "978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.')"

insert into books(isbn,book_title,category,rental_price,status,author,publisher)
values ('978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.')

-- Task 2: Update an Existing Member's Address

update members
set member_address='125 Main St'
where member_id='C101'

-- Task 3: Delete a Record from the Issued Status Table
-- Objective: Delete the record with issued_id = 'IS121' from the issued_status table.

delete from issued_status where issued_id='IS121'

-- Task 4: Retrieve All Books Issued by a Specific Employee
-- Objective: Select all books issued by the employee with emp_id = 'E101'.

select * from issued_status where issued_emp_id='E101'

-- Task 5: List Members Who Have Issued More Than One Book
-- Objective: Use GROUP BY to find members who have issued more than one book.

select issued_emp_id,COUNT(issued_id) as no_of_issued from issued_status 
group by issued_emp_id
having COUNT(issued_id)>1

-- ### 3. CTAS (Create Table As Select)

-- Task 6: Create Summary Tables**: 
-- Used CTAS to generate new tables based on query results 
-- each book and total book_issued_cnt


select b.isbn,b.book_title
,COUNT(ist.issued_id) as no_issued
into book_counts
from books b
JOIN issued_status ist ON ist.issued_book_isbn=b.isbn
group by b.isbn,b.book_title

select * from book_counts

-- ### 4. Data Analysis & Findings

-- Task 7. **Retrieve All Books in a Specific Category:

select * from books where category='Classic'

-- Task 8: Find Total Rental Income by Category:

select b.category,SUM(b.rental_price) total_rental,COUNT(1) as number_od_times 
from books b
JOIN issued_status ist ON ist.issued_book_isbn=b.isbn
group by category

-- Task 9. **List Members Who Registered in the Last 180 Days**:

insert into members(member_id,member_address,member_name,reg_date)
values('C120','James','202 James St','2025-09-01'),
('C121','Brandon','195 Smith St','2025-08-30')

select * from members 
where reg_date>dateadd(MONTH,-6,GETDATE())

-- Task 10: List Employees with Their Branch Manager's Name and their branch details**:

select e.emp_name,e.position,e.salary
,m.emp_name as manager
,b.branch_address,contact_no from employee e
INNER JOIN branch b ON e.branch_id=b.branch_id
INNER JOIN employee m ON b.manager_id=m.emp_id

-- Task 11. Create a Table of Books with Rental Price Above a Certain Threshold (Eg . $7.00)

select * 
into books_ct
from books where rental_price>7

select * from books_ct

-- Task 12: Retrieve the List of Books Not Yet Returned

select * from books

select distinct i.issued_book_isbn,i.issued_book_name 
from issued_status i
LEFT JOIN return_status r ON i.issued_id=r.issued_id
where r.return_id is null

/*
### Advanced SQL Operations

Task 13: Identify Members with Overdue Books
Write a query to identify members who have overdue books (assume a 30-day return period). Display the member's name, book title, issue date, and days overdue.
*/

select member_name,b.book_title,issued_date,DATEDIFF(DAY,issued_date,ISNULL(return_date,GETDATE())) as days_overdue
from issued_status ist
JOIN members m ON ist.issued_member_id=m.member_id
JOIN books b ON b.isbn=ist.issued_book_isbn
LEFT JOIN return_status rs ON rs.issued_id=ist.issued_id
where DATEDIFF(DAY,issued_date,ISNULL(return_date,GETDATE()))>30 and return_id is null

/*
Task 14: Update Book Status on Return
Write a query to update the status of books in the books table to "available" 
when they are returned (based on entries in the return_status table).
*/
GO 

create or alter procedure add_return_records 
@p_return_id varchar(10),
@p_issued_id varchar(10),
@p_book_quality varchar(25)
AS
BEGIN

	-- inserting return books by user/member
	insert into return_status(return_id,issued_id,return_date,book_quality)
	values(@p_return_id,@p_issued_id,getdate(),@p_book_quality)

	declare @v_isbn varchar(20)
	, @v_bookname varchar(80)

	select @v_isbn=issued_book_isbn,@v_bookname=issued_book_name from issued_status where issued_id=@p_issued_id

	update books
	set status='yes'
	where isbn=@v_isbn

	PRINT('Thank you for returning the'+@v_bookname)

END

GO 

select * from books where isbn='978-0-307-58837-1'
select * from issued_status where issued_book_isbn='978-0-307-58837-1'
select * from return_status where return_book_isbn='978-0-307-58837-1' or issued_id='IS135'

--'IS135','RS119','978-0-307-58837-1'

-- Testing Stored Procedure
exec add_return_records 'RS119','IS135','Good'

/*
Task 15: Branch Performance Report
Create a query that generates a performance report for each branch, showing the number of books issued
, the number of books returned, and the total revenue generated from book rentals.
*/

DROP TABLE IF EXISTS branch_report
select b.branch_id,b.branch_address 
,COUNT(ist.issued_id) no_of_books_issued
,COUNT(rs.return_id) no_of_books_retunred
,SUM(bo.rental_price) as total_revenue
into branch_report
from branch b
JOIN employee e ON b.branch_id=e.branch_id
JOIN issued_status ist ON ist.issued_emp_id=e.emp_id
JOIN books bo ON bo.isbn=ist.issued_book_isbn
LEFT JOIN return_status rs ON rs.issued_id=ist.issued_id
group by b.branch_id,b.branch_address

select * from branch_report

--select * from employee
select * from return_status
select * from issued_status

/*
Task 16: CTAS: Create a Table of Active Members
Use the CREATE TABLE AS (CTAS) statement to create a new table active_members containing members 
who have issued at least one book in the last 6 months.
*/


drop table if exists active_members

select * 
into active_members
from members where member_id IN (
select distinct issued_member_id from issued_status
where issued_date >= DATEADD(MONTH,-6,GETDATE())
)

select * from active_members


/*
Task 17: Find Employees with the Most Book Issues Processed
Write a query to find the top 3 employees who have processed the most book issues. 
Display the employee name, number of books processed, and their branch.
*/


select  
	e.emp_name,
	b.branch_id,
	b.branch_address,
	COUNT(ist.issued_id) as no_of_books_processed
from issued_status ist 
JOIN employee e oN e.emp_id=ist.issued_emp_id
JOIN branch b ON b.branch_id=e.branch_id
group by e.emp_name,
	b.branch_id,
	b.branch_address


/*
Task 18: Identify Members Issuing High-Risk Books
Write a query to identify members who have issued books more than twice with the status "damaged" 
in the books table. Display the member name, book title, and the number of times they've issued damaged books.    
*/

--select * from issued_status
select m.member_name,ist.issued_book_name,COUNT(1) as no_times_books_damaged from return_status rs
JOIN issued_status ist ON rs.issued_id=ist.issued_id
JOIN members m ON m.member_id=ist.issued_member_id
where rs.book_quality='Damaged'
GROUP BY m.member_name,ist.issued_book_name



/*

Task 19: Stored Procedure
Objective: Create a stored procedure to manage the status of books in a library system.
    Description: Write a stored procedure that updates the status of a book based on its issuance or return. 
	Specifically:
    If a book is issued, the status should change to 'no'.
    If a book is returned, the status should change to 'yes'.
*/

--select * from books

--select * from issued_status

GO

create or alter procedure issue_book
@issued_id varchar(10)
, @issued_member_id varchar(10)
, @issued_book_isbn varchar(20)
, @issued_emp_id varchar(10)
AS
BEGIN

-- checking if book is available

declare @status varchar(10),
@bookname varchar(50)

select @status=status,@bookname=book_title from books where isbn=@issued_book_isbn

--select @status

	if @status='yes'
		BEGIN
			insert into issued_status(issued_id,issued_member_id,issued_book_isbn,issued_date,issued_emp_id,issued_book_name)
			VALUES(@issued_id,@issued_member_id,@issued_book_isbn,GETDATE(),@issued_emp_id,@bookname)

			PRINT('1 Book record added successfully for '+@bookname)

			update books
			set status='no'
			where isbn=@issued_book_isbn

		END
	Else 
		BEGIN

			PRINT('Sorry to inform that the book is unavailable currently!')

		END
END



-- 978-0-553-29698-2 'yes' -->> 'no'
-- 978-0-375-41398-8 'no'
exec issue_book 'IS155','C108','978-0-553-29698-2','E104'
exec issue_book 'IS156','C108','978-0-375-41398-8','E104'
exec issue_book 'IS157','C108','978-0-553-29698-2','E104'

GO


/*
Task 20: Create Table As Select (CTAS)
Objective: Create a CTAS (Create Table As Select) query to identify overdue books and calculate fines.

Description: Write a CTAS query to create a new table that lists each member and 
			the books they have issued but not returned within 30 days. The table should include:
    The number of overdue books.
    The total fines, with each day's fine calculated at $0.50.
    The number of books issued by each member.
    The resulting table should show:
    Member ID
    Number of overdue books
    Total fines
*/

