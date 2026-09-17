#!/bin/bash

BASE_URL="https://devjbs.hanwhalife.com:10101/jobmind/api/v1"
#BASE_URL="http://centec.iptime.org:8085/jobmind/api/v1"
BASE_DIR="/hli_app/sw/was/jobmind/jobmind_server/profile/"

. ${BASE_DIR}jobmind_profile

##################################################
# check shell args
##################################################

if [ "$#" -lt 4 ]; then
	echo "Usage:"
	echo "$0 <MAX_WAIT_MIN> <CHECK_INTERVAL_MIN> <gCoreDate:DATE> <PUB_COND:OPTION> ..."
	echo ""
	echo "OPTION"
	echo " ODAT : 오늘"
	echo " PREV : 전일"
	echo " ALL  : 최근 2개월"
	echo ""
	echo "Example"
	echo "$0 180 10 \ \ "
	echo " \"효율센터지급실적적재ETL-OK:PREV\" \ \ "
	echo " \"CNS_S_효율센터지급실적적재ETL-OK:ODAT\" \ \ "
	echo " \"ABC_JOB:ALL\" "
	exit 1
fi

MAX_WAIT_MIN=$1
INTERVAL_MIN=$2

gCoreDate=$3
JOBNAME=$4
#JOBNAME="EXEC_123456#_2_"$0
CHECK_INTERVAL_MIN=$((INTERVAL_MIN * 60))

echo "gCoreDate: $gCoreDate"
echo "JOBNAME: $JOBNAME"

if ! [[ "$MAX_WAIT_MIN" =~ ^[0-9]+$ ]]; then
	echo "MAX_WAIT_MIN must be number"
	exit 1
fi

if ! [[ "$INTERVAL_MIN" =~ ^[0-9]+$ ]]; then
	echo "CHECK_INTERVAL_MIN must be number"
	exit 1
fi

