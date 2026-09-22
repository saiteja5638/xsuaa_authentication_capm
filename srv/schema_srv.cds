using schema from '../db/schema';

service BusinessService {



     @restrict: [
        {
            grant: 'READ',
            to: 'READPROD'
        },
        {
            grant: ['READ', 'UPDATE'],
            to: 'Auditor'
        },
        {
            grant: ['READ', 'CREATE', 'UPDATE'],
            to: 'SuperAuditor'
        }
    ]
    entity AdminConfigurations as projection on schema.AdminConfiguration;

    @requires: 'ADMIN'
    entity Users               as projection on schema.Users;
    entity Roles               as projection on schema.Roles;
    entity Products            as projection on schema.Products;
    entity UserRoleAssignment            as projection on schema.UserRoleAssignment;
    entity WarehouseLocations  as projection on schema.WarehouseLocations;
    entity Customers           as projection on schema.Customers;
    entity Employees           as projection on schema.Employees;
    entity EmployeeLeaves      as projection on schema.EmployeeLeaves;
    entity EmployeePayroll     as projection on schema.EmployeePayroll;
    entity PurchaseOrders      as projection on schema.PurchaseOrders;
    entity PurchaseOrderItems  as projection on schema.PurchaseOrderItems;


    entity Employees1  as projection on schema.Employees1;
    entity Departments  as projection on schema.Departments;


   entity books  as projection on schema.books;
     entity Author  as projection on schema.Author;

}