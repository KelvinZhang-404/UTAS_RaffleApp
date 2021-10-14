//
//  SQLiteDatabase.swift
//  RaffleApp
//
//  Created by Lianxue Zhang on 19/5/20.
//  Copyright © 2020 Lianxue Zhang. All rights reserved.
//

import Foundation
import SQLite3

class SQLiteDatabase
{
    /* This variable is of type OpaquePointer, which is effectively the same as a C pointer (recall the SQLite API is a C-library). The variable is declared as an optional, since it is possible that a database connection is not made successfully, and will be nil until such time as we create the connection.*/
    private var db: OpaquePointer?
    
    /* Change this value whenever you make a change to table structure.
        When a version change is detected, the updateDatabase() function is called,
        which in turn calls the createTables() function.
     
        WARNING: DOING THIS WILL WIPE YOUR DATA, unless you modify how updateDatabase() works.
     */
    private let DATABASE_VERSION = 8
    
    // Constructor, Initializes a new connection to the database
    /* This code checks for the existence of a file within the application’s document directory with the name <dbName>.sqlite. If the file doesn’t exist, it attempts to create it for us. Since our application has the ability to write into this directory, this should happen the first time that we run the application without fail (it can still possibly fail if the device is out of storage space).
     The remainder of the function checks to see if we are able to open a successful connection to this database file using the sqlite3_open() function. With all of the SQLite functions we will be using, we can check for success by checking for a return value of SQLITE_OK.
     */
    init(databaseName dbName:String)
    {
        
        //get a file handle somewhere on this device
        //(if it doesn't exist, this should create the file for us)
        let fileURL = try! FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("\(dbName).sqlite")
        
        //try and open the file path as a database
        if sqlite3_open(fileURL.path, &db) == SQLITE_OK
        {
//            print("Successfully opened connection to database at \(fileURL.path)")
            checkForUpgrade();
        }
        else
        {
            print("Unable to open database at \(fileURL.path)")
            printCurrentSQLErrorMessage(db)
        }
//        print("cp \(fileURL.path) ~/Desktop/\(dbName).sqlite")
    }
    
    deinit
    {
        /* We should clean up our memory usage whenever the object is deinitialized, */
        sqlite3_close(db)
    }
    private func printCurrentSQLErrorMessage(_ db: OpaquePointer?)
    {
        let errorMessage = String.init(cString: sqlite3_errmsg(db))
        print("Error:\(errorMessage)")
    }
    
    private func createTables()
    {
        //INSERT YOUR createTable function calls here
        createRaffleTable()
        createTicketTable()
        createCustomerTable()
    }
    private func dropTables()
    {
        //INSERT YOUR dropTable function calls here
        dropTable(tableName:"Raffle")
        dropTable(tableName:"Ticket")
        dropTable(tableName:"Customer")
    }
    
    /* --------------------------------*/
    /* ----- VERSIONING FUNCTIONS -----*/
    /* --------------------------------*/
    func checkForUpgrade()
    {
        // get the current version number
        let defaults = UserDefaults.standard
        let lastSavedVersion = defaults.integer(forKey: "DATABASE_VERSION")
        
        // detect a version change
        if (DATABASE_VERSION > lastSavedVersion)
        {
            onUpdateDatabase(previousVersion:lastSavedVersion, newVersion: DATABASE_VERSION);
            
            // set the stored version number
            defaults.set(DATABASE_VERSION, forKey: "DATABASE_VERSION")
        }
    }
    
    func onUpdateDatabase(previousVersion : Int, newVersion : Int)
    {
        print("Detected Database Version Change (was:\(previousVersion), now:\(newVersion))")
        
        //handle the change (simple version)
        dropTables()
        createTables()
    }
    
    
    
    /* --------------------------------*/
    /* ------- HELPER FUNCTIONS -------*/
    /* --------------------------------*/
    
