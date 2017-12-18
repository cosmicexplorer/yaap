###

arg list -> (dict, list)

- assume invoked as:
COMMAND kwargs [--] args

- kwargs is a Map[String -> String], args is a List[String]
- later options override earlier options

COMMAND (--arg=value|--arg value|-a value)* (--)? (value)*

###

user_short_switches = new Set [
  'a'
  'c'
]

user_long_switches = new Set [
  'asdf'
]

args = []
kwargs = {}
shortSwitches = []
longSwitches = []

previousLongArgName = null
previousShortArgName = null

argv = process.argv[2..]

shortToken = '[a-zA-Z]'
longToken = '[a-zA-Z][a-zA-Z_-]*'

throwOnAccidentalOption = no

accidentalArgErrMsg = (argWithDashes) ->
  "The argument '#{argWithDashes}' looks like a keyword argument, but isn't
  recognized "

for arg, i in argv
  if previousShortArgName?
    kwargs[previousShortArgName] = arg
    previousShortArgName = null
    continue

  if previousLongArgName?
    kwargs[previousLongArgName] = arg
    previousLongArgName = null
    continue

  longArgWithValue = arg.match ///^--(#{longToken})=(.*)$///
  if longArgWithValue?
    [_, argName, argValue] = longArgWithValue
    kwargs[argName] = argValue
    continue

  longArg = arg.match ///^--(#{longToken})$///
  if longArg?
    [_, argName] = longArg
    if user_long_switches.has(argName)
      longSwitches.push argName
    else
      previousLongArgName = argName
    continue

  # TODO: split combined short args (e.g. -uno)
  shortArg = arg.match ///^-(#{shortToken})$///
  if shortArg?
    [_, argName] = shortArg
    console.log "argName: #{argName}"
    if user_short_switches.has argName
      shortSwitches.push argName
    else
      previousShortArgName = argName
    continue

  accidentalArg = arg.match ///^-///
  if accidentalArg?
    # TODO: finish this -- does this make sense if we split combined short args?
    # throw new Error

  if arg is '--'
    args = argv[i+1..]
    break
  else
    args = argv[i..]
    break

previousArgErrMsg = (argWithDashes) ->
  "The last argument '#{argWithDashes}' requires a value after it in the
  argument list. If you meant to use this option, please provide an appropriate
  value (e.g. '#{argWithDashes} value')."

if previousShortArgName?
  throw new Error previousArgErrMsg("-#{previousShortArgName}")

if previousLongArgName?
  throw new Error previousArgErrMsg("--#{previousLongArgName}")

console.log 'process.argv:'
console.log process.argv
console.log 'args:'
console.log args
console.log 'kwargs:'
console.log kwargs
console.log 'shortSwitches:'
console.log shortSwitches
console.log 'longSwitches:'
console.log longSwitches
