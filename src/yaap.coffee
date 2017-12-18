###

arg list -> (dict, list)

- assume invoked as:
COMMAND kwargs [--] args

- kwargs is a Map[String -> String], args is a List[String]
- later options override earlier options

COMMAND (--arg=value|--arg value|-a value)* (--)? (value)*

###

argv = process.argv[2..]

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

shortArgToken = '[a-zA-Z]'
longArgToken = '[a-zA-Z][a-zA-Z_-]*'

class CombinedShortOptionsValueError extends Error
  constructor: (combinedNoDash, erroneousArg) ->
    argsDashed = combinedNoDash.split('').map (x) -> "-#{x}"

    super "The argument '-#{combinedNoDash}' is interpreted as the consecutive
    arguments #{argsDashed}. The switch '-#{erroneousArg}' is in the middle of
    the interpreted arguments, but that argument is not a switch. It requires a
    value (e.g. '-#{erroneousArg} value'). Move '#{erroneousArg}' to the end of
    the combined arguments, or separate it into a separate '-#{erroneousArg}'
    short keyword argument."

class PreviousArgNoValueError extends Error
  constructor: (argWithDashes) ->
    super "The last keyword argument '#{argWithDashes}' is not a switch. It
    requires a value after it in the argument list (e.g. '#{argWithDashes}
    value'). If you meant to use this option, please provide an appropriate
    value."

for arg, i in argv
  if previousShortArgName?
    if arg is '--'
      throw new PreviousArgNoValueError "-#{previousShortArgName}"
    kwargs[previousShortArgName] = arg
    previousShortArgName = null
    continue

  if previousLongArgName?
    if arg is '--'
      throw new PreviousArgNoValueError "--#{previousLongArgName}"
    kwargs[previousLongArgName] = arg
    previousLongArgName = null
    continue

  longArgWithValue = arg.match ///^--(#{longArgToken})=(.*)$///
  if longArgWithValue?
    [_, argName, argValue] = longArgWithValue
    kwargs[argName] = argValue
    continue

  longArg = arg.match ///^--(#{longArgToken})$///
  if longArg?
    [_, argName] = longArg
    if user_long_switches.has(argName)
      longSwitches.push argName
    else
      previousLongArgName = argName
    continue

  shortArg = arg.match ///^-((?:#{shortArgToken})+)$///
  if shortArg?
    [_, shortArguments] = shortArg
    [switchArgs..., maybeSwitchArg] = shortArguments.split ''
    for argName in switchArgs
      if user_short_switches.has argName
        shortSwitches.push argName
      else
        throw new CombinedShortOptionsValueError shortArguments, argName
    if user_short_switches.has maybeSwitchArg
      shortSwitches.push maybeSwitchArg
    else
      previousShortArgName = maybeSwitchArg
    continue

  if arg is '--'
    args = argv[i+1..]
    break
  else
    args = argv[i..]
    break

if previousShortArgName?
  throw new PreviousArgNoValueError "-#{previousShortArgName}"

if previousLongArgName?
  throw new PreviousArgNoValueError "--#{previousLongArgName}"



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