    /* Pass this function a CREATE sql string, and a table name, and it will create a table
        You should call this function from createTables()
     */
    private func createTableWithQuery(_ createTableQuery:String, tableName:String)
    {
        /*
         1.    sqlite3_prepare_v2()
         2.    sqlite3_step()
         3.    sqlite3_finalize()
         */
        //prepare the statement
        var createTableStatement: OpaquePointer? = nil
        if sqlite3_prepare_v2(db, createTableQuery, -1, &createTableStatement, nil) == SQLITE_OK
        {
            //execute the statement
            if sqlite3_step(createTableStatement) == SQLITE_DONE
            {
                print("\(tableName) table created.")
            }
            else
            {
                print("\(tableName) table could not be created.")
                printCurrentSQLErrorMessage(db)
            }
        }
        else
        {
            print("CREATE TABLE statement for \(tableName) could not be prepared.")
            printCurrentSQLErrorMessage(db)
        }
        
        //clean up
        sqlite3_finalize(createTableStatement)
        
    }
    /* Pass this function a table name.
        You should call this function from dropTables()
     */
    private func dropTable(tableName:String)
    {
        /*
         1.    sqlite3_prepare_v2()
         2.    sqlite3_step()
         3.    sqlite3_finalize()
         */
        
        //prepare the statement
        let query = "DROP TABLE IF EXISTS \(tableName)"
        var statement: OpaquePointer? = nil

        if sqlite3_prepare_v2(db, query, -1, &statement, nil)     == SQLITE_OK
        {
            //run the query
            if sqlite3_step(statement) == SQLITE_DONE {
                print("\(tableName) table deleted.")
            }
        }
        else
        {
            print("\(tableName) table could not be deleted.")
            printCurrentSQLErrorMessage(db)
        }
        
        //clear up
        sqlite3_finalize(statement)
    }
    
    //helper function for handling INSERT statements
    //provide it with a binding function for replacing the ?'s for setting values
    private func insertWithQuery(_ insertStatementQuery : String, bindingFunction:(_ insertStatement: OpaquePointer?)->())
    {
        /*
         Similar to the CREATE statement, the INSERT statement needs the following SQLite functions to be called (note the addition of the binding function calls):
         1.    sqlite3_prepare_v2()
         2.    sqlite3_bind_***()
         3.    sqlite3_step()
         4.    sqlite3_finalize()
         */
        // First, we prepare the statement, and check that this was successful. The result will be a C-
        // pointer to the statement:
        var insertStatement: OpaquePointer? = nil
        if sqlite3_prepare_v2(db, insertStatementQuery, -1, &insertStatement, nil) == SQLITE_OK
        {
            //handle bindings
            bindingFunction(insertStatement)
            
            /* Using the pointer to the statement, we can call the sqlite3_step() function. Again, we only
             step once. We check that this was successful */
            //execute the statement
            if sqlite3_step(insertStatement) == SQLITE_DONE
            {
                print("Successfully inserted row.")
            }
            else
            {
                print("Could not insert row.")
                printCurrentSQLErrorMessage(db)
            }
        }
        else
        {
            print("INSERT statement could not be prepared.")
            printCurrentSQLErrorMessage(db)
        }
    
        //clean up
        sqlite3_finalize(insertStatement)
    }
    
    //helper function to run Select statements
    //provide it with a function to do *something* with each returned row
    //(optionally) Provide it with a binding function for replacing the "?"'s in the WHERE clause
    private func selectWithQuery(
        _ selectStatementQuery : String,
        eachRow: (_ rowHandle: OpaquePointer?)->(),
        bindingFunction: ((_ rowHandle: OpaquePointer?)->())? = nil)
    {
        //prepare the statement
        var selectStatement: OpaquePointer? = nil
        if sqlite3_prepare_v2(db, selectStatementQuery, -1, &selectStatement, nil) == SQLITE_OK
        {
            //do bindings, only if we have a bindingFunction set
            //hint, to do selectMovieBy(id:) you will need to set a bindingFunction (if you don't hardcode the id)
            bindingFunction?(selectStatement)
            
            //iterate over the result
            while sqlite3_step(selectStatement) == SQLITE_ROW
            {
                eachRow(selectStatement);
            }
            
        }
        else
        {
            print("SELECT statement could not be prepared.")
            printCurrentSQLErrorMessage(db)
        }
        //clean up
        sqlite3_finalize(selectStatement)
    }
    
