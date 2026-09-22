using {
    cuid,
    managed
} from '@sap/cds/common';

context schema {

    // -------------------------------------------------------------------
    // 1. Admin Configuration
    // -------------------------------------------------------------------
    entity AdminConfiguration : cuid, managed {
        configKey   : String(50) @assert.unique;
        configValue : String(255);
        description : String(255);
        isSystem    : Boolean default false;
    }

    // -------------------------------------------------------------------
    // 2. User Access Management
    // -------------------------------------------------------------------
    entity Users : cuid, managed {
        username  : String(50)  @assert.unique;
        email     : String(255) @assert.format: '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
        firstName : String(100);
        lastName  : String(100);
        isActive  : Boolean default true;
        userRoles : Composition of many UserRoleAssignment
                        on userRoles.user = $self;
    }

    entity Roles : cuid, managed {
        roleName    : String(50) @assert.unique;
        description : String(255);
    }

    entity UserRoleAssignment : cuid, managed {
        user : Association to Users;
        role : Association to Roles;
    }

    // -------------------------------------------------------------------
    // 3. Products
    // -------------------------------------------------------------------
    entity Products : cuid, managed {
        productCode : String(30) @assert.unique;
        name        : String(100);
        description : String(500);
        category    : String(50);
        unitPrice   : Decimal(15, 2);
        currency    : String(3) default 'USD';
        stockQty    : Decimal(13, 3);
    }

    // -------------------------------------------------------------------
    // 4. Warehouse Locations
    // -------------------------------------------------------------------
    entity WarehouseLocations : cuid, managed {
        plantCode       : String(10);
        storageLocation : String(10);
        description     : String(100);
        city            : String(50);
        country         : String(30);
    }

    // -------------------------------------------------------------------
    // 5. Customer Base
    // -------------------------------------------------------------------
    entity Customers : cuid, managed {
        customerNumber : String(20) @assert.unique;
        companyName    : String(100);
        contactName    : String(100);
        email          : String(255);
        phone          : String(30);
        city           : String(50);
        country        : String(30);
    }

    // -------------------------------------------------------------------
    // 6. Employee Management
    // -------------------------------------------------------------------
    entity Employees : cuid, managed {
        employeeId  : String(20) @assert.unique;
        firstName   : String(50);
        lastName    : String(50);
        email       : String(255);
        department  : String(50);
        designation : String(50);
        joiningDate : Date;
        status      : String(20) enum {
            ACTIVE;
            INACTIVE;
            ON_LEAVE;
        } default 'ACTIVE';
        leaves      : Association to many EmployeeLeaves
                          on leaves.employee = $self;
        payrolls    : Association to many EmployeePayroll
                          on payrolls.employee = $self;
    }

    // -------------------------------------------------------------------
    // 7. Employee Leaves
    // -------------------------------------------------------------------
    entity EmployeeLeaves : cuid, managed {
        employee  : Association to Employees;
        leaveType : String(20) enum {
            ANNUAL;
            SICK;
            CASUAL;
            MATERNITY;
            PATERNITY;
        };
        startDate : Date;
        endDate   : Date;
        days      : Decimal(4, 1);
        status    : String(20) enum {
            SUBMITTED;
            APPROVED;
            REJECTED;
        } default 'SUBMITTED';
    }

    // -------------------------------------------------------------------
    // 8. Employee Payroll
    // -------------------------------------------------------------------
    entity EmployeePayroll : cuid, managed {
        employee    : Association to Employees;
        payPeriod   : String(7); // Format: YYYY-MM
        basicPay    : Decimal(12, 2);
        allowances  : Decimal(12, 2);
        deductions  : Decimal(12, 2);
        netPay      : Decimal(12, 2);
        currency    : String(3) default 'USD';
        paymentDate : Date;
        status      : String(20) enum {
            DRAFT;
            PROCESSED;
            PAID;
        } default 'DRAFT';
    }

    // -------------------------------------------------------------------
    // 9. Purchase Order & Purchase Order Items
    // -------------------------------------------------------------------
    entity PurchaseOrders : cuid, managed {
        poNumber    : String(30) @assert.unique;
        orderDate   : Date;
        customer    : Association to Customers;
        status      : String(20) enum {
            DRAFT;
            SUBMITTED;
            APPROVED;
            COMPLETED;
            CANCELLED;
        } default 'DRAFT';
        totalAmount : Decimal(15, 2);
        currency    : String(3) default 'USD';
        items       : Composition of many PurchaseOrderItems
                          on items.purchaseOrder = $self;
    }

    entity PurchaseOrderItems : cuid, managed {
        purchaseOrder : Association to PurchaseOrders;
        itemNo        : Integer;
        product       : Association to Products;
        quantity      : Decimal(13, 3);
        unitPrice     : Decimal(15, 2);
        netAmount     : Decimal(15, 2);
        warehouse     : Association to WarehouseLocations;
    }


    entity Author {
        key ID    : UUID;
            name  : String;
            Books : Association to books;
    }

    entity books {
        key ID     : UUID;
            title  : String;
            author : Association to many Author
                         on author.Books = $self;
    }


    entity Departments {
        key ID        : Integer;
            name      : String;
    }

    entity Employees1 {
        key ID         : Integer;
            name       : String;
            department : Association to one Departments;
    }
}