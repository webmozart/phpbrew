#!/usr/bin/env bash
set -euo pipefail

key_exists() {
  eval '[ ${'$2'[$1]+key_exists} ]'
}

is_option() {
  if [[ $1 == --* ]] || [[ $1 == -* ]]; then
    return 0
  fi

  return 1
}

parse_arguments() {
  command=''
  declare -g -A command_arguments=()

  #get function agruments
  local known_arguments=("${!1}")
  local known_options=("${!2}")
  local raw_arguments=("${!3}")


  #get definied options
  local opt_map opt_type_map
  declare -A opt_map=()
  declare -A opt_type_map=()

  for opt in "${known_options[@]}"; do
    local full_opt_name=''
    local opt_names=( $(echo ${opt} | grep -o '[a-z0-9\-]*') )

    if [[ ${#opt_names[@]} == 2 ]]; then
      full_opt_name="--${opt_names[1]}"
      opt_map["-${opt_names[0]}"]=${full_opt_name}
    elif [[ ${#opt_names[@]} == 1 ]]; then
      full_opt_name="--${opt_names[0]}"
      opt_map[${full_opt_name}]=${full_opt_name}
    else
      echo "Error wrong defined options"
      exit 1
    fi

    local opt_type=$(echo ${opt} | grep -o '[:?+]')

    if [[ ${opt_type} == "" ]]; then
      echo "Error no option type given for ${full_opt_name}"
      exit 1
    fi

    opt_type_map[${full_opt_name}]=${opt_type}
  done


  #iterate over the raw argumgents
  local number_command_arguments=${#known_arguments[@]}
  local no_raw_arguments=${#raw_arguments[@]}
  local arg=''
  local current_arg=''
  local counter=0
  local req_param_name=''

  while [[ ${counter} -lt ${no_raw_arguments} ]]; do
    arg=${raw_arguments[${counter}]}

    if [[ ${counter} == 0 ]] && !(is_option ${arg}); then
      command=${arg}
    elif [[ ${counter} -le ${number_command_arguments} ]] && !(is_option ${arg}); then
      req_param_name=${known_arguments[$((counter - 1))]}
      command_arguments[${req_param_name}]=${arg}
    elif [[ ${counter} -gt ${number_command_arguments} ]] && is_option ${arg}; then
      if (key_exists ${arg} opt_map); then
        arg=${opt_map[${arg}]}
      else
        echo "Invalid option ${arg}"
        exit 1
      fi

      current_arg=${arg}
      local is_multiple_opt=false

      if [[ ${opt_type_map[$current_arg]} == '+' ]]; then
        is_multiple_opt=true
      fi

      if ${is_multiple_opt} && !(key_exists "${current_arg},#" command_arguments); then
        command_arguments["${current_arg},#"]=0
      elif !(${is_multiple_opt}) && !(key_exists ${current_arg} command_arguments); then
        command_arguments[${current_arg}]=''
      elif (key_exists ${current_arg} command_arguments) && [[ ${is_multiple_opt} ]]; then
        echo "Error ${current_arg} can't be multiple definied"
        exit 1
      fi

      local next=$((counter + 1))

      if [[ ${next} -lt ${no_raw_arguments} ]]; then
        arg=${raw_arguments[${next}]}

        if [[ ${arg} != "" ]] && !(is_option ${arg}); then
          if ${is_multiple_opt}; then
            local no_opt_args=${command_arguments["${current_arg},#"]}
            command_arguments["${current_arg},${no_opt_args}"]="${arg}"
            command_arguments["${current_arg},#"]=$((no_opt_args+1))
          else
            command_arguments[${current_arg}]="${arg}"
          fi

          counter=${next}
        fi
      fi
    else
      if [[ ${counter} == 0 ]]; then
        echo "invalide command ${arg}"
      elif [[ ${counter} -le ${number_command_arguments} ]]; then
        req_param_name=${known_arguments[$((counter - 1))]}
        echo "missing required parameter ${req_param_name}"
      elif [[ ${counter} -gt ${number_command_arguments} ]]; then
        echo "wrong option ${arg}"
      fi

      exit 1
    fi

    counter=$((counter + 1))
  done
}

#test
command_args=(
  'name'
  'version'
)
sub_commands=(
  ''
)
command_ops=(
  'single-required:'
  'single-optional?'
  'single-repeatable+'
  'r|required-opt:'
  'o|optional-opt?'
  'p|repeatable-opt+'
)
args=("$@")

parse_arguments command_args[@] command_ops[@] args[@]

echo "--- Command ---"
echo "${command}"

echo "---- Args -----"

for k in "${!command_arguments[@]}"; do
  echo "${k}: "
  params=()
  IFS='|' read -a params <<< "${command_arguments["${k}"]}"

  if [ ${#params[@]} -gt 0 ]; then
    for param in "${params[@]}"; do
        echo "${param}"
    done
  fi
done