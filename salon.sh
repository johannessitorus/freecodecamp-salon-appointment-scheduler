#! /bin/bash
set -e
PSQL=(psql -X -qAt -v ON_ERROR_STOP=1 -U freecodecamp -d salon)

printf '\n~~~~~ SALON APPOINTMENT SCHEDULER ~~~~~\n\n'
printf 'Welcome! Which service would you like?\n'
MENU=$("${PSQL[@]}" -c "SELECT service_id || ') ' || name FROM services ORDER BY service_id")
while true; do
  printf '%s\n' "$MENU"
  read SERVICE_ID_SELECTED || exit 0
  SERVICE_NAME=$("${PSQL[@]}" -v id="$SERVICE_ID_SELECTED" <<'SQL'
SELECT name FROM services WHERE service_id::text = :'id';
SQL
)
  [[ -z "$SERVICE_NAME" ]] || break
  printf '\nI could not find that service. What would you like today?\n'
done

printf '\nWhat is your phone number?\n'
read CUSTOMER_PHONE || exit 0
CUSTOMER_NAME=$("${PSQL[@]}" -v phone="$CUSTOMER_PHONE" <<'SQL'
SELECT name FROM customers WHERE phone = :'phone';
SQL
)
if [[ -z "$CUSTOMER_NAME" ]]; then
  printf "\nI don't have a record for that phone number. What is your name?\n"
  read CUSTOMER_NAME || exit 0
fi
printf '\nWhat time would you like your %s, %s?\n' "$SERVICE_NAME" "$CUSTOMER_NAME"
read SERVICE_TIME || exit 0

CUSTOMER_NAME=$("${PSQL[@]}" -v phone="$CUSTOMER_PHONE" -v name="$CUSTOMER_NAME" -v id="$SERVICE_ID_SELECTED" -v time="$SERVICE_TIME" <<'SQL'
BEGIN;
INSERT INTO customers (phone, name) VALUES (:'phone', :'name') ON CONFLICT (phone) DO NOTHING;
INSERT INTO appointments (customer_id, service_id, time)
SELECT customer_id, :'id'::int, :'time' FROM customers WHERE phone = :'phone';
SELECT name FROM customers WHERE phone = :'phone';
COMMIT;
SQL
)
printf '\nI have put you down for a %s at %s, %s.\n' "$SERVICE_NAME" "$SERVICE_TIME" "$CUSTOMER_NAME"
