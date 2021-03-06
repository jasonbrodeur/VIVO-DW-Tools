
Address for UTS Ticket reporting (to be used to report data issues, such as missing MacIDs):
https://macservicedesk.mcmaster.ca/splash/

Task List (20170430)
- Check new DW extract for errors -- incorporate fixes into processing script (+lookup table)
- Develop initials for all users
- refine the SE HR import data script to include secondary positions as auto groups
- For the ~36 individuals with cross-appointments, select the first as primary and the rest as secondary
- 

Notes (20170430)
- FSS profile pages include personal email address (e.g. Jim Gladstone)--might want to let them know that this is personal information and should be removed.


=============================

Update (20170423)
Task list: 
- Email DW folks to inquire about: 
> Title (Prof. Dr. Ms. Mr. Mrs. etc.)
> Initials--First and middle(e.g. JJ Brodeur)
> Known As (individuals' most commonly used first name)
> Suffix (e.g. OC, PEng, GISP, CPA, etc.)
> 

Notes from the User Groups article:
- each user is an explicit member of ONLY ONE Primary Group (for us, this will be faculties, I believe)
--(if no Primary Group is assigned, then users wil be assigned to the top-level organization group
- Explicit membership of an Auto Group is based on a specified query against one or more of the user's HR generic fields.
--primarily used for purposes of reporting and user management. (for us, this will be departments (
- 
Questions from the User Groups article:
- In the HR import file we have a field for "Department". Is the information in this field used (or could it be used) to assign Auto Groups to an individual? For example, if J. Smith has a primary appointment of Professor in the department of Mathematics and Statistics, will indicating this in the "Department" field register them in the Auto Group for this department? 



Update (20170420)
A first draft of the HR data file to review can be found in the file VIVO_Secure_Data/03_Processed_For_Elements/Elements_HR.csv
- The 36 individuals who do not have a clear primary appointment.
- The lack of Title, Known As, etc. etc.
- There may be errors with selecting the primary position for individuals, and this is going to be difficult to figure out unless people go through the data closely.
- A number of people in the data warehouse feed don't have MAC IDs -- I have a list of the individuals, and we'll need to think about how to deal with this moving forward.
- It's unclear how we might be able to add second, third, etc. appointments to the HR data feed. I'll inquire with the symplectic folks on this point tomorrow. 
- Still a bit of inconsistency with the Position titles -- FHS uses "xxxx xxxx (Adjunct)" while other faculties use "Adjunct xxxx xxxx". 



Data work to do:

1) Additional Cleanup
- Remove redundant entries in faculty sheet (e.g. Susan Robinson)
-- look for matching strings for:
--- Position title
--- Faculty
--- Department
--- > idea: can we make a hash out of these three columns and then just compare hashes?
-- if more than one match still remains:
--- take the entry with mcmaster email
--- take the first of the remaining entries
- Think we can remove WORK/STUDY STUDENT entries

2)  


3) Potential issues:
- Randall Jackson has two "Lecturer" appointments
- Still lots of blanks in 'department' field -- are these getting dropped by the cleaning algorithm?
-- I think we may need to change the script so that it just adds missing items to the lookup table

4) Other questions:
- Some departments seem to have a 'director' listed
-- e.g. Ram Mishra is listed as the 'director'
- or maybe all departments use this designation
- take a look at Susan McCracken's entry -- duplicates but one lacks a Department designation

- Alison McQueen -- listed as director of 'school of the arts', but also professor in History
-- is School of the Arts something different than a department??
-- no, I don't think so -- I think it's the same thing

- People can have cross-appointments show up 
-- e.g. Christopher Myhr is SoTA and CSMM
-- e.g. Lori Campbell is Associate Professor in Sociology and Health, Aging & Society (indestinguishable)

Lookup table for unit_type variable:
1 = dept
2 = inst
3 = centre
4 = admin
5 = chair
0 = other