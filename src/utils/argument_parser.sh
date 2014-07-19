#!/usr/bin/env bash

key_exists() {
  if [ "$2" != in ]; then
    echo "Incorrect usage."
    echo "Correct usage: key_exists {key} in {array}"
    return
  fi

  eval '[ ${'$3'[$1]+key_exists} ]'
}

is_option() {
  if [[ $1 == --* ]] || [[ $1 == -* ]]; then
    return 0
  fi

  return 1
}
parse_arguments() {
  command=''
  required_arguments=()
  declare -g -A optional_arguments
  optional_arguments=()

  local number_required_arguments known_options raw_arguments

  number_required_arguments=$1
  known_options=("${!2}")
  raw_arguments=("${!3}")

  local no_raw_arguments first_argument could_argument_option current_arg

  no_raw_arguments=${#raw_arguments[@]}
  first_argument=true
  could_argument_option=false
  current_arg=''
  counter=0

  while [[ ${counter} < ${no_raw_arguments} ]]; do
    arg="${raw_arguments["${counter}"]}"

    if [[ ${counter} == 0 ]] && !(is_option ${arg}); then
      command=${arg}
    elif [[ ${counter} < ${no_raw_arguments} ]] && !(is_option ${arg}); then
      required_arguments=("${required_arguments[@]}" ${arg})
    elif [[ ${counter} > no_raw_arguments ]] && is_option ${arg}; then
      could_argument_option=true
      current_arg=`expr "${arg}" : '-*\([a-zA-Z]*\)'`

      if !(key_exists ${current_arg} in optional_arguments); then
        optional_arguments["${current_arg}"]=''
      fi

      let next=counter+1
      arg="${raw_arguments["${next}"]}"

      if !(is_option ${arg}); then
        if [[ "${optional_arguments["${current_arg}"]}" != "" ]]; then
          optional_arguments["${current_arg}"]+="|"
        fi

        optional_arguments["${current_arg}"]+="${arg}"
      fi
    fi

    let counter=counter+1
  done

  for arg in "${raw_arguments[@]}"; do
    if is_option ${arg}; then
      could_argument_option=true
      current_arg=`expr "${arg}" : '-*\([a-zA-Z]*\)'`

      if !(key_exists ${current_arg} in optional_arguments); then
        optional_arguments["${current_arg}"]=''
      fi
    elif ${could_argument_option}; then
      if [[ "${optional_arguments["${current_arg}"]}" != "" ]]; then
        optional_arguments["${current_arg}"]+="|"
      fi

      optional_arguments["${current_arg}"]+="${arg}"
      could_argument_option=false
    elif ${first_argument}; then
      command=${arg}
    elif [[ ${number_required_arguments} > 0 ]]; then
      required_arguments=("${required_arguments[@]}" ${arg})
      let number_required_arguments=number_required_arguments-1
    else
      echo "invalid argument ${arg}"
      exit 1
    fi

    if [ "${command}" == '' ]; then
      echo "no command given"
      exit 1
    else
      first_argument=false
    fi
  done
}

args=("$@")
command_options=(
  '-t/--test|desc'
)
parse_arguments 2 command_options[@] args[@]

#test
echo "--- Command ---"
echo "${command}"
echo "--- Required args ---"
for req_arg in "${required_arguments[@]}"; do
  echo ${req_arg}
done
echo "---- Args -----"

for k in "${!optional_arguments[@]}"; do
  echo "${k}: "
  IFS='|' read -a params <<< "${optional_arguments["${k}"]}"

  for param in "${params[@]}"; do
      echo "-- ${param}"
  done
done