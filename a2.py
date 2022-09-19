"""
# This code is provided solely for the personal and private use of students 
# taking the CSC343H course at the University of Toronto. Copying for purposes 
# other than this use is expressly prohibited. All forms of distribution of 
# this code, including but not limited to public repositories on GitHub, 
# GitLab, Bitbucket, or any other online platform, whether as given or with 
# any changes, are expressly prohibited. 
"""

from turtle import update 
from typing import Optional, Tuple
import psycopg2 as pg
import datetime
import math

class Assignment2:

    ##### DO NOT MODIFY THE CODE BELOW. #####

    def __init__(self) -> None:
        """Initialize this class, with no database connection yet.
        """
        self.db_conn = None

    
    def connect_db(self, url: str, username: str, pword: str) -> bool:
        """Connect to the database at url and for username, and set the
        search_path to "air_travel". Return True iff the connection was made
        successfully.

        >>> a2 = Assignment2()
        >>> # This example will make sense if you change the arguments as
        >>> # appropriate for you.
        >>> a2.connect_db("csc343h-<your_username>", "<your_username>", "")
        True
        >>> a2.connect_db("test", "postgres", "password") # test doesn't exist
        False
        """
        try:
            self.db_conn = pg.connect(dbname=url, user=username, password=pword,
                                      options="-c search_path=air_travel")
        except pg.Error:
            return False

        return True

    def disconnect_db(self) -> bool:
        """Return True iff the connection to the database was closed
        successfully.

        >>> a2 = Assignment2()
        >>> # This example will make sense if you change the arguments as
        >>> # appropriate for you.
        >>> a2.connect_db("csc343h-<your_username>", "<your_username>", "")
        True
        >>> a2.disconnect_db()
        True
        """
        try:
            self.db_conn.close()
        except pg.Error:
            return False

        return True

    ##### DO NOT MODIFY THE CODE ABOVE. #####

    # ----------------------- Airline-related methods ------------------------- */

    def book_seat(self, pass_id: int, flight_id: int, seat_class: str) -> Optional[bool]:
        """Attempts to book a flight for a passenger in a particular seat class. 
        Does so by inserting a row into the Booking table.
        
        Read the handout for information on how seats are booked.

        Parameters:
        * pass_id - id of the passenger
        * flight_id - id of the flight
        * seat_class - the class of the seat

        Precondition:
        * seat_class is one of "economy", "business", or "first".
        
        Return: 
        * True iff the booking was successful.
        * False iff the seat can't be booked, or if the passenger or flight cannot be found.
        """
        try:
            # TODO: Complete this method.
            if seat_class not in ('first', 'business', 'economy'):
                # print(1)
                return False
            
            cur = self.db_conn.cursor()

            cur.execute(f"(SELECT id FROM Flight WHERE id = {flight_id})"
                        "UNION ALL"
                        f"(SELECT id FROM Passenger WHERE id = {pass_id});")
            # either one doesn't exist
            if (len(cur.fetchall()) != 2):  
                # print(2)
                return False


            cur.execute("SET SEARCH_PATH TO air_travel;")

            cur.execute("SELECT count(seat_class) "
                        "FROM Booking "
                        f"WHERE flight_id = {flight_id} AND "
                        f"seat_class = '{seat_class}';")
            
            # total number seated in that class
            num_seated = cur.fetchone()[0]  # only one tuple
            if num_seated < 0:
                # print(3)
                return False
            
            # find capacity
            cur.execute("SELECT capacity_economy, "
                        "       capacity_business, "
                        "       capacity_first, "
                        f"      capacity_{seat_class} "
                        "FROM Flight JOIN Plane ON Flight.plane = tail_number "
                        f"WHERE id = {flight_id};")
            cap_e, cap_b, cap_f, capacity = cur.fetchone()

            if seat_class == 'economy':
                if num_seated >= capacity + 10:
                    # print(4) 
                    return False 
            else:
                if num_seated >= capacity:
                    # print(5)
                    return False

            # find booking.id
            cur.execute("SELECT count(*) FROM Booking;")
            num_booking = cur.fetchone()[0]

            # find price
            cur.execute(f"SELECT {seat_class} "
                        "FROM Price "
                        f"WHERE flight_id = {flight_id}")
            price = cur.fetchone()[0]


            f_used = math.ceil(cap_f / 6) * 6  # space on plane first class used
            b_used = math.ceil(cap_b / 6) * 6  # ... business ...
            space_dic = {
                'economy': f_used + b_used + num_seated + 1,
                'business': f_used + num_seated + 1,
                'first': num_seated + 1
            }

            row, letter = 'NULL', 'NULL'
            if not (seat_class == 'economy' and \
                  capacity <= num_seated < capacity + 10):
                row, letter = self._calc_seat(space_dic[seat_class])
                letter = f"'{letter}'"

            # print("below")
            # print(f"INSERT INTO Booking VALUES "
            #       f"({num_booking + 1}, {pass_id}, {flight_id}, "
            #       f"'{self._get_current_timestamp()}', "
            #       f"{price}, '{seat_class}', {row}, {letter});")

            cur.execute(f"INSERT INTO Booking VALUES "
                        f"({num_booking + 1}, {pass_id}, {flight_id}, "
                        f"'{self._get_current_timestamp()}', "
                        f"{price}, '{seat_class}', {row}, {letter});")

            return True
           
        except pg.Error:
            # print(10)
            return None

    def upgrade(self, flight_id: int) -> Optional[int]:  
        """Attempts to upgrade overbooked economy passengers to business class 
        or first class (in that order until each seat class is filled). 
        Does so by altering the database records for the bookings such that the 
        seat and seat_class are updated if an upgrade can be processed. 
         
        Upgrades should happen in order of earliest booking timestamp first. 
        If economy passengers are left over without a seat (i.e. not enough higher class seats),  
        remove their bookings from the database. 
         
        Parameters: 
        * flight_id - the flight to upgrade passengers in 
         
        Precondition:  
        * flight_id exists in the database (a valid flight id). 
         
        Return:  
        * The number of passengers upgraded. 
        """  
        try:  
            # TODO: Complete this method.  
            cur = self.db_conn.cursor()  
            cur.execute("SET SEARCH_PATH TO air_travel;")
            cur.execute("Select capacity_economy, capacity_business, capacity_first "
                        "From plane, flight "
                            "Where flight.airline = plane.airline "
                            "and tail_number = plane "
                            "and flight.id = %s", (flight_id,))  
            economy_capacity, business_capacity, first_capacity = cur.fetchone()  
  
            cur.execute("Select count(*) "
                        "From booking, passenger, flight "
                        "Where pass_id = passenger.id "
                            "and flight.id = flight_id "
                            "and seat_class = 'economy' "
                            "and booking.flight_id = %s", (flight_id,))  
            booked_economy = cur.fetchone()[0]
  
            cur.execute("Select count(*) "  
                        "From booking, passenger, flight "
                        "Where pass_id = passenger.id "  
                            "and flight.id = flight_id "
                            "and seat_class = 'business' " 
                            "and booking.flight_id = %s", (flight_id,))  
            booked_business = cur.fetchone()[0]
  
            cur.execute("Select count(*) "
                        "From booking, passenger, flight "
                        "Where pass_id = passenger.id "
                            "and flight.id = flight_id "
                            "and seat_class = 'first' "
                            "and booking.flight_id = %s", (flight_id,))  
            booked_first = cur.fetchone()[0]

            eco_room = booked_economy - economy_capacity
            bus_room = booked_business - business_capacity
            fir_room = booked_first - first_capacity

            f_used = math.ceil(first_capacity / 6) * 6
            b_used = math.ceil(business_capacity / 6) * 6
            space_dic = {
                'economy': f_used + b_used + booked_economy + 1,
                'business': f_used + booked_business + 1,
                'first': booked_first + 1
            }

            # print("below")
            # print("Select * "
            #             "From booking "
            #             f"Where flight_id = {flight_id};")
            cur.execute("Select * "
                        "From booking "
                        f"Where flight_id = {flight_id};")  
            all_ = cur.fetchall()

            total_upgraded = 0  
            for row in all_:  
                # print(row)
                id_ = row[0]  
                seat_class_ = row[5]  
                row_ = row[6]  
                letter_ = row[7]
                if total_upgraded == 10:  
                    return 10  
                elif (row_ is None or letter_ is None):  
                    if bus_room == 0 and fir_room == 0:  
                        cur.execute("DELETE From booking Where id = id;")  
                    elif seat_class_ == 'economy' and eco_room > 0 and bus_room < 0:  
                        # print(id_, seat_class_, row_, letter_)
                        # print("here")
                        total_upgraded += 1  
                        eco_room -= 1
                        bus_room += 1
                        tup_ = self._calc_seat(space_dic['business'])
                        # print("UPDATE booking "
                        #         "Set seat_class = 'business', "
                        #         f"row = {tup_[0]}, "
                        #         f"letter = '{tup_[1]}' "
                        #         f"Where id = {id_};")
                        cur.execute("UPDATE booking "
                                    "Set seat_class = 'business', "
                                    "row = %s, "
                                    "letter = %s "
                                    "Where id = %s;", (tup_[0], tup_[1], id_))
                    elif seat_class_ == 'economy' and eco_room > 0 and bus_room == 0 and fir_room < 0:  
                        total_upgraded += 1  
                        eco_room -= 1
                        bus_room += 1
                        tup_ = self._calc_seat(space_dic['first'])
                        cur.execute("UPDATE booking "
                                    "Set seat_class = 'first', "
                                    "row = %s, "
                                    "letter = %s "
                                    "Where id = %s;", (tup_[0], tup_[1], id_))
                    elif seat_class_ == 'business' and bus_room == 0 and fir_room < 0:  
                        total_upgraded += 1  
                        tup_ = self._calc_seat(space_dic['first'])
                        cur.execute("UPDATE booking "
                                    "Set seat_class = 'first', "
                                    "row = %s, "
                                    "letter = %s "
                                    "Where id = %s;", (tup_[0], tup_[1], id_))
            return total_upgraded  
        except pg.Error:  
            return None