    //helper function to run update statements.
    //Provide it with a binding function for replacing the "?"'s in the WHERE clause
    private func updateWithQuery(
        _ updateStatementQuery : String,
        bindingFunction: ((_ rowHandle: OpaquePointer?)->()))
    {
        //prepare the statement
        var updateStatement: OpaquePointer? = nil
        if sqlite3_prepare_v2(db, updateStatementQuery, -1, &updateStatement, nil) == SQLITE_OK
        {
            //do bindings
            bindingFunction(updateStatement)
            print(updateStatementQuery)
            //execute
            if sqlite3_step(updateStatement) == SQLITE_DONE
            {
                print("Successfully updated row.")
            }
            else
            {
                print("Could not insert row.")
                printCurrentSQLErrorMessage(db)
            }
        }
        else
        {
            print("UPDATE statement could not be prepared.")
            printCurrentSQLErrorMessage(db)
        }
        //clean up
        sqlite3_finalize(updateStatement)
    }
    
    
    
    /* --------------------------------*/
    /* --- ADD YOUR TABLES ETC HERE ---*/
    /* --------------------------------*/
    func createRaffleTable()
    {
        let createRafflesTableQuery = """
            CREATE TABLE Raffle (
                RaffleID INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
                Name CHAR(255),
                Description CHAR(255),
                DrawnMethod CHAR(20),
                StartDate TEXT,
                EndDate TEXT,
                Status CHAR(10),
                TicketAmount INTEGER,
                TicketPrice DOUBLE,
                PurchaseLimit INTEGER,
                Image TEXT,
                Winner TEXT
            );
        """
        createTableWithQuery(createRafflesTableQuery, tableName: "Raffle")
    }
    
    func createTicketTable()
    {
        let createTicketsTableQuery = """
            CREATE TABLE Ticket (
                TicketID INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
                RaffleID INTEGER,
                CustomerID INTEGER,
                TicketNo INTEGER,
                PurchaseDate TEXT
            );
        """
        createTableWithQuery(createTicketsTableQuery, tableName: "Ticket")
    }
    
    func createCustomerTable()
    {
        let createCustomerTableQuery = """
            CREATE TABLE Customer (
                CustomerID INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
                Name TEXT,
                Email TEXT,
                Phone INTEGER
            );
        """
        createTableWithQuery(createCustomerTableQuery, tableName: "Customer")
    }

    func insert(raffle:Raffle)
    {
        let insertStatementQuery = "INSERT INTO Raffle (Name, Description, DrawnMethod, StartDate, EndDate, Status, TicketAmount, TicketPrice, PurchaseLimit, Image, Winner) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);"
        //1, 2, 3 indicates binding to which '?'. -1 and nil is included for strings for complicated reasons
        insertWithQuery(insertStatementQuery, bindingFunction: { (insertStatement) in
            sqlite3_bind_text(insertStatement, 1, NSString(string:raffle.name).utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 2, NSString(string:raffle.description).utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 3, NSString(string:raffle.drawnMethod).utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 4, NSString(string:raffle.startDate).utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 5, NSString(string:raffle.endDate).utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 6, NSString(string:raffle.status).utf8String, -1, nil)
            sqlite3_bind_int(insertStatement, 7, raffle.ticketAmount)
            sqlite3_bind_double(insertStatement, 8, raffle.ticketPrice)
            sqlite3_bind_int(insertStatement, 9, raffle.purchaseLimit)
            sqlite3_bind_text(insertStatement, 10, NSString(string:raffle.image).utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 11, NSString(string:raffle.winner).utf8String, -1, nil)
        })
    }
    
