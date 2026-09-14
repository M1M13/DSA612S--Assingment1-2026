import ballerina/grpc;
import ballerina/io;

public function main() returns error? {
    RentalServiceClient rentalClient = check new ("http://localhost:9090");

    io:println("=== RENTAL ACCOMMODATION SYSTEM CLIENT ===");

    boolean running = true;
    while running {
        io:println("\n--- MENU ---");
        io:println("1. Add property");
        io:println("2. List available properties");
        io:println("3. Search property");
        io:println("4. Book property");
        io:println("5. Confirm booking");
        io:println("6. Update property");
        io:println("7. Remove property");
        io:println("8. Register users (streaming)");
        io:println("9. Exit");
        string choice = io:readln("Choose an option: ");

        if choice == "1" {
            string hostId = io:readln("Host ID: ");
            string name = io:readln("Property name: ");
            string location = io:readln("Location: ");
            string ptype = io:readln("Property type: ");
            string priceStr = io:readln("Price per night: ");
            string status = io:readln("Status (AVAILABLE/UNDER_MAINTENANCE): ");

            float|error price = float:fromString(priceStr);
            if price is error {
                io:println("Invalid price entered.");
                continue;
            }

            AddPropertyResponse resp = check rentalClient->add_property({
                host_id: hostId, property_name: name,
                location: location, property_type: ptype,
                price_per_night: price, status: status
            });
            io:println("Result: ", resp.message, " | property_id = ", resp.property_id);

        } else if choice == "2" {
            string location = io:readln("Filter by location (blank for any): ");
            string minStr = io:readln("Min price (0 for any): ");
            string maxStr = io:readln("Max price (0 for any): ");

            float minPrice = 0.0;
            float maxPrice = 0.0;
            float|error minParsed = float:fromString(minStr);
            float|error maxParsed = float:fromString(maxStr);
            if minParsed is float { minPrice = minParsed; }
            if maxParsed is float { maxPrice = maxParsed; }

            stream<PropertyMessage, grpc:Error?> propStream =
                check rentalClient->list_available_properties({
                    location: location, min_price: minPrice, max_price: maxPrice
                });
            check from PropertyMessage prop in propStream
                do {
                    io:println("  [", prop.property_id, "] ", prop.property_name,
                        " | ", prop.location, " | N$", prop.price_per_night, "/night");
                };

        } else if choice == "3" {
            string propertyId = io:readln("Property ID to search: ");
            SearchPropertyResponse search = check rentalClient->search_property({property_id: propertyId});
            if search.found {
                io:println("Found: ", search.property.property_name, " (", search.status, ")");
            } else {
                io:println("Not available: ", search.status);
            }

        } else if choice == "4" {
            string guestId = io:readln("Guest ID: ");
            string propertyId = io:readln("Property ID: ");
            string checkIn = io:readln("Check-in (YYYY-MM-DD): ");
            string checkOut = io:readln("Check-out (YYYY-MM-DD): ");

            BookPropertyResponse book = check rentalClient->book_property({
                guest_id: guestId, property_id: propertyId,
                check_in: checkIn, check_out: checkOut
            });
            io:println("Result: ", book.message, " | ref: ", book.booking_ref);

        } else if choice == "5" {
            string guestId = io:readln("Guest ID confirming booking: ");
            ConfirmBookingResponse confirm = check rentalClient->confirm_booking({guest_id: guestId});
            if confirm.success {
                io:println("Booking ID : ", confirm.booking_id);
                io:println("Property   : ", confirm.property_name);
                io:println("Dates      : ", confirm.check_in, " to ", confirm.check_out);
                io:println("Nights     : ", confirm.nights);
                io:println("Total Cost : N$", confirm.total_cost);
            } else {
                io:println("Confirmation failed: ", confirm.message);
            }

        } else if choice == "6" {
            string propertyId = io:readln("Property ID to update: ");
            string priceStr = io:readln("New price per night: ");
            string status = io:readln("New status: ");

            float|error price = float:fromString(priceStr);
            if price is error {
                io:println("Invalid price entered.");
                continue;
            }

            UpdatePropertyResponse upd = check rentalClient->update_property({
                property_id: propertyId, price_per_night: price, status: status
            });
            io:println("Result: ", upd.message);

        } else if choice == "7" {
            string propertyId = io:readln("Property ID to remove: ");
            string hostId = io:readln("Host ID: ");

            RemovePropertyResponse rem = check rentalClient->remove_property({
                property_id: propertyId, host_id: hostId
            });
            io:println("Result: ", rem.message);
            io:println("Remaining available in region: ", rem.properties.length());

        } else if choice == "8" {
            io:println("Enter user details. Type 'done' as User ID to finish.");
            Create_usersStreamingClient createUsersClient = check rentalClient->create_users();
            boolean addingUsers = true;
            while addingUsers {
                string userId = io:readln("User ID (or 'done'): ");
                if userId == "done" {
                    addingUsers = false;
                } else {
                    string userName = io:readln("User name: ");
                    string role = io:readln("Role (HOST/GUEST): ");
                    string email = io:readln("Email: ");
                    check createUsersClient->sendCreateUserRequest({
                        user_id: userId, user_name: userName, role: role, email: email
                    });
                }
            }
            check createUsersClient->complete();
            CreateUsersResponse? resp = check createUsersClient->receiveCreateUsersResponse();
            if resp is CreateUsersResponse {
                io:println("Users created: ", resp.total_created);
                io:println("Message: ", resp.message);
            }

        } else if choice == "9" {
            running = false;
            io:println("Goodbye.");
        } else {
            io:println("Not a valid option.");
        }
    }
}