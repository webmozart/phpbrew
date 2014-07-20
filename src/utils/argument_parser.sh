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
  declare -g -A required_arguments
  required_arguments=()
  declare -g -A optional_arguments
  optional_arguments=()

  local known_arguments known_options raw_arguments

  known_arguments=("${!1}")
  known_options=("${!2}")
  raw_arguments=("${!3}")

  local number_required_arguments no_raw_arguments current_arg counter

  number_required_arguments=${#known_arguments[@]}
  no_raw_arguments=${#raw_arguments[@]}
  current_arg=''
  counter=0

  while [[ ${counter} -lt ${no_raw_arguments} ]]; do
    arg="${raw_arguments["${counter}"]}"

    if [[ ${counter} == 0 ]] && !(is_option ${arg}); then
      command=${arg}
    elif [[ ${counter} -le ${number_required_arguments} ]] && !(is_option ${arg}); then
      required_arguments=("${required_arguments[@]}" ${arg})
    elif [[ ${counter} -gt ${number_required_arguments} ]] && is_option ${arg}; then
      current_arg=`expr "${arg}" : '-*\([a-zA-Z]*\)'`

      if !(key_exists ${current_arg} in optional_arguments); then
        optional_arguments["${current_arg}"]=''
      fi

      local next
      let next=counter+1
      arg="${raw_arguments["${next}"]}"

      if [[ ${arg} != "" ]] && !(is_option ${arg}); then
        if [[ "${optional_arguments["${current_arg}"]}" != "" ]]; then
          optional_arguments["${current_arg}"]+="|"
        fi

        optional_arguments["${current_arg}"]+="${arg}"
        let counter=next
      fi
    else
      if [[ ${counter} == 0 ]]; then
        echo "invalide command ${arg}"
      elif [[ ${counter} -le ${number_required_arguments} ]]; then
        req_param_name=known_arguments[0]
        echo "missing required parameter ${req_param_name}"
      elif [[ ${counter} -gt ${number_required_arguments} ]]; then
        echo "wrong option ${arg}"
      fi

      exit 1
    fi

    let counter=counter+1
  done
}

args=("$@")
known_arguments=('name' 'version')
known_options=(
  '-t/--test|desc'
)
parse_arguments known_arguments[@] command_options[@] args[@]

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