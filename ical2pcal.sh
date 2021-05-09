#!/bin/bash

# Copyright (c) 2010 Jörg Kühne <jk-ical2pcal at gmx dot de>
# Copyright (c) 2008 Francisco José Marín Pérez <pacogeek at gmail dot com>

# All rights reserved. (The Mit License)

#Permission is hereby granted, free of charge, to any person obtaining a copy
#of this software and associated documentation files (the "Software"), to deal
#in the Software without restriction, including without limitation the rights
#to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
#copies of the Software, and to permit persons to whom the Software is
#furnished to do so, subject to the following conditions:
#
#The above copyright notice and this permission notice shall be included in
#all copies or substantial portions of the Software.
#
#THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
#IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
#FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
#AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
#LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
#OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
#THE SOFTWARE.

# Changes from Jörg Kühne

#v0.0.7
# - fix handling of events without end time

#v0.0.6
# - correct handling of repeating events with count condition
# - better display of events that have equal start and end time

#v0.0.5
# - support of changed single events in a series of repeating events

#v0.0.4
# - support of excluded dates in a simple series of repeating events

#v0.0.3
# - support of simple repeating events like:
#   every n-th [day|week|month|year] from <DATE> until <DATE>
#   but not like:
#   every first sunday in month

# v0.0.2:
# - auto conversion from UTC times to local times
# - support of multiple day events
# - support of begin/end times

# ----------------------------------------------------------------------
# Configuration

# if the gnu date command is not in default path, please specify the command
# with full path
GNU_DATE_COMMAND=""

# ----------------------------------------------------------------------
# Code starts here

help() { # Show the help
   cat << EOF
ical2pcal v0.0.7 - Convert iCalendar (.ics) data files to pcal data files

Usage:   ical2pcal  [-E] [-o <file>] [-h] file

         -E Use European date format (dd/mm/yyyy)

         -o <file> Write the output to file instead of to stdout

         -h Display this help

The iCalendar format (.ics file extension) is a standard (RFC 2445)
for calendar data exchange. Programs that support the iCalendar format
are: Google Calendar, Apple iCal, Evolution, Orange, etc.

The iCalendar format have many objects like events, to-do lists,
alarms, journal entries etc. ical2pcal only use the events
in the file showing in the pcal file the summary and the time of
the event, the rest information of the event like
description or location are commented in the pcal file (because
usually this information does not fit in the day box).

Currently automatic detection and conversion to local time of time values
in UTC is implemented. All other time values are assumed as local times.

ical2pcal does not support complex repeating events, like every first sunday in month.
Only simple recurrence are allowed like:
every n-th [day|week|month|year] from <DATE> until <DATE> except <DATE>,...

EOF
}

european_format=0
output="/dev/stdout"

while getopts Eho: arg
do
   case "$arg"
   in
      E) european_format=1;;

      o) output="$OPTARG";;

      h) help
         exit 0;;

      ?) help
         exit 1;;
   esac
done

shift $(( $OPTIND - 1))

