import ballerina/grpc;
import ballerina/log;
import ballerina/time;

type Property record {|
    string propertyId;
    string hostId;
    string propertyName;
    string location;
    string propertyType;
    decimal pricePerNight;
    string status;
|};

type BookingCart record {|
    string propertyId;
    string checkIn;
    string checkOut;
    decimal pricePerNight;
|};

type ConfirmedBooking record {|
    string bookingId;
    string propertyId;
    string guestId;
    string checkIn;
    string checkOut;
|};

map<Property> properties = {};
map<BookingCart> carts = {};
ConfirmedBooking[] confirmedBookings = [];
int propertyCounter = 0;
int bookingCounter = 0;

listener grpc:Listener ep = new (9090);

@grpc:Descriptor {value: RENTAL_DESC}
service "RentalService" on ep {

    remote function add_property(AddPropertyRequest req) returns AddPropertyResponse|error {
        string hostId = req.host_id;
        string propertyName = req.property_name;
        string location = req.location;
        string propertyType = req.property_type;
        decimal pricePerNight = <decimal>req.price_per_night;
        string status = req.status;

        lock {
            propertyCounter += 1;
            string pid = "PROP-" + propertyCounter.toString();
            properties[pid] = {
                propertyId: pid,
                hostId: hostId,
                propertyName: propertyName,
                location: location,
                propertyType: propertyType,
                pricePerNight: pricePerNight,
                status: status
            };
            log:printInfo("Property added: " + pid);
            return {property_id: pid, message: "Property added successfully."};
        }
    }

    remote function create_users(stream<CreateUserRequest, grpc:Error?> clientStream)
            returns CreateUsersResponse|error {
        CreateUserRequest[] users = check from CreateUserRequest u in clientStream
            select u;

        foreach CreateUserRequest user in users {
            log:printInfo("User registered: " + user.user_name + " (" + user.role + ")");
        }
        return {
            total_created: users.length(),
            message: users.length().toString() + " user(s) registered successfully."
        };
    }

    remote function update_property(UpdatePropertyRequest req) returns UpdatePropertyResponse|error {
        string propertyId = req.property_id;
        decimal pricePerNight = <decimal>req.price_per_night;
        string status = req.status;

        lock {
            if !properties.hasKey(propertyId) {
                return {success: false, message: "Property not found."};
            }
            Property p = properties.get(propertyId);
            p.pricePerNight = pricePerNight;
            p.status = status;
            properties[propertyId] = p;
            return {success: true, message: "Property updated."};
        }
    }

    remote function remove_property(RemovePropertyRequest req) returns RemovePropertyResponse|error {
        string propertyId = req.property_id;

        lock {
            if !properties.hasKey(propertyId) {
                return {success: false, message: "Property not found.", properties: []};
            }
            Property removed = properties.get(propertyId);
            _ = properties.remove(propertyId);

            PropertyMessage[] remaining = [];
            foreach Property p in properties {
                if p.location == removed.location && p.status == "AVAILABLE" {
                    remaining.push(toPropertyMessage(p));
                }
            }
            return {success: true, message: "Property removed.", properties: remaining};
        }
    }

    remote function list_available_properties(ListAvailableRequest req)
            returns stream<PropertyMessage, error?>|error {
        string loc = req.location;
        float minP = req.min_price;
        float maxP = req.max_price;

        PropertyMessage[] results = [];
        lock {
            foreach Property p in properties {
                if p.status != "AVAILABLE" { continue; }
                if loc != "" && p.location != loc { continue; }
                if minP > 0.0 && p.pricePerNight < <decimal>minP { continue; }
                if maxP > 0.0 && p.pricePerNight > <decimal>maxP { continue; }
                results.push(toPropertyMessage(p));
            }
        }
        return results.toStream();
    }

    remote function search_property(SearchPropertyRequest req) returns SearchPropertyResponse|error {
        string propertyId = req.property_id;

        lock {
            if !properties.hasKey(propertyId) {
                return {found: false, status: "Not Available", property: {}};
            }
            Property p = properties.get(propertyId);
            if p.status != "AVAILABLE" {
                return {found: false, status: "Not Available", property: toPropertyMessage(p)};
            }
            return {found: true, status: "AVAILABLE", property: toPropertyMessage(p)};
        }
    }

    remote function book_property(BookPropertyRequest req) returns BookPropertyResponse|error {
        string guestId = req.guest_id;
        string propertyId = req.property_id;
        string checkIn = req.check_in;
        string checkOut = req.check_out;

        if !isValidDate(checkIn) || !isValidDate(checkOut) {
            return {success: false, message: "Invalid date format. Use YYYY-MM-DD.", booking_ref: ""};
        }
        if !isEndAfterStart(checkIn, checkOut) {
            return {success: false, message: "Check-out date must be after check-in date.", booking_ref: ""};
        }

        lock {
            if !properties.hasKey(propertyId) {
                return {success: false, message: "Property not found.", booking_ref: ""};
            }
            Property p = properties.get(propertyId);
            if p.status != "AVAILABLE" {
                return {success: false, message: "Property is not available.", booking_ref: ""};
            }
            ConfirmedBooking[] existingBookings = confirmedBookings;
            if hasOverlap(existingBookings, propertyId, checkIn, checkOut) {
                return {success: false, message: "Property already booked for these dates.", booking_ref: ""};
            }

            carts[guestId] = {
                propertyId: propertyId,
                checkIn: checkIn,
                checkOut: checkOut,
                pricePerNight: p.pricePerNight
            };
            return {success: true, message: "Added to booking cart. Confirm to finalise.", booking_ref: "CART-" + guestId};
        }
    }

    remote function confirm_booking(ConfirmBookingRequest req) returns ConfirmBookingResponse|error {
        string guestId = req.guest_id;

        lock {
            if !carts.hasKey(guestId) {
                return {
                    success: false, message: "No pending booking in cart.",
                    booking_id: "", total_cost: 0.0, nights: 0,
                    property_name: "", check_in: "", check_out: ""
                };
            }
            BookingCart cart = carts.get(guestId);
            if hasOverlap(confirmedBookings, cart.propertyId, cart.checkIn, cart.checkOut) {
                _ = carts.remove(guestId);
                return {
                    success: false, message: "Property is no longer available for these dates.",
                    booking_id: "", total_cost: 0.0, nights: 0,
                    property_name: "", check_in: cart.checkIn, check_out: cart.checkOut
                };
            }

            int nights = calculateNights(cart.checkIn, cart.checkOut);
            decimal total = cart.pricePerNight * <decimal>nights;

            bookingCounter += 1;
            string bid = "BK-" + bookingCounter.toString();

            Property p = properties.get(cart.propertyId);
            confirmedBookings.push({
                bookingId: bid,
                propertyId: cart.propertyId,
                guestId: guestId,
                checkIn: cart.checkIn,
                checkOut: cart.checkOut
            });
            _ = carts.remove(guestId);

            return {
                success: true, message: "Booking confirmed.",
                booking_id: bid, total_cost: <float>total, nights: nights,
                property_name: p.propertyName, check_in: cart.checkIn, check_out: cart.checkOut
            };
        }
    }
}