    func insert(ticket:Ticket)
    {
        let insertStatementQuery = "INSERT INTO Ticket (RaffleID, CustomerID, TicketNo, PurchaseDate) VALUES (?, ?, ?, ?);"
        //1, 2, 3 indicates binding to which '?'. -1 and nil is included for strings for complicated reasons
        insertWithQuery(insertStatementQuery, bindingFunction: { (insertStatement) in
            sqlite3_bind_int(insertStatement, 1, ticket.raffleID)
            sqlite3_bind_int(insertStatement, 2, ticket.customerID)
            sqlite3_bind_int(insertStatement, 3, ticket.ticketNo)
            sqlite3_bind_text(insertStatement, 4, NSString(string:ticket.purchaseDate).utf8String, -1, nil)
        })
    }
    
    func insert(customer:Customer)
    {
        let insertStatementQuery = "INSERT INTO Customer (Name, Email, Phone) VALUES (?, ?, ?);"
        //1, 2, 3 indicates binding to which '?'. -1 and nil is included for strings for complicated reasons
        insertWithQuery(insertStatementQuery, bindingFunction: { (insertStatement) in
            sqlite3_bind_text(insertStatement, 1, NSString(string:customer.name).utf8String, -1, nil)
            sqlite3_bind_text(insertStatement, 2, NSString(string:customer.email).utf8String, -1, nil)
            sqlite3_bind_int(insertStatement, 3, customer.phone)
        })
    }

    func selectAllRaffles() -> [Raffle]
    {
        var result = [Raffle]()
        let selectStatementQuery = "SELECT RaffleID, Name, Description, DrawnMethod, StartDate, EndDate, Status, TicketAmount, TicketPrice, PurchaseLimit, Image, Winner FROM Raffle"
        selectWithQuery(selectStatementQuery, eachRow: { (row) in
            //create a movie object from each result
            let raffle = Raffle(
                raffleID: sqlite3_column_int(row, 0),
                name: String(cString:sqlite3_column_text(row, 1)),
                description: String(cString:sqlite3_column_text(row, 2)),
                drawnMethod: String(cString:sqlite3_column_text(row, 3)),
                startDate: String(cString:sqlite3_column_text(row, 4)),
                endDate: String(cString:sqlite3_column_text(row, 5)),
                status: String(cString:sqlite3_column_text(row, 6)),
                ticketAmount: sqlite3_column_int(row, 7),
                ticketPrice: sqlite3_column_double(row, 8),
                purchaseLimit: sqlite3_column_int(row, 9),
                image: String(cString:sqlite3_column_text(row, 10)),
                winner: String(cString:sqlite3_column_text(row, 11))
            )
            //add it to the result array
            result += [raffle]
        })
        return result
    }
    
    func selectAllCustomers() -> [Customer]
    {
        var result = [Customer]()
        let selectStatementQuery = "SELECT CustomerID, Name, Email, Phone FROM Customer"
        selectWithQuery(selectStatementQuery, eachRow: { (row) in
            //create a movie object from each result
            let customer = Customer(
                customerID: sqlite3_column_int(row, 0),
                name: String(cString:sqlite3_column_text(row, 1)),
                email: String(cString:sqlite3_column_text(row, 2)),
                phone: sqlite3_column_int(row, 3)
            )
            //add it to the result array
            result += [customer]
        })
        return result
    }