# ----------------------- Helper methods below  ------------------------- */
    

    # A helpful method for adding a timestamp to new bookings.
    def _get_current_timestamp(self):
        """Return a datetime object of the current time, formatted as required
        in our database.
        """
        return datetime.datetime.now().replace(microsecond=0)


    ## Add more helper methods below if desired.

    def _calc_seat(self, num_seat: int) -> Tuple[int, str]:
        row = (num_seat - 1) // 6 + 1
        seat = num_seat % 6
        letter_dic = {
            1: 'A', 2: 'B', 3: 'C', 4: 'D', 5: 'E', 0: 'F'
        }
        return row, letter_dic[seat]


# ----------------------- Testing code below  ------------------------- */

def sample_testing_function() -> None:
    a2 = Assignment2()
    # TO DO: Change this to connect to your own database:
    print(a2.connect_db("csc343h-yangy180", "yangy180", "2000yi005"))

    # TODO: Test one or more methods here.
    assert(a2._calc_seat(12) == (2, 'F'))
    assert(a2._calc_seat(1) == (1, 'A'))

    # book_seat(self, pass_id: int, flight_id: int, seat_class: str) -> Optional[bool]
    cur = a2.db_conn.cursor()

    # cur.execute("SELECT count(*) FROM Booking;")
    # num_rows = cur.fetchone()[0]

    # assert(a2.book_seat(-12, 1, 'economy') == False)  # id not found
    # assert(a2.book_seat(1, -12, 'economy') == False)  # same
    # assert(a2.book_seat(1, 1, 'league') == False)  # seat_class wrong
    # assert(a2.book_seat(1, 5, 'first') == False)  # full
    # assert(a2.book_seat(1, 10, 'business'))
    # assert(a2.book_seat(1, 10, 'economy'))  # full but < 10
    # # test 2 rows are inserted
    # cur.execute("SELECT count(*) FROM Booking;")
    # assert(num_rows + 2 == cur.fetchone()[0])

    # for i in range(8):
    #     assert(a2.book_seat(1, 10, 'economy'))
    # assert(a2.book_seat(1, 10, 'economy') == False)  # reach 10
    # # test 8 rows are inserted
    # cur.execute("SELECT count(*) FROM Booking;")
    # assert(num_rows + 10 == cur.fetchone()[0])

    # # print Booking
    # cur.execute("SELECT * FROM Booking;")
    # for i in cur:
    #     print(i)

    # # upgrade(self, flight_id: int) -> Optional[int]
    # # flight 5: f: 1/1, b: 1/2, e: 3/3
    # assert(a2.book_seat(1, 5, 'economy'))
    # # flight 5: f: 1/1, b: 1/2, e: 4/3
    # val = a2.upgrade(5)
    # # print(val)
    # assert(val == 1)
    # # flight 5: f: 1/1, b: 2/2, e: 3/3
    # cur.execute("SELECT * FROM Booking WHERE flight_id = 5;")


## You can put testing code in here. It will not affect our autotester.
if __name__ == '__main__':
    # TODO: Put your testing code here, or call testing functions such as
    # this one:
    sample_testing_function()