if [ $# -lt 1 ]
then
   help
   exit 0
fi

if [ -z "$GNU_DATE_COMMAND" ]; then
   GNU_DATE_COMMAND=date
fi

# check date command for gnu version
TEST_DATE=`"$GNU_DATE_COMMAND" -d 20100101 +%Y%m%d`
if [ "x$TEST_DATE" != "x20100101" ]; then
   echo "Gnu version of date command not found. Please set correct config value."
   echo " "
   exit 1
fi

{
  cat "$*" |
  awk '
  BEGIN{
     RS = ""
  }

  {
     gsub(/\r/,"",$0) # Remove the Windows style line ending
     gsub(/\f/,"",$0) # Remove the Windows style line ending
     gsub(/\n /,"", $0) # Unfold the lines
     gsub(/\\\\/,"\\",$0)
     gsub(/\\,/,",",$0)
     gsub(/\\;/,";",$0)
     gsub(/\\n/," ",$0)
     gsub(/\\N/," ",$0)
     print
  }' |
  awk -v date_command="$GNU_DATE_COMMAND" '
  BEGIN {
     FS = ":" #field separator
     print "BEGIN:RECURRENCES"
  }

  $0 ~ /^BEGIN:VEVENT/ {
     recurrence = 0
     all_day_event = 0
     summary = ""
     utc_time = 0
     recurrence_date = ""
     uid = ""

     while ($0 !~ /^END:VEVENT/)
     {
        if ($1 ~ /^RECURRENCE-ID/)
        {
           year = substr($2, 1, 4)
           month = substr($2, 5, 2)
           day = substr($2, 7, 2)

           if ($1 ~ /VALUE=DATE/)
           {
              all_day_event = 1
           }
           else
           {
              hour = substr($2, 10, 2)
              minute = substr($2, 12, 2)
              UTCTAG = substr($2, 16, 1)

              if (UTCTAG == "Z")
              {
                 utc_time = 1
              }
           }

           recurrence = 1
        }

        if ($1 ~ /^SUMMARY/)
        {
           sub(/SUMMARY/,"",$0)
           sub(/^:/,"",$0)
           summary = $0
        }

        if ($1 ~ /^UID/)
        {
           sub(/UID/,"",$0)
           sub(/^:/,"",$0)
           uid = $0
        }

        getline
     }

     if ( recurrence )
     {
        if (! all_day_event && utc_time)
        {
           # Convert Date/Time from UTC to local time

           tmp_date = year month day "UTC" hour minute
           command = date_command " -d" tmp_date " +%Y%m%d%H%M"
           command | getline captureresult
           close(command)
           year = substr(captureresult, 1, 4)
           month = substr(captureresult, 5, 2)
           day = substr(captureresult, 7, 2)
           hour = substr(captureresult, 9, 2)
           minute = substr(captureresult, 11, 2)
        }

        if (all_day_event)
        {
           recurrence_date = year month day
        }
        else
        {
           recurrence_date = year month day hour minute
        }

        print "RECURRENCE_ENTRY:" uid ":" recurrence_date ":" summary
     }
  }

  END {
     print "END:RECURRENCES"
  }'

  cat "$*" |
  awk '
  BEGIN{
     RS = ""
  }

  {
     gsub(/\r/,"",$0) # Remove the Windows style line ending
     gsub(/\f/,"",$0) # Remove the Windows style line ending
     gsub(/\n /,"", $0) # Unfold the lines
     gsub(/\\\\/,"\\",$0)
     gsub(/\\,/,",",$0)
     gsub(/\\;/,";",$0)
     gsub(/\\n/," ",$0)
     gsub(/\\N/," ",$0)
     print
  }'

} | awk -v european_format=$european_format -v date_command="$GNU_DATE_COMMAND" '
BEGIN {
   FS = ":" #field separator
   print "# Creator: ical2pcal"
   print "# include this file into your .calendar file with: include \"a_file.pcal\"\n"
}

$0 ~ /^BEGIN:RECURRENCES/ {
   recurrence_index = 0
   print "#Replaced events in event series:"

   while ($0 !~ /^END:RECURRENCES/)
   {
      if ($1 ~ /^RECURRENCE_ENTRY/)
      {
         recurrences[recurrence_index] = $2 ":" $3
         recurrence_index = recurrence_index + 1
         print "#" $1 ":" $3 ":" substr($0, index($0,$4))
      }

      getline
   }

   print ""
}

$0 ~ /^BEGIN:VEVENT/ {
   all_day_event = 0
   no_start_date = 1
   no_end_date = 1
   utc_time = 0
   summary = ""
   location = ""
   description = ""
   uid = ""
   recurence_reference_date = ""

   repeat = 1
   repeating_event = 0
   frequency =""
   interval = 1
   count = 0
   repeating_end_date = ""
   date_incr_str = "week"
   debug_repeat_str = ""
   # empty exdates array
   for (i in exdates)
   {
      delete exdates[i]
   }
   exdates_index = 0

   while ($0 !~ /^END:VEVENT/)
   {
      if ($1 ~ /^DTSTART/)
      {
         year_start = substr($2, 1, 4)
         month_start = substr($2, 5, 2)
         day_start = substr($2, 7, 2)

         if ($1 ~ /VALUE=DATE/)
         {
            all_day_event = 1
         }
         else
         {
            hour_start = substr($2, 10, 2)
            minute_start = substr($2, 12, 2)
            UTCTAG = substr($2, 16, 1)

            if (UTCTAG == "Z")
            {
               utc_time = 1
            }
         }
         
         no_start_date = 0
      }

      if ($1 ~ /^DTEND/)
      {
         year_end = substr($2, 1, 4)
         month_end = substr($2, 5, 2)
         day_end = substr($2, 7, 2)

         if ($1 ~ /VALUE=DATE/)
         {
            all_day_event = 1
         }
         else
         {
            hour_end = substr($2, 10, 2)
            minute_end = substr($2, 12, 2)
         }
         
         no_end_date = 0
      }

      if ($1 ~ /^SUMMARY/)
      {
         sub(/SUMMARY/,"",$0)
         sub(/^:/,"",$0)
         summary = $0
      }

      if ($1 ~ /^LOCATION/)
      {
         sub(/LOCATION/,"",$0)
         sub(/^:/,"",$0)
         location = $0
      }

      if ($1 ~ /^DESCRIPTION/)
      {
         sub(/DESCRIPTION/,"",$0)
         sub(/^:/,"",$0)
         description = $0
      }

      if ($1 ~ /^UID/)
      {
         sub(/UID/,"",$0)
         sub(/^:/,"",$0)
         uid = $0
      }

      if ($1 ~ /^RRULE/)
      {
         debug_repeat_str = $0
         sub(/RRULE/,"",$0)
         sub(/^:/,"",$0)
         split($0,part,";")
         for (i in part)
         {
            numparts = split(part[i],subpart,"=")

            if (numparts > 1)
            {
               if (subpart[1] ~ /FREQ/)
               {
                  frequency = subpart[2]
               }

               if (subpart[1] ~ /INTERVAL/)
               {
                  interval = subpart[2]
               }

               if (subpart[1] ~ /COUNT/)
               {
                  count = subpart[2]
               }

               if (subpart[1] ~ /UNTIL/)
               {
                  until_year = substr(subpart[2], 1, 4)
                  until_month = substr(subpart[2], 5, 2)
                  until_day = substr(subpart[2], 7, 2)
                  until_hour = substr(subpart[2], 10, 2)
                  until_minute = substr(subpart[2], 12, 2)
                  until_UTCTAG = substr(subpart[2], 16, 1)

                  if (until_UTCTAG == "Z")
                  {
                     tmp_repeating_end_date = until_year until_month until_day "UTC" until_hour until_minute
                     command = date_command " -d" tmp_repeating_end_date " +%Y%m%d%H%M"
                     command | getline captureresult
                     close(command)
                     until_year = substr(captureresult, 1, 4)
                     until_month = substr(captureresult, 5, 2)
                     until_day = substr(captureresult, 7, 2)
                  }

                  repeating_end_date = until_year until_month until_day
               }
            }
         }

         if (frequency == "DAILY")
         {
            repeating_event = 1
            date_incr_str = "day"
            if (count == 0)
            {
               count = 750
            }
         }
         if (frequency == "WEEKLY")
         {
            repeating_event = 1
            date_incr_str = "week"
            if (count == 0)
            {
               count = 260
            }
         }
         if (frequency == "MONTHLY")
         {
            repeating_event = 1
            date_incr_str = "month"
            if (count == 0)
            {
               count = 60
            }
         }
         if (frequency == "YEARLY")
         {
            repeating_event = 1
            date_incr_str = "year"
            if (count == 0)
            {
               count = 5
            }
         }
      }

      if ($1 ~ /^EXDATE/)
      {
         split($2,part,",")
         for (i in part)
         {
            year_exdate = substr(part[i], 1, 4)
            month_exdate = substr(part[i], 5, 2)
            day_exdate = substr(part[i], 7, 2)
            hour_exdate = substr(part[i], 10, 2)
            minute_exdate = substr(part[i], 12, 2)
            UTCTAG = substr(part[i], 16, 1)

            if (UTCTAG == "Z")
            {
               tmp_exdate = year_exdate month_exdate day_exdate "UTC" hour_exdate minute_exdate
               command = date_command " -d" tmp_exdate " +%Y%m%d%H%M"
               command | getline captureresult
               close(command)
               year_exdate = substr(captureresult, 1, 4)
               month_exdate = substr(captureresult, 5, 2)
               day_exdate = substr(captureresult, 7, 2)
            }

            tmp_exdate = year_exdate month_exdate day_exdate
            exdates[exdates_index] = tmp_exdate
            exdates_index = exdates_index + 1
         }
      }

      getline
   }

   if (count == 0)
   {
      count = 1
   }
   
   if (no_start_date == 1)
   {
      next
   }
   
   if (no_end_date == 1)
   {  
      # event only with start time
      year_end = year_start
      month_end = month_start
      day_end = day_start
      hour_end = hour_start
      minute_end = minute_start
   }

   if (! all_day_event && utc_time)
   {
      # Convert Date/Time from UTC to local time

      tmp_date_start = year_start month_start day_start "UTC" hour_start minute_start
      command = date_command " -d" tmp_date_start " +%Y%m%d%H%M"
      command | getline captureresult
      close(command)
      year_start = substr(captureresult, 1, 4)
      month_start = substr(captureresult, 5, 2)
      day_start = substr(captureresult, 7, 2)
      hour_start = substr(captureresult, 9, 2)
      minute_start = substr(captureresult, 11, 2)

      tmp_date_end = year_end month_end day_end "UTC" hour_end minute_end
      command = date_command " -d " tmp_date_end " +%Y%m%d%H%M"
      command | getline captureresult
      close(command)
      year_end = substr(captureresult, 1, 4)
      month_end = substr(captureresult, 5, 2)
      day_end = substr(captureresult, 7, 2)
      hour_end = substr(captureresult, 9, 2)
      minute_end = substr(captureresult, 11, 2)
   }

   date_start = year_start month_start day_start
   date_end = year_end month_end day_end

   # avoid new day entry if end time is 12AM
   if (! all_day_event && hour_end == "00" && minute_end == "00")
   {
      command = date_command "  -d \"" date_end " -1 day\"" " +%Y%m%d"
      command | getline captureresult
      close(command)
      year_end = substr(captureresult, 1, 4)
      month_end = substr(captureresult, 5, 2)
      day_end = substr(captureresult, 7, 2)

      date_end = year_end month_end day_end
   }

   if (summary == "")
   {
      next
   }

   print "#### BEGIN EVENT -----------------------------------"

   if (debug_repeat_str != "")
   {
      print "#"debug_repeat_str
   }
   if (exdates_index > 0)
   {
      for (i in exdates)
      {
         print "#EXDATE:" exdates[i]
      }
   }

   num_repetitions = 0
   while (repeat == 1 && num_repetitions < count)
   {
      date_start_bak = date_start
      date_end_bak = date_end

      # check for excluded dates
      exdate = 0
      for (i in exdates)
      {
         if (exdates[i] == date_start)
         {
            exdate = 1
            break
         }
      }

      if (exdate == 0 && repeating_event)
      {
         if (! all_day_event)
         {
            recurence_reference_date = year_start month_start day_start hour_start minute_start
         }
         else
         {
            recurence_reference_date = year_start month_start day_start
         }

         for (i in recurrences)
         {
            if (recurrences[i] == uid ":" recurence_reference_date)
            {
               exdate = 1
               print "#skip event due to modified series element: " uid ":" recurence_reference_date
               break
            }
         }
      }

      if (exdate == 0)
      {
         if (all_day_event)
         {
            # Hack to save calculation time - not works for last day of month
            if (date_start + 1 == date_end)
            {
               if (european_format)
               {
                  print day_start "/" month_start "/" year_start " " summary
               }
               else
               {
                  print month_start "/" day_start "/" year_start " " summary
               }
            }
            else
            {
               if (date_start < date_end)
               {
                  date_next = date_start
                  while (date_next < date_end)
                  {
                     tmp_year_next = substr(date_next, 1, 4)
                     tmp_month_next = substr(date_next, 5, 2)
                     tmp_day_next = substr(date_next, 7, 2)

                     if (european_format)
                     {
                        print tmp_day_next "/" tmp_month_next "/" tmp_year_next " " summary
                     }
                     else
                     {
                        print tmp_month_next "/" tmp_day_next "/" tmp_year_next " " summary
                     }

                     command = date_command  " -d \"" date_next " 1 day\"" " +%Y%m%d"
                     command | getline captureresult
                     close(command)
                     date_next = captureresult
                  }
               }
               else
               {
                  # Should not happen
                  if (european_format)
                  {
                     print day_start "/" month_start "/" year_start " " summary
                  }
                  else
                  {
                     print month_start "/" day_start "/" year_start " " summary
                  }
               }
            }
         }
         else
         {
            if (date_start < date_end)
            {
               # first date with start time
               if (european_format)
               {
                  print day_start "/" month_start "/" year_start " " hour_start ":" minute_start " -> " summary
               }
               else
               {
                  command = date_command " -d " hour_start ":" minute_start " +%I:%M%P"
                  command | getline time_start
                  close(command)

                  print month_start "/" day_start "/" year_start " " time_start " -> " summary
               }

               #middle days without time
               command = date_command  " -d \"" date_start " 1 day\"" " +%Y%m%d"
               command | getline captureresult
               close(command)
               date_next = captureresult
               while (date_next < date_end)
               {
                  tmp_year_next = substr(date_next, 1, 4)
                  tmp_month_next = substr(date_next, 5, 2)
                  tmp_day_next = substr(date_next, 7, 2)

                  if (european_format)
                  {
                     print tmp_day_next "/" tmp_month_next "/" tmp_year_next " " summary
                  }
                  else
                  {
                     print tmp_month_next "/" tmp_day_next "/" tmp_year_next " " summary
                  }

                  command = date_command " -d \"" date_next " 1 day\"" " +%Y%m%d"
                  command | getline captureresult
                  close(command)
                  date_next = captureresult
               }

               # last day with end time
               if (european_format)
               {
                  print day_end "/" month_end "/" year_end " -> " hour_end ":" minute_end " " summary
               }
               else
               {
                  command = date_command " -d " hour_end ":" minute_end " +%I:%M%P"
                  command | getline time_end
                  close(command)

                  print month_end "/" day_end "/" year_end " -> " time_end " " summary
               }
            }
            else
            {
               if (european_format)
               {
                  if (hour_start == hour_end && minute_start == minute_end)
                  {
                     print day_start "/" month_start "/" year_start " " hour_start ":" minute_start " " summary
                  }
                  else
                  {
                     print day_start "/" month_start "/" year_start " " hour_start ":" minute_start "-" hour_end ":" minute_end " " summary
                  }
               }
               else
               {
                  command = date_command " -d " hour_start ":" minute_start " +%I:%M%P"
                  command | getline time_start
                  close(command)

                  command = date_command " -d " hour_end ":" minute_end " +%I:%M%P"
                  command | getline time_end
                  close(command)

                  if (time_start == time_end)
                  {
                     print month_start "/" day_start "/" year_start " " time_start " " summary
                  }
                  else
                  {
                     print month_start "/" day_start "/" year_start " " time_start "-" time_end " " summary
                  }
               }
            }
         }
         if (location != "")
         {
            if (european_format)
            {
               print "#"day_start "/" month_start "/" year_start" location: "location
            }
            else
            {
               print "#"month_start "/" day_start "/" year_start" location: "location
            }
         }
         if (description != "")
         {
            if (european_format)
            {
               print "#"day_start "/" month_start "/" year_start" description: "description
            }
            else
            {
               print "#"month_start "/" day_start "/" year_start" description: "description
            }
         }
      }

      # calculate repeating events
      if (repeating_event == 0)
      {
         repeat = 0
      }
      else
      {
         num_repetitions = num_repetitions + 1

         command = date_command  " -d \"" date_start_bak " " interval " " date_incr_str "\" " "+%Y%m%d"
         command | getline captureresult
         close(command)
         date_start = captureresult
         year_start = substr(captureresult, 1, 4)
         month_start = substr(captureresult, 5, 2)
         day_start = substr(captureresult, 7, 2)

         command = date_command  " -d \"" date_end_bak " " interval " " date_incr_str "\" " "+%Y%m%d"
         command | getline captureresult
         close(command)
         date_end = captureresult
         year_end = substr(captureresult, 1, 4)
         month_end = substr(captureresult, 5, 2)
         day_end = substr(captureresult, 7, 2)

         if (repeating_end_date != "" && date_start > repeating_end_date)
         {
            repeat = 0
         }
      }
   }

   print "#### END EVENT -------------------------------------\n"
}

END {

}' > "$output"