    func selectRaffleByID(id:Int32) -> Raffle? {
        var result : Raffle?
        let selectStatementQuery = "SELECT RaffleID, Name, Description, DrawnMethod, StartDate, EndDate, Status, TicketAmount, TicketPrice, PurchaseLimit, Image, Winner FROM Raffle WHERE RaffleID = ?"
        selectWithQuery(selectStatementQuery, eachRow: { (row) in
                //create a movie object from each result
                let raffle = Raffle(
                    raffleID: sqlite3_column_int(row, 0),
                    name: String(cString:sqlite3_column_text(row, 1)),
                    description: String(cString:sqlite3_column_text(row, 2)),
                    drawnMethod: String(cString:sqlite3_column_text(row, 3)),
                    startDate: String(cString:sqlite3_column_text(row, 4)),
                    endDate: String(cString:sqlite3_column_text(row, 5)),
                    status: String(cString:sqlite3_column_text(row, 6)),
                    ticketAmount: sqlite3_column_int(row, 7),
                    ticketPrice: sqlite3_column_double(row, 8),
                    purchaseLimit: sqlite3_column_int(row, 9),
                    image: String(cString:sqlite3_column_text(row, 10)),
                    winner: String(cString:sqlite3_column_text(row, 11))
                )
                result = raffle
            },
            bindingFunction: { (selectStatement) in
                sqlite3_bind_int(selectStatement, 1, id) }
        )
        
        return result
    }
    
    func selectCustomerByName(name:String) -> Customer? {
        var result : Customer?
        let selectStatementQuery = "SELECT CustomerID, Name, Email, Phone FROM Customer WHERE Name = ?"
        selectWithQuery(selectStatementQuery, eachRow: { (row) in
                //create a movie object from each result
                let customer = Customer(
                    customerID:sqlite3_column_int(row, 0),
                    name: String(cString:sqlite3_column_text(row, 1)),
                    email: String(cString:sqlite3_column_text(row, 2)),
                    phone: sqlite3_column_int(row, 3)
                )
                result = customer
            },
            bindingFunction: { (selectStatement) in
                sqlite3_bind_text(selectStatement, 1, NSString(string: name).utf8String, -1, nil) }
        )
        
        return result
    }
    
    func selectTicketByRaffleTicket(raffleID: Int32, ticketNo: Int32) -> Ticket? {
        var result : Ticket?
        let selectStatementQuery = "SELECT TicketID, RaffleID, CustomerID, TicketNo, PurchaseDate FROM Ticket WHERE RaffleID = ? AND TicketNo = ?"
        selectWithQuery(selectStatementQuery, eachRow: { (row) in
                //create a movie object from each result
                let ticket = Ticket(
                    ticketID: sqlite3_column_int(row, 0),
                    raffleID: sqlite3_column_int(row, 1),
                    customerID: sqlite3_column_int(row, 2),
                    ticketNo: sqlite3_column_int(row, 3),
                    purchaseDate: String(cString:sqlite3_column_text(row, 4))
                )
                //add it to the result array
                result = ticket
            },
            bindingFunction: { (selectStatement) in
                sqlite3_bind_int(selectStatement, 1, raffleID)
                sqlite3_bind_int(selectStatement, 2, ticketNo) }
        )
        return result
    }
    
    func selectCustomerByID(id:Int32) -> Customer? {
        var result : Customer?
        let selectStatementQuery = "SELECT CustomerID, Name, Email, Phone FROM Customer WHERE CustomerID = ?"
        selectWithQuery(selectStatementQuery, eachRow: { (row) in
                //create a movie object from each result
                let customer = Customer(
                    customerID:sqlite3_column_int(row, 0),
                    name: String(cString:sqlite3_column_text(row, 1)),
                    email: String(cString:sqlite3_column_text(row, 2)),
                    phone: sqlite3_column_int(row, 3)
                )
                result = customer
            },
            bindingFunction: { (selectStatement) in
                sqlite3_bind_int(selectStatement, 1, id) }
        )
        
        return result
    }
    
    func selectTicketsByRaffle(id:Int32) -> [Ticket]
    {
        var result = [Ticket]()
        let selectStatementQuery = "SELECT TicketID, RaffleID, CustomerID, TicketNo, PurchaseDate FROM Ticket WHERE RaffleID = ?"
        selectWithQuery(selectStatementQuery, eachRow: { (row) in
                //create a movie object from each result
                let ticket = Ticket(
                    ticketID: sqlite3_column_int(row, 0),
                    raffleID: sqlite3_column_int(row, 1),
                    customerID: sqlite3_column_int(row, 2),
                    ticketNo: sqlite3_column_int(row, 3),
                    purchaseDate: String(cString:sqlite3_column_text(row, 4))
                )
                //add it to the result array
                result += [ticket]
            },
            bindingFunction: { (selectStatement) in
            sqlite3_bind_int(selectStatement, 1, id) }
        )
        return result
    }
    