function toPropertyMessage(Property p) returns PropertyMessage {
    return {
        property_id: p.propertyId,
        host_id: p.hostId,
        property_name: p.propertyName,
        location: p.location,
        property_type: p.propertyType,
        price_per_night: <float>p.pricePerNight,
        status: p.status
    };
}

function isValidDate(string d) returns boolean {
    return re `^\d{4}-\d{2}-\d{2}$`.isFullMatch(d);
}

function isEndAfterStart(string startDate, string endDate) returns boolean {
    time:Civil|error s = time:civilFromString(startDate + "T00:00:00Z");
    time:Civil|error e = time:civilFromString(endDate + "T00:00:00Z");
    if s is error || e is error { return false; }
    time:Utc|error su = time:utcFromCivil(s);
    time:Utc|error eu = time:utcFromCivil(e);
    if su is error || eu is error { return false; }
    return <int>time:utcDiffSeconds(eu, su) > 0;
}

function calculateNights(string checkIn, string checkOut) returns int {
    time:Civil|error s = time:civilFromString(checkIn + "T00:00:00Z");
    time:Civil|error e = time:civilFromString(checkOut + "T00:00:00Z");
    if s is error || e is error { return 0; }
    time:Utc|error su = time:utcFromCivil(s);
    time:Utc|error eu = time:utcFromCivil(e);
    if su is error || eu is error { return 0; }
    return <int>(time:utcDiffSeconds(eu, su) / 86400d);
}

function hasOverlap(ConfirmedBooking[] bookings, string propertyId, string checkIn, string checkOut) returns boolean {
    foreach ConfirmedBooking b in bookings {
        if b.propertyId != propertyId { continue; }
        boolean existingEndsBeforeNewStarts = !isEndAfterStart(b.checkIn, checkOut);
        boolean existingStartsAfterNewEnds  = !isEndAfterStart(checkIn, b.checkOut);
        if !(existingEndsBeforeNewStarts || existingStartsAfterNewEnds) {
            return true;
        }
    }
    return false;
}