#!/bin/bash -x

set -o errexit

function resolveNodeName() {
  local logio_nodename="node"
  if [ -n "${LOGIO_HARVESTER_NODENAME}" ]; then
    logio_nodename=${LOGIO_HARVESTER_NODENAME}
  fi
  echo $logio_nodename
}

function resolveStreamName() {
  logio_streamname="stream"
  if [ -n "${LOGIO_HARVESTER_STREAMNAME}" ]; then
    logio_streamname=${LOGIO_HARVESTER_STREAMNAME}
  fi
}

function resolveMasterSetting() {
  logio_master="logio";
  if [ -n "${LOGIO_HARVESTER_MASTER_HOST}" ]; then
    logio_master=${LOGIO_HARVESTER_MASTER_HOST}
  fi
  logio_master_port="28777";
  if [ -n "${LOGIO_HARVESTER_MASTER_PORT}" ]; then
    logio_master_port=${LOGIO_HARVESTER_MASTER_PORT}
  fi
}

function crawlLogFiles() {
  local log_dirs=""

  if [ -n "${LOGS_DIRECTORIES}" ]; then
    log_dirs=${LOGS_DIRECTORIES}
  fi

  local log_file_pattern=""

  if [ -n "${LOG_FILE_PATTERN}" ]; then
    log_file_pattern=${LOG_FILE_PATTERN}
  fi

  LOG_PATTERN_FILES=""
  SAVEIFS=$IFS
  IFS=' '
  for pattern in "${log_file_pattern}"
  do
    for d in ${log_dirs}
    do
      IFS=$'\n'
      CRAWLED_LOGFILES=$(find ${d} -type f -iname "${pattern}")
      for foundfile in $CRAWLED_LOGFILES;
      do
        LOG_PATTERN_FILES=$LOG_PATTERN_FILES\"${foundfile}\",$'\n'
      done
      IFS=$' '
    done
  done
  IFS=$SAVEIFS
}

function crawlParameterizedLogFiles() {
  local index=$1
  local log_dirs=""

  VAR_LOGIO_HARVESTER_LOGSTREAMS="LOGIO_HARVESTER${i}LOGSTREAMS"
  VAR_LOGIO_HARVESTER_FILEPATTERN="LOGIO_HARVESTER${i}FILEPATTERN"

  log_dirs=${!VAR_LOGIO_HARVESTER_LOGSTREAMS}
  local log_file_pattern
  read -r -a log_file_pattern <<< "${!VAR_LOGIO_HARVESTER_FILEPATTERN}"

  LOG_PATTERN_FILES=""
  SAVEIFS=$IFS
  IFS=' '
  local i=0
  for (( i; i < ${#log_file_pattern}; i++ ))
  do
    pattern="${log_file_pattern[$i]}"
    for d in ${log_dirs}
    do
      IFS=$'\n'
      CRAWLED_LOGFILES=$(find ${d} -type f -iname "${pattern}")
      for foundfile in $CRAWLED_LOGFILES;
      do
        LOG_PATTERN_FILES=$LOG_PATTERN_FILES\"${foundfile}\",$'\n'
      done
      IFS=$' '
    done
  done
  IFS=$SAVEIFS
}

function collectHarvesterLogfiles() {
  harvester_log_files=""
  HARVESTER_LOG_FILES=""

  if [ -n "${LOGIO_HARVESTER_LOGFILES}" ]; then
    harvester_log_files=${LOGIO_HARVESTER_LOGFILES}
  fi

  SAVEIFS=$IFS
  IFS=$' '
  COUNTER=0
  for logfile in $harvester_log_files
  do
    HARVESTER_LOG_FILES=$LOG_FILES\"${logfile}\",$'\n'
  done
  IFS=$SAVEIFS
}

function crawlLegacyLogfileMechanism() {
  crawlSingleConfiguration
  crawlEnumeratedConfiguration
}

function crawlEnumeratedConfiguration() {
  local i=1
  for (( i; ; i++ ))
  do
    VAR_LOGIO_HARVESTER_STREAMNAME="LOGIO_HARVESTER${i}STREAMNAME"
    if [ ! -n "${!VAR_LOGIO_HARVESTER_STREAMNAME}" ]; then
      break
    fi
    local streamname=${!VAR_LOGIO_HARVESTER_STREAMNAME}
    crawlParameterizedLogFiles ${i}
    local attachlogs=${LOG_PATTERN_FILES}
    if [ -n "${attachlogs}" ]; then
      attachlogs=${attachlogs::-2}
      cat >> ~/.log.io/harvester.conf <<_EOF_
    ${streamname}: [
      ${attachlogs}
    ],
_EOF_
    fi

  done
}

function crawlSingleConfiguration() {
  resolveStreamName
  collectHarvesterLogfiles
  crawlLogFiles
  ATTACH_LOGS=${HARVESTER_LOG_FILES}${LOG_PATTERN_FILES}
  if [ -n "${ATTACH_LOGS}" ]; then
    ATTACH_LOGS=${ATTACH_LOGS::-2}
    cat >> ~/.log.io/harvester.conf <<_EOF_
    ${logio_streamname}: [
      ${ATTACH_LOGS}
    ],
_EOF_
  fi

}

function crawlForStreamFiles() {
  local fileMatchPattern=$1
  local files=""
  echo $files
}

function crawlForStreams() {
  local streams=""
  if [ -n "${LOGIO_HARVESTER_STREAMS}" ]; then
    streams=${LOGIO_HARVESTER_STREAMS}
  fi
  SAVEIFS=$IFS
  IFS=$' '
  for stream in $streams
  do
    streamParameters=(${stream//:/ })
    local streamname=${streamParameters[0]}
    local files=$(crawlForStreamFiles "${streamParameters[1]}")
    cat > ~/.log.io/harvester.conf <<_EOF_
    ${streamname}: [
      ${files}
    ]
_EOF_
  done
  IFS=$SAVEIFS
}

function printHarvesterConfigFile() {
  local node=`resolveNodeName`
  cat > ~/.log.io/harvester.conf <<_EOF_
exports.config = {
  nodeName: "${node}",
  logStreams: {
_EOF_
  crawlLegacyLogfileMechanism
  resolveMasterSetting
  cat >> ~/.log.io/harvester.conf <<_EOF_
  },
  server: {
    host: '${logio_master}',
    port: ${logio_master_port}
  }
}
_EOF_
  cat ~/.log.io/harvester.conf
}