    func selectTicketsByRaffleCustomer(raffleID: Int32, customerID: Int32) -> [Ticket] {
        var result = [Ticket]()
        let selectStatementQuery = "SELECT TicketID, RaffleID, CustomerID, TicketNo, PurchaseDate FROM Ticket WHERE RaffleID = ? AND CustomerID = ?"
        selectWithQuery(selectStatementQuery, eachRow: { (row) in
                //create a movie object from each result
                let ticket = Ticket(
                    ticketID: sqlite3_column_int(row, 0),
                    raffleID: sqlite3_column_int(row, 1),
                    customerID: sqlite3_column_int(row, 2),
                    ticketNo: sqlite3_column_int(row, 3),
                    purchaseDate: String(cString:sqlite3_column_text(row, 4))
                )
                //add it to the result array
                result += [ticket]
            },
            bindingFunction: { (selectStatement) in
                sqlite3_bind_int(selectStatement, 1, raffleID)
                sqlite3_bind_int(selectStatement, 2, customerID) }
        )
        return result
    }
    
    func deleteRaffleBy(id: Int32) {
        let deleteStatementStirng = "DELETE FROM Raffle WHERE RaffleID = ?;"

        var deleteStatement: OpaquePointer? = nil
        if sqlite3_prepare_v2(db, deleteStatementStirng, -1, &deleteStatement, nil) == SQLITE_OK {

            sqlite3_bind_int(deleteStatement, 1, id)

            if sqlite3_step(deleteStatement) == SQLITE_DONE {
                print("Successfully deleted row.")
            } else {
                print("Could not delete row.")
            }
        } else {
            print("DELETE statement could not be prepared")
        }

        sqlite3_finalize(deleteStatement)
        print("delete")
    }
    
    func updateCustomer(customer: Customer) {
        let updateStatementQuery = "UPDATE Customer SET Email = ?, Phone =? WHERE CustomerID = ?"
        updateWithQuery(updateStatementQuery, bindingFunction: { (updateStatement) in
            sqlite3_bind_text(updateStatement, 1, NSString(string: customer.email).utf8String, -1, nil)
            sqlite3_bind_int(updateStatement, 2, customer.phone)
            sqlite3_bind_int(updateStatement, 3, customer.customerID)
        })
    }

    func updateRaffle(raffle: Raffle) {
        let updateStatementQuery = "UPDATE Raffle SET Name = ?, Description = ?, TicketAmount = ?, TicketPrice = ? WHERE RaffleID = ?"
        updateWithQuery(updateStatementQuery, bindingFunction: { (updateStatement) in
            sqlite3_bind_text(updateStatement, 1, NSString(string: raffle.name).utf8String, -1, nil)
            sqlite3_bind_text(updateStatement, 2, NSString(string: raffle.description).utf8String, -1, nil)
            sqlite3_bind_int(updateStatement, 3, raffle.ticketAmount)
            sqlite3_bind_double(updateStatement, 4, raffle.ticketPrice)
            sqlite3_bind_int(updateStatement, 5, raffle.raffleID)
        })
    }
    
    func updateRaffleStatus(raffle: Raffle) {
        let updateStatementQuery = "UPDATE Raffle SET Status = ?, Winner = ? WHERE RaffleID = ?"
        updateWithQuery(updateStatementQuery, bindingFunction: { (updateStatement) in
            sqlite3_bind_text(updateStatement, 1, NSString(string: raffle.status).utf8String, -1, nil)
            sqlite3_bind_text(updateStatement, 2, NSString(string: raffle.winner).utf8String, -1, nil)
            sqlite3_bind_int(updateStatement, 3, raffle.raffleID)
        })
    }
}
