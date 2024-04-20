#! /bin/bash

PSQL="psql -X --username=freecodecamp --dbname=salon -c"

echo -e "\n~~~~~ FCC Salon ~~~~~\n" 

DISPLAY_SERVICES() {
  echo -e "\nHere are the services we offer:"  

  # display available services
    SERVICE_LIST=$($PSQL "SELECT service_id, name FROM services ORDER BY service_id")
    echo "$SERVICE_LIST" | grep -E '^\s+[0-9]+' | sed -E 's/\s*\|\s*/\) /' | sed -E 's/\)  +/\) /'
}

MAIN_MENU() {
  while true; do
    DISPLAY_SERVICES
    echo -e "\nPlease choose a service by entering the number (e.g., 1 for cut): " 
    read SERVICE_ID_SELECTED

    # if input is not a number
    if [[ ! $SERVICE_ID_SELECTED =~ ^[0-9]+$ ]]
    then
      echo -e "\nThat is not a valid service number."
      continue
    fi

      # check if services exists
      SERVICE_NAME=$($PSQL "SELECT name FROM services WHERE service_id = $SERVICE_ID_SELECTED")
      SERVICE_NAME_FORMATTED=$(echo "$SERVICE_NAME" | grep -v -e '^$' -e '-' -e 'row' -e 'name' | xargs)

      if [[ -z $SERVICE_NAME_FORMATTED ]]
      then
        echo -e "\nSorry, that's not a valid services. Please try again."
        continue
      else
        break
      fi
  done

  # get customer info
  echo -e "\nWhat's your phone number?"
  read CUSTOMER_PHONE
  CUSTOMER_NAME=$($PSQL "SELECT name FROM customers WHERE phone = '$CUSTOMER_PHONE'")
  CUSTOMER_NAME_FORMATTED=$(echo "$CUSTOMER_NAME" | grep -v -e '^$' -e '-' -e 'row' -e 'name' | xargs)

  # if customer doesn't exist
  if [[ -z $CUSTOMER_NAME_FORMATTED ]]
  then
    # get new customer name
    echo -e "\nI don't have a record for that phone number. What's your name?"
    read CUSTOMER_NAME

    #insert new customer
    INSERT_CUSTOMER_RESULT=$($PSQL "INSERT INTO customers(name,phone) VALUES('$CUSTOMER_NAME','$CUSTOMER_PHONE')")
    CUSTOMER_NAME_FORMATTED=$(echo "$CUSTOMER_NAME" | grep -v -e '^$' -e '-' -e 'row' -e 'name' | xargs)
  fi

  # get appointment time
  echo -e "\nWhat time would you like your appointment?"
  read SERVICE_TIME

  # get customer_id
  CUSTOMER_ID=$($PSQL "SELECT customer_id FROM customers WHERE phone='$CUSTOMER_PHONE'")
  CUSTOMER_ID_FORMATTED=$(echo "$CUSTOMER_ID" | grep -Eo '[0-9]+' | head -1)

  if [[ -z $CUSTOMER_ID_FORMATTED ]]; then
    echo "Could not find customer ID, please check your database and customer entry."
    exit 1
  fi

  # insert service appointment
  APPOINTMENT_RESULT=$($PSQL "INSERT INTO appointments (customer_id,service_id,time) VALUES ($CUSTOMER_ID_FORMATTED, $SERVICE_ID_SELECTED, '$SERVICE_TIME')")

  # confirm the appointment booking  
  if [[ "$APPOINTMENT_RESULT" =~ "ERROR" ]]; then
    echo -e "\nThere was an error booking your appointment. Please try again."
  else
    echo -e "\nI have put you down for a $SERVICE_NAME_FORMATTED at $SERVICE_TIME, $CUSTOMER_NAME_FORMATTED."
  fi

}

MAIN_MENU