COND_COUNT=$(($# - 4))

##################################################
# get token
##################################################

get_token() {
	HEADER=$(mktemp)
	TOKEN=$(curl -s -D "$HEADER" \
		-X POST "$BASE_URL/sessions" \
		-H "accept: */*" \
		-H "Content-Type: application/json" \
		-d "{
            \"userId\": \"$ID\",
            \"passwd\": \"$PWD\",
            \"authenticationType\": \"$PWD\",
            \"durationMin\": 999
        }" | jq -r '.token')

	echo "TOKEN=$TOKEN"
	# JSESSIONID=$(grep -i '^Set-Cookie:' "$HEADER" \
	# | sed -n 's/.*JSESSIONID=\([^;]*\).*/\1/p')

	#echo "$JSESSIONID"
}

get_token

##################################################
# end time
##################################################

NOW=$(date +%s)
END_TIME=$((NOW + MAX_WAIT_MIN * 60))

echo "START_TIME=$(date)"
echo "END_TIME=$(date -d @$END_TIME)"
echo "COND_COUNT=$COND_COUNT"

##################################################
# loop
##################################################

while true; do

	MATCH_COUNT=0

	for ARG in "${@:5}"; do
		COND="${ARG%:*}"
		OPTION="${ARG#*:}"

		case "$OPTION" in
		ODAT)
			PUB_DT_FR="$gCoreDate"
			PUB_DT_TO="$gCoreDate"
			;;
		PREV)
			PUB_DT_FR=$(date -d "${gCoreDate} -1 day" +%Y%m%d)
			PUB_DT_TO=$PUB_DT_FR
			;;
		ALL)
			PUB_DT_FR=$(date -d "${gCoreDate} -2 months" +%Y%m%d)
			PUB_DT_TO="$gCoreDate"
			;;
		*)
			echo "Invalid option : $OPTION"
			continue
			;;
		esac

		echo "----------------------------------------"
		echo "COND=$COND"
		echo "OPTION=$OPTION"
		echo "FROM=$PUB_DT_FR"
		echo "TO=$PUB_DT_TO"

		##################################################
		# call api
		##################################################

		RESPONSE=$(curl -s -G "$BASE_URL/tickets" \
			--data-urlencode "page=1" \
			--data-urlencode "pageSize=50" \
			--data-urlencode "pubCondNmList=$COND" \
			--data-urlencode "pubDtFr=$PUB_DT_FR" \
			--data-urlencode "pubDtTo=$PUB_DT_TO" \
			-H "accept: */*" \
			-H "Authorization: Bearer $TOKEN")

		echo "RESPONSE=$RESPONSE"

		##################################################
		# connection check
		##################################################

		connection_error="N"

		if [ -z "$RESPONSE" ]; then
			connection_error="Y"
		fi

		if echo "$RESPONSE" | grep -qi "503 Service Unavailable"; then
			connection_error="Y"
		fi

		if echo "$RESPONSE" | jq . >/dev/null 2>&1; then
			STATUS=$(echo "$RESPONSE" | jq -r '.status // empty')

			if [ "$STATUS" = "9999" ]; then
				connection_error="Y"
			fi
		fi

		if [ "$connection_error" = "Y" ]; then
			echo "Connection Error. Re-login..."
			get_token

			RESPONSE=$(curl -s -G "$BASE_URL/tickets" \
				--data-urlencode "page=1" \
				--data-urlencode "pageSize=50" \
				--data-urlencode "pubCondNmList=$COND" \
				--data-urlencode "pubDtFr=$PUB_DT_FR" \
				--data-urlencode "pubDtTo=$PUB_DT_TO" \
				-H "accept: */*" \
				-H "Authorization: Bearer $TOKEN")
		fi

		##################################################
		# compare
		##################################################

		echo "[$COND]"

		EXISTS=$(echo "$RESPONSE" |
			jq -r --arg COND "$COND" \
				'.list[]? | select(.pubCondNm==$COND) | .pubCondNm' | head -1)

		# 티켓이 존재하는지 대상티켓명[#독립수행번호 허용]
		if [[ "$EXISTS" =~ ^"${COND}"(#_?[0-9]+)?$ ]]; then
			echo "MATCH_OK : $COND"

			MATCH_COUNT=$((MATCH_COUNT + 1))
			# 작업명에서 exec_#[0-9]값 파싱
			PREFIX=$(echo "$JOBNAME" | sed -n 's/^\(EXEC_[^#]*#[0-9]*\).*/\1/p')

			POSTFIX=""

			##
			if [ "${JOBNAME:-5:1}" = "#" ]; then
				POSTFIX="${JOBNAME:-4}"
				echo "POSTFIX EXIST: ${POSTFIX}"
			fi

			if [ -n "$PREFIX" ]; then
				TICKET_NAME="${PREFIX}${COND}"
			fi

			if [ -n "$POSTFIX" ]; then
				TICKET_NAME="${PREFIX}${COND}#${POSTFIX}"
			fi
			#

			# 이미 발행했는지 확인
			if echo "$ISSUED_TICKETS" | grep -qxF "$TICKET_NAME" >/dev/null 2>&1; then
				echo "ALREADY ISSUED : $TICKET_NAME"
			else
				echo "PREFIX=$PREFIX"

				RESPONSE=$(curl -s -X POST "$BASE_URL/tickets" \
					-H "accept: */*" \
					-H "Content-Type: application/json" \
					-H "Authorization: Bearer $TOKEN" \
					-d "{
                        \"pubCondNm\": \"$TICKET_NAME\",
                        \"pubDt\": \"$PUB_DT_FR\"
                    }")

				echo "ADD TICKET : $RESPONSE"

				echo $TICKET_NAME
				# 발행 목록에 추가
				ISSUED_TICKETS="${ISSUED_TICKETS:+$ISSUED_TICKETS
}$TICKET_NAME"
			fi
		elif [[ -n "$POSTFIX" && -z "$PREFIX" ]]; then

			TICKET_NAME="${COND}#${POSTFIX}"
			# 이미 발행했는지 확인
			if echo "$ISSUED_TICKETS" | grep -qxF "$TICKET_NAME" >/dev/null 2>&1; then
				echo "ALREADY ISSUED : $TICKET_NAME"
			else
				RESPONSE=$(curl -s -X POST "$BASE_URL/tickets" \
					-H "accept: */*" \
					-H "Content-Type: application/json" \
					-H "Authorization: Bearer $TOKEN" \
					-d "{
                        \"pubCondNm\": \"$TICKET_NAME\",
                        \"pubDt\": \"$PUB_DT_FR\"
                    }")

				echo "ADD TICKET : $RESPONSE"

				echo $TICKET_NAME
				# 발행 목록에 추가
				ISSUED_TICKETS="${ISSUED_TICKETS:+$ISSUED_TICKETS
}$TICKET_NAME"
			fi
		else
			echo "MATCH_FAIL : $COND"
		fi
	done
	echo "MATCH_COUNT=$MATCH_COUNT"
	#    if [ "$MATCH_COUNT" -eq "$COND_COUNT" ]; then
	#        echo "SUCCESS"
	#        exit 0
	#    fi

	NOW=$(date +%s)

	if [ "$NOW" -ge "$END_TIME" ]; then
		echo "$(date) TIMEOUT"
		exit 1
	fi

	sleep "$CHECK_INTERVAL_MIN"

done